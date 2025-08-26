#if canImport(Darwin)
    import Darwin
#elseif canImport(Glibc)
    @preconcurrency import Glibc
#elseif canImport(Musl)
    @preconcurrency import Musl
#else
    #error("Unsupported Platform")
#endif

import Foundation

extension addr2line {
    typealias Swift_Demangle = @convention(c) (
        _ mangledName: UnsafePointer<UInt8>?,
        _ mangledNameLength: Int,
        _ outputBuffer: UnsafeMutablePointer<UInt8>?,
        _ outputBufferSize: UnsafeMutablePointer<Int>?,
        _ flags: UInt32
    ) -> UnsafeMutablePointer<Int8>?

    static let swiftDemangleFunction: Swift_Demangle? = {
        let RTLD_DEFAULT = dlopen(nil, RTLD_NOW)
        guard let sym = dlsym(RTLD_DEFAULT, "swift_demangle") else {
            stderrLog("Warning: swift_demangle symbol not found")
            return nil
        }
        return unsafeBitCast(sym, to: Swift_Demangle.self)
    }()

    @inline(__always)
    static func _swiftDemangle(cString: UnsafePointer<CChar>) -> UnsafeMutablePointer<CChar>? {
        guard let demangleFunc = swiftDemangleFunction else {
            return nil
        }

        let count = strlen(cString)
        let uint8Pointer = UnsafeRawPointer(cString).assumingMemoryBound(to: UInt8.self)

        return demangleFunc(uint8Pointer, count, nil, nil, 0)
    }

    /// Demangles a Swift symbol name and prints the result to standard output.
    /// - Parameter cString: A C-style null-terminated string containing the mangled
    ///   Swift symbol name.
    /// - Returns: `true` if the symbol was successfully demangled and printed;
    ///   otherwise, `false`.
    @inline(__always)
    static func swiftDemangle(cString: UnsafePointer<CChar>) -> Bool {
        guard let cDemangled = _swiftDemangle(cString: cString) else {
            return false
        }
        defer { cDemangled.deallocate() }
        fputs(cDemangled, stdout)
        return true
    }

    static func swiftDemangle(_ mangled: String) -> String? {
        return mangled.withCString { cString in
            guard let cDemangled = _swiftDemangle(cString: cString) else {
                return nil
            }
            defer { cDemangled.deallocate() }
            return String(cString: cDemangled)
        }
    }

    static func getAddr2linePath() -> String {
        if let envPath = ProcessInfo.processInfo.environment["ADDR2LINE_PATH"] {
            return envPath
        }
        return "/usr/local/bin/addr2line-gimli"
    }

    static func stderrLog(_ message: String) {
        FileHandle.standardError.write(message.data(using: .utf8)!)
    }
}

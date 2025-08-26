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

@main
struct addr2line {
    static func main() throws {
        guard swiftDemangleFunction != nil else {
            stderrLog("Failed to load swift_demangle\n")
            exit(EXIT_FAILURE)
        }

        let addr2linePath = getAddr2linePath()
        guard FileManager.default.isExecutableFile(atPath: addr2linePath) else {
            stderrLog("Error: addr2line not found at \(addr2linePath)\n")
            exit(EXIT_FAILURE)
        }

        let outPipe = Pipe()
        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: addr2linePath)
        proc.arguments = Array(CommandLine.arguments.dropFirst())
        proc.standardInput = FileHandle.standardInput // Inherit our stdin directly
        proc.standardOutput = outPipe
        proc.standardError = FileHandle.standardError

        try proc.run()

        processAddr2LineOutput(fd: outPipe.fileHandleForReading.fileDescriptor)

        proc.waitUntilExit()
        exit(proc.terminationStatus)
    }

    static func processAddr2LineOutput(fd: Int32) {
        guard let inputPipe = fdopen(fd, "r") else { return }
        defer { fclose(inputPipe) }

        setvbuf(inputPipe, nil, _IONBF, 0)
        setvbuf(stdout, nil, _IOLBF, 0)

        var linePtr: UnsafeMutablePointer<CChar>? = nil
        var cap = 0
        defer { free(linePtr) }

        while getline(&linePtr, &cap, inputPipe) > 0 {
            guard let line = linePtr else { continue }
            if let newline = strchr(line, Int32(UInt8(ascii: "\n"))) {
                newline.pointee = 0
            }
            // Attempt to demangle if Swift
            let isDemangled =
                line.pointee == CChar(UInt8(ascii: "$"))
                    && line.advanced(by: 1).pointee == CChar(UInt8(ascii: "s"))
                    && swiftDemangle(cString: line)

            // Not Swift, print what is passed from addr2line
            if !isDemangled {
                fputs(line, stdout)
            }
            fputc(Int32(UInt8(ascii: "\n")), stdout)
        }
    }
}

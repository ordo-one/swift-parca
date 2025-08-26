@testable import addr2line_swift
import Testing

@Suite("Swift Symbol Demangling")
struct DemangleTests {
    @Test("FoundationEssentials closure demangling")
    func demangling() throws {
        let mangled = "$s20FoundationEssentials15JSONDecoderImpl33_B7023549748C8ED7BD56D5ACF500CBFALLC6unwrap_2as3for_xAA7JSONMapC5ValueO_xmAA15_CodingPathNodeOq_SgtKSeRzs0Q3KeyR_r0_lFxyKXEfU_"
        let expected = "closure #1 () throws -> A in FoundationEssentials.(JSONDecoderImpl in _B7023549748C8ED7BD56D5ACF500CBFA).unwrap<A, B where A: Swift.Decodable, B: Swift.CodingKey>(_: FoundationEssentials.JSONMap.Value, as: A.Type, for: FoundationEssentials._CodingPathNode, _: Swift.Optional<B>) throws -> A"

        let result = addr2line.swiftDemangle(mangled)
        #expect(result == expected)
    }

    @Test("Protocol witness demangling")
    func protocolWitnessDemangling() throws {
        let mangled = "$s20FoundationEssentials15JSONDecoderImpl33_B7023549748C8ED7BD56D5ACF500CBFALLC14KeyedContainerVy_xGs0l8DecodingM8ProtocolAAsAHP6decode_6forKeyqd__qd__m_0R0QztKSeRd__lFTW"
        let expected = "protocol witness for Swift.KeyedDecodingContainerProtocol.decode<A where A1: Swift.Decodable>(_: A1.Type, forKey: A.Key) throws -> A1 in conformance FoundationEssentials.(JSONDecoderImpl in _B7023549748C8ED7BD56D5ACF500CBFA).KeyedContainer<A> : Swift.KeyedDecodingContainerProtocol in FoundationEssentials"

        let result = addr2line.swiftDemangle(mangled)
        #expect(result == expected)
    }

    @Test("C++ symbol demangling")
    func cppDemangling() throws {
        let cppSymbol = "_ZNK3MapIiSsE3getERKi" // Map<int, std::string>::get(int const&) const
        let result = addr2line.swiftDemangle(cppSymbol)
        #expect(result == nil)
    }

    @Test("Invalid/empty symbol handling")
    func invalidSymbolHandling() throws {
        let invalidSymbols = [
            "", // Empty string
            "not_a_mangled_symbol", // Plain text
            "$s", // Incomplete Swift mangle
            "_Z", // Incomplete C++ mangle
            "random_text_123", // Random text
        ]

        for symbol in invalidSymbols {
            let result = addr2line.swiftDemangle(symbol)
            // Invalid symbols should return nil or remain unchanged
            #expect(result == nil || result == symbol,
                    "Invalid symbol '\(symbol)' should not be changed")
        }
    }
}

import Testing

@testable import APICompatibilityKit

@Suite("Compatibility mapping discovery")
struct CompatibilityMappingDiscoveryTests {
    @Test("Discovers a unique exact structural mapping")
    func discoversExactMapping() throws {
        let fixture = try exactFixture()

        let candidates = CompatibilityMappingDiscovery().discover(
            referenceSet: fixture.referenceSet,
            tuikitSet: fixture.tuikitSet
        )

        #expect(
            candidates == [
                CompatibilityMappingCandidate(
                    referenceID: ReferenceID.widget,
                    tuikitSymbolID: TUIkitID.widget,
                    differences: []
                ),
            ]
        )
    }

    @Test("Reports every differing compatibility dimension")
    func reportsDifferences() throws {
        var referenceDetails = baseSemanticDetails(moduleName: "SwiftUI")
        var tuikitDetails = baseSemanticDetails(moduleName: "TUIkit")
        referenceDetails["availability"] = .string("Apple platforms")
        tuikitDetails["availability"] = .string("macOS and Linux")
        tuikitDetails["swiftActorIsolation"] = .string("MainActor")
        let fixture = try exactFixture(
            referenceSymbol: symbol(
                id: ReferenceID.widget,
                moduleName: "SwiftUI",
                semanticDetails: referenceDetails
            ),
            tuikitSymbol: symbol(
                id: TUIkitID.widget,
                moduleName: "TUIkit",
                semanticDetails: tuikitDetails
            )
        )

        let candidate = try #require(
            CompatibilityMappingDiscovery().discover(
                referenceSet: fixture.referenceSet,
                tuikitSet: fixture.tuikitSet
            ).first
        )

        #expect(candidate.differences == [.availability, .isolation])
    }

    @Test("Rejects ambiguous structural matches")
    func rejectsAmbiguousMatches() throws {
        let fixture = try exactFixture()
        let ambiguousTUIkitSet = try makeSet(
            name: "TUIkit",
            sources: [
                sourceFixture(
                    id: "tuikit-macos",
                    moduleName: "TUIkit",
                    symbols: [
                        symbol(id: TUIkitID.widget, moduleName: "TUIkit"),
                        symbol(id: "s:TUIkit.OtherWidget", moduleName: "TUIkit"),
                    ]
                ),
            ]
        )

        let candidates = CompatibilityMappingDiscovery().discover(
            referenceSet: fixture.referenceSet,
            tuikitSet: ambiguousTUIkitSet
        )

        #expect(candidates.isEmpty)
    }
}

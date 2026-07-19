import Testing

@testable import APICompatibilityKit

@Suite("Compatibility evidence validator")
struct CompatibilityEvidenceValidatorTests {
    @Test(
        "Accepts exact reference and TUIkit source provenance",
        arguments: [DecisionStatus.implemented, .verified]
    )
    func acceptsExactSourceProvenance(status: DecisionStatus) throws {
        var fixture = try exactFixture(
            additionalReferenceSources: [
                sourceFixture(
                    id: "reference-ios",
                    platform: "iOS",
                    symbols: [symbol(id: ReferenceID.widget, moduleName: "SwiftUI")]
                ),
            ],
            additionalTUIkitSources: [
                sourceFixture(
                    id: "tuikit-linux",
                    moduleName: "TUIkit",
                    platform: "Linux",
                    symbols: [symbol(id: TUIkitID.widget, moduleName: "TUIkit")]
                ),
            ]
        )
        fixture.manifest.decisions[0].status = status

        let diagnostics = validate(fixture)

        #expect(diagnostics.isEmpty)
    }

    @Test("Reports every missing occurrence source")
    func rejectsMissingSourceEvidence() throws {
        var fixture = try exactFixture(
            additionalReferenceSources: [
                sourceFixture(
                    id: "reference-ios",
                    platform: "iOS",
                    symbols: [symbol(id: ReferenceID.widget, moduleName: "SwiftUI")]
                ),
            ],
            additionalTUIkitSources: [
                sourceFixture(
                    id: "tuikit-linux",
                    moduleName: "TUIkit",
                    platform: "Linux",
                    symbols: [symbol(id: TUIkitID.widget, moduleName: "TUIkit")]
                ),
            ]
        )
        fixture.manifest.decisions[0].evidence.removeAll {
            $0.reference == "reference-ios" || $0.reference == "tuikit-linux"
        }

        let diagnostics = validate(fixture)

        #expect(diagnostics.map(\.code) == [
            "evidence.reference-source-missing",
            "evidence.tuikit-source-missing",
        ])
        #expect(diagnostics[0].message.contains("reference-ios"))
        #expect(diagnostics[1].message.contains("tuikit-linux"))
    }

    @Test("Distinguishes unknown IDs from existing sources without the symbol")
    func rejectsUnknownAndAdditionalSources() throws {
        var fixture = try exactFixture(
            additionalReferenceSources: [
                sourceFixture(id: "reference-empty", symbols: []),
            ],
            additionalTUIkitSources: [
                sourceFixture(
                    id: "tuikit-empty",
                    moduleName: "TUIkit",
                    platform: "Linux",
                    symbols: []
                ),
            ]
        )
        fixture.manifest.decisions[0].evidence += [
            CompatibilityEvidence(kind: .tuikitSymbolGraph, reference: "tuikit-unknown"),
            CompatibilityEvidence(kind: .referenceSymbolGraph, reference: "reference-unknown"),
            CompatibilityEvidence(kind: .tuikitSymbolGraph, reference: "tuikit-empty"),
            CompatibilityEvidence(kind: .referenceSymbolGraph, reference: "reference-empty"),
        ]

        let diagnostics = validate(fixture)

        #expect(diagnostics.map(\.code) == [
            "evidence.reference-source-additional",
            "evidence.reference-source-unknown",
            "evidence.tuikit-source-unknown",
            "evidence.tuikit-source-unproven",
        ])
        #expect(diagnostics == diagnostics.sorted())
    }

    @Test("Rejects duplicate source evidence")
    func rejectsDuplicateSourceEvidence() throws {
        var fixture = try exactFixture()
        fixture.manifest.decisions[0].evidence += [
            CompatibilityEvidence(kind: .tuikitSymbolGraph, reference: "tuikit-macos"),
            CompatibilityEvidence(kind: .referenceSymbolGraph, reference: "reference-macos"),
        ]

        let diagnostics = validate(fixture)

        #expect(diagnostics.map(\.code) == [
            "evidence.reference-source-duplicate",
            "evidence.tuikit-source-duplicate",
        ])
    }

    @Test("Every required TUIkit module source must contain an implemented symbol")
    func rejectsMissingTUIkitPlatformOccurrence() throws {
        let fixture = try exactFixture(
            additionalTUIkitSources: [
                sourceFixture(
                    id: "tuikit-linux",
                    moduleName: "TUIkit",
                    platform: "Linux",
                    symbols: []
                ),
            ]
        )

        let diagnostics = validate(fixture)

        #expect(diagnostics.map(\.code) == ["evidence.tuikit-source-unproven"])
        #expect(diagnostics[0].message.contains("tuikit-linux"))
    }

    @Test("A TUIkit symbol cannot be sourced from multiple modules")
    func rejectsAmbiguousTUIkitModule() throws {
        let fixture = try exactFixture(
            additionalTUIkitSources: [
                sourceFixture(
                    id: "tuikit-core-linux",
                    moduleName: "TUIkitCore",
                    platform: "Linux",
                    symbols: [symbol(id: TUIkitID.widget, moduleName: "TUIkit")]
                ),
            ]
        )

        let diagnostics = validate(fixture)

        #expect(diagnostics.map(\.code).contains("evidence.tuikit-module-ambiguous"))
    }

    @Test("Planned and excluded decisions forbid TUIkit snapshot evidence")
    func forbidsTUIkitEvidenceWithoutCurrentImplementation() throws {
        for state in [(InclusionDecision.include, DecisionStatus.planned), (.exclude, .verified)] {
            var fixture = try exactFixture()
            fixture.manifest.decisions[0].inclusion = state.0
            fixture.manifest.decisions[0].status = state.1
            fixture.manifest.decisions[0].tuikitSymbolID = nil

            let diagnostics = validate(fixture)

            #expect(diagnostics.map(\.code) == ["evidence.tuikit-forbidden"])
            #expect(diagnostics.first?.message.contains("tuikit-macos") == true)
        }
    }

    @Test("Uses directional symbol graph evidence kinds")
    func exposesDirectionalEvidenceKinds() {
        #expect(Set(CompatibilityEvidenceKind.allCases.map(\.rawValue)) == [
            "behaviorContract",
            "compileContract",
            "documentation",
            "referenceSymbolGraph",
            "tuikitSymbolGraph",
        ])
    }

    private func validate(_ fixture: SurfaceFixture) -> [APICheckDiagnostic] {
        CompatibilityEvidenceValidator().validate(
            fixture.manifest,
            referenceSet: fixture.referenceSet,
            tuikitSet: fixture.tuikitSet
        )
    }
}

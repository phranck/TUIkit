import Testing

@testable import APICompatibilityKit

@Suite("Compatibility manifest validator")
struct ManifestValidatorTests {
    @Test("Accepts a complete reviewed manifest")
    func acceptsValidManifest() throws {
        let manifest = try validManifest()

        let diagnostics = ManifestValidator().validate(manifest)

        #expect(diagnostics.isEmpty)
    }

    @Test("Requires reference IDs and decision IDs to match one-to-one")
    func requiresOneDecisionPerReference() throws {
        var manifest = try validManifest()
        manifest.referenceIDs.append("s:SwiftUI.Missing")
        manifest.referenceIDs.append("s:SwiftUI.Exact")
        manifest.decisions.append(manifest.decisions[0])

        let diagnostics = ManifestValidator().validate(manifest)

        #expect(diagnostics.map(\.code) == [
            "manifest.duplicate-decision",
            "manifest.duplicate-reference",
            "manifest.missing-decision",
        ])
        #expect(diagnostics.last?.description == "error[manifest.missing-decision]: Missing decision for 's:SwiftUI.Missing'")
    }

    @Test("Rejects every unreviewed reference decision")
    func rejectsUnreviewedDecision() throws {
        let manifest = try ManifestLoader().load(
            from: FixtureSupport.url("Manifests/unreviewed.json")
        )

        let diagnostics = ManifestValidator().validate(manifest)

        #expect(diagnostics.map(\.code) == ["manifest.unreviewed"])
        #expect(
            diagnostics.first?.description
                == "error[manifest.unreviewed]: Reference 's:SwiftUI.Pending' remains unreviewed"
        )
    }

    @Test("Include decisions require one nonempty owner issue and contract ID")
    func includeRequiresOwnershipAndContract() throws {
        var manifest = try validManifest()
        let index = try #require(manifest.decisions.firstIndex { $0.referenceID == "s:SwiftUI.Planned" })
        manifest.decisions[index].ownerIssue = "  "
        manifest.decisions[index].contractID = nil

        let diagnostics = ManifestValidator().validate(manifest)

        #expect(diagnostics.map(\.code) == [
            "manifest.include-contract",
            "manifest.include-owner",
        ])
    }

    @Test("Every reference records signatures, availability policy, and evidence")
    func requiresCompatibilityRecord() throws {
        var manifest = try validManifest()
        manifest.decisions[0].referenceSignature = " "
        manifest.decisions[0].tuikitSignature = nil
        manifest.decisions[0].evidence = []
        manifest.decisions[1].availability = AvailabilityDecision(
            policy: .terminalCrossPlatform,
            reason: "\n"
        )

        let diagnostics = ManifestValidator().validate(manifest)

        #expect(diagnostics.map(\.code).contains("manifest.reference-signature"))
        #expect(diagnostics.map(\.code).contains("manifest.tuikit-signature"))
        #expect(diagnostics.map(\.code).contains("manifest.evidence-required"))
        #expect(diagnostics.map(\.code).contains("manifest.availability-reason"))
    }

    @Test("Included references link exactly one matching compile or behavior contract")
    func requiresLinkedContractEvidence() throws {
        var manifest = try validManifest()
        let index = try #require(manifest.decisions.firstIndex { $0.inclusion == .include })
        manifest.decisions[index].evidence = [
            CompatibilityEvidence(kind: .referenceSymbolGraph, reference: "reference-macos"),
            CompatibilityEvidence(kind: .behaviorContract, reference: "behavior.other"),
        ]

        let diagnostics = ManifestValidator().validate(manifest)

        #expect(diagnostics.map(\.code) == ["manifest.contract-evidence"])
    }

    @Test("Planned includes reject mappings while implemented includes require them")
    func mappingMatchesStatus() throws {
        var manifest = try validManifest()
        let planned = try #require(manifest.decisions.firstIndex { $0.referenceID == "s:SwiftUI.Planned" })
        let implemented = try #require(manifest.decisions.firstIndex { $0.referenceID == "s:SwiftUI.Exception" })
        manifest.decisions[planned].tuikitSymbolID = "s:TUIkit.Future"
        manifest.decisions[implemented].tuikitSymbolID = nil

        let diagnostics = ManifestValidator().validate(manifest)

        #expect(diagnostics.map(\.code) == [
            "manifest.mapping-forbidden",
            "manifest.mapping-required",
        ])
    }

    @Test("Exclude decisions require an allowed category and a concrete reason", arguments: ExclusionCategory.allCases)
    func excludesUseAllowedCategories(category: ExclusionCategory) throws {
        var manifest = try validManifest()
        let index = try #require(manifest.decisions.firstIndex { $0.inclusion == .exclude })
        manifest.decisions[index].exclusion = ExclusionDecision(category: category, reason: "  ")

        let diagnostics = ManifestValidator().validate(manifest)

        #expect(diagnostics.map(\.code) == ["manifest.exclusion-reason"])
        #expect(Set(ExclusionCategory.allCases.map(\.rawValue)) == [
            "appleRepresentable",
            "rasterOrGPU",
            "touchOrSpatialInput",
            "windowServer",
        ])
    }

    @Test("Exclude decisions reject include-only ownership and mapping fields")
    func excludesRejectIncludeFields() throws {
        var manifest = try validManifest()
        let index = try #require(manifest.decisions.firstIndex { $0.inclusion == .exclude })
        manifest.decisions[index].ownerIssue = "#999"
        manifest.decisions[index].contractID = "compile.invalid"
        manifest.decisions[index].tuikitSymbolID = "s:TUIkit.Invalid"

        let diagnostics = ManifestValidator().validate(manifest)

        #expect(diagnostics.map(\.code) == ["manifest.exclusion-fields"])
    }

    @Test("Uses the exact reviewed TUIkit classifications")
    func usesExpectedTUIkitClassifications() {
        #expect(Set(TUIkitClassification.allCases.map(\.rawValue)) == [
            "implementationLeak",
            "reviewedException",
            "swiftUIExact",
            "tuiSpecific",
        ])
    }

    @Test("Reviewed exceptions require a supported exception kind and reason")
    func reviewedExceptionRequiresDetails() throws {
        var manifest = try validManifest()
        let index = try #require(
            manifest.tuikitDecisions.firstIndex { $0.classification == .reviewedException }
        )
        manifest.tuikitDecisions[index].exception = CompatibilityException(
            kind: .compilerFloor,
            reason: "",
            allowedDifferences: [.isolation]
        )

        let diagnostics = ManifestValidator().validate(manifest)

        #expect(diagnostics.map(\.code) == ["manifest.exception-reason"])
        #expect(Set(CompatibilityExceptionKind.allCases.map(\.rawValue)) == ["compilerFloor", "terminal"])
    }

    @Test("Reviewed exceptions explicitly allow every compatibility difference")
    func reviewedExceptionRequiresAllowedDifferences() throws {
        var manifest = try validManifest()
        let index = try #require(
            manifest.tuikitDecisions.firstIndex { $0.classification == .reviewedException }
        )
        manifest.tuikitDecisions[index].exception?.allowedDifferences = []

        let diagnostics = ManifestValidator().validate(manifest)

        #expect(diagnostics.map(\.code) == ["manifest.exception-differences"])
        #expect(Set(CompatibilityDifference.allCases.map(\.rawValue)) == [
            "availability",
            "declaration",
            "generics",
            "isolation",
            "kind",
            "relationships",
            "sendability",
        ])
    }

    @Test("Implementation leaks require an owning issue")
    func implementationLeakRequiresOwner() throws {
        var manifest = try validManifest()
        let index = try #require(
            manifest.tuikitDecisions.firstIndex { $0.classification == .implementationLeak }
        )
        manifest.tuikitDecisions[index].ownerIssue = nil

        let diagnostics = ManifestValidator().validate(manifest)

        #expect(diagnostics.map(\.code) == ["manifest.leak-owner"])
    }

    @Test("Exact and reviewed mappings are bidirectional")
    func mappingsAreBidirectional() throws {
        var manifest = try validManifest()
        let index = try #require(
            manifest.tuikitDecisions.firstIndex { $0.classification == .swiftUIExact }
        )
        manifest.tuikitDecisions[index].referenceID = "s:SwiftUI.Exception"

        let diagnostics = ManifestValidator().validate(manifest)

        #expect(diagnostics.map(\.code) == [
            "manifest.mapping-backlink",
            "manifest.mapping-backlink",
        ])
    }

    @Test("Exact mappings require an implemented or verified included reference")
    func exactMappingsRequireImplementedIncludedReference() throws {
        var manifest = try validManifest()
        manifest.tuikitDecisions.append(
            TUIkitSymbolDecision(
                symbolID: "s:TUIkit.Future",
                classification: .swiftUIExact,
                referenceID: "s:SwiftUI.Planned"
            )
        )

        let diagnostics = ManifestValidator().validate(manifest)

        #expect(diagnostics.map(\.code) == ["manifest.mapping-backlink"])
        #expect(
            diagnostics.first?.description
                == "error[manifest.mapping-backlink]: Mapping between 's:SwiftUI.Planned' and 's:TUIkit.Future' is not bidirectional"
        )
    }

    @Test("Rejects empty and whitespace-only manifest identities")
    func rejectsEmptyIdentities() throws {
        var manifest = try validManifest()
        manifest.referenceIDs[0] = " "
        manifest.decisions[0].referenceID = "\n"
        manifest.tuikitDecisions[0].symbolID = ""

        let diagnostics = ManifestValidator().validate(manifest)

        #expect(diagnostics.map(\.code).contains("manifest.empty-reference"))
        #expect(diagnostics.map(\.code).contains("manifest.empty-decision-id"))
        #expect(diagnostics.map(\.code).contains("manifest.empty-tuikit-symbol"))
    }

    private func validManifest() throws -> CompatibilityManifest {
        try ManifestLoader().load(from: FixtureSupport.url("Manifests/valid.json"))
    }
}

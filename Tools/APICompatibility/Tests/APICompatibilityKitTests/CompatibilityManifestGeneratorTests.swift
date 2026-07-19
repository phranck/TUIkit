import Foundation
import Testing

@testable import APICompatibilityKit

@Suite("Compatibility manifest generator")
struct CompatibilityManifestGeneratorTests {
    @Test("Generates a complete schema 2 manifest from SwiftUI and SwiftUICore")
    func generatesCompleteManifest() throws {
        let policy = try CompatibilityReviewPolicyCodec().load(
            from: FixtureSupport.url("Policies/valid.json")
        )
        let fixture = try generatorFixture()

        let manifest = try manifestGenerator().generate(
            policy: policy,
            referenceSet: fixture.referenceSet,
            tuikitSet: fixture.tuikitSet
        )

        #expect(manifest.schemaVersion == 2)
        #expect(manifest.referenceIDs == manifest.referenceIDs.sorted())
        #expect(manifest.referenceIDs == [
            "s:SwiftUI.ImageRenderer",
            "s:SwiftUI.Widget",
            "s:SwiftUICore.Gadget",
        ])
        #expect(manifest.decisions.map(\.referenceID) == manifest.referenceIDs)
        #expect(manifest.tuikitDecisions.map(\.symbolID) == [
            "s:TUIkit.Gadget",
            "s:TUIkit.TerminalOnly",
            "s:TUIkit.Widget",
        ])
        #expect(
            manifest.decisions
                .filter { $0.inclusion == .include }
                .map(\.contractID) == ["compile.core-controls", "compile.core-controls"]
        )
        #expect(
            manifest.tuikitDecisions
                .filter { $0.classification == .swiftUIExact }
                .count == 2
        )
        #expect(
            manifest.tuikitDecisions
                .first { $0.symbolID == "s:TUIkit.TerminalOnly" }?
                .classification == .tuiSpecific
        )
        #expect(ManifestValidator().validate(manifest).isEmpty)
    }

    @Test("Writes byte-identical canonical output independent of policy ordering")
    func writesDeterministicManifest() throws {
        let fixture = try generatorFixture()
        let policy = try CompatibilityReviewPolicyCodec().load(
            from: FixtureSupport.url("Policies/valid.json")
        )
        let first = try manifestGenerator().generate(
            policy: policy,
            referenceSet: fixture.referenceSet,
            tuikitSet: fixture.tuikitSet
        )
        var reorderedPolicy = policy
        reorderedPolicy.referenceRules.reverse()
        for index in reorderedPolicy.referenceRules.indices {
            reorderedPolicy.referenceRules[index].referenceIDs.reverse()
        }
        reorderedPolicy.tuikitOverrides.reverse()
        let second = try manifestGenerator().generate(
            policy: reorderedPolicy,
            referenceSet: fixture.referenceSet,
            tuikitSet: fixture.tuikitSet
        )

        let codec = CompatibilityManifestCodec()
        let firstData = try codec.encode(first)
        let secondData = try codec.encode(second)

        #expect(firstData == secondData)
        #expect(firstData.last == 0x0A)
    }

    @Test("Fails closed when a reference has no review rule")
    func rejectsUnmatchedReference() throws {
        let fixture = try generatorFixture()
        var policy = try CompatibilityReviewPolicyCodec().load(
            from: FixtureSupport.url("Policies/valid.json")
        )
        policy.referenceRules.removeAll { $0.id == "exclude-raster-rendering" }

        let failure = FixtureSupport.diagnostic {
            try manifestGenerator().generate(
                policy: policy,
                referenceSet: fixture.referenceSet,
                tuikitSet: fixture.tuikitSet
            )
        }

        #expect(failure?.code == "review-policy.reference-unmatched")
        #expect(failure?.message == "Reference 's:SwiftUI.ImageRenderer' matches no review rule")
    }

    @Test("Fails closed when ordered rules overlap")
    func rejectsMultiplyMatchedReference() throws {
        let fixture = try generatorFixture()
        var policy = try CompatibilityReviewPolicyCodec().load(
            from: FixtureSupport.url("Policies/valid.json")
        )
        policy.referenceRules[0].referenceIDs.append("s:SwiftUI.ImageRenderer")

        let failure = FixtureSupport.diagnostic {
            try manifestGenerator().generate(
                policy: policy,
                referenceSet: fixture.referenceSet,
                tuikitSet: fixture.tuikitSet
            )
        }

        #expect(failure?.code == "review-policy.reference-multiply-matched")
        #expect(
            failure?.message
                == "Reference 's:SwiftUI.ImageRenderer' matches multiple review rules "
                    + "[include-core-controls, exclude-raster-rendering]"
        )
    }

    @Test("Does not equate unrelated modules while looking for exact mappings")
    func rejectsBroadModuleSubstitution() throws {
        let fixture = try generatorFixture(referenceWidgetTypeModule: "SwiftUICore")
        let policy = try CompatibilityReviewPolicyCodec().load(
            from: FixtureSupport.url("Policies/valid.json")
        )

        let failure = FixtureSupport.diagnostic {
            try manifestGenerator().generate(
                policy: policy,
                referenceSet: fixture.referenceSet,
                tuikitSet: fixture.tuikitSet
            )
        }

        #expect(failure?.code == "manifest-generator.implemented-unmapped")
        #expect(failure?.message.contains("s:SwiftUI.Widget") == true)
    }

    @Test("Requires an explicit override for a structural signature match")
    func rejectsUnreviewedSignatureDifference() throws {
        let fixture = try generatorFixture(tuikitWidgetDeclarationSuffix: " async")
        let policy = try CompatibilityReviewPolicyCodec().load(
            from: FixtureSupport.url("Policies/valid.json")
        )

        let failure = FixtureSupport.diagnostic {
            try manifestGenerator().generate(
                policy: policy,
                referenceSet: fixture.referenceSet,
                tuikitSet: fixture.tuikitSet
            )
        }

        #expect(failure?.code == "manifest-generator.implemented-unmapped")
    }

    @Test("Availability drift always requires a reviewed mapping override")
    func rejectsExactAvailabilityDrift() throws {
        let fixture = try generatorFixture(
            referenceWidgetAvailability: "macOS 26",
            tuikitWidgetAvailability: "macOS and Linux"
        )
        var policy = try CompatibilityReviewPolicyCodec().load(
            from: FixtureSupport.url("Policies/valid.json")
        )
        policy.referenceRules[0].action.availability = AvailabilityDecision(
            policy: .terminalCrossPlatform,
            reason: "TUIkit supports terminals on every platform."
        )

        let automaticFailure = FixtureSupport.diagnostic {
            try manifestGenerator().generate(
                policy: policy,
                referenceSet: fixture.referenceSet,
                tuikitSet: fixture.tuikitSet
            )
        }
        #expect(automaticFailure?.code == "manifest-generator.implemented-unmapped")

        policy.tuikitOverrides.append(
            TUIkitReviewOverride(
                symbolID: "s:TUIkit.Widget",
                action: .mapExact,
                referenceID: "s:SwiftUI.Widget"
            )
        )
        let explicitFailure = FixtureSupport.diagnostic {
            try manifestGenerator().generate(
                policy: policy,
                referenceSet: fixture.referenceSet,
                tuikitSet: fixture.tuikitSet
            )
        }
        #expect(explicitFailure?.code == "manifest-generator.exact-surface-mismatch")

        policy.tuikitOverrides[policy.tuikitOverrides.count - 1] = reviewedWidgetOverride(
            allowedDifferences: [.availability]
        )
        let manifest = try manifestGenerator().generate(
            policy: policy,
            referenceSet: fixture.referenceSet,
            tuikitSet: fixture.tuikitSet
        )
        #expect(
            manifest.tuikitDecisions.first { $0.symbolID == "s:TUIkit.Widget" }?
                .classification == .reviewedException
        )
    }

    @Test("Rejects a reviewed override that does not allow the observed difference")
    func rejectsIncompleteReviewedOverride() throws {
        let fixture = try generatorFixture(tuikitWidgetDeclarationSuffix: " async")
        var policy = try CompatibilityReviewPolicyCodec().load(
            from: FixtureSupport.url("Policies/valid.json")
        )
        policy.tuikitOverrides.append(
            reviewedWidgetOverride(allowedDifferences: [.availability])
        )

        let failure = FixtureSupport.diagnostic {
            try manifestGenerator().generate(
                policy: policy,
                referenceSet: fixture.referenceSet,
                tuikitSet: fixture.tuikitSet
            )
        }

        #expect(failure?.code == "surface.declaration")
    }

    @Test("Records a signature deviation as an explicit reviewed exception")
    func acceptsCompleteReviewedOverride() throws {
        let fixture = try generatorFixture(tuikitWidgetDeclarationSuffix: " async")
        var policy = try CompatibilityReviewPolicyCodec().load(
            from: FixtureSupport.url("Policies/valid.json")
        )
        policy.tuikitOverrides.append(
            reviewedWidgetOverride(allowedDifferences: [.declaration])
        )

        let manifest = try manifestGenerator().generate(
            policy: policy,
            referenceSet: fixture.referenceSet,
            tuikitSet: fixture.tuikitSet
        )

        let decision = try #require(
            manifest.tuikitDecisions.first { $0.symbolID == "s:TUIkit.Widget" }
        )
        #expect(decision.classification == .reviewedException)
        #expect(decision.exception?.allowedDifferences == [.declaration])
        #expect(
            CompatibilitySurfaceValidator().validate(
                manifest,
                referenceSet: fixture.referenceSet,
                tuikitSet: fixture.tuikitSet
            ).isEmpty
        )
    }

    @Test("Keeps per-symbol planned signatures while sharing one contract")
    func supportsSharedPlannedContract() throws {
        let fixture = try generatorFixture()
        var policy = try CompatibilityReviewPolicyCodec().load(
            from: FixtureSupport.url("Policies/valid.json")
        )
        policy.referenceRules[0].action.status = .planned
        policy.referenceRules[0].action.plannedTUIkitSignatures = [
            "s:SwiftUI.Widget": "func widget(_ value: TUIkit.Value) -> TUIkit.Text",
            "s:SwiftUICore.Gadget": "func gadget(_ value: TUIkit.Value) -> TUIkit.Text",
        ]
        policy.tuikitOverrides += [
            TUIkitReviewOverride(
                symbolID: "s:TUIkit.Widget",
                action: .implementationLeak,
                ownerIssue: "#18"
            ),
            TUIkitReviewOverride(
                symbolID: "s:TUIkit.Gadget",
                action: .implementationLeak,
                ownerIssue: "#18"
            ),
        ]

        let manifest = try manifestGenerator().generate(
            policy: policy,
            referenceSet: fixture.referenceSet,
            tuikitSet: fixture.tuikitSet
        )

        let planned = manifest.decisions.filter { $0.status == .planned }
        #expect(planned.count == 2)
        #expect(Set(planned.compactMap(\.contractID)) == ["compile.core-controls"])
        #expect(Dictionary(uniqueKeysWithValues: planned.map {
            ($0.referenceID, $0.tuikitSignature)
        }) == [
            "s:SwiftUI.Widget": "func widget(_ value: TUIkit.Value) -> TUIkit.Text",
            "s:SwiftUICore.Gadget": "func gadget(_ value: TUIkit.Value) -> TUIkit.Text",
        ])
    }

    @Test("Rejects duplicate reference IDs within one explicit rule")
    func rejectsDuplicateRuleReference() throws {
        let fixture = try generatorFixture()
        var policy = try CompatibilityReviewPolicyCodec().load(
            from: FixtureSupport.url("Policies/valid.json")
        )
        policy.referenceRules[0].referenceIDs.append("s:SwiftUI.Widget")

        let failure = FixtureSupport.diagnostic {
            try manifestGenerator().generate(
                policy: policy,
                referenceSet: fixture.referenceSet,
                tuikitSet: fixture.tuikitSet
            )
        }

        #expect(failure?.code == "review-policy.duplicate-rule-reference")
        #expect(failure?.message.contains("include-core-controls") == true)
    }

    @Test("A review policy cannot authorize an arbitrary owner issue")
    func rejectsSelfAuthorizedOwnerIssue() throws {
        let fixture = try generatorFixture()
        var policy = try CompatibilityReviewPolicyCodec().load(
            from: FixtureSupport.url("Policies/valid.json")
        )
        policy.referenceRules[0].action.ownerIssue = "#999"

        let failure = FixtureSupport.diagnostic {
            try manifestGenerator().generate(
                policy: policy,
                referenceSet: fixture.referenceSet,
                tuikitSet: fixture.tuikitSet
            )
        }

        #expect(failure?.code == "review-policy.owner-issue")
        #expect(failure?.message.contains("#999") == true)
    }

    @Test("Owner registry metadata is strict and repository-bound")
    func rejectsMalformedOwnerRegistry() throws {
        let fixture = try generatorFixture()
        let policy = try CompatibilityReviewPolicyCodec().load(
            from: FixtureSupport.url("Policies/valid.json")
        )
        var registry = try CompatibilityOwnerRegistryCodec().load(
            from: FixtureSupport.url("Policies/owners.json")
        )
        registry.issues[0].url = "https://github.com/other/project/issues/17"

        let urlFailure = FixtureSupport.diagnostic {
            try manifestGenerator(ownerRegistry: registry).generate(
                policy: policy,
                referenceSet: fixture.referenceSet,
                tuikitSet: fixture.tuikitSet
            )
        }
        #expect(urlFailure?.code == "owner-registry.issue-url")

        registry = try CompatibilityOwnerRegistryCodec().load(
            from: FixtureSupport.url("Policies/owners.json")
        )
        registry.repository = "phranck/TUIkit/issues"
        let repositoryFailure = FixtureSupport.diagnostic {
            try manifestGenerator(ownerRegistry: registry).generate(
                policy: policy,
                referenceSet: fixture.referenceSet,
                tuikitSet: fixture.tuikitSet
            )
        }
        #expect(repositoryFailure?.code == "owner-registry.repository")

        registry = try CompatibilityOwnerRegistryCodec().load(
            from: FixtureSupport.url("Policies/owners.json")
        )
        registry.issues.swapAt(0, 1)
        let orderFailure = FixtureSupport.diagnostic {
            try manifestGenerator(ownerRegistry: registry).generate(
                policy: policy,
                referenceSet: fixture.referenceSet,
                tuikitSet: fixture.tuikitSet
            )
        }
        #expect(orderFailure?.code == "owner-registry.issue-number")
    }

    @Test("Does not auto-map an ambiguous structural match")
    func rejectsAmbiguousStructuralMatch() throws {
        let fixture = try generatorFixture(includeAmbiguousWidget: true)
        let policy = try CompatibilityReviewPolicyCodec().load(
            from: FixtureSupport.url("Policies/valid.json")
        )

        let failure = FixtureSupport.diagnostic {
            try manifestGenerator().generate(
                policy: policy,
                referenceSet: fixture.referenceSet,
                tuikitSet: fixture.tuikitSet
            )
        }

        #expect(failure?.code == "manifest-generator.implemented-unmapped")
        #expect(failure?.message.contains("s:SwiftUI.Widget") == true)
    }

    @Test("Resolves ambiguity only through explicit mapping and ownership")
    func resolvesAmbiguityExplicitly() throws {
        let fixture = try generatorFixture(includeAmbiguousWidget: true)
        var policy = try CompatibilityReviewPolicyCodec().load(
            from: FixtureSupport.url("Policies/valid.json")
        )
        policy.tuikitOverrides += [
            TUIkitReviewOverride(
                symbolID: "s:TUIkit.Widget",
                action: .mapExact,
                referenceID: "s:SwiftUI.Widget"
            ),
            TUIkitReviewOverride(
                symbolID: "s:TUIkit.WidgetAlias",
                action: .implementationLeak,
                ownerIssue: "#18"
            ),
        ]

        let manifest = try manifestGenerator().generate(
            policy: policy,
            referenceSet: fixture.referenceSet,
            tuikitSet: fixture.tuikitSet
        )

        #expect(
            manifest.decisions.first { $0.referenceID == "s:SwiftUI.Widget" }?
                .tuikitSymbolID == "s:TUIkit.Widget"
        )
        #expect(
            manifest.tuikitDecisions.first { $0.symbolID == "s:TUIkit.WidgetAlias" }?
                .classification == .implementationLeak
        )
    }
}

func generatorSymbol(
    id: String,
    moduleName: String,
    name: String,
    typeModuleName: String? = nil,
    declarationSuffix: String = "",
    availability: String? = nil
) -> CanonicalSymbol {
    let typeModuleName = typeModuleName ?? moduleName
    let declaration = "func \(name)(_ value: \(typeModuleName).Value) -> \(typeModuleName).Text\(declarationSuffix)"
    var fragments = [
        CanonicalDeclarationFragment(kind: "keyword", spelling: "func", preciseIdentifier: nil),
        CanonicalDeclarationFragment(kind: "text", spelling: " ", preciseIdentifier: nil),
        CanonicalDeclarationFragment(kind: "identifier", spelling: name, preciseIdentifier: id),
        CanonicalDeclarationFragment(kind: "text", spelling: "(_ value: ", preciseIdentifier: nil),
        CanonicalDeclarationFragment(
            kind: "typeIdentifier",
            spelling: "\(typeModuleName).Value",
            preciseIdentifier: nil
        ),
        CanonicalDeclarationFragment(kind: "text", spelling: ") -> ", preciseIdentifier: nil),
        CanonicalDeclarationFragment(
            kind: "typeIdentifier",
            spelling: "\(typeModuleName).Text",
            preciseIdentifier: nil
        ),
    ]
    if !declarationSuffix.isEmpty {
        fragments.append(
            CanonicalDeclarationFragment(kind: "text", spelling: declarationSuffix, preciseIdentifier: nil)
        )
    }
    var semanticDetails = baseSemanticDetails(moduleName: typeModuleName)
    if let availability {
        semanticDetails["availability"] = .string(availability)
    }
    return CanonicalSymbol(
        preciseIdentifier: id,
        kindIdentifier: "swift.func",
        title: "\(name)(_:)",
        pathComponents: [name.capitalized, "\(name)(_:)"],
        canonicalDeclaration: declaration,
        declarationFragments: fragments,
        accessLevel: "public",
        semanticDetails: semanticDetails
    )
}

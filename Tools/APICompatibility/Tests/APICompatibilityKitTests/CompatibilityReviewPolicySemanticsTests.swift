import Testing

@testable import APICompatibilityKit

@Suite("Compatibility review policy semantics")
struct CompatibilityReviewPolicySemanticsTests {
    @Test(
        "Rejects nonportable planned terminal signatures",
        arguments: [
            "init(nsColor: NSColor)",
            "init(_ image: CGImage)",
            "func gesture(_ representable: some UIGestureRecognizerRepresentable) -> some View",
            "func onCommand(_ selector: Selector) -> some View",
            "func resolve(in space: some CoordinateSpace3D)",
        ]
    )
    func rejectsNonportableTerminalSignature(_ signature: String) throws {
        let failure = try policyFailure(
            referenceSignature: signature,
            plannedSignature: signature,
            availability: .terminalCrossPlatform
        )

        #expect(failure?.code == "review-policy.nonportable-signature")
    }

    @Test("Requires the compiler-floor policy for type-level nonisolated")
    func requiresCompilerFloorForTypeIsolation() throws {
        let failure = try policyFailure(
            referenceSignature: "nonisolated struct LayoutRotationUnaryLayout",
            plannedSignature: "struct LayoutRotationUnaryLayout",
            availability: .terminalCrossPlatform
        )

        #expect(failure?.code == "review-policy.compiler-floor")
    }

    @Test("Rejects compiler-floor policy for Swift 6.0 syntax")
    func rejectsCompilerFloorForSupportedSyntax() throws {
        let signature = "func task(action: sending @escaping @isolated(any) () async -> Void)"
        let failure = try policyFailure(
            referenceSignature: signature,
            plannedSignature: signature,
            availability: .swift60CompilerFloor
        )

        #expect(failure?.code == "review-policy.compiler-floor")
    }

    @Test("Requires a Swift 6.0-compatible planned compiler-floor signature")
    func requiresAdaptedCompilerFloorSignature() throws {
        let signature = "nonisolated struct LayoutRotationUnaryLayout"
        let failure = try policyFailure(
            referenceSignature: signature,
            plannedSignature: signature,
            availability: .swift60CompilerFloor
        )

        #expect(failure?.code == "review-policy.compiler-floor-signature")
    }

    @Test("Accepts supported sending and isolated-any syntax")
    func acceptsSupportedTaskIsolationSyntax() throws {
        let signature = "func task(action: sending @escaping @isolated(any) () async -> Void)"

        try validatePolicy(
            referenceSignature: signature,
            plannedSignature: signature,
            availability: .terminalCrossPlatform
        )
    }
}

private func policyFailure(
    referenceSignature: String,
    plannedSignature: String,
    availability: AvailabilityPolicy
) throws -> APICheckDiagnostic? {
    FixtureSupport.diagnostic {
        try validatePolicy(
            referenceSignature: referenceSignature,
            plannedSignature: plannedSignature,
            availability: availability
        )
    }
}

private func validatePolicy(
    referenceSignature: String,
    plannedSignature: String,
    availability: AvailabilityPolicy
) throws {
    let referenceID = "s:SwiftUI.SemanticFixture"
    let referenceSet = try makeSet(
        name: "SwiftUI reference",
        sources: [
            sourceFixture(
                id: "reference-macos",
                moduleName: "SwiftUI",
                symbols: [
                    symbol(
                        id: referenceID,
                        moduleName: "SwiftUI",
                        declaration: referenceSignature
                    ),
                ]
            ),
        ]
    )
    let tuikitSet = try makeSet(
        name: "TUIkit",
        sources: [
            sourceFixture(id: "tuikit-macos", moduleName: "TUIkit", symbols: []),
        ]
    )
    let policy = CompatibilityReviewPolicy(
        schemaVersion: 1,
        referenceRules: [
            ReferenceReviewRule(
                id: "include-semantic-fixture",
                referenceIDs: [referenceID],
                action: ReferenceReviewAction(
                    kind: .include,
                    ownerIssue: "#17",
                    status: .planned,
                    contractID: "compile.semantic-fixture",
                    contractKind: .compile,
                    plannedTUIkitSignatures: [referenceID: plannedSignature],
                    availability: AvailabilityDecision(
                        policy: availability,
                        reason: "Reviewed compatibility policy fixture."
                    )
                )
            ),
        ],
        tuikitOverrides: []
    )

    try CompatibilityManifestGenerator(
        ownerRegistry: CompatibilityOwnerRegistry(
            schemaVersion: 1,
            repository: "phranck/TUIkit",
            issues: [
                CompatibilityOwnerIssue(
                    number: 17,
                    title: "Semantic fixture owner",
                    url: "https://github.com/phranck/TUIkit/issues/17"
                ),
            ]
        )
    ).validatePolicy(
        policy,
        referenceSet: referenceSet,
        tuikitSet: tuikitSet,
        allowedOwnerIssues: ["#17"]
    )
}

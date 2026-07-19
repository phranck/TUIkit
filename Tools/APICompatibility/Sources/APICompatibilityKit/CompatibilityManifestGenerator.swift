import Foundation

public struct CompatibilityManifestGenerator: Sendable {
    private let ownerRegistry: CompatibilityOwnerRegistry

    public init(ownerRegistry: CompatibilityOwnerRegistry) {
        self.ownerRegistry = ownerRegistry
    }

    public func generate(
        policy: CompatibilityReviewPolicy,
        referenceSet: APISnapshotSet,
        tuikitSet: APISnapshotSet
    ) throws -> CompatibilityManifest {
        let allowedOwnerIssues = try CompatibilityOwnerRegistryValidator()
            .allowedIssueReferences(in: ownerRegistry)
        try validatePolicy(
            policy,
            referenceSet: referenceSet,
            tuikitSet: tuikitSet,
            allowedOwnerIssues: allowedOwnerIssues
        )
        let rulesByReferenceID = try matchedRules(
            policy.referenceRules,
            referenceIDs: referenceSet.unionPreciseIdentifiers
        )
        var state = ManifestGenerationState(
            decisions: try initialDecisions(
                rulesByReferenceID: rulesByReferenceID,
                referenceSet: referenceSet
            )
        )
        try applyExplicitOverrides(
            policy.tuikitOverrides,
            referenceSet: referenceSet,
            tuikitSet: tuikitSet,
            state: &state
        )
        try applyAutomaticMappings(
            excluding: Set(policy.tuikitOverrides.map(\.symbolID)),
            referenceSet: referenceSet,
            tuikitSet: tuikitSet,
            state: &state
        )
        try validateCompleteness(state, tuikitSet: tuikitSet)

        let manifest = canonicalManifest(
            state: state,
            referenceIDs: referenceSet.unionPreciseIdentifiers
        )
        try validateGeneratedManifest(
            manifest,
            referenceSet: referenceSet,
            tuikitSet: tuikitSet
        )
        return manifest
    }
}

extension CompatibilityManifestGenerator {
    func initialDecisions(
        rulesByReferenceID: [String: ReferenceReviewRule],
        referenceSet: APISnapshotSet
    ) throws -> [ReferenceDecision] {
        try referenceSet.unionPreciseIdentifiers.map { referenceID in
            guard let rule = rulesByReferenceID[referenceID] else {
                throw manifestGenerationDiagnostic(
                    "review-policy.reference-unmatched",
                    "Reference '\(referenceID)' matches no review rule"
                )
            }
            return try decision(
                for: referenceID,
                rule: rule,
                referenceSet: referenceSet
            )
        }
    }

    func applyExplicitOverrides(
        _ overrides: [TUIkitReviewOverride],
        referenceSet: APISnapshotSet,
        tuikitSet: APISnapshotSet,
        state: inout ManifestGenerationState
    ) throws {
        for override in overrides.sorted(by: { $0.symbolID < $1.symbolID }) {
            switch override.action {
            case .tuiSpecific:
                state.tuikitDecisions.append(
                    TUIkitSymbolDecision(
                        symbolID: override.symbolID,
                        classification: .tuiSpecific,
                        ownerIssue: override.ownerIssue
                    )
                )
            case .implementationLeak:
                state.tuikitDecisions.append(
                    TUIkitSymbolDecision(
                        symbolID: override.symbolID,
                        classification: .implementationLeak,
                        ownerIssue: override.ownerIssue
                    )
                )
            case .mapExact, .mapReviewedException:
                guard let referenceID = override.referenceID else {
                    throw manifestGenerationDiagnostic(
                        "review-policy.mapping-reference",
                        "TUIkit override '\(override.symbolID)' requires a reference ID"
                    )
                }
                try applyMapping(
                    referenceID: referenceID,
                    tuikitID: override.symbolID,
                    classification: override.action == .mapExact
                        ? .swiftUIExact
                        : .reviewedException,
                    exception: override.exception,
                    referenceSet: referenceSet,
                    tuikitSet: tuikitSet,
                    state: &state
                )
            }
        }
    }

    func applyAutomaticMappings(
        excluding excludedTUIkitIDs: Set<String>,
        referenceSet: APISnapshotSet,
        tuikitSet: APISnapshotSet,
        state: inout ManifestGenerationState
    ) throws {
        let candidates = automaticMappingCandidates(
            decisions: state.decisions,
            referenceSet: referenceSet,
            tuikitSet: tuikitSet,
            excludedTUIkitIDs: excludedTUIkitIDs
        )
        for candidate in candidates {
            try applyMapping(
                referenceID: candidate.referenceID,
                tuikitID: candidate.tuikitID,
                classification: .swiftUIExact,
                exception: nil,
                referenceSet: referenceSet,
                tuikitSet: tuikitSet,
                state: &state
            )
        }
    }

    func validateCompleteness(
        _ state: ManifestGenerationState,
        tuikitSet: APISnapshotSet
    ) throws {
        if let unmapped = state.decisions.first(where: {
            $0.inclusion == .include && $0.status == .implemented && $0.tuikitSymbolID == nil
        }) {
            throw manifestGenerationDiagnostic(
                "manifest-generator.implemented-unmapped",
                "Implemented reference '\(unmapped.referenceID)' has no explicit or unique exact mapping"
            )
        }
        let classifiedTUIkitIDs = Set(state.tuikitDecisions.map(\.symbolID))
        if let unclassified = tuikitSet.unionPreciseIdentifiers
            .first(where: { !classifiedTUIkitIDs.contains($0) }) {
            throw manifestGenerationDiagnostic(
                "manifest-generator.tuikit-unclassified",
                "TUIkit symbol '\(unclassified)' has no unique exact mapping or explicit override"
            )
        }
    }

    func canonicalManifest(
        state: ManifestGenerationState,
        referenceIDs: [String]
    ) -> CompatibilityManifest {
        var decisions = state.decisions.sorted { $0.referenceID < $1.referenceID }
        for index in decisions.indices {
            decisions[index].evidence.sort(by: compatibilityEvidenceOrder)
        }
        var tuikitDecisions = state.tuikitDecisions.sorted { $0.symbolID < $1.symbolID }
        for index in tuikitDecisions.indices {
            tuikitDecisions[index].exception?.allowedDifferences.sort {
                $0.rawValue < $1.rawValue
            }
        }
        return CompatibilityManifest(
            schemaVersion: 2,
            referenceIDs: referenceIDs.sorted(),
            decisions: decisions,
            tuikitDecisions: tuikitDecisions
        )
    }

    func validateGeneratedManifest(
        _ manifest: CompatibilityManifest,
        referenceSet: APISnapshotSet,
        tuikitSet: APISnapshotSet
    ) throws {
        let diagnostics = ManifestValidator().validate(manifest)
            + CompatibilityEvidenceValidator().validate(
                manifest,
                referenceSet: referenceSet,
                tuikitSet: tuikitSet
            )
            + CompatibilitySurfaceValidator().validate(
                manifest,
                referenceSet: referenceSet,
                tuikitSet: tuikitSet
            )
        if let failure = diagnostics.min() {
            throw failure
        }
    }
}

struct ManifestGenerationState {
    var decisions: [ReferenceDecision]
    var tuikitDecisions: [TUIkitSymbolDecision] = []
    var mappedReferenceIDs: Set<String> = []
    var mappedTUIkitIDs: Set<String> = []
}

func compatibilityEvidenceOrder(
    _ lhs: CompatibilityEvidence,
    _ rhs: CompatibilityEvidence
) -> Bool {
    lhs.kind.rawValue == rhs.kind.rawValue
        ? lhs.reference < rhs.reference
        : lhs.kind.rawValue < rhs.kind.rawValue
}

func manifestGenerationDiagnostic(_ code: String, _ message: String) -> APICheckDiagnostic {
    APICheckDiagnostic(code: code, message: message)
}

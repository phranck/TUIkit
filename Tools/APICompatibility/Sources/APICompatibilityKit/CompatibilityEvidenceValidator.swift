/// Binds directional symbol graph evidence to the exact snapshot occurrences it proves.
public struct CompatibilityEvidenceValidator: Sendable {
    public init() {}

    public func validate(
        _ manifest: CompatibilityManifest,
        referenceSet: APISnapshotSet,
        tuikitSet: APISnapshotSet
    ) -> [APICheckDiagnostic] {
        let referenceSourceIDs = Set(referenceSet.sources.map(\.source.id))
        let tuikitSourceIDs = Set(tuikitSet.sources.map(\.source.id))
        return manifest.decisions.flatMap { decision in
            var diagnostics = sourceDiagnostics(
                evidence: decision.evidence.filter { $0.kind == .referenceSymbolGraph },
                expectedSourceIDs: occurrenceSourceIDs(
                    in: referenceSet,
                    identifier: decision.referenceID
                ),
                allSourceIDs: referenceSourceIDs,
                unprovenSourceIDs: [],
                direction: .reference,
                decision: decision
            )
            diagnostics += tuikitDiagnostics(
                decision,
                set: tuikitSet,
                allSourceIDs: tuikitSourceIDs
            )
            return diagnostics
        }.sorted()
    }

    private func tuikitDiagnostics(
        _ decision: ReferenceDecision,
        set: APISnapshotSet,
        allSourceIDs: Set<String>
    ) -> [APICheckDiagnostic] {
        let evidence = decision.evidence.filter { $0.kind == .tuikitSymbolGraph }
        guard decision.inclusion == .include,
              decision.status == .implemented || decision.status == .verified,
              let identifier = decision.tuikitSymbolID
        else {
            return Set(evidence.map(\.reference)).sorted().map { sourceID in
                APICheckDiagnostic(
                    code: "evidence.tuikit-forbidden",
                    message: "Reference '\(decision.referenceID)' cannot claim TUIkit snapshot source '\(sourceID)' without a current mapping"
                )
            }
        }
        let occurrences = set.occurrences(for: identifier)
        let moduleNames = Set(occurrences.map(\.source.moduleName))
        guard moduleNames.count <= 1 else {
            return [
                APICheckDiagnostic(
                    code: "evidence.tuikit-module-ambiguous",
                    message: "TUIkit symbol '\(identifier)' occurs in multiple modules [\(moduleNames.sorted().joined(separator: ", "))]"
                ),
            ]
        }
        guard let moduleName = moduleNames.first else {
            return []
        }
        let occurrenceSourceIDs = Set(occurrences.map(\.source.id))
        let requiredSourceIDs = Set(set.sources.compactMap { source in
            source.source.moduleName == moduleName ? source.source.id : nil
        })
        let unprovenSourceIDs = requiredSourceIDs.subtracting(occurrenceSourceIDs)
        return sourceDiagnostics(
            evidence: evidence,
            expectedSourceIDs: occurrenceSourceIDs,
            allSourceIDs: allSourceIDs,
            unprovenSourceIDs: unprovenSourceIDs,
            direction: .tuikit,
            decision: decision
        ) + unprovenSourceIDs.map { sourceID in
            APICheckDiagnostic(
                code: "evidence.tuikit-source-unproven",
                message: "TUIkit source '\(sourceID)' does not contain implemented symbol '\(identifier)'"
            )
        }
    }

    private func occurrenceSourceIDs(
        in set: APISnapshotSet,
        identifier: String
    ) -> Set<String> {
        Set(set.occurrences(for: identifier).map(\.source.id))
    }

    private func sourceDiagnostics(
        evidence: [CompatibilityEvidence],
        expectedSourceIDs: Set<String>,
        allSourceIDs: Set<String>,
        unprovenSourceIDs: Set<String>,
        direction: EvidenceDirection,
        decision: ReferenceDecision
    ) -> [APICheckDiagnostic] {
        let evidenceCounts = Dictionary(grouping: evidence.map(\.reference), by: { $0 })
            .mapValues(\.count)
        let actualSourceIDs = Set(evidenceCounts.keys)
        var diagnostics = evidenceCounts.filter { $0.value > 1 }.keys.map { sourceID in
            sourceDiagnostic(
                direction: direction,
                category: "duplicate",
                decision: decision,
                sourceID: sourceID
            )
        }
        diagnostics += expectedSourceIDs.subtracting(actualSourceIDs).map { sourceID in
            sourceDiagnostic(
                direction: direction,
                category: "missing",
                decision: decision,
                sourceID: sourceID
            )
        }
        diagnostics += actualSourceIDs.subtracting(allSourceIDs).map { sourceID in
            sourceDiagnostic(
                direction: direction,
                category: "unknown",
                decision: decision,
                sourceID: sourceID
            )
        }
        diagnostics += actualSourceIDs.intersection(allSourceIDs)
            .subtracting(expectedSourceIDs)
            .subtracting(unprovenSourceIDs).map { sourceID in
                sourceDiagnostic(
                    direction: direction,
                    category: "additional",
                    decision: decision,
                    sourceID: sourceID
                )
            }
        return diagnostics
    }

    private func sourceDiagnostic(
        direction: EvidenceDirection,
        category: String,
        decision: ReferenceDecision,
        sourceID: String
    ) -> APICheckDiagnostic {
        let description: String
        switch category {
        case "additional":
            description = "does not contain the recorded symbol"
        case "duplicate":
            description = "is recorded more than once"
        case "missing":
            description = "is missing from the evidence"
        default:
            description = "is not part of the snapshot set"
        }
        return APICheckDiagnostic(
            code: "evidence.\(direction.rawValue)-source-\(category)",
            message: "\(direction.label) source '\(sourceID)' \(description) for '\(decision.referenceID)'"
        )
    }
}

private enum EvidenceDirection: String {
    case reference
    case tuikit

    var label: String {
        switch self {
        case .reference: "Reference"
        case .tuikit: "TUIkit"
        }
    }
}

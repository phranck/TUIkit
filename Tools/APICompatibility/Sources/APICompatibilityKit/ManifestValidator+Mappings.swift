extension ManifestValidator {
    func validateMappings(
        _ manifest: CompatibilityManifest,
        diagnostics: inout [APICheckDiagnostic]
    ) {
        let decisionIDCounts = Dictionary(
            grouping: manifest.decisions,
            by: \.referenceID
        ).mapValues(\.count)
        let mappedDecisions = mappedDecisions(
            in: manifest,
            decisionIDCounts: decisionIDCounts
        )
        appendDuplicateDiagnostics(
            values: mappedDecisions.compactMap(\.tuikitSymbolID),
            code: "manifest.duplicate-mapping",
            noun: "TUIkit mapping",
            diagnostics: &diagnostics
        )
        validateReferenceMappings(
            mappedDecisions,
            tuikitDecisions: manifest.tuikitDecisions,
            diagnostics: &diagnostics
        )
        validateTUIkitMappings(
            manifest,
            decisionIDCounts: decisionIDCounts,
            diagnostics: &diagnostics
        )
    }
}

private extension ManifestValidator {
    func mappedDecisions(
        in manifest: CompatibilityManifest,
        decisionIDCounts: [String: Int]
    ) -> [ReferenceDecision] {
        manifest.decisions.filter {
            $0.inclusion == .include
                && ($0.status == .implemented || $0.status == .verified)
                && isNonempty($0.tuikitSymbolID)
                && decisionIDCounts[$0.referenceID] == 1
        }
    }

    func validateReferenceMappings(
        _ mappedDecisions: [ReferenceDecision],
        tuikitDecisions: [TUIkitSymbolDecision],
        diagnostics: inout [APICheckDiagnostic]
    ) {
        let tuikitByID = Dictionary(
            tuikitDecisions.map { ($0.symbolID, $0) },
            uniquingKeysWith: { first, _ in first }
        )
        for decision in mappedDecisions {
            guard let symbolID = decision.tuikitSymbolID,
                  let tuikitDecision = tuikitByID[symbolID]
            else {
                diagnostics.append(
                    APICheckDiagnostic(
                        code: "manifest.mapping-target",
                        message: "Reference '\(decision.referenceID)' maps to an unclassified TUIkit symbol"
                    )
                )
                continue
            }
            guard tuikitDecision.referenceID == decision.referenceID,
                  tuikitDecision.classification == .swiftUIExact
                    || tuikitDecision.classification == .reviewedException
            else {
                appendBacklinkDiagnostic(
                    decision.referenceID,
                    symbolID: symbolID,
                    diagnostics: &diagnostics
                )
                continue
            }
        }
    }

    func validateTUIkitMappings(
        _ manifest: CompatibilityManifest,
        decisionIDCounts: [String: Int],
        diagnostics: inout [APICheckDiagnostic]
    ) {
        let referenceDecisions = Dictionary(
            manifest.decisions.compactMap { decision -> (String, ReferenceDecision)? in
                guard decisionIDCounts[decision.referenceID] == 1 else { return nil }
                return (decision.referenceID, decision)
            },
            uniquingKeysWith: { first, _ in first }
        )
        for decision in manifest.tuikitDecisions
            where decision.classification == .swiftUIExact
                || decision.classification == .reviewedException {
            if let referenceID = decision.referenceID,
               decisionIDCounts[referenceID] != 1 {
                continue
            }
            guard let referenceID = decision.referenceID,
                  let reference = referenceDecisions[referenceID]
            else {
                appendBacklinkDiagnostic(
                    decision.referenceID ?? "<missing>",
                    symbolID: decision.symbolID,
                    diagnostics: &diagnostics
                )
                continue
            }
            guard reference.inclusion == .include,
                  reference.status == .implemented || reference.status == .verified
            else {
                appendBacklinkDiagnostic(
                    referenceID,
                    symbolID: decision.symbolID,
                    diagnostics: &diagnostics
                )
                continue
            }
            guard isNonempty(reference.tuikitSymbolID) else { continue }
            guard reference.tuikitSymbolID == decision.symbolID else {
                appendBacklinkDiagnostic(
                    referenceID,
                    symbolID: decision.symbolID,
                    diagnostics: &diagnostics
                )
                continue
            }
        }
    }

    func appendBacklinkDiagnostic(
        _ referenceID: String,
        symbolID: String,
        diagnostics: inout [APICheckDiagnostic]
    ) {
        diagnostics.append(
            APICheckDiagnostic(
                code: "manifest.mapping-backlink",
                message: "Mapping between '\(referenceID)' and '\(symbolID)' is not bidirectional"
            )
        )
    }
}

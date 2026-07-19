import Foundation

/// Validates the links between manifest decisions and compatibility contracts.
public struct CompatibilityContractLinkValidator: Sendable {
    public init() {}

    public func validate(
        _ manifest: CompatibilityManifest,
        registry: CompatibilityContractRegistry
    ) -> [APICheckDiagnostic] {
        let definitionsByID = Dictionary(grouping: registry.contracts, by: \.id)
        let includedDecisions = manifest.decisions.filter { $0.inclusion == .include }
        let referencedContractIDs = Set(includedDecisions.map { $0.contractID ?? "" })
        var diagnostics = ContractRegistryValidator().validate(
            referencedContractIDs: referencedContractIDs,
            registry: registry
        )

        for decision in manifest.decisions {
            let contractEvidence = decision.evidence.filter { $0.kind.isContractEvidence }
            validateEvidenceIDs(
                contractEvidence,
                for: decision,
                definitionsByID: definitionsByID,
                diagnostics: &diagnostics
            )

            switch decision.inclusion {
            case .exclude:
                validateExcludedDecision(
                    decision,
                    contractEvidence: contractEvidence,
                    diagnostics: &diagnostics
                )
            case .include:
                validateIncludedDecision(
                    decision,
                    contractEvidence: contractEvidence,
                    definitionsByID: definitionsByID,
                    diagnostics: &diagnostics
                )
            }
        }

        return diagnostics.sorted()
    }
}

private extension CompatibilityContractLinkValidator {
    func validateIncludedDecision(
        _ decision: ReferenceDecision,
        contractEvidence: [CompatibilityEvidence],
        definitionsByID: [String: [ContractDefinition]],
        diagnostics: inout [APICheckDiagnostic]
    ) {
        guard let contractID = decision.contractID,
              Self.isNonempty(contractID) else {
            diagnostics.append(
                linkDiagnostic(
                    "contract-link.missing-contract-id",
                    "Included reference '\(decision.referenceID)' requires a nonempty contract ID"
                )
            )
            return
        }

        let matchingEvidence = contractEvidence.filter { $0.reference == contractID }
        if matchingEvidence.count != 1 {
            diagnostics.append(
                linkDiagnostic(
                    "contract-link.evidence-count",
                    "Included reference '\(decision.referenceID)' requires exactly one contract evidence "
                        + "for '\(contractID)'; found \(matchingEvidence.count)"
                )
            )
        }

        guard let definitions = definitionsByID[contractID] else {
            return
        }
        guard definitions.count == 1 else {
            diagnostics.append(
                linkDiagnostic(
                    "contract-link.ambiguous-contract",
                    "Included reference '\(decision.referenceID)' references contract '\(contractID)', "
                        + "which is registered \(definitions.count) times"
                )
            )
            return
        }
        guard matchingEvidence.count == 1,
              let evidence = matchingEvidence.first else {
            return
        }

        let expectedEvidenceKind = definitions[0].kind.compatibilityEvidenceKind
        if evidence.kind != expectedEvidenceKind {
            diagnostics.append(
                linkDiagnostic(
                    "contract-link.evidence-kind",
                    "Included reference '\(decision.referenceID)' links contract '\(contractID)' "
                        + "with '\(evidence.kind.rawValue)' evidence; expected "
                        + "'\(expectedEvidenceKind.rawValue)'"
                )
            )
        }
    }

    func validateExcludedDecision(
        _ decision: ReferenceDecision,
        contractEvidence: [CompatibilityEvidence],
        diagnostics: inout [APICheckDiagnostic]
    ) {
        if let contractID = decision.contractID {
            diagnostics.append(
                linkDiagnostic(
                    "contract-link.noninclude-contract-id",
                    "Excluded reference '\(decision.referenceID)' cannot reference contract '\(contractID)'"
                )
            )
        }
        if !contractEvidence.isEmpty {
            diagnostics.append(
                linkDiagnostic(
                    "contract-link.noninclude-evidence",
                    "Excluded reference '\(decision.referenceID)' cannot contain contract evidence"
                )
            )
        }
    }

    func validateEvidenceIDs(
        _ evidenceValues: [CompatibilityEvidence],
        for decision: ReferenceDecision,
        definitionsByID: [String: [ContractDefinition]],
        diagnostics: inout [APICheckDiagnostic]
    ) {
        for evidence in evidenceValues {
            guard Self.isNonempty(evidence.reference) else {
                diagnostics.append(
                    linkDiagnostic(
                        "contract-link.empty-evidence-id",
                        "Reference '\(decision.referenceID)' contains contract evidence with an empty ID"
                    )
                )
                continue
            }

            if definitionsByID[evidence.reference] == nil {
                diagnostics.append(
                    linkDiagnostic(
                        "contract-link.unknown-evidence-id",
                        "Reference '\(decision.referenceID)' contains evidence for unregistered contract "
                            + "'\(evidence.reference)'"
                    )
                )
            }

            if decision.inclusion == .include,
               let contractID = decision.contractID,
               Self.isNonempty(contractID),
               evidence.reference != contractID {
                diagnostics.append(
                    linkDiagnostic(
                        "contract-link.unmatched-evidence-id",
                        "Included reference '\(decision.referenceID)' contains evidence for contract "
                            + "'\(evidence.reference)' instead of '\(contractID)'"
                    )
                )
            }
        }
    }

    static func isNonempty(_ value: String) -> Bool {
        !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

private extension CompatibilityEvidenceKind {
    var isContractEvidence: Bool {
        self == .compileContract || self == .behaviorContract
    }
}

private extension ContractKind {
    var compatibilityEvidenceKind: CompatibilityEvidenceKind {
        switch self {
        case .behavior:
            .behaviorContract
        case .compile:
            .compileContract
        }
    }
}

private func linkDiagnostic(_ code: String, _ message: String) -> APICheckDiagnostic {
    APICheckDiagnostic(code: code, message: message)
}

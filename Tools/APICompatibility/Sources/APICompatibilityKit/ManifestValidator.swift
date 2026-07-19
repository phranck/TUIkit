import Foundation

public struct ManifestValidator: Sendable {
    public init() {}

    public func validate(_ manifest: CompatibilityManifest) -> [APICheckDiagnostic] {
        var diagnostics: [APICheckDiagnostic] = []
        validateSchema(manifest, diagnostics: &diagnostics)
        validateIdentities(manifest, diagnostics: &diagnostics)
        validateReferenceInventory(manifest, diagnostics: &diagnostics)
        validateReferenceDecisions(manifest, diagnostics: &diagnostics)
        validateTUIkitDecisions(manifest, diagnostics: &diagnostics)
        validateMappings(manifest, diagnostics: &diagnostics)
        return diagnostics.sorted()
    }
}

extension ManifestValidator {
    private func validateIdentities(
        _ manifest: CompatibilityManifest,
        diagnostics: inout [APICheckDiagnostic]
    ) {
        appendEmptyDiagnostics(
            values: manifest.referenceIDs,
            code: "manifest.empty-reference",
            noun: "reference ID",
            diagnostics: &diagnostics
        )
        appendEmptyDiagnostics(
            values: manifest.decisions.map(\.referenceID),
            code: "manifest.empty-decision-id",
            noun: "decision reference ID",
            diagnostics: &diagnostics
        )
        appendEmptyDiagnostics(
            values: manifest.tuikitDecisions.map(\.symbolID),
            code: "manifest.empty-tuikit-symbol",
            noun: "TUIkit symbol ID",
            diagnostics: &diagnostics
        )
    }

    private func validateSchema(
        _ manifest: CompatibilityManifest,
        diagnostics: inout [APICheckDiagnostic]
    ) {
        guard manifest.schemaVersion == 2 else {
            diagnostics.append(
                APICheckDiagnostic(
                    code: "manifest.schema-version",
                    message: "Unsupported manifest schema version \(manifest.schemaVersion)"
                )
            )
            return
        }
    }

    private func validateReferenceInventory(
        _ manifest: CompatibilityManifest,
        diagnostics: inout [APICheckDiagnostic]
    ) {
        appendDuplicateDiagnostics(
            values: manifest.referenceIDs,
            code: "manifest.duplicate-reference",
            noun: "reference ID",
            diagnostics: &diagnostics
        )
        let decisionIDs = manifest.decisions.map(\.referenceID)
        appendDuplicateDiagnostics(
            values: decisionIDs,
            code: "manifest.duplicate-decision",
            noun: "decision ID",
            diagnostics: &diagnostics
        )

        let references = Set(manifest.referenceIDs)
        let decisions = Set(decisionIDs)
        for identifier in references.subtracting(decisions).sorted() {
            diagnostics.append(
                APICheckDiagnostic(
                    code: "manifest.missing-decision",
                    message: "Missing decision for '\(identifier)'"
                )
            )
        }
        for identifier in decisions.subtracting(references).sorted() {
            diagnostics.append(
                APICheckDiagnostic(
                    code: "manifest.unknown-decision",
                    message: "Decision references unknown symbol '\(identifier)'"
                )
            )
        }
    }

    private func validateReferenceDecisions(
        _ manifest: CompatibilityManifest,
        diagnostics: inout [APICheckDiagnostic]
    ) {
        for decision in manifest.decisions {
            validateCompatibilityRecord(decision, diagnostics: &diagnostics)
            if decision.status == .unreviewed {
                diagnostics.append(
                    APICheckDiagnostic(
                        code: "manifest.unreviewed",
                        message: "Reference '\(decision.referenceID)' remains unreviewed"
                    )
                )
            }
            switch decision.inclusion {
            case .include:
                validateIncludedDecision(decision, diagnostics: &diagnostics)
            case .exclude:
                validateExcludedDecision(decision, diagnostics: &diagnostics)
            }
        }
    }

    private func validateCompatibilityRecord(
        _ decision: ReferenceDecision,
        diagnostics: inout [APICheckDiagnostic]
    ) {
        if !isNonempty(decision.referenceSignature) {
            diagnostics.append(
                APICheckDiagnostic(
                    code: "manifest.reference-signature",
                    message: "Reference '\(decision.referenceID)' requires its Apple signature"
                )
            )
        }
        if decision.inclusion == .include, !isNonempty(decision.tuikitSignature) {
            diagnostics.append(
                APICheckDiagnostic(
                    code: "manifest.tuikit-signature",
                    message: "Included reference '\(decision.referenceID)' requires its planned or current TUIkit signature"
                )
            )
        }
        if decision.inclusion == .exclude, decision.tuikitSignature != nil {
            diagnostics.append(
                APICheckDiagnostic(
                    code: "manifest.excluded-signature",
                    message: "Excluded reference '\(decision.referenceID)' cannot define a TUIkit signature"
                )
            )
        }
        validateAvailability(decision, diagnostics: &diagnostics)
        validateEvidence(decision, diagnostics: &diagnostics)
    }

    private func validateAvailability(
        _ decision: ReferenceDecision,
        diagnostics: inout [APICheckDiagnostic]
    ) {
        let isExcludedPolicy = decision.availability.policy == .excluded
        if (decision.inclusion == .exclude) != isExcludedPolicy {
            diagnostics.append(
                APICheckDiagnostic(
                    code: "manifest.availability-policy",
                    message: "Reference '\(decision.referenceID)' has an availability policy incompatible with its inclusion decision"
                )
            )
        }
        if decision.availability.policy != .matchesReference,
           !isNonempty(decision.availability.reason) {
            diagnostics.append(
                APICheckDiagnostic(
                    code: "manifest.availability-reason",
                    message: "Reference '\(decision.referenceID)' requires a reason for availability policy '\(decision.availability.policy.rawValue)'"
                )
            )
        }
    }

    private func validateEvidence(
        _ decision: ReferenceDecision,
        diagnostics: inout [APICheckDiagnostic]
    ) {
        guard !decision.evidence.isEmpty else {
            diagnostics.append(
                APICheckDiagnostic(
                    code: "manifest.evidence-required",
                    message: "Reference '\(decision.referenceID)' requires review evidence"
                )
            )
            return
        }
        if decision.evidence.contains(where: { !isNonempty($0.reference) }) {
            diagnostics.append(
                APICheckDiagnostic(
                    code: "manifest.evidence-reference",
                    message: "Reference '\(decision.referenceID)' contains evidence without a reference"
                )
            )
        }
        let uniqueEvidence = Set(decision.evidence)
        if uniqueEvidence.count != decision.evidence.count {
            diagnostics.append(
                APICheckDiagnostic(
                    code: "manifest.duplicate-evidence",
                    message: "Reference '\(decision.referenceID)' contains duplicate evidence"
                )
            )
        }
    }

    private func validateIncludedDecision(
        _ decision: ReferenceDecision,
        diagnostics: inout [APICheckDiagnostic]
    ) {
        if !isNonempty(decision.ownerIssue) {
            diagnostics.append(
                APICheckDiagnostic(
                    code: "manifest.include-owner",
                    message: "Included reference '\(decision.referenceID)' requires one ownerIssue"
                )
            )
        }
        if !isNonempty(decision.contractID) {
            diagnostics.append(
                APICheckDiagnostic(
                    code: "manifest.include-contract",
                    message: "Included reference '\(decision.referenceID)' requires one contractID"
                )
            )
        }
        if let contractID = decision.contractID,
           !contractID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let linkedContracts = decision.evidence.filter {
                ($0.kind == .compileContract || $0.kind == .behaviorContract)
                    && $0.reference == contractID
            }
            if linkedContracts.count != 1 {
                diagnostics.append(
                    APICheckDiagnostic(
                        code: "manifest.contract-evidence",
                        message: "Included reference '\(decision.referenceID)' requires exactly one matching compile or behavior contract evidence"
                    )
                )
            }
        }
        if decision.exclusion != nil {
            diagnostics.append(
                APICheckDiagnostic(
                    code: "manifest.include-exclusion",
                    message: "Included reference '\(decision.referenceID)' cannot define an exclusion"
                )
            )
        }

        switch decision.status {
        case .planned:
            if decision.tuikitSymbolID != nil {
                diagnostics.append(
                    APICheckDiagnostic(
                        code: "manifest.mapping-forbidden",
                        message: "Planned reference '\(decision.referenceID)' cannot map to an implementation"
                    )
                )
            }
        case .implemented, .verified:
            if !isNonempty(decision.tuikitSymbolID) {
                diagnostics.append(
                    APICheckDiagnostic(
                        code: "manifest.mapping-required",
                        message: "\(decision.status.rawValue.capitalized) reference '\(decision.referenceID)' requires a TUIkit mapping"
                    )
                )
            }
        case .unreviewed:
            break
        }
    }

    private func validateExcludedDecision(
        _ decision: ReferenceDecision,
        diagnostics: inout [APICheckDiagnostic]
    ) {
        if decision.ownerIssue != nil || decision.contractID != nil || decision.tuikitSymbolID != nil {
            diagnostics.append(
                APICheckDiagnostic(
                    code: "manifest.exclusion-fields",
                    message: "Excluded reference '\(decision.referenceID)' contains include-only fields"
                )
            )
        }
        guard let exclusion = decision.exclusion else {
            diagnostics.append(
                APICheckDiagnostic(
                    code: "manifest.exclusion-required",
                    message: "Excluded reference '\(decision.referenceID)' requires an exclusion category and reason"
                )
            )
            return
        }
        if exclusion.reason.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            diagnostics.append(
                APICheckDiagnostic(
                    code: "manifest.exclusion-reason",
                    message: "Excluded reference '\(decision.referenceID)' requires a concrete reason"
                )
            )
        }
    }

    private func validateTUIkitDecisions(
        _ manifest: CompatibilityManifest,
        diagnostics: inout [APICheckDiagnostic]
    ) {
        appendDuplicateDiagnostics(
            values: manifest.tuikitDecisions.map(\.symbolID),
            code: "manifest.duplicate-tuikit-symbol",
            noun: "TUIkit symbol ID",
            diagnostics: &diagnostics
        )
        for decision in manifest.tuikitDecisions {
            switch decision.classification {
            case .swiftUIExact:
                validateExactDecision(decision, diagnostics: &diagnostics)
            case .reviewedException:
                validateExceptionDecision(decision, diagnostics: &diagnostics)
            case .tuiSpecific:
                validateTUISpecificDecision(decision, diagnostics: &diagnostics)
            case .implementationLeak:
                validateImplementationLeak(decision, diagnostics: &diagnostics)
            }
        }
    }

    private func validateExactDecision(
        _ decision: TUIkitSymbolDecision,
        diagnostics: inout [APICheckDiagnostic]
    ) {
        if !isNonempty(decision.referenceID) {
            appendClassificationDiagnostic(
                decision,
                detail: "requires a referenceID",
                diagnostics: &diagnostics
            )
        }
        if decision.exception != nil {
            appendClassificationDiagnostic(
                decision,
                detail: "cannot define an exception",
                diagnostics: &diagnostics
            )
        }
    }

    private func validateExceptionDecision(
        _ decision: TUIkitSymbolDecision,
        diagnostics: inout [APICheckDiagnostic]
    ) {
        if !isNonempty(decision.referenceID) {
            appendClassificationDiagnostic(
                decision,
                detail: "requires a referenceID",
                diagnostics: &diagnostics
            )
        }
        guard let exception = decision.exception else {
            diagnostics.append(
                APICheckDiagnostic(
                    code: "manifest.exception-required",
                    message: "Reviewed exception '\(decision.symbolID)' requires an exception kind and reason"
                )
            )
            return
        }
        if exception.reason.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            diagnostics.append(
                APICheckDiagnostic(
                    code: "manifest.exception-reason",
                    message: "Reviewed exception '\(decision.symbolID)' requires a concrete reason"
                )
            )
        }
        if exception.allowedDifferences.isEmpty {
            diagnostics.append(
                APICheckDiagnostic(
                    code: "manifest.exception-differences",
                    message: "Reviewed exception '\(decision.symbolID)' requires at least one allowed compatibility difference"
                )
            )
        }
        if Set(exception.allowedDifferences).count != exception.allowedDifferences.count {
            diagnostics.append(
                APICheckDiagnostic(
                    code: "manifest.duplicate-exception-difference",
                    message: "Reviewed exception '\(decision.symbolID)' contains duplicate compatibility differences"
                )
            )
        }
    }

    private func validateTUISpecificDecision(
        _ decision: TUIkitSymbolDecision,
        diagnostics: inout [APICheckDiagnostic]
    ) {
        if decision.referenceID != nil || decision.exception != nil {
            appendClassificationDiagnostic(
                decision,
                detail: "cannot define SwiftUI reference or exception fields",
                diagnostics: &diagnostics
            )
        }
    }

    private func validateImplementationLeak(
        _ decision: TUIkitSymbolDecision,
        diagnostics: inout [APICheckDiagnostic]
    ) {
        if !isNonempty(decision.ownerIssue) {
            diagnostics.append(
                APICheckDiagnostic(
                    code: "manifest.leak-owner",
                    message: "Implementation leak '\(decision.symbolID)' requires one ownerIssue"
                )
            )
        }
        if decision.referenceID != nil || decision.exception != nil {
            appendClassificationDiagnostic(
                decision,
                detail: "cannot define SwiftUI reference or exception fields",
                diagnostics: &diagnostics
            )
        }
    }

    func appendDuplicateDiagnostics(
        values: [String],
        code: String,
        noun: String,
        diagnostics: inout [APICheckDiagnostic]
    ) {
        var seen: Set<String> = []
        var reported: Set<String> = []
        for value in values where !seen.insert(value).inserted && reported.insert(value).inserted {
            diagnostics.append(
                APICheckDiagnostic(
                    code: code,
                    message: "Duplicate \(noun) '\(value)'"
                )
            )
        }
    }

    private func appendEmptyDiagnostics(
        values: [String],
        code: String,
        noun: String,
        diagnostics: inout [APICheckDiagnostic]
    ) {
        for (index, value) in values.enumerated()
            where value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            diagnostics.append(
                APICheckDiagnostic(
                    code: code,
                    message: "Empty \(noun) at index \(index)"
                )
            )
        }
    }

    private func appendClassificationDiagnostic(
        _ decision: TUIkitSymbolDecision,
        detail: String,
        diagnostics: inout [APICheckDiagnostic]
    ) {
        diagnostics.append(
            APICheckDiagnostic(
                code: "manifest.classification-fields",
                message: "\(decision.classification.rawValue) symbol '\(decision.symbolID)' \(detail)"
            )
        )
    }

    func isNonempty(_ value: String?) -> Bool {
        value?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
    }
}

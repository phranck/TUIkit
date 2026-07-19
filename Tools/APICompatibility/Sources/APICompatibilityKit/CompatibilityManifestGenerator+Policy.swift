import Foundation

extension CompatibilityManifestGenerator {
    func validatePolicy(
        _ policy: CompatibilityReviewPolicy,
        referenceSet: APISnapshotSet,
        tuikitSet: APISnapshotSet,
        allowedOwnerIssues: Set<String>
    ) throws {
        guard policy.schemaVersion == 1 else {
            throw manifestGenerationDiagnostic(
                "review-policy.schema-version",
                "Unsupported compatibility review policy schema version \(policy.schemaVersion)"
            )
        }
        try validateRuleIdentities(policy.referenceRules)
        try validateReferenceInventory(
            policy.referenceRules,
            referenceIDs: Set(referenceSet.unionPreciseIdentifiers)
        )
        try validateOverrides(
            policy.tuikitOverrides,
            tuikitIDs: Set(tuikitSet.unionPreciseIdentifiers),
            allowedOwnerIssues: allowedOwnerIssues
        )
        for rule in policy.referenceRules {
            try validate(rule, allowedOwnerIssues: allowedOwnerIssues)
            try validateSignatureSemantics(rule, referenceSet: referenceSet)
        }
    }

    func validateRuleIdentities(_ rules: [ReferenceReviewRule]) throws {
        let ruleIDs = rules.map(\.id)
        guard Set(ruleIDs).count == ruleIDs.count,
              ruleIDs.allSatisfy(isNonempty) else {
            throw manifestGenerationDiagnostic(
                "review-policy.rule-id",
                "Reference review rule IDs must be nonempty and unique"
            )
        }
        for rule in rules {
            guard !rule.referenceIDs.isEmpty else {
                throw manifestGenerationDiagnostic(
                    "review-policy.empty-rule",
                    "Reference review rule '\(rule.id)' does not list any symbols"
                )
            }
            guard Set(rule.referenceIDs).count == rule.referenceIDs.count else {
                throw manifestGenerationDiagnostic(
                    "review-policy.duplicate-rule-reference",
                    "Reference review rule '\(rule.id)' lists a symbol more than once"
                )
            }
        }
    }

    func validateReferenceInventory(
        _ rules: [ReferenceReviewRule],
        referenceIDs: Set<String>
    ) throws {
        let unknown = rules.flatMap(\.referenceIDs)
            .filter { !referenceIDs.contains($0) }
            .min()
        if let unknown {
            throw manifestGenerationDiagnostic(
                "review-policy.unknown-reference",
                "Review policy references unknown symbol '\(unknown)'"
            )
        }
    }

    func validateOverrides(
        _ overrides: [TUIkitReviewOverride],
        tuikitIDs: Set<String>,
        allowedOwnerIssues: Set<String>
    ) throws {
        let overrideIDs = overrides.map(\.symbolID)
        guard Set(overrideIDs).count == overrideIDs.count else {
            throw manifestGenerationDiagnostic(
                "review-policy.duplicate-tuikit-override",
                "TUIkit review overrides must have unique symbol IDs"
            )
        }
        if let unknown = overrideIDs.filter({ !tuikitIDs.contains($0) }).min() {
            throw manifestGenerationDiagnostic(
                "review-policy.unknown-tuikit-symbol",
                "TUIkit review override references unknown symbol '\(unknown)'"
            )
        }
        for override in overrides {
            try validate(override, allowedOwnerIssues: allowedOwnerIssues)
        }
    }

    func validate(
        _ rule: ReferenceReviewRule,
        allowedOwnerIssues: Set<String>
    ) throws {
        let action = rule.action
        switch action.kind {
        case .exclude:
            guard action.category != nil, isNonempty(action.reason),
                  action.ownerIssue == nil, action.status == nil,
                  action.contractID == nil, action.contractKind == nil,
                  action.plannedTUIkitSignatures == nil,
                  action.availability == nil else {
                throw manifestGenerationDiagnostic(
                    "review-policy.exclusion-fields",
                    "Exclusion rule '\(rule.id)' requires only category and reason"
                )
            }
        case .include:
            try validateIncludedRule(rule, allowedOwnerIssues: allowedOwnerIssues)
        }
    }

    func validateIncludedRule(
        _ rule: ReferenceReviewRule,
        allowedOwnerIssues: Set<String>
    ) throws {
        let action = rule.action
        guard let ownerIssue = action.ownerIssue,
              allowedOwnerIssues.contains(ownerIssue) else {
            throw manifestGenerationDiagnostic(
                "review-policy.owner-issue",
                "Include rule '\(rule.id)' references unregistered owner issue '\(action.ownerIssue ?? "<missing>")'"
            )
        }
        guard let status = action.status,
              status == .planned || status == .implemented,
              isNonempty(action.contractID),
              action.contractKind != nil,
              let availability = action.availability,
              availability.policy != .excluded,
              action.category == nil,
              action.reason == nil else {
            throw manifestGenerationDiagnostic(
                "review-policy.include-fields",
                "Include rule '\(rule.id)' has incomplete or incompatible fields"
            )
        }
        if status == .planned {
            let signatures = action.plannedTUIkitSignatures ?? [:]
            guard Set(signatures.keys) == Set(rule.referenceIDs),
                  signatures.values.allSatisfy(isNonempty) else {
                throw manifestGenerationDiagnostic(
                    "review-policy.planned-signature",
                    "Planned include rule '\(rule.id)' requires one TUIkit signature per reference"
                )
            }
        }
        if status == .implemented, action.plannedTUIkitSignatures != nil {
            throw manifestGenerationDiagnostic(
                "review-policy.implemented-signature",
                "Implemented include rule '\(rule.id)' cannot define planned signatures"
            )
        }
    }

    func validateSignatureSemantics(
        _ rule: ReferenceReviewRule,
        referenceSet: APISnapshotSet
    ) throws {
        guard rule.action.kind == .include,
              let status = rule.action.status,
              let availability = rule.action.availability?.policy else {
            return
        }
        for referenceID in rule.referenceIDs.sorted() {
            let referenceSignature = try uniqueSignature(
                in: referenceSet,
                identifier: referenceID,
                direction: "Reference"
            )
            let requiresCompilerFloor = ReviewPolicySignatureSemantics
                .requiresSwift60CompilerFloor(referenceSignature)
            guard (availability == .swift60CompilerFloor) == requiresCompilerFloor else {
                throw manifestGenerationDiagnostic(
                    "review-policy.compiler-floor",
                    requiresCompilerFloor
                        ? "Include rule '\(rule.id)' must use swift60CompilerFloor for '\(referenceID)'"
                        : "Include rule '\(rule.id)' assigns swift60CompilerFloor to Swift 6.0-compatible "
                            + "reference '\(referenceID)'"
                )
            }
            guard status == .planned,
                  let plannedSignature = rule.action.plannedTUIkitSignatures?[referenceID] else {
                continue
            }
            if requiresCompilerFloor,
               ReviewPolicySignatureSemantics.requiresSwift60CompilerFloor(plannedSignature) {
                throw manifestGenerationDiagnostic(
                    "review-policy.compiler-floor-signature",
                    "Compiler-floor rule '\(rule.id)' must record a Swift 6.0-compatible planned signature "
                        + "for '\(referenceID)'"
                )
            }
            if let token = ReviewPolicySignatureSemantics.nonportableToken(in: plannedSignature) {
                throw manifestGenerationDiagnostic(
                    "review-policy.nonportable-signature",
                    "Include rule '\(rule.id)' plans nonportable symbol '\(referenceID)' with type '\(token)'"
                )
            }
        }
    }

    func validate(
        _ override: TUIkitReviewOverride,
        allowedOwnerIssues: Set<String>
    ) throws {
        switch override.action {
        case .implementationLeak, .tuiSpecific:
            guard let ownerIssue = override.ownerIssue,
                  allowedOwnerIssues.contains(ownerIssue) else {
                throw manifestGenerationDiagnostic(
                    "review-policy.owner-issue",
                    "TUIkit override '\(override.symbolID)' references unregistered owner issue "
                        + "'\(override.ownerIssue ?? "<missing>")'"
                )
            }
            guard override.referenceID == nil,
                  override.exception == nil else {
                throw manifestGenerationDiagnostic(
                    "review-policy.tuikit-classification-fields",
                    "TUIkit classification override '\(override.symbolID)' requires one allowed owner issue"
                )
            }
        case .mapExact:
            guard isNonempty(override.referenceID),
                  override.ownerIssue == nil,
                  override.exception == nil else {
                throw manifestGenerationDiagnostic(
                    "review-policy.exact-mapping-fields",
                    "Exact mapping override '\(override.symbolID)' requires only a reference ID"
                )
            }
        case .mapReviewedException:
            guard isNonempty(override.referenceID),
                  override.ownerIssue == nil,
                  override.exception != nil else {
                throw manifestGenerationDiagnostic(
                    "review-policy.exception-mapping-fields",
                    "Reviewed mapping override '\(override.symbolID)' requires a reference ID and exception"
                )
            }
        }
    }

    func matchedRules(
        _ rules: [ReferenceReviewRule],
        referenceIDs: [String]
    ) throws -> [String: ReferenceReviewRule] {
        var result: [String: ReferenceReviewRule] = [:]
        for referenceID in referenceIDs.sorted() {
            let matches = rules.filter { $0.referenceIDs.contains(referenceID) }
            guard matches.count == 1, let match = matches.first else {
                let code = matches.isEmpty
                    ? "review-policy.reference-unmatched"
                    : "review-policy.reference-multiply-matched"
                let detail = matches.isEmpty
                    ? "no review rule"
                    : "multiple review rules [\(matches.map(\.id).joined(separator: ", "))]"
                throw manifestGenerationDiagnostic(
                    code,
                    "Reference '\(referenceID)' matches \(detail)"
                )
            }
            result[referenceID] = match
        }
        return result
    }

    func decision(
        for referenceID: String,
        rule: ReferenceReviewRule,
        referenceSet: APISnapshotSet
    ) throws -> ReferenceDecision {
        let signature = try uniqueSignature(
            in: referenceSet,
            identifier: referenceID,
            direction: "Reference"
        )
        var evidence = referenceSet.occurrences(for: referenceID).map {
            CompatibilityEvidence(kind: .referenceSymbolGraph, reference: $0.source.id)
        }
        switch rule.action.kind {
        case .exclude:
            return try excludedDecision(
                referenceID: referenceID,
                signature: signature,
                rule: rule,
                evidence: evidence
            )
        case .include:
            guard let contractID = rule.action.contractID,
                  let contractKind = rule.action.contractKind,
                  let status = rule.action.status,
                  let availability = rule.action.availability else {
                throw manifestGenerationDiagnostic(
                    "review-policy.include-fields",
                    "Include rule '\(rule.id)' has incomplete fields"
                )
            }
            evidence.append(
                CompatibilityEvidence(
                    kind: contractKind == .compile ? .compileContract : .behaviorContract,
                    reference: contractID
                )
            )
            return ReferenceDecision(
                referenceID: referenceID,
                referenceSignature: signature,
                tuikitSignature: rule.action.plannedTUIkitSignatures?[referenceID],
                inclusion: .include,
                status: status,
                availability: availability,
                evidence: evidence.sorted(by: compatibilityEvidenceOrder),
                ownerIssue: rule.action.ownerIssue,
                contractID: contractID
            )
        }
    }

    func excludedDecision(
        referenceID: String,
        signature: String,
        rule: ReferenceReviewRule,
        evidence: [CompatibilityEvidence]
    ) throws -> ReferenceDecision {
        guard let category = rule.action.category,
              let reason = rule.action.reason else {
            throw manifestGenerationDiagnostic(
                "review-policy.exclusion-fields",
                "Exclusion rule '\(rule.id)' requires category and reason"
            )
        }
        return ReferenceDecision(
            referenceID: referenceID,
            referenceSignature: signature,
            inclusion: .exclude,
            status: .verified,
            availability: AvailabilityDecision(policy: .excluded, reason: reason),
            evidence: evidence.sorted(by: compatibilityEvidenceOrder),
            exclusion: ExclusionDecision(category: category, reason: reason)
        )
    }

    func uniqueSignature(
        in set: APISnapshotSet,
        identifier: String,
        direction: String
    ) throws -> String {
        let signatures = Set(set.occurrences(for: identifier).map {
            $0.symbol.canonicalDeclaration
        })
        guard signatures.count == 1, let signature = signatures.first else {
            throw manifestGenerationDiagnostic(
                "manifest-generator.signature-ambiguous",
                "\(direction) symbol '\(identifier)' has no single canonical signature"
            )
        }
        return signature
    }

    func isNonempty(_ value: String) -> Bool {
        !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func isNonempty(_ value: String?) -> Bool {
        value.map(isNonempty) == true
    }
}

private enum ReviewPolicySignatureSemantics {
    static let nonportableTokens = [
        "CAAnimation",
        "CALayer",
        "CGImage",
        "CIImage",
        "CoordinateSpace3D",
        "CVPixelBuffer",
        "NSColor",
        "NSControl",
        "NSDirectionalEdgeInsets",
        "NSDraggingInfo",
        "NSDraggingSession",
        "NSGestureRecognizerRepresentable",
        "NSHelpManager",
        "NSImage",
        "NSItemProvider",
        "NSManagedObjectContext",
        "NSTextContentType",
        "NSUnderlineStyle",
        "NSUserActivity",
        "Selector",
        "SurfaceClassification",
        "SurfaceSnappingInfo",
        "UIAccessibilityContrast",
        "UIColor",
        "UIContentSizeCategory",
        "UIDragSession",
        "UIDropSession",
        "UIGestureRecognizerRepresentable",
        "UIImage",
        "UIKeyboardType",
        "UILegibilityWeight",
        "UITextAutocapitalizationType",
        "UITextContentType",
        "UITraitBridgedEnvironmentKey",
        "UITraitEnvironmentLayoutDirection",
        "UIUserInterfaceSizeClass",
        "UIUserInterfaceStyle",
        "WKTextContentType",
    ]

    static func requiresSwift60CompilerFloor(_ signature: String) -> Bool {
        ["actor", "class", "enum", "protocol", "struct"].contains { declarationKind in
            signature.hasPrefix("nonisolated \(declarationKind) ")
        }
    }

    static func nonportableToken(in signature: String) -> String? {
        let tokens = Set(signature.split { character in
            !(character.isLetter || character.isNumber || character == "_")
        })
        return nonportableTokens.first { tokens.contains(Substring($0)) }
    }
}

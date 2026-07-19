import Foundation

/// Validates the recorded compatibility contract against complete API snapshot sets.
public struct CompatibilitySurfaceValidator: Sendable {
    public init() {}

    public func validate(
        _ manifest: CompatibilityManifest,
        referenceSet: APISnapshotSet,
        tuikitSet: APISnapshotSet
    ) -> [APICheckDiagnostic] {
        SurfaceValidation(
            manifest: manifest,
            referenceSet: referenceSet,
            tuikitSet: tuikitSet
        ).diagnostics().sorted()
    }
}

private struct SurfaceValidation {
    let manifest: CompatibilityManifest
    let referenceSet: APISnapshotSet
    let tuikitSet: APISnapshotSet

    func diagnostics() -> [APICheckDiagnostic] {
        let normalizer = SurfaceNormalizer(
            manifest: manifest,
            moduleNames: referenceSet.moduleNames + tuikitSet.moduleNames
        )
        let referenceRelationships = relationshipIndex(in: referenceSet)
        let tuikitRelationships = relationshipIndex(in: tuikitSet)
        return inventoryDiagnostics()
            + signatureDiagnostics()
            + mappedSurfaceDiagnostics(
                normalizer: normalizer,
                referenceRelationships: referenceRelationships,
                tuikitRelationships: tuikitRelationships
            )
            + unownedRelationshipDiagnostics(
                reference: referenceRelationships,
                tuikit: tuikitRelationships
            )
            + collisionDiagnostics(normalizer: normalizer)
    }

    private func inventoryDiagnostics() -> [APICheckDiagnostic] {
        inventoryDiagnostics(
            expected: Set(manifest.referenceIDs),
            actual: Set(referenceSet.unionPreciseIdentifiers),
            name: "reference"
        ) + inventoryDiagnostics(
            expected: Set(manifest.tuikitDecisions.map(\.symbolID)),
            actual: Set(tuikitSet.unionPreciseIdentifiers),
            name: "tuikit"
        )
    }

    private func inventoryDiagnostics(
        expected: Set<String>,
        actual: Set<String>,
        name: String
    ) -> [APICheckDiagnostic] {
        expected.subtracting(actual).sorted().map {
            APICheckDiagnostic(
                code: "surface.\(name)-inventory-missing",
                message: "Recorded \(name) symbol '\($0)' is absent from the snapshot union"
            )
        } + actual.subtracting(expected).sorted().map {
            APICheckDiagnostic(
                code: "surface.\(name)-inventory-unexpected",
                message: "Snapshot union contains unrecorded \(name) symbol '\($0)'"
            )
        }
    }

    private func signatureDiagnostics() -> [APICheckDiagnostic] {
        manifest.decisions.sorted { $0.referenceID < $1.referenceID }.flatMap { decision in
            recordedSignatureDiagnostics(
                identifier: decision.referenceID,
                expected: decision.referenceSignature,
                occurrences: referenceSet.occurrences(for: decision.referenceID),
                name: "reference"
            ) + tuikitSignatureDiagnostics(for: decision)
        }
    }

    private func tuikitSignatureDiagnostics(for decision: ReferenceDecision) -> [APICheckDiagnostic] {
        guard decision.inclusion == .include,
              decision.status == .implemented || decision.status == .verified,
              let identifier = decision.tuikitSymbolID
        else { return [] }
        guard let expected = decision.tuikitSignature else {
            return [
                APICheckDiagnostic(
                    code: "surface.tuikit-signature-missing",
                    message: "Implemented TUIkit symbol '\(identifier)' has no recorded signature"
                ),
            ]
        }
        return recordedSignatureDiagnostics(
            identifier: identifier,
            expected: expected,
            occurrences: tuikitSet.occurrences(for: identifier),
            name: "tuikit"
        )
    }

    private func recordedSignatureDiagnostics(
        identifier: String,
        expected: String,
        occurrences: [APISnapshotSymbolOccurrence],
        name: String
    ) -> [APICheckDiagnostic] {
        guard !occurrences.isEmpty else {
            return [
                APICheckDiagnostic(
                    code: "surface.\(name)-signature-missing",
                    message: "No \(name) snapshot occurrence proves the signature for '\(identifier)'"
                ),
            ]
        }
        let declarations = Dictionary(grouping: occurrences) { $0.symbol.canonicalDeclaration }
        return declarations.keys.filter { $0 != expected }.sorted().map { declaration in
            let sources = declarations[declaration, default: []].map(\.source.id).sorted()
            return APICheckDiagnostic(
                code: "surface.\(name)-signature",
                message: "\(name.capitalized) symbol '\(identifier)' has '\(declaration)' in [\(sources.joined(separator: ", "))], expected '\(expected)'"
            )
        }
    }

    private func mappedSurfaceDiagnostics(
        normalizer: SurfaceNormalizer,
        referenceRelationships: RelationshipAnchorIndex,
        tuikitRelationships: RelationshipAnchorIndex
    ) -> [APICheckDiagnostic] {
        let tuikitByID = Dictionary(grouping: manifest.tuikitDecisions, by: \.symbolID)
        var diagnostics: [APICheckDiagnostic] = []
        for decision in manifest.decisions.sorted(by: { $0.referenceID < $1.referenceID }) {
            guard decision.inclusion == .include,
                  let tuikitID = decision.tuikitSymbolID,
                  let candidates = tuikitByID[tuikitID],
                  let tuikitDecision = mappedDecision(
                      candidates,
                      referenceID: decision.referenceID
                  )
            else { continue }
            let reference = surfaceOccurrences(
                in: referenceSet,
                identifier: decision.referenceID,
                relationshipIndex: referenceRelationships,
                normalizer: normalizer
            )
            let current = surfaceOccurrences(
                in: tuikitSet,
                identifier: tuikitID,
                relationshipIndex: tuikitRelationships,
                normalizer: normalizer
            )
            let mismatches: [SurfaceMismatch] = CompatibilityDifference.allCases.flatMap { difference in
                reference.flatMap { referenceOccurrence in
                    current.compactMap { currentOccurrence -> SurfaceMismatch? in
                        guard referenceOccurrence.surface.value(for: difference)
                            != currentOccurrence.surface.value(for: difference)
                        else { return nil }
                        return SurfaceMismatch(
                            difference: difference,
                            reference: referenceOccurrence.source,
                            current: currentOccurrence.source
                        )
                    }
                }
            }
            let differences = Set(mismatches.map(\.difference))
            diagnostics += differenceDiagnostics(
                differences: differences,
                mismatches: mismatches,
                decision: decision,
                tuikitDecision: tuikitDecision
            )
        }
        return diagnostics
    }

    private func mappedDecision(
        _ candidates: [TUIkitSymbolDecision],
        referenceID: String
    ) -> TUIkitSymbolDecision? {
        candidates.first {
            guard $0.referenceID == referenceID else { return false }
            return $0.classification == .swiftUIExact
                || $0.classification == .reviewedException
        }
    }

    private func differenceDiagnostics(
        differences: Set<CompatibilityDifference>,
        mismatches: [SurfaceMismatch],
        decision: ReferenceDecision,
        tuikitDecision: TUIkitSymbolDecision
    ) -> [APICheckDiagnostic] {
        if tuikitDecision.classification == .swiftUIExact {
            return differences.map {
                differenceDiagnostic($0, mismatches: mismatches, decision: decision)
            }
        }
        guard let exception = tuikitDecision.exception else {
            return [
                APICheckDiagnostic(
                    code: "surface.exception-missing",
                    message: "Reviewed exception '\(tuikitDecision.symbolID)' has no allowlist"
                ),
            ]
        }
        let allowed = Set(exception.allowedDifferences)
        var diagnostics = differences.subtracting(allowed).map {
            differenceDiagnostic($0, mismatches: mismatches, decision: decision)
        }
        diagnostics += allowed.subtracting(differences).map {
            APICheckDiagnostic(
                code: "surface.exception-unused-difference",
                message: "Reviewed exception '\(tuikitDecision.symbolID)' allows unused '\($0.rawValue)' difference"
            )
        }
        if differences.contains(.availability),
           allowed.contains(.availability),
           !decision.availability.policy.permitsSurfaceDifference {
            diagnostics.append(
                APICheckDiagnostic(
                    code: "surface.availability-policy",
                    message: "Availability difference for '\(tuikitDecision.symbolID)' requires a permissive manifest policy"
                )
            )
        }
        return diagnostics
    }

    private func differenceDiagnostic(
        _ difference: CompatibilityDifference,
        mismatches: [SurfaceMismatch],
        decision: ReferenceDecision
    ) -> APICheckDiagnostic {
        let sourcePairs = Set(mismatches.filter { $0.difference == difference }.map {
            "\($0.reference.diagnosticLabel) -> \($0.current.diagnosticLabel)"
        }).sorted()
        let mapping = "'\(decision.referenceID)' -> '\(decision.tuikitSymbolID ?? "<missing>")'"
        return APICheckDiagnostic(
            code: "surface.\(difference.rawValue)",
            message: "\(difference.rawValue) differs for \(mapping); source pairs [\(sourcePairs.joined(separator: ", "))]"
        )
    }

    private func surfaceOccurrences(
        in set: APISnapshotSet,
        identifier: String,
        relationshipIndex: RelationshipAnchorIndex,
        normalizer: SurfaceNormalizer
    ) -> [SurfaceOccurrence] {
        set.sources.flatMap { loadedSource in
            loadedSource.snapshot.symbols.filter { $0.preciseIdentifier == identifier }.map { symbol in
                return SurfaceOccurrence(
                    source: SnapshotSourceIdentity(loadedSource.source),
                    surface: normalizer.surface(
                        symbol: symbol,
                        relationships: relationshipIndex.relationships(
                            anchoredTo: symbol.preciseIdentifier,
                            platform: loadedSource.source.platform
                        )
                    )
                )
            }
        }.sorted { $0.source.id < $1.source.id }
    }

    private func relationshipIndex(in set: APISnapshotSet) -> RelationshipAnchorIndex {
        let localIdentifiers = Set(set.unionPreciseIdentifiers)
        var relationships: [RelationshipAnchorKey: Set<CanonicalRelationship>] = [:]
        var unowned: [UnownedRelationship] = []
        for source in set.sources {
            for relationship in source.snapshot.relationships {
                let anchors = relationshipAnchors(
                    relationship,
                    localIdentifiers: localIdentifiers
                )
                if anchors.isEmpty,
                   !isForeignStandardConformance(relationship) {
                    unowned.append(
                        UnownedRelationship(
                            sourceID: source.source.id,
                            relationship: relationship
                        )
                    )
                }
                for anchor in anchors {
                    relationships[
                        RelationshipAnchorKey(
                            platform: source.source.platform,
                            identifier: anchor
                        ),
                        default: []
                    ].insert(relationship)
                }
            }
        }
        return RelationshipAnchorIndex(
            relationshipsByAnchor: relationships,
            unowned: unowned
        )
    }

    private func isForeignStandardConformance(
        _ relationship: CanonicalRelationship
    ) -> Bool {
        guard relationship.kind == "conformsTo",
              relationship.semanticDetails.isEmpty else {
            return false
        }
        let targets = [
            "s:SQ": "Swift.Equatable",
            "s:s8CopyableP": "Swift.Copyable",
            "s:s8SendableP": "Swift.Sendable",
            "s:s9EscapableP": "Swift.Escapable",
            "s:s16SendableMetatypeP": "Swift.SendableMetatype",
            "s:s18AdditiveArithmeticP": "Swift.AdditiveArithmetic",
        ]
        return targets[relationship.target] == relationship.targetFallback
    }

    private func relationshipAnchors(
        _ relationship: CanonicalRelationship,
        localIdentifiers: Set<String>
    ) -> Set<String> {
        if localIdentifiers.contains(relationship.source) {
            return [relationship.source]
        }
        if localIdentifiers.contains(relationship.target) {
            return [relationship.target]
        }
        return Set(relationship.semanticDetails.values.flatMap(\.allStrings))
            .intersection(localIdentifiers)
    }

    private func unownedRelationshipDiagnostics(
        reference: RelationshipAnchorIndex,
        tuikit: RelationshipAnchorIndex
    ) -> [APICheckDiagnostic] {
        unownedRelationshipDiagnostics(reference.unowned, name: "reference")
            + unownedRelationshipDiagnostics(tuikit.unowned, name: "tuikit")
    }

    private func unownedRelationshipDiagnostics(
        _ relationships: [UnownedRelationship],
        name: String
    ) -> [APICheckDiagnostic] {
        relationships.map { occurrence in
            APICheckDiagnostic(
                code: "surface.\(name)-relationship-unowned",
                message: "Relationship '\(occurrence.relationship.source)' "
                    + "-> '\(occurrence.relationship.target)' in '\(occurrence.sourceID)' "
                    + "has no \(name) symbol anchor"
            )
        }
    }

    private func collisionDiagnostics(normalizer: SurfaceNormalizer) -> [APICheckDiagnostic] {
        let reference = referenceSet.sources.flatMap { source in
            source.snapshot.symbols.map {
                CollisionOccurrence(
                    sourceID: source.source.id,
                    symbolID: $0.preciseIdentifier,
                    key: normalizer.collisionKey(for: $0)
                )
            }
        }
        return manifest.tuikitDecisions.filter { $0.classification == .tuiSpecific }.flatMap { decision in
            tuikitSet.occurrences(for: decision.symbolID).flatMap { occurrence in
                let key = normalizer.collisionKey(for: occurrence.symbol)
                return reference.filter { $0.key == key }.map { match in
                    APICheckDiagnostic(
                        code: "surface.tui-specific-collision",
                        message: "TUI-specific '\(decision.symbolID)' in '\(occurrence.source.id)' collides with '\(match.symbolID)' in '\(match.sourceID)'"
                    )
                }
            }
        }
    }
}

private struct RelationshipAnchorKey: Hashable {
    let platform: String
    let identifier: String
}

private struct RelationshipAnchorIndex {
    let relationshipsByAnchor: [RelationshipAnchorKey: Set<CanonicalRelationship>]
    let unowned: [UnownedRelationship]

    func relationships(
        anchoredTo identifier: String,
        platform: String
    ) -> [CanonicalRelationship] {
        Array(relationshipsByAnchor[
            RelationshipAnchorKey(platform: platform, identifier: identifier),
            default: []
        ])
    }
}

private struct UnownedRelationship {
    let sourceID: String
    let relationship: CanonicalRelationship
}

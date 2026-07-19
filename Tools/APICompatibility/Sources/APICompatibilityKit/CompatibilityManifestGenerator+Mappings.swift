extension CompatibilityManifestGenerator {
    func automaticMappingCandidates(
        decisions: [ReferenceDecision],
        referenceSet: APISnapshotSet,
        tuikitSet: APISnapshotSet,
        excludedTUIkitIDs: Set<String>
    ) -> [MappingCandidate] {
        let implementedIDs = Set(decisions.compactMap {
            $0.inclusion == .include && $0.status == .implemented ? $0.referenceID : nil
        })
        let referencesByKey = Dictionary(grouping: implementedIDs.sorted()) {
            structuralKey(in: referenceSet, identifier: $0)
        }
        let tuikitIDs = tuikitSet.unionPreciseIdentifiers.filter {
            !excludedTUIkitIDs.contains($0)
        }
        let tuikitByKey = Dictionary(grouping: tuikitIDs) {
            structuralKey(in: tuikitSet, identifier: $0)
        }
        return referencesByKey.keys.compactMap { key in
            guard let key,
                  let referenceIDs = referencesByKey[key], referenceIDs.count == 1,
                  let tuikitIDs = tuikitByKey[key], tuikitIDs.count == 1,
                  let referenceID = referenceIDs.first,
                  let tuikitID = tuikitIDs.first,
                  let decision = decisions.first(where: { $0.referenceID == referenceID }),
                  exactSurfaceMatch(
                      referenceID: referenceID,
                      tuikitID: tuikitID,
                      availability: decision.availability.policy,
                      referenceSet: referenceSet,
                      tuikitSet: tuikitSet
                  ) else { return nil }
            return MappingCandidate(referenceID: referenceID, tuikitID: tuikitID)
        }.sorted { lhs, rhs in
            lhs.referenceID == rhs.referenceID
                ? lhs.tuikitID < rhs.tuikitID
                : lhs.referenceID < rhs.referenceID
        }
    }

    func applyMapping(
        referenceID: String,
        tuikitID: String,
        classification: TUIkitClassification,
        exception: CompatibilityException?,
        referenceSet: APISnapshotSet,
        tuikitSet: APISnapshotSet,
        state: inout ManifestGenerationState
    ) throws {
        guard let index = state.decisions.firstIndex(where: {
            $0.referenceID == referenceID
        }),
        state.decisions[index].inclusion == .include,
        state.decisions[index].status == .implemented else {
            throw manifestGenerationDiagnostic(
                "manifest-generator.mapping-reference",
                "Mapping for '\(tuikitID)' requires an implemented included reference"
            )
        }
        guard tuikitSet.contains(tuikitID) else {
            throw manifestGenerationDiagnostic(
                "manifest-generator.mapping-tuikit",
                "Mapping references unknown TUIkit symbol '\(tuikitID)'"
            )
        }
        guard state.mappedReferenceIDs.insert(referenceID).inserted,
              state.mappedTUIkitIDs.insert(tuikitID).inserted else {
            throw manifestGenerationDiagnostic(
                "manifest-generator.mapping-duplicate",
                "Mapping '\(referenceID)' -> '\(tuikitID)' is not one-to-one"
            )
        }
        if classification == .swiftUIExact,
           !exactSurfaceMatch(
               referenceID: referenceID,
               tuikitID: tuikitID,
               availability: state.decisions[index].availability.policy,
               referenceSet: referenceSet,
               tuikitSet: tuikitSet
           ) {
            throw manifestGenerationDiagnostic(
                "manifest-generator.exact-surface-mismatch",
                "Exact mapping '\(referenceID)' -> '\(tuikitID)' has compatibility differences"
            )
        }
        state.decisions[index].tuikitSymbolID = tuikitID
        state.decisions[index].tuikitSignature = try uniqueSignature(
            in: tuikitSet,
            identifier: tuikitID,
            direction: "TUIkit"
        )
        state.decisions[index].evidence += tuikitSet.occurrences(for: tuikitID).map {
            CompatibilityEvidence(kind: .tuikitSymbolGraph, reference: $0.source.id)
        }
        state.tuikitDecisions.append(
            TUIkitSymbolDecision(
                symbolID: tuikitID,
                classification: classification,
                referenceID: referenceID,
                exception: exception
            )
        )
    }

    func structuralKey(
        in set: APISnapshotSet,
        identifier: String
    ) -> StructuralKey? {
        let keys = Set(set.occurrences(for: identifier).map {
            StructuralKey(
                kind: $0.symbol.kindIdentifier,
                title: $0.symbol.title,
                path: $0.symbol.pathComponents
            )
        })
        return keys.count == 1 ? keys.first : nil
    }

    func exactSurfaceMatch(
        referenceID: String,
        tuikitID: String,
        availability: AvailabilityPolicy,
        referenceSet: APISnapshotSet,
        tuikitSet: APISnapshotSet
    ) -> Bool {
        let referenceModules = Set(
            referenceSet.occurrences(for: referenceID).map(\.source.moduleName)
        )
        let tuikitModules = Set(
            tuikitSet.occurrences(for: tuikitID).map(\.source.moduleName)
        )
        guard referenceModules.count == 1, tuikitModules.count == 1 else {
            return false
        }
        let normalizer = SurfaceNormalizer(
            manifest: mappingManifest(
                referenceID: referenceID,
                tuikitID: tuikitID,
                availability: availability
            ),
            moduleNames: referenceModules.sorted() + tuikitModules.sorted()
        )
        let referenceSurfaces = generatorSurfaces(
            in: referenceSet,
            identifier: referenceID,
            normalizer: normalizer
        )
        let tuikitSurfaces = generatorSurfaces(
            in: tuikitSet,
            identifier: tuikitID,
            normalizer: normalizer
        )
        guard !referenceSurfaces.isEmpty, !tuikitSurfaces.isEmpty else { return false }
        return referenceSurfaces.allSatisfy { reference in
            tuikitSurfaces.allSatisfy { current in
                exactSurfaceMatch(
                    reference,
                    current,
                    availability: availability
                )
            }
        }
    }

    func mappingManifest(
        referenceID: String,
        tuikitID: String,
        availability: AvailabilityPolicy
    ) -> CompatibilityManifest {
        CompatibilityManifest(
            schemaVersion: 2,
            referenceIDs: [referenceID],
            decisions: [
                ReferenceDecision(
                    referenceID: referenceID,
                    referenceSignature: "placeholder",
                    tuikitSignature: "placeholder",
                    inclusion: .include,
                    status: .implemented,
                    availability: AvailabilityDecision(policy: availability),
                    evidence: [],
                    ownerIssue: "#0",
                    contractID: "placeholder",
                    tuikitSymbolID: tuikitID
                ),
            ],
            tuikitDecisions: [
                TUIkitSymbolDecision(
                    symbolID: tuikitID,
                    classification: .swiftUIExact,
                    referenceID: referenceID
                ),
            ]
        )
    }

    func exactSurfaceMatch(
        _ reference: SymbolCompatibilitySurface,
        _ current: SymbolCompatibilitySurface,
        availability _: AvailabilityPolicy
    ) -> Bool {
        CompatibilityDifference.allCases.allSatisfy { difference in
            return reference.value(for: difference) == current.value(for: difference)
        }
    }

    func generatorSurfaces(
        in set: APISnapshotSet,
        identifier: String,
        normalizer: SurfaceNormalizer
    ) -> [SymbolCompatibilitySurface] {
        set.sources.flatMap { source in
            source.snapshot.symbols.filter {
                $0.preciseIdentifier == identifier
            }.map { symbol in
                let relationships = source.snapshot.relationships.filter { relationship in
                    relationship.source == identifier
                        || relationship.target == identifier
                        || relationship.semanticDetails.values
                            .contains { $0.allStrings.contains(identifier) }
                }
                return normalizer.surface(symbol: symbol, relationships: relationships)
            }
        }
    }
}

struct MappingCandidate {
    let referenceID: String
    let tuikitID: String
}

struct StructuralKey: Hashable {
    let kind: String
    let title: String
    let path: [String]
}

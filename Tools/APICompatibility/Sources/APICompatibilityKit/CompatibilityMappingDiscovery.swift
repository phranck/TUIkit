public struct CompatibilityMappingCandidate: Equatable, Sendable {
    public let referenceID: String
    public let tuikitSymbolID: String
    public let differences: [CompatibilityDifference]

    public init(
        referenceID: String,
        tuikitSymbolID: String,
        differences: [CompatibilityDifference]
    ) {
        self.referenceID = referenceID
        self.tuikitSymbolID = tuikitSymbolID
        self.differences = differences
    }
}

/// Finds unambiguous structural pairs and reports their complete surface differences.
public struct CompatibilityMappingDiscovery: Sendable {
    public init() {}

    public func discover(
        referenceSet: APISnapshotSet,
        tuikitSet: APISnapshotSet
    ) -> [CompatibilityMappingCandidate] {
        let referencesByKey = identifiersByStructuralKey(in: referenceSet)
        let tuikitByKey = identifiersByStructuralKey(in: tuikitSet)
        return referencesByKey.keys.compactMap { key in
            guard let referenceIDs = referencesByKey[key],
                  referenceIDs.count == 1,
                  let tuikitIDs = tuikitByKey[key],
                  tuikitIDs.count == 1,
                  let referenceID = referenceIDs.first,
                  let tuikitID = tuikitIDs.first else {
                return nil
            }
            let manifest = mappingManifest(referenceID: referenceID, tuikitID: tuikitID)
            return CompatibilityMappingCandidate(
                referenceID: referenceID,
                tuikitSymbolID: tuikitID,
                differences: compatibilityMappingDifferences(
                    manifest: manifest,
                    referenceSet: referenceSet,
                    tuikitSet: tuikitSet,
                    referenceID: referenceID,
                    tuikitID: tuikitID
                )
            )
        }.sorted {
            $0.referenceID == $1.referenceID
                ? $0.tuikitSymbolID < $1.tuikitSymbolID
                : $0.referenceID < $1.referenceID
        }
    }

    private func identifiersByStructuralKey(
        in set: APISnapshotSet
    ) -> [StructuralKey: [String]] {
        var result: [StructuralKey: [String]] = [:]
        for identifier in set.unionPreciseIdentifiers {
            let keys = Set(set.occurrences(for: identifier).map {
                StructuralKey(
                    kind: $0.symbol.kindIdentifier,
                    title: $0.symbol.title,
                    path: $0.symbol.pathComponents
                )
            })
            guard keys.count == 1, let key = keys.first else { continue }
            result[key, default: []].append(identifier)
        }
        return result
    }

    private func mappingManifest(
        referenceID: String,
        tuikitID: String
    ) -> CompatibilityManifest {
        CompatibilityManifest(
            schemaVersion: 2,
            referenceIDs: [referenceID],
            decisions: [
                ReferenceDecision(
                    referenceID: referenceID,
                    referenceSignature: "discovery",
                    tuikitSignature: "discovery",
                    inclusion: .include,
                    status: .implemented,
                    availability: AvailabilityDecision(policy: .matchesReference),
                    evidence: [],
                    ownerIssue: "#7",
                    contractID: "discovery",
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
}

import Foundation

public struct SnapshotComparator: Sendable {
    public init() {}

    public func compare(reference: APISnapshot, current: APISnapshot) throws -> APIComparison {
        guard reference.moduleName == current.moduleName else {
            throw APICheckDiagnostic(
                code: "snapshot.module-mismatch",
                message: "Cannot compare module '\(reference.moduleName)' with module '\(current.moduleName)'"
            )
        }

        let referenceSymbols = try symbolMap(reference.symbols, role: "Reference")
        let currentSymbols = try symbolMap(current.symbols, role: "Current")
        let referenceIDs = Set(referenceSymbols.keys)
        let currentIDs = Set(currentSymbols.keys)
        let added = currentIDs.subtracting(referenceIDs).compactMap { currentSymbols[$0] }.sorted(by: compareSymbols)
        let removed = referenceIDs.subtracting(currentIDs).compactMap { referenceSymbols[$0] }.sorted(by: compareSymbols)
        let changed = referenceIDs.intersection(currentIDs).compactMap { identifier -> SymbolChange? in
            guard let before = referenceSymbols[identifier],
                  let after = currentSymbols[identifier],
                  before != after
            else {
                return nil
            }
            return SymbolChange(
                preciseIdentifier: identifier,
                reference: before,
                current: after
            )
        }.sorted { $0.preciseIdentifier < $1.preciseIdentifier }

        let referenceRelationships = try relationshipSet(reference.relationships, role: "Reference")
        let currentRelationships = try relationshipSet(current.relationships, role: "Current")
        let addedRelationships = currentRelationships.subtracting(referenceRelationships).sorted(by: compareRelationships)
        let removedRelationships = referenceRelationships.subtracting(currentRelationships).sorted(by: compareRelationships)

        return APIComparison(
            schemaVersion: 1,
            moduleName: reference.moduleName,
            addedSymbols: added,
            removedSymbols: removed,
            changedSymbols: changed,
            addedRelationships: addedRelationships,
            removedRelationships: removedRelationships
        )
    }

    private func compareSymbols(_ lhs: CanonicalSymbol, _ rhs: CanonicalSymbol) -> Bool {
        lhs.preciseIdentifier < rhs.preciseIdentifier
    }

    private func symbolMap(
        _ symbols: [CanonicalSymbol],
        role: String
    ) throws -> [String: CanonicalSymbol] {
        var result: [String: CanonicalSymbol] = [:]
        for symbol in symbols {
            guard result.updateValue(symbol, forKey: symbol.preciseIdentifier) == nil else {
                throw APICheckDiagnostic(
                    code: "snapshot.duplicate-symbol",
                    message: "\(role) snapshot contains duplicate precise identifier '\(symbol.preciseIdentifier)'"
                )
            }
        }
        return result
    }

    private func compareRelationships(
        _ lhs: CanonicalRelationship,
        _ rhs: CanonicalRelationship
    ) -> Bool {
        let lhsKey = relationshipSortKey(lhs)
        let rhsKey = relationshipSortKey(rhs)
        return lhsKey < rhsKey
    }

    private func relationshipSortKey(_ relationship: CanonicalRelationship) -> String {
        [
            relationship.source,
            relationship.kind,
            relationship.target,
            relationship.targetFallback ?? "",
            canonicalSemanticDetailsSortKey(relationship.semanticDetails),
        ].joined(separator: "\u{0}")
    }

    private func relationshipSet(
        _ relationships: [CanonicalRelationship],
        role: String
    ) throws -> Set<CanonicalRelationship> {
        var result: Set<CanonicalRelationship> = []
        for relationship in relationships {
            guard result.insert(relationship).inserted else {
                throw APICheckDiagnostic(
                    code: "snapshot.duplicate-relationship",
                    message: "\(role) snapshot contains a duplicate relationship from '\(relationship.source)' to '\(relationship.target)'"
                )
            }
        }
        return result
    }
}

public struct APIComparison: Codable, Equatable, Sendable {
    public let schemaVersion: Int
    public let moduleName: String
    public let addedSymbols: [CanonicalSymbol]
    public let removedSymbols: [CanonicalSymbol]
    public let changedSymbols: [SymbolChange]
    public let addedRelationships: [CanonicalRelationship]
    public let removedRelationships: [CanonicalRelationship]

    public var hasChanges: Bool {
        !addedSymbols.isEmpty
            || !removedSymbols.isEmpty
            || !changedSymbols.isEmpty
            || !addedRelationships.isEmpty
            || !removedRelationships.isEmpty
    }
}

public struct SymbolChange: Codable, Equatable, Sendable {
    public let preciseIdentifier: String
    public let reference: CanonicalSymbol
    public let current: CanonicalSymbol
}

public struct ComparisonCodec: Sendable {
    public init() {}

    public func encode(_ comparison: APIComparison) throws -> Data {
        try JSONArtifactCodec.encode(comparison)
    }
}

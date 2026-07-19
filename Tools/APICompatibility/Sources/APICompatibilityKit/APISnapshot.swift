import Foundation

public struct APISnapshotProvenance: Codable, Equatable, Sendable {
    public var platform: String
    public var targetTriple: String
    public var sdkName: String
    public var sdkVersion: String
    public var sdkBuild: String
    public var compilerVersion: String

    public init(
        platform: String,
        targetTriple: String,
        sdkName: String,
        sdkVersion: String,
        sdkBuild: String,
        compilerVersion: String
    ) {
        self.platform = platform
        self.targetTriple = targetTriple
        self.sdkName = sdkName
        self.sdkVersion = sdkVersion
        self.sdkBuild = sdkBuild
        self.compilerVersion = compilerVersion
    }
}

public struct APISnapshot: Codable, Equatable, Sendable {
    public var schemaVersion: Int
    public var moduleName: String
    public var provenance: APISnapshotProvenance
    public var symbols: [CanonicalSymbol]
    public var relationships: [CanonicalRelationship]

    public init(
        schemaVersion: Int,
        moduleName: String,
        provenance: APISnapshotProvenance,
        symbols: [CanonicalSymbol],
        relationships: [CanonicalRelationship]
    ) {
        self.schemaVersion = schemaVersion
        self.moduleName = moduleName
        self.provenance = provenance
        self.symbols = symbols
        self.relationships = relationships
    }
}

public struct CanonicalSymbol: Codable, Equatable, Sendable {
    public var preciseIdentifier: String
    public var kindIdentifier: String
    public var title: String
    public var pathComponents: [String]
    public var canonicalDeclaration: String
    public var declarationFragments: [CanonicalDeclarationFragment]
    public var accessLevel: String
    public var semanticDetails: [String: CanonicalJSONValue]

    public init(
        preciseIdentifier: String,
        kindIdentifier: String,
        title: String,
        pathComponents: [String],
        canonicalDeclaration: String,
        declarationFragments: [CanonicalDeclarationFragment]? = nil,
        accessLevel: String,
        semanticDetails: [String: CanonicalJSONValue] = [:]
    ) {
        self.preciseIdentifier = preciseIdentifier
        self.kindIdentifier = kindIdentifier
        self.title = title
        self.pathComponents = pathComponents
        self.canonicalDeclaration = canonicalDeclaration
        self.declarationFragments = declarationFragments ?? [
            CanonicalDeclarationFragment(
                kind: "text",
                spelling: canonicalDeclaration,
                preciseIdentifier: nil
            ),
        ]
        self.accessLevel = accessLevel
        self.semanticDetails = semanticDetails
    }
}

public struct CanonicalDeclarationFragment: Codable, Equatable, Sendable {
    public var kind: String
    public var spelling: String
    public var preciseIdentifier: String?

    public init(kind: String, spelling: String, preciseIdentifier: String?) {
        self.kind = kind
        self.spelling = spelling
        self.preciseIdentifier = preciseIdentifier
    }
}

public struct CanonicalRelationship: Codable, Equatable, Hashable, Sendable {
    public var kind: String
    public var source: String
    public var target: String
    public var targetFallback: String?
    public var semanticDetails: [String: CanonicalJSONValue]

    public init(
        kind: String,
        source: String,
        target: String,
        targetFallback: String?,
        semanticDetails: [String: CanonicalJSONValue] = [:]
    ) {
        self.kind = kind
        self.source = source
        self.target = target
        self.targetFallback = targetFallback
        self.semanticDetails = semanticDetails
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(kind)
        hasher.combine(source)
        hasher.combine(target)
        hasher.combine(targetFallback)
        hasher.combine(canonicalSemanticDetailsSortKey(semanticDetails))
    }
}

public struct SymbolGraphCanonicalizer: Sendable {
    public init() {}

    public func canonicalize(
        _ graph: LoadedSymbolGraph,
        provenance: APISnapshotProvenance
    ) -> APISnapshot {
        let symbols = graph.symbols.map { symbol in
            let fragments = canonicalFragments(from: symbol.declarationFragments)
            return CanonicalSymbol(
                preciseIdentifier: symbol.preciseIdentifier,
                kindIdentifier: symbol.kindIdentifier,
                title: symbol.title,
                pathComponents: symbol.pathComponents,
                canonicalDeclaration: DeclarationCanonicalization.render(fragments),
                declarationFragments: fragments,
                accessLevel: symbol.accessLevel,
                semanticDetails: symbol.semanticDetails
            )
        }.sorted(by: compareSymbols)
        let relationships = graph.relationships.map {
            CanonicalRelationship(
                kind: $0.kind,
                source: $0.source,
                target: $0.target,
                targetFallback: normalizedFallback($0.targetFallback),
                semanticDetails: $0.semanticDetails
            )
        }.sorted(by: compareRelationships)

        return APISnapshot(
            schemaVersion: 3,
            moduleName: graph.moduleName,
            provenance: provenance,
            symbols: symbols,
            relationships: relationships
        )
    }

    private func canonicalFragments(
        from fragments: [LoadedDeclarationFragment]
    ) -> [CanonicalDeclarationFragment] {
        fragments.map { fragment in
            let spelling: String
            if !fragment.spelling.isEmpty, fragment.spelling.allSatisfy(\.isWhitespace) {
                spelling = " "
            } else {
                spelling = fragment.spelling
            }
            let preciseIdentifier = fragment.preciseIdentifier?.trimmingCharacters(
                in: .whitespacesAndNewlines
            )
            return CanonicalDeclarationFragment(
                kind: fragment.kind,
                spelling: spelling,
                preciseIdentifier: preciseIdentifier?.isEmpty == false ? preciseIdentifier : nil
            )
        }
    }

    private func normalizedFallback(_ fallback: String?) -> String? {
        guard let fallback else { return nil }
        let normalized = fallback.trimmingCharacters(in: .whitespacesAndNewlines)
        return normalized.isEmpty ? nil : normalized
    }

    private func compareSymbols(_ lhs: CanonicalSymbol, _ rhs: CanonicalSymbol) -> Bool {
        if lhs.preciseIdentifier != rhs.preciseIdentifier {
            return lhs.preciseIdentifier < rhs.preciseIdentifier
        }
        return lhs.canonicalDeclaration < rhs.canonicalDeclaration
    }

    private func compareRelationships(
        _ lhs: CanonicalRelationship,
        _ rhs: CanonicalRelationship
    ) -> Bool {
        relationshipSortKey(lhs) < relationshipSortKey(rhs)
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
}

public struct SnapshotCodec: Sendable {
    public init() {}

    public func encode(_ snapshot: APISnapshot) throws -> Data {
        try validate(snapshot)
        return try JSONArtifactCodec.encode(snapshot)
    }

    public func write(_ snapshot: APISnapshot, to url: URL) throws {
        let data = try encode(snapshot)
        do {
            try FileManager.default.createDirectory(
                at: url.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            try data.write(to: url, options: .atomic)
        } catch {
            throw APICheckDiagnostic(
                code: "snapshot.write-failed",
                message: "Unable to write \(url.lastPathComponent)"
            )
        }
    }

    public func load(from url: URL) throws -> APISnapshot {
        let snapshot: APISnapshot
        do {
            let data = try Data(contentsOf: url)
            snapshot = try JSONDecoder().decode(APISnapshot.self, from: data)
        } catch {
            throw APICheckDiagnostic(
                code: "snapshot.invalid-json",
                message: "\(url.lastPathComponent) is not a valid API snapshot"
            )
        }
        try validate(snapshot)
        return snapshot
    }

    private func validate(_ snapshot: APISnapshot) throws {
        guard snapshot.schemaVersion == 3 else {
            throw APICheckDiagnostic(
                code: "snapshot.schema-version",
                message: "Unsupported snapshot schema version \(snapshot.schemaVersion)"
            )
        }
        guard !snapshot.moduleName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw APICheckDiagnostic(
                code: "snapshot.empty-module",
                message: "API snapshot has an empty module name"
            )
        }
        try validate(snapshot.provenance)
        var seenIDs: Set<String> = []
        for symbol in snapshot.symbols {
            try validate(symbol, seenIDs: &seenIDs)
        }
        try validateRelationships(snapshot.relationships, symbolIDs: seenIDs)
    }

    private func validate(_ provenance: APISnapshotProvenance) throws {
        let values = [
            ("platform", provenance.platform),
            ("targetTriple", provenance.targetTriple),
            ("sdkName", provenance.sdkName),
            ("sdkVersion", provenance.sdkVersion),
            ("sdkBuild", provenance.sdkBuild),
            ("compilerVersion", provenance.compilerVersion),
        ]
        for (field, value) in values {
            let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else {
                throw APICheckDiagnostic(
                    code: "snapshot.empty-provenance",
                    message: "API snapshot has empty \(field) provenance"
                )
            }
            guard value == trimmed else {
                throw APICheckDiagnostic(
                    code: "snapshot.noncanonical-provenance",
                    message: "API snapshot has noncanonical \(field) provenance"
                )
            }
        }
    }

    private func validate(
        _ symbol: CanonicalSymbol,
        seenIDs: inout Set<String>
    ) throws {
        guard !symbol.preciseIdentifier.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw APICheckDiagnostic(
                code: "snapshot.empty-symbol-id",
                message: "API snapshot contains a symbol without a precise identifier"
            )
        }
        guard seenIDs.insert(symbol.preciseIdentifier).inserted else {
            throw APICheckDiagnostic(
                code: "snapshot.duplicate-symbol",
                message: "Duplicate precise identifier '\(symbol.preciseIdentifier)'"
            )
        }
        guard !symbol.kindIdentifier.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw APICheckDiagnostic(
                code: "snapshot.empty-symbol-kind",
                message: "Symbol '\(symbol.preciseIdentifier)' has an empty kind"
            )
        }
        guard !symbol.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw APICheckDiagnostic(
                code: "snapshot.empty-symbol-title",
                message: "Symbol '\(symbol.preciseIdentifier)' has an empty title"
            )
        }
        guard !symbol.pathComponents.isEmpty,
              symbol.pathComponents.allSatisfy({ !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty })
        else {
            throw APICheckDiagnostic(
                code: "snapshot.invalid-symbol-path",
                message: "Symbol '\(symbol.preciseIdentifier)' has an invalid path"
            )
        }
        guard !symbol.canonicalDeclaration.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw APICheckDiagnostic(
                code: "snapshot.empty-symbol-declaration",
                message: "Symbol '\(symbol.preciseIdentifier)' has an empty declaration"
            )
        }
        guard !symbol.accessLevel.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw APICheckDiagnostic(
                code: "snapshot.empty-symbol-access",
                message: "Symbol '\(symbol.preciseIdentifier)' has an empty access level"
            )
        }
        try validateDeclarationFragments(symbol.declarationFragments, symbolID: symbol.preciseIdentifier)
        guard symbol.canonicalDeclaration == DeclarationCanonicalization.render(symbol.declarationFragments) else {
            throw APICheckDiagnostic(
                code: "snapshot.declaration-mismatch",
                message: "Symbol '\(symbol.preciseIdentifier)' declaration does not match its fragments"
            )
        }
    }

    private func validateRelationships(
        _ relationships: [CanonicalRelationship],
        symbolIDs: Set<String>
    ) throws {
        var seenRelationships: Set<CanonicalRelationship> = []
        for relationship in relationships {
            let fallback = relationship.targetFallback?.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !relationship.kind.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                  !relationship.source.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                  !relationship.target.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                  relationship.targetFallback == nil || fallback?.isEmpty == false
            else {
                throw APICheckDiagnostic(
                    code: "snapshot.invalid-relationship",
                    message: "API snapshot contains an incomplete relationship"
                )
            }
            guard relationship.targetFallback == fallback else {
                throw APICheckDiagnostic(
                    code: "snapshot.noncanonical-relationship-fallback",
                    message: "Relationship fallback '\(relationship.targetFallback ?? "")' is not canonical"
                )
            }
            guard symbolIDs.contains(relationship.target) || fallback?.isEmpty == false else {
                throw APICheckDiagnostic(
                    code: "snapshot.unknown-relationship-target",
                    message: "Relationship target '\(relationship.target)' is not exported and has no fallback"
                )
            }
            guard seenRelationships.insert(relationship).inserted else {
                throw APICheckDiagnostic(
                    code: "snapshot.duplicate-relationship",
                    message: "Duplicate relationship from '\(relationship.source)' to '\(relationship.target)'"
                )
            }
        }
    }

    private func validateDeclarationFragments(
        _ fragments: [CanonicalDeclarationFragment],
        symbolID: String
    ) throws {
        guard !fragments.isEmpty else {
            throw APICheckDiagnostic(
                code: "snapshot.invalid-declaration-fragment",
                message: "Symbol '\(symbolID)' has no declaration fragments"
            )
        }
        for fragment in fragments {
            let preciseIdentifier = fragment.preciseIdentifier?.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !fragment.kind.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                  !fragment.spelling.isEmpty,
                  fragment.preciseIdentifier == nil || preciseIdentifier?.isEmpty == false
            else {
                throw APICheckDiagnostic(
                    code: "snapshot.invalid-declaration-fragment",
                    message: "Symbol '\(symbolID)' has an invalid declaration fragment"
                )
            }
        }
    }
}

private enum DeclarationCanonicalization {
    static func render(_ fragments: [CanonicalDeclarationFragment]) -> String {
        var declaration = ""
        for fragment in fragments {
            if !fragment.spelling.isEmpty, fragment.spelling.allSatisfy(\.isWhitespace) {
                if declaration.last?.isWhitespace != true {
                    declaration.append(" ")
                }
            } else {
                declaration.append(fragment.spelling)
            }
        }
        return declaration.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

enum JSONArtifactCodec {
    static func encode(_ value: some Encodable) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        var data = try encoder.encode(value)
        data.append(0x0A)
        return data
    }
}

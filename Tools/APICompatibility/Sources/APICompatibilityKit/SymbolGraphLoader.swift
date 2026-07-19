import Foundation

public struct SymbolGraphLoader: Sendable {
    private static let extensionBlockKind = "swift.extension"
    private static let synthesizedMarker = "::SYNTHESIZED::"

    public init() {}

    public func load(
        from directory: URL,
        moduleName: String,
        extensionProvenance: ExtensionProvenanceMode = .disabled
    ) throws -> LoadedSymbolGraph {
        let mainFileName = "\(moduleName).symbols.json"
        let mainURL = directory.appendingPathComponent(mainFileName)
        guard FileManager.default.fileExists(atPath: mainURL.path) else {
            throw APICheckDiagnostic(
                code: "symbolgraph.missing-main",
                message: "Missing \(mainFileName)"
            )
        }

        let extensionURLs = try extensionGraphURLs(in: directory, moduleName: moduleName)
        let graphURLs = [mainURL] + extensionURLs
        var symbols: [LoadedSymbol] = []
        var relationships: [LoadedRelationship] = []
        var seenSymbolIDs: Set<String> = []
        var excludedSynthesizedSymbolIDs: Set<String> = []

        for url in graphURLs {
            let graph = try decodeGraph(at: url)
            try validate(module: graph.module.name, expected: moduleName, fileName: url.lastPathComponent)
            let fileSymbols = try graph.symbols.map {
                try loadSymbol($0, fileName: url.lastPathComponent, seenIDs: &seenSymbolIDs)
            }.sorted { $0.preciseIdentifier < $1.preciseIdentifier }
            let fileRelationships = try graph.relationships.map {
                try loadRelationship($0, fileName: url.lastPathComponent)
            }
            let extensionBlocks = fileSymbols.filter {
                $0.kindIdentifier == Self.extensionBlockKind
            }

            if url == mainURL {
                guard extensionBlocks.isEmpty else {
                    throw APICheckDiagnostic(
                        code: "symbolgraph.extension-block-in-main",
                        message: "\(url.lastPathComponent) contains a swift.extension block"
                    )
                }
                relationships.append(contentsOf: fileRelationships)
            } else {
                relationships.append(contentsOf: try extensionRelationships(
                    fileSymbols: fileSymbols,
                    relationships: fileRelationships,
                    extensionBlocks: extensionBlocks,
                    moduleName: moduleName,
                    fileName: url.lastPathComponent,
                    provenance: extensionProvenance
                ))
            }

            for symbol in fileSymbols {
                if symbol.preciseIdentifier.contains(Self.synthesizedMarker) {
                    excludedSynthesizedSymbolIDs.insert(symbol.preciseIdentifier)
                } else if symbol.kindIdentifier != Self.extensionBlockKind {
                    symbols.append(symbol)
                }
            }
        }

        relationships.removeAll {
            excludedSynthesizedSymbolIDs.contains($0.source)
                || excludedSynthesizedSymbolIDs.contains($0.target)
                || $0.source.contains(Self.synthesizedMarker)
                || $0.target.contains(Self.synthesizedMarker)
        }
        let inventorySymbolIDs = Set(symbols.map(\.preciseIdentifier))
        relationships = try validatedRelationships(relationships, symbolIDs: inventorySymbolIDs)
        return LoadedSymbolGraph(
            moduleName: moduleName,
            sourceFiles: graphURLs.map(\.lastPathComponent),
            symbols: symbols,
            relationships: relationships,
            excludedSynthesizedSymbolIDs: excludedSynthesizedSymbolIDs.sorted()
        )
    }
}

private extension SymbolGraphLoader {
    private func extensionRelationships(
        fileSymbols: [LoadedSymbol],
        relationships: [LoadedRelationship],
        extensionBlocks: [LoadedSymbol],
        moduleName: String,
        fileName: String,
        provenance: ExtensionProvenanceMode
    ) throws -> [LoadedRelationship] {
        switch provenance {
        case .disabled:
            guard extensionBlocks.isEmpty else {
                throw APICheckDiagnostic(
                    code: "symbolgraph.extension-block-requires-strict",
                    message: "\(fileName) contains swift.extension blocks; enable strict extension provenance"
                )
            }
            return relationships
        case .strict:
            let extendedModule = try extendedModuleName(
                fileName: fileName,
                moduleName: moduleName
            )
            let extensionTargets = try validateExtensionProvenance(
                fileSymbols: fileSymbols,
                relationships: relationships,
                extensionBlocks: extensionBlocks,
                extendedModule: extendedModule,
                fileName: fileName
            )
            return normalizeExtensionRelationships(
                relationships,
                extensionTargets: extensionTargets
            )
        }
    }

    private func extendedModuleName(fileName: String, moduleName: String) throws -> String {
        let prefix = "\(moduleName)@"
        let suffix = ".symbols.json"
        guard fileName.hasPrefix(prefix), fileName.hasSuffix(suffix) else {
            throw APICheckDiagnostic(
                code: "symbolgraph.extension-invalid-filename",
                message: "\(fileName) is not a valid extension graph filename"
            )
        }
        let start = fileName.index(fileName.startIndex, offsetBy: prefix.count)
        let end = fileName.index(fileName.endIndex, offsetBy: -suffix.count)
        let extendedModule = String(fileName[start ..< end])
        guard !extendedModule.isEmpty else {
            throw APICheckDiagnostic(
                code: "symbolgraph.extension-invalid-filename",
                message: "\(fileName) has no extended module name"
            )
        }
        return extendedModule
    }

    private func validateExtensionProvenance(
        fileSymbols: [LoadedSymbol],
        relationships: [LoadedRelationship],
        extensionBlocks: [LoadedSymbol],
        extendedModule: String,
        fileName: String
    ) throws -> [String: ExtensionTarget] {
        guard !extensionBlocks.isEmpty else {
            throw APICheckDiagnostic(
                code: "symbolgraph.extension-missing-block",
                message: "\(fileName) contains no swift.extension provenance block"
            )
        }
        let blockIDs = Set(extensionBlocks.map(\.preciseIdentifier))
        try rejectOrphanExtensionTargets(
            relationships,
            blockIDs: blockIDs,
            fileName: fileName
        )

        var extensionTargets: [String: ExtensionTarget] = [:]
        for blockID in blockIDs.sorted() {
            let targetRelationships = relationships.filter {
                $0.kind == "extensionTo" && $0.source == blockID
            }
            guard targetRelationships.count == 1 else {
                throw APICheckDiagnostic(
                    code: "symbolgraph.extension-target-count",
                    message: "\(fileName) extension block '\(blockID)' has \(targetRelationships.count) extensionTo relationships; expected 1"
                )
            }
            let relationship = targetRelationships[0]
            let fallback = relationship.targetFallback?.trimmingCharacters(in: .whitespacesAndNewlines)
            guard let fallback, !fallback.isEmpty else {
                throw APICheckDiagnostic(
                    code: "symbolgraph.extension-empty-fallback",
                    message: "\(fileName) extension block '\(blockID)' has no target fallback"
                )
            }
            guard fallback == extendedModule || fallback.hasPrefix("\(extendedModule).") else {
                throw APICheckDiagnostic(
                    code: "symbolgraph.extension-module-mismatch",
                    message: "\(fileName) extension block '\(blockID)' targets '\(fallback)'; expected module '\(extendedModule)'"
                )
            }
            extensionTargets[blockID] = ExtensionTarget(
                preciseIdentifier: relationship.target,
                fallback: fallback
            )
        }

        try validateTransitiveOwnership(
            fileSymbols: fileSymbols,
            relationships: relationships,
            blockIDs: blockIDs,
            fileName: fileName
        )
        return extensionTargets
    }

    private func rejectOrphanExtensionTargets(
        _ relationships: [LoadedRelationship],
        blockIDs: Set<String>,
        fileName: String
    ) throws {
        guard let orphan = relationships.first(where: {
            $0.kind == "extensionTo" && !blockIDs.contains($0.source)
        }) else {
            return
        }
        throw APICheckDiagnostic(
            code: "symbolgraph.extension-orphan-target",
            message: "\(fileName) extensionTo source '\(orphan.source)' is not a swift.extension block"
        )
    }

    private func validateTransitiveOwnership(
        fileSymbols: [LoadedSymbol],
        relationships: [LoadedRelationship],
        blockIDs: Set<String>,
        fileName: String
    ) throws {
        var parents: [String: Set<String>] = [:]
        for relationship in relationships where relationship.kind == "memberOf" {
            parents[relationship.source, default: []].insert(relationship.target)
        }
        let normalSymbolIDs = fileSymbols.filter {
            $0.kindIdentifier != Self.extensionBlockKind
        }.map(\.preciseIdentifier).sorted()
        for symbolID in normalSymbolIDs where !isTransitivelyOwned(
            symbolID,
            by: blockIDs,
            parents: parents
        ) {
            throw APICheckDiagnostic(
                code: "symbolgraph.extension-unproven-symbol",
                message: "\(fileName) symbol '\(symbolID)' is not transitively owned by a swift.extension block"
            )
        }
    }

    private func isTransitivelyOwned(
        _ symbolID: String,
        by blockIDs: Set<String>,
        parents: [String: Set<String>]
    ) -> Bool {
        var pending = Array(parents[symbolID, default: []])
        var visited: Set<String> = []
        while let parent = pending.popLast() {
            guard visited.insert(parent).inserted else { continue }
            if blockIDs.contains(parent) {
                return true
            }
            pending.append(contentsOf: parents[parent, default: []])
        }
        return false
    }

    private func normalizeExtensionRelationships(
        _ relationships: [LoadedRelationship],
        extensionTargets: [String: ExtensionTarget]
    ) -> [LoadedRelationship] {
        relationships.compactMap { relationship in
            guard relationship.kind != "extensionTo" else { return nil }
            let sourceTarget = extensionTargets[relationship.source]
            let targetTarget = extensionTargets[relationship.target]
            return LoadedRelationship(
                kind: relationship.kind,
                source: sourceTarget?.preciseIdentifier ?? relationship.source,
                target: targetTarget?.preciseIdentifier ?? relationship.target,
                targetFallback: targetTarget?.fallback ?? relationship.targetFallback,
                semanticDetails: relationship.semanticDetails,
                sourceFile: relationship.sourceFile
            )
        }
    }

    private func extensionGraphURLs(in directory: URL, moduleName: String) throws -> [URL] {
        let urls: [URL]
        do {
            urls = try FileManager.default.contentsOfDirectory(
                at: directory,
                includingPropertiesForKeys: [.isRegularFileKey],
                options: [.skipsHiddenFiles]
            )
        } catch {
            throw APICheckDiagnostic(
                code: "symbolgraph.unreadable-directory",
                message: "Unable to read symbol graph directory"
            )
        }
        return urls.filter {
            $0.lastPathComponent.hasPrefix("\(moduleName)@")
                && $0.lastPathComponent.hasSuffix(".symbols.json")
        }.sorted { $0.lastPathComponent < $1.lastPathComponent }
    }

    private func decodeGraph(at url: URL) throws -> RawSymbolGraph {
        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode(RawSymbolGraph.self, from: data)
        } catch {
            throw APICheckDiagnostic(
                code: "symbolgraph.invalid-json",
                message: "\(url.lastPathComponent) is not a valid symbol graph"
            )
        }
    }

    private func validate(module: String, expected: String, fileName: String) throws {
        guard module == expected else {
            throw APICheckDiagnostic(
                code: "symbolgraph.module-mismatch",
                message: "\(fileName) declares module '\(module)'; expected '\(expected)'"
            )
        }
    }

    private func loadSymbol(
        _ symbol: RawSymbol,
        fileName: String,
        seenIDs: inout Set<String>
    ) throws -> LoadedSymbol {
        let preciseIdentifier = symbol.identifier.precise.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !preciseIdentifier.isEmpty else {
            throw APICheckDiagnostic(
                code: "symbolgraph.empty-symbol-id",
                message: "\(fileName) contains a symbol without a precise identifier"
            )
        }
        guard seenIDs.insert(preciseIdentifier).inserted else {
            throw APICheckDiagnostic(
                code: "symbolgraph.duplicate-symbol",
                message: "Duplicate precise identifier '\(preciseIdentifier)' in \(fileName)"
            )
        }

        return LoadedSymbol(
            preciseIdentifier: preciseIdentifier,
            kindIdentifier: symbol.kind.identifier,
            title: symbol.names?.title ?? symbol.pathComponents.last ?? preciseIdentifier,
            pathComponents: symbol.pathComponents,
            declarationFragments: symbol.declarationFragments.map {
                LoadedDeclarationFragment(
                    kind: $0.kind,
                    spelling: $0.spelling,
                    preciseIdentifier: $0.preciseIdentifier
                )
            },
            accessLevel: symbol.accessLevel,
            semanticDetails: symbol.semanticDetails,
            sourceFile: fileName
        )
    }

    private func loadRelationship(
        _ relationship: RawRelationship,
        fileName: String
    ) throws -> LoadedRelationship {
        let kind = relationship.kind.trimmingCharacters(in: .whitespacesAndNewlines)
        let source = relationship.source.trimmingCharacters(in: .whitespacesAndNewlines)
        let target = relationship.target.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !kind.isEmpty, !source.isEmpty, !target.isEmpty else {
            throw APICheckDiagnostic(
                code: "symbolgraph.invalid-relationship",
                message: "\(fileName) contains an incomplete relationship"
            )
        }
        return LoadedRelationship(
            kind: kind,
            source: source,
            target: target,
            targetFallback: relationship.targetFallback,
            semanticDetails: relationship.semanticDetails,
            sourceFile: fileName
        )
    }

    private func inferredFallback(
        for relationship: LoadedRelationship
    ) -> String? {
        let target = relationship.target
        guard let moduleName = swiftModuleName(from: target) else { return nil }
        guard case let .array(constraints)? = relationship.semanticDetails["swiftConstraints"] else {
            return nil
        }
        let matchingNames = Set(constraints.compactMap { constraint -> String? in
            guard case let .object(fields) = constraint,
                  case let .string(rhsPrecise)? = fields["rhsPrecise"],
                  rhsPrecise.trimmingCharacters(in: .whitespacesAndNewlines) == target,
                  case let .string(rhs)? = fields["rhs"]
            else {
                return nil
            }
            let name = rhs.trimmingCharacters(in: .whitespacesAndNewlines)
            return name.isEmpty ? nil : name
        })
        guard matchingNames.count == 1, let name = matchingNames.first else { return nil }
        return name.hasPrefix("\(moduleName).") ? name : "\(moduleName).\(name)"
    }

    private func swiftModuleName(from preciseIdentifier: String) -> String? {
        let bytes = Array(preciseIdentifier.utf8)
        guard bytes.count >= 2, bytes[0] == 115, bytes[1] == 58 else {
            return nil
        }
        var index = 2
        while index < bytes.count, bytes[index] >= 48, bytes[index] <= 57 {
            index += 1
        }
        guard index > 2,
              let encodedLength = String(bytes: bytes[2 ..< index], encoding: .utf8),
              let length = Int(encodedLength),
              length > 0,
              index + length <= bytes.count
        else {
            return nil
        }
        let moduleBytes = bytes[index ..< index + length]
        guard let first = moduleBytes.first,
              Self.isSwiftIdentifierHead(first),
              moduleBytes.allSatisfy(Self.isSwiftIdentifierByte)
        else {
            return nil
        }
        return String(bytes: moduleBytes, encoding: .utf8)
    }

    private static func isSwiftIdentifierHead(_ byte: UInt8) -> Bool {
        byte == 95 || (65 ... 90).contains(byte) || (97 ... 122).contains(byte)
    }

    private static func isSwiftIdentifierByte(_ byte: UInt8) -> Bool {
        Self.isSwiftIdentifierHead(byte) || (48 ... 57).contains(byte)
    }

    private func validatedRelationships(
        _ relationships: [LoadedRelationship],
        symbolIDs: Set<String>
    ) throws -> [LoadedRelationship] {
        var seenRelationships: Set<RelationshipKey> = []
        var validated: [LoadedRelationship] = []
        for relationship in relationships {
            let suppliedFallback = relationship.targetFallback?.trimmingCharacters(in: .whitespacesAndNewlines)
            let fallback: String?
            if suppliedFallback?.isEmpty == false {
                fallback = suppliedFallback
            } else if !symbolIDs.contains(relationship.target) {
                fallback = inferredFallback(for: relationship)
            } else {
                fallback = nil
            }
            guard symbolIDs.contains(relationship.target) || fallback != nil else {
                throw APICheckDiagnostic(
                    code: "symbolgraph.unknown-relationship-target",
                    message: "Relationship target '\(relationship.target)' is not exported and has no fallback"
                )
            }
            let normalized = LoadedRelationship(
                kind: relationship.kind,
                source: relationship.source,
                target: relationship.target,
                targetFallback: fallback,
                semanticDetails: relationship.semanticDetails,
                sourceFile: relationship.sourceFile
            )
            let key = RelationshipKey(normalized)
            if seenRelationships.insert(key).inserted {
                validated.append(normalized)
            }
        }
        return validated
    }
}

private struct RelationshipKey: Hashable {
    let kind: String
    let source: String
    let target: String
    let targetFallback: String?
    let semanticDetailsKey: String

    init(_ relationship: LoadedRelationship) {
        self.kind = relationship.kind
        self.source = relationship.source
        self.target = relationship.target
        self.targetFallback = relationship.targetFallback
        self.semanticDetailsKey = canonicalSemanticDetailsSortKey(relationship.semanticDetails)
    }
}

private struct ExtensionTarget {
    let preciseIdentifier: String
    let fallback: String
}

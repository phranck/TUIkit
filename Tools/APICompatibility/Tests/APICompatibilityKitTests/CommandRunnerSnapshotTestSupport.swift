import Foundation

@testable import APICompatibilityKit

extension CommandRunnerTests {
    func writeCompatibilitySnapshotSets(
        manifest: CompatibilityManifest,
        referenceDescriptorURL: URL,
        tuikitDescriptorURL: URL
    ) throws {
        let referenceSymbols = manifest.decisions.map { decision in
            commandSymbol(
                id: decision.referenceID,
                moduleName: "SwiftUI",
                declaration: decision.referenceSignature,
                title: decision.referenceID == "s:SwiftUI.Exception" ? "exception(_:)" : decision.referenceID,
                path: decision.referenceID == "s:SwiftUI.Exception"
                    ? ["Exception", "exception(_:)"]
                    : [decision.referenceID]
            )
        }
        let signatures = Dictionary(
            uniqueKeysWithValues: manifest.decisions.compactMap { decision in
                decision.tuikitSymbolID.flatMap { symbolID in
                    decision.tuikitSignature.map { (symbolID, $0) }
                }
            }
        )
        let tuikitSymbols = manifest.tuikitDecisions.map { decision in
            let isException = decision.symbolID == "s:TUIkit.Exception"
            return commandSymbol(
                id: decision.symbolID,
                moduleName: "TUIkit",
                declaration: signatures[decision.symbolID] ?? "struct \(decision.symbolID)",
                title: isException ? "terminalException(_:)" : decision.referenceID ?? decision.symbolID,
                path: isException
                    ? ["Exception", "terminalException(_:)"]
                    : [decision.referenceID ?? decision.symbolID]
            )
        }
        try writeSnapshotSet(
            descriptorURL: referenceDescriptorURL,
            sourceID: "reference-macos",
            moduleName: "SwiftUI",
            symbols: referenceSymbols
        )
        try writeSnapshotSet(
            descriptorURL: tuikitDescriptorURL,
            sourceID: "tuikit-macos",
            moduleName: "TUIkit",
            symbols: tuikitSymbols
        )
    }

    func writeSnapshotSet(
        descriptorURL: URL,
        sourceID: String,
        moduleName: String,
        symbols: [CanonicalSymbol]
    ) throws {
        let snapshotPath = "snapshots/\(sourceID).json"
        let snapshotURL = descriptorURL.deletingLastPathComponent().appendingPathComponent(snapshotPath)
        let source = APISnapshotSetSourceDescriptor(
            id: sourceID,
            moduleName: moduleName,
            platform: "macOS",
            targetTriple: "arm64-apple-macosx",
            sdkName: "macosx",
            sdkVersion: "26.6",
            sdkBuild: "25G100",
            compilerVersion: "Swift 6.0",
            snapshotPath: snapshotPath
        )
        try SnapshotCodec().write(
            APISnapshot(
                schemaVersion: 3,
                moduleName: moduleName,
                provenance: APISnapshotProvenance(
                    platform: source.platform,
                    targetTriple: source.targetTriple,
                    sdkName: source.sdkName,
                    sdkVersion: source.sdkVersion,
                    sdkBuild: source.sdkBuild,
                    compilerVersion: source.compilerVersion
                ),
                symbols: symbols.sorted { $0.preciseIdentifier < $1.preciseIdentifier },
                relationships: []
            ),
            to: snapshotURL
        )
        try SnapshotSetDescriptorCodec().write(
            APISnapshotSetDescriptor(
                schemaVersion: 2,
                name: moduleName,
                requiredCoverage: [
                    APISnapshotCoverageRequirement(
                        moduleName: moduleName,
                        platform: "macOS"
                    ),
                ],
                sources: [source]
            ),
            to: descriptorURL
        )
    }

    func writeContractRegistry(
        for manifest: CompatibilityManifest,
        to url: URL
    ) throws {
        let contracts = manifest.decisions.compactMap(\.contractID).sorted().map { contractID in
            ContractDefinition(
                id: contractID,
                kind: .compile,
                compile: CompileContract(
                    fixture: "\(contractID).swift",
                    expectation: CompileContractExpectation(outcome: .succeeds)
                )
            )
        }
        try ContractRegistryCodec().write(
            CompatibilityContractRegistry(schemaVersion: 1, contracts: contracts),
            to: url
        )
    }

    func commandSymbol(
        id: String,
        moduleName: String,
        declaration: String,
        title: String,
        path: [String]
    ) -> CanonicalSymbol {
        CanonicalSymbol(
            preciseIdentifier: id,
            kindIdentifier: "swift.symbol",
            title: title,
            pathComponents: path,
            canonicalDeclaration: declaration,
            declarationFragments: commandDeclarationFragments(
                declaration,
                moduleName: moduleName
            ),
            accessLevel: "public"
        )
    }

    func commandDeclarationFragments(
        _ declaration: String,
        moduleName: String
    ) -> [CanonicalDeclarationFragment] {
        let pattern = #"\b"# + NSRegularExpression.escapedPattern(for: moduleName)
            + #"\.[A-Za-z_][A-Za-z0-9_]*"#
        guard let expression = try? NSRegularExpression(pattern: pattern) else {
            return [
                CanonicalDeclarationFragment(
                    kind: "text",
                    spelling: declaration,
                    preciseIdentifier: nil
                ),
            ]
        }
        let range = NSRange(declaration.startIndex..., in: declaration)
        var fragments: [CanonicalDeclarationFragment] = []
        var cursor = declaration.startIndex

        for match in expression.matches(in: declaration, range: range) {
            guard let matchRange = Range(match.range, in: declaration) else { continue }
            if cursor < matchRange.lowerBound {
                fragments.append(
                    CanonicalDeclarationFragment(
                        kind: "text",
                        spelling: String(declaration[cursor..<matchRange.lowerBound]),
                        preciseIdentifier: nil
                    )
                )
            }
            fragments.append(
                CanonicalDeclarationFragment(
                    kind: "typeIdentifier",
                    spelling: String(declaration[matchRange]),
                    preciseIdentifier: nil
                )
            )
            cursor = matchRange.upperBound
        }

        if cursor < declaration.endIndex {
            fragments.append(
                CanonicalDeclarationFragment(
                    kind: "text",
                    spelling: String(declaration[cursor...]),
                    preciseIdentifier: nil
                )
            )
        }
        return fragments.isEmpty
            ? [CanonicalDeclarationFragment(kind: "text", spelling: declaration, preciseIdentifier: nil)]
            : fragments
    }

    func snapshotSourceLine(id: String, platform: String, snapshot: String) -> String {
        [
            id,
            "TUIkit",
            platform,
            platform == "Linux" ? "x86_64-unknown-linux-gnu" : "arm64-apple-macosx14.0",
            platform == "Linux" ? "none" : "macosx",
            platform == "Linux" ? "none" : "26.5",
            platform == "Linux" ? "none" : "17F113",
            "Swift 6.0.3",
            snapshot,
        ].joined(separator: "\t")
    }
}

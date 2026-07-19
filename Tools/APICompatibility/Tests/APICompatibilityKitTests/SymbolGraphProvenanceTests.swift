import Foundation
import Testing

@testable import APICompatibilityKit

@Suite("Symbol graph extension provenance")
struct SymbolGraphProvenanceTests {
    @Test("Validates extension blocks without inventorying foreign endpoints")
    func validatesStrictExtensionProvenance() throws {
        let loaded = try loadExtensionGraph(
            symbols: strictExtensionSymbols,
            relationships: strictExtensionRelationships,
            provenance: .strict
        )

        #expect(loaded.symbols.map(\.preciseIdentifier) == [
            "s:Fixture.Widget",
            "s:External.Thing.Fixture.Addition",
            "s:External.Thing.Fixture.Addition.value",
        ])
        #expect(!loaded.symbols.map(\.preciseIdentifier).contains("s:External.Thing"))
        #expect(!loaded.symbols.map(\.kindIdentifier).contains("swift.extension"))
        #expect(loaded.relationships.count == 3)
        #expect(!loaded.relationships.contains {
            $0.source == Self.extensionBlockID || $0.target == Self.extensionBlockID
        })
        #expect(loaded.relationships.contains {
            $0.kind == "memberOf"
                && $0.source == "s:External.Thing.Fixture.Addition"
                && $0.target == "s:External.Thing"
                && $0.targetFallback == "External.Thing"
        })
        #expect(loaded.relationships.contains {
            $0.kind == "conformsTo"
                && $0.source == "s:External.Thing"
                && $0.target == "s:Fixture.Widget"
        })
    }

    @Test("Extension blocks require an explicit strict provenance mode")
    func requiresExplicitStrictMode() {
        let diagnostic = FixtureSupport.diagnostic {
            try loadExtensionGraph(
                symbols: strictExtensionSymbols,
                relationships: strictExtensionRelationships,
                provenance: .disabled
            )
        }

        let expected = "error[symbolgraph.extension-block-requires-strict]: "
            + "Fixture@External.symbols.json contains swift.extension blocks; "
            + "enable strict extension provenance"
        #expect(diagnostic?.code == "symbolgraph.extension-block-requires-strict")
        #expect(diagnostic?.description == expected)
    }

    @Test("Strict provenance requires at least one extension block")
    func strictProvenanceRequiresBlock() {
        let diagnostic = FixtureSupport.diagnostic {
            try loadExtensionGraph(
                symbols: "[\(Self.extensionMemberSymbol)]",
                relationships: "[]",
                provenance: .strict
            )
        }

        let expected = "error[symbolgraph.extension-missing-block]: "
            + "Fixture@External.symbols.json contains no swift.extension provenance block"
        #expect(diagnostic?.code == "symbolgraph.extension-missing-block")
        #expect(diagnostic?.description == expected)
    }

    @Test("Strict provenance rejects symbols outside an extension block")
    func strictProvenanceRejectsUnownedSymbol() {
        let diagnostic = FixtureSupport.diagnostic {
            try loadExtensionGraph(
                symbols: "[\(Self.extensionBlockSymbol), \(Self.extensionMemberSymbol)]",
                relationships: """
                [{
                  "kind": "extensionTo",
                  "source": "\(Self.extensionBlockID)",
                  "target": "s:External.Thing",
                  "targetFallback": "External.Thing"
                }]
                """,
                provenance: .strict
            )
        }

        let expected = "error[symbolgraph.extension-unproven-symbol]: "
            + "Fixture@External.symbols.json symbol 's:External.Thing.Fixture.Addition' "
            + "is not transitively owned by a swift.extension block"
        #expect(diagnostic?.code == "symbolgraph.extension-unproven-symbol")
        #expect(diagnostic?.description == expected)
    }

    @Test("Strict provenance requires one extension target per block")
    func strictProvenanceRequiresTarget() {
        let diagnostic = FixtureSupport.diagnostic {
            try loadExtensionGraph(
                symbols: "[\(Self.extensionBlockSymbol)]",
                relationships: "[]",
                provenance: .strict
            )
        }

        let expected = "error[symbolgraph.extension-target-count]: "
            + "Fixture@External.symbols.json extension block '\(Self.extensionBlockID)' "
            + "has 0 extensionTo relationships; expected 1"
        #expect(diagnostic?.code == "symbolgraph.extension-target-count")
        #expect(diagnostic?.description == expected)
    }

    @Test("Strict provenance rejects an empty extension target fallback")
    func strictProvenanceRejectsEmptyFallback() {
        let diagnostic = FixtureSupport.diagnostic {
            try loadExtensionGraph(
                symbols: "[\(Self.extensionBlockSymbol)]",
                relationships: """
                [{
                  "kind": "extensionTo",
                  "source": "\(Self.extensionBlockID)",
                  "target": "s:External.Thing",
                  "targetFallback": "  "
                }]
                """,
                provenance: .strict
            )
        }

        let expected = "error[symbolgraph.extension-empty-fallback]: "
            + "Fixture@External.symbols.json extension block '\(Self.extensionBlockID)' "
            + "has no target fallback"
        #expect(diagnostic?.code == "symbolgraph.extension-empty-fallback")
        #expect(diagnostic?.description == expected)
    }

    @Test("Strict provenance requires the target fallback to match the filename module")
    func strictProvenanceRejectsWrongModule() {
        let diagnostic = FixtureSupport.diagnostic {
            try loadExtensionGraph(
                symbols: "[\(Self.extensionBlockSymbol)]",
                relationships: """
                [{
                  "kind": "extensionTo",
                  "source": "\(Self.extensionBlockID)",
                  "target": "s:External.Thing",
                  "targetFallback": "Other.Thing"
                }]
                """,
                provenance: .strict
            )
        }

        let expected = "error[symbolgraph.extension-module-mismatch]: "
            + "Fixture@External.symbols.json extension block '\(Self.extensionBlockID)' "
            + "targets 'Other.Thing'; expected module 'External'"
        #expect(diagnostic?.code == "symbolgraph.extension-module-mismatch")
        #expect(diagnostic?.description == expected)
    }

    private func loadExtensionGraph(
        symbols: String,
        relationships: String,
        provenance: ExtensionProvenanceMode
    ) throws -> LoadedSymbolGraph {
        let directory = try FixtureSupport.temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let mainGraph = """
        {
          "module": { "name": "Fixture" },
          "symbols": [\(Self.widgetSymbol)],
          "relationships": []
        }
        """
        let extensionGraph = """
        {
          "module": { "name": "Fixture" },
          "symbols": \(symbols),
          "relationships": \(relationships)
        }
        """
        try Data(mainGraph.utf8).write(to: directory.appendingPathComponent("Fixture.symbols.json"))
        try Data(extensionGraph.utf8).write(
            to: directory.appendingPathComponent("Fixture@External.symbols.json")
        )
        return try SymbolGraphLoader().load(
            from: directory,
            moduleName: "Fixture",
            extensionProvenance: provenance
        )
    }

    private var strictExtensionSymbols: String {
        """
        [
          \(Self.extensionBlockSymbol),
          \(Self.extensionMemberSymbol),
          {
            "kind": { "identifier": "swift.property" },
            "identifier": { "precise": "s:External.Thing.Fixture.Addition.value" },
            "pathComponents": ["Thing", "Addition", "value"],
            "declarationFragments": [{ "kind": "text", "spelling": "var value: Int" }],
            "accessLevel": "public"
          }
        ]
        """
    }

    private var strictExtensionRelationships: String {
        """
        [
          {
            "kind": "extensionTo",
            "source": "\(Self.extensionBlockID)",
            "target": "s:External.Thing",
            "targetFallback": "External.Thing"
          },
          {
            "kind": "memberOf",
            "source": "s:External.Thing.Fixture.Addition",
            "target": "\(Self.extensionBlockID)",
            "targetFallback": "External.Thing"
          },
          {
            "kind": "memberOf",
            "source": "s:External.Thing.Fixture.Addition.value",
            "target": "s:External.Thing.Fixture.Addition"
          },
          {
            "kind": "conformsTo",
            "source": "\(Self.extensionBlockID)",
            "target": "s:Fixture.Widget"
          }
        ]
        """
    }

    private static let extensionBlockID = "s:e:s:External.Thing.Fixture"

    private static let widgetSymbol = """
    {
      "kind": { "identifier": "swift.struct" },
      "identifier": { "precise": "s:Fixture.Widget" },
      "pathComponents": ["Widget"],
      "declarationFragments": [{ "kind": "text", "spelling": "struct Widget" }],
      "accessLevel": "public"
    }
    """

    private static let extensionBlockSymbol = """
    {
      "kind": { "identifier": "swift.extension" },
      "identifier": { "precise": "\(extensionBlockID)" },
      "pathComponents": ["Thing"],
      "declarationFragments": [{ "kind": "text", "spelling": "extension Thing" }],
      "accessLevel": "public"
    }
    """

    private static let extensionMemberSymbol = """
    {
      "kind": { "identifier": "swift.struct" },
      "identifier": { "precise": "s:External.Thing.Fixture.Addition" },
      "pathComponents": ["Thing", "Addition"],
      "declarationFragments": [{ "kind": "text", "spelling": "struct Addition" }],
      "accessLevel": "public"
    }
    """
}

import Foundation
import Testing

@testable import APICompatibilityKit

@Suite("Symbol graph loader")
struct SymbolGraphLoaderTests {
    @Test("Loads a module graph and all of its extension graphs")
    func loadsMainAndExtensionGraphs() throws {
        let directory = try FixtureSupport.url("SymbolGraphs/Valid")

        let graph = try SymbolGraphLoader().load(from: directory, moduleName: "Fixture")

        #expect(graph.moduleName == "Fixture")
        #expect(graph.sourceFiles == ["Fixture.symbols.json", "Fixture@Swift.symbols.json"])
        #expect(graph.symbols.map(\.preciseIdentifier) == [
            "s:Fixture.Widget",
            "s:Fixture.Widget.render.count",
            "s:Fixture.Widget.render.text",
            "s:Fixture.Widget.badge",
            "s:Fixture.Widget.label",
        ])
        #expect(graph.relationships.count == 4)
        #expect(graph.excludedSynthesizedSymbolIDs.isEmpty)
    }

    @Test("Rejects malformed JSON with a stable diagnostic")
    func rejectsMalformedJSON() throws {
        let directory = try FixtureSupport.temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        try Data("{not-json".utf8).write(to: directory.appendingPathComponent("Fixture.symbols.json"))

        let diagnostic = FixtureSupport.diagnostic {
            try SymbolGraphLoader().load(from: directory, moduleName: "Fixture")
        }

        #expect(diagnostic?.code == "symbolgraph.invalid-json")
        #expect(diagnostic?.description == "error[symbolgraph.invalid-json]: Fixture.symbols.json is not a valid symbol graph")
    }

    @Test("Requires exactly one main module graph")
    func requiresMainGraph() throws {
        let directory = try FixtureSupport.temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }

        let diagnostic = FixtureSupport.diagnostic {
            try SymbolGraphLoader().load(from: directory, moduleName: "Fixture")
        }

        #expect(diagnostic?.code == "symbolgraph.missing-main")
        #expect(diagnostic?.description == "error[symbolgraph.missing-main]: Missing Fixture.symbols.json")
    }

    @Test("Rejects a graph whose declared module differs from the requested module")
    func rejectsWrongModule() throws {
        let directory = try FixtureSupport.url("SymbolGraphs/WrongModule")

        let diagnostic = FixtureSupport.diagnostic {
            try SymbolGraphLoader().load(from: directory, moduleName: "Fixture")
        }

        #expect(diagnostic?.code == "symbolgraph.module-mismatch")
        #expect(
            diagnostic?.description
                == "error[symbolgraph.module-mismatch]: Fixture.symbols.json declares module 'Unexpected'; expected 'Fixture'"
        )
    }

    @Test("Rejects duplicate precise identifiers across graph files")
    func rejectsDuplicatePreciseIdentifiers() throws {
        let directory = try FixtureSupport.url("SymbolGraphs/Duplicate")

        let diagnostic = FixtureSupport.diagnostic {
            try SymbolGraphLoader().load(from: directory, moduleName: "Fixture")
        }

        #expect(diagnostic?.code == "symbolgraph.duplicate-symbol")
        #expect(
            diagnostic?.description
                == "error[symbolgraph.duplicate-symbol]: Duplicate precise identifier 's:Fixture.Duplicate' in Fixture@Swift.symbols.json"
        )
    }

    @Test("Accepts external relationship sources emitted for reexported conformances")
    func acceptsExternalRelationshipSource() throws {
        let directory = try FixtureSupport.url("SymbolGraphs/ExternalSource")

        let graph = try SymbolGraphLoader().load(from: directory, moduleName: "Fixture")

        #expect(graph.relationships.map(\.source) == ["s:Fixture.Missing"])
    }

    @Test("Accepts an external relationship target when a fallback name is present")
    func acceptsExternalTargetWithFallback() throws {
        let loaded = try loadSyntheticGraph(relationships: """
        [{
            "kind": "conformsTo",
            "source": "s:Fixture.Widget",
            "target": "s:External.Protocol",
            "targetFallback": "External.Protocol",
            "sourceOrigin": {
                "displayName": "Fixture.Widget",
                "identifier": "s:Fixture.Widget"
            },
            "swiftConstraints": [{
                "kind": "conformance",
                "lhs": "Content",
                "rhs": "Protocol",
                "rhsPrecise": "s:External.Protocol"
            }]
        }]
        """)

        #expect(loaded.relationships.count == 1)
        #expect(Set(loaded.relationships[0].semanticDetails.keys) == ["sourceOrigin", "swiftConstraints"])
    }

    @Test("Rejects an unknown relationship target without a fallback name")
    func rejectsUnknownTargetWithoutFallback() {
        let diagnostic = FixtureSupport.diagnostic {
            try loadSyntheticGraph(relationships: """
            [{
                "kind": "conformsTo",
                "source": "s:Fixture.Widget",
                "target": "s:External.Protocol"
            }]
            """)
        }

        #expect(diagnostic?.code == "symbolgraph.unknown-relationship-target")
        #expect(
            diagnostic?.description
                == "error[symbolgraph.unknown-relationship-target]: Relationship target 's:External.Protocol' is not exported and has no fallback"
        )
    }

    @Test("Recovers a missing fallback from matching Swift constraints")
    func recoversMissingFallbackFromConstraints() throws {
        let loaded = try loadSyntheticGraph(relationships: """
        [{
            "kind": "conformsTo",
            "source": "s:Fixture.Widget",
            "target": "s:7Fixture8ProtocolP",
            "swiftConstraints": [{
                "kind": "conformance",
                "lhs": "Content",
                "rhs": "Protocol",
                "rhsPrecise": "s:7Fixture8ProtocolP"
            }]
        }]
        """)

        #expect(loaded.relationships.count == 1)
        #expect(loaded.relationships[0].targetFallback == "Fixture.Protocol")
    }

    @Test("Recovers a missing cross-module fallback from the target identifier")
    func recoversMissingCrossModuleFallback() throws {
        let loaded = try loadSyntheticGraph(relationships: """
        [{
            "kind": "conformsTo",
            "source": "s:Fixture.Widget",
            "target": "s:8External8ProtocolP",
            "swiftConstraints": [{
                "kind": "conformance",
                "lhs": "Content",
                "rhs": "Protocol",
                "rhsPrecise": "s:8External8ProtocolP"
            }]
        }]
        """)

        #expect(loaded.relationships[0].targetFallback == "External.Protocol")
    }

    @Test("Does not add an inferred fallback to an exported relationship target")
    func doesNotAddFallbackToExportedTarget() throws {
        let protocolSymbol = """
        {
          "kind": { "identifier": "swift.protocol" },
          "identifier": { "precise": "s:7Fixture8ProtocolP" },
          "pathComponents": ["Protocol"],
          "declarationFragments": [{ "kind": "text", "spelling": "protocol Protocol" }],
          "accessLevel": "public"
        }
        """
        let loaded = try loadMainGraph(
            symbols: "[\(Self.widgetSymbol), \(protocolSymbol)]",
            relationships: """
            [{
                "kind": "conformsTo",
                "source": "s:Fixture.Widget",
                "target": "s:7Fixture8ProtocolP",
                "swiftConstraints": [{
                    "kind": "conformance",
                    "lhs": "Content",
                    "rhs": "Protocol",
                    "rhsPrecise": "s:7Fixture8ProtocolP"
                }]
            }]
            """
        )

        #expect(loaded.relationships[0].targetFallback == nil)
    }

    @Test("Deduplicates identical relationships emitted by the symbol graph extractor")
    func deduplicatesRelationships() throws {
        let loaded = try loadSyntheticGraph(relationships: """
        [
          { "kind": "memberOf", "source": "s:Fixture.Widget", "target": "s:Fixture.Widget" },
          { "kind": "memberOf", "source": "s:Fixture.Widget", "target": "s:Fixture.Widget" }
        ]
        """)

        #expect(loaded.relationships.count == 1)
    }

    @Test("Normalizes relationship fallbacks before deduplication")
    func normalizesFallbackBeforeDeduplication() throws {
        let loaded = try loadSyntheticGraph(relationships: """
        [
          {
            "kind": "conformsTo",
            "source": "s:Fixture.Widget",
            "target": "s:External.Protocol",
            "targetFallback": " External.Protocol "
          },
          {
            "kind": "conformsTo",
            "source": "s:Fixture.Widget",
            "target": "s:External.Protocol",
            "targetFallback": "External.Protocol"
          }
        ]
        """)

        #expect(loaded.relationships.count == 1)
        #expect(loaded.relationships[0].targetFallback == "External.Protocol")
    }

    @Test("Excludes synthesized symbols and their relationships with sorted audit metadata")
    func excludesSynthesizedSurface() throws {
        let firstSynthesizedID = "s:Fixture.First::SYNTHESIZED::s:Fixture.Widget"
        let secondSynthesizedID = "s:Fixture.Second::SYNTHESIZED::s:Fixture.Widget"
        let loaded = try loadMainGraph(
            symbols: """
            [
              \(Self.widgetSymbol),
              {
                "kind": { "identifier": "swift.method" },
                "identifier": { "precise": "\(secondSynthesizedID)" },
                "pathComponents": ["Widget", "second"],
                "declarationFragments": [{ "kind": "text", "spelling": "func second()" }],
                "accessLevel": "public"
              },
              {
                "kind": { "identifier": "swift.method" },
                "identifier": { "precise": "\(firstSynthesizedID)" },
                "pathComponents": ["Widget", "first"],
                "declarationFragments": [{ "kind": "text", "spelling": "func first()" }],
                "accessLevel": "public"
              }
            ]
            """,
            relationships: """
            [
              { "kind": "memberOf", "source": "\(firstSynthesizedID)", "target": "s:Fixture.Widget" },
              { "kind": "memberOf", "source": "s:Fixture.Widget", "target": "\(secondSynthesizedID)" },
              { "kind": "memberOf", "source": "s:Fixture.Widget", "target": "s:Fixture.Widget" }
            ]
            """
        )

        #expect(loaded.symbols.map(\.preciseIdentifier) == ["s:Fixture.Widget"])
        #expect(loaded.relationships.count == 1)
        #expect(loaded.excludedSynthesizedSymbolIDs == [firstSynthesizedID, secondSynthesizedID])
    }

    private func loadSyntheticGraph(relationships: String) throws -> LoadedSymbolGraph {
        try loadMainGraph(
            symbols: "[\(Self.widgetSymbol)]",
            relationships: relationships
        )
    }

    private func loadMainGraph(
        symbols: String,
        relationships: String
    ) throws -> LoadedSymbolGraph {
        let directory = try FixtureSupport.temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let graph = """
        {
          "module": { "name": "Fixture" },
          "symbols": \(symbols),
          "relationships": \(relationships)
        }
        """
        try Data(graph.utf8).write(to: directory.appendingPathComponent("Fixture.symbols.json"))
        return try SymbolGraphLoader().load(from: directory, moduleName: "Fixture")
    }

    private static let widgetSymbol = """
    {
      "kind": { "identifier": "swift.struct" },
      "identifier": { "precise": "s:Fixture.Widget" },
      "pathComponents": ["Widget"],
      "declarationFragments": [{ "kind": "text", "spelling": "struct Widget" }],
      "accessLevel": "public"
    }
    """
}

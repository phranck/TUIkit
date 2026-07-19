import Foundation
import Testing

@testable import APICompatibilityKit

@Suite("Symbol graph canonicalizer")
struct CanonicalizerTests {
    @Test("Removes volatile fields and sorts symbols and relationships deterministically")
    func removesVolatileFieldsAndSorts() throws {
        let graph = try loadFixtureGraph()

        let snapshot = SymbolGraphCanonicalizer().canonicalize(
            graph,
            provenance: fixtureProvenance()
        )
        let data = try SnapshotCodec().encode(snapshot)
        let encoded = try #require(String(data: data, encoding: .utf8))

        #expect(snapshot.symbols.map(\.preciseIdentifier) == [
            "s:Fixture.Widget",
            "s:Fixture.Widget.badge",
            "s:Fixture.Widget.label",
            "s:Fixture.Widget.render.count",
            "s:Fixture.Widget.render.text",
        ])
        #expect(snapshot.relationships.map(\.source) == [
            "s:Fixture.Widget.badge",
            "s:Fixture.Widget.label",
            "s:Fixture.Widget.render.count",
            "s:Fixture.Widget.render.text",
        ])
        #expect(encoded.contains("volatile-generator-value") == false)
        #expect(encoded.contains("file:///volatile/Widget.swift") == false)
        #expect(encoded.contains("Volatile prose") == false)
    }

    @Test("Preserves semantic whitespace inside declaration fragments")
    func preservesSemanticWhitespace() throws {
        let snapshot = SymbolGraphCanonicalizer().canonicalize(
            try loadFixtureGraph(),
            provenance: fixtureProvenance()
        )
        let symbol = try #require(
            snapshot.symbols.first { $0.preciseIdentifier == "s:Fixture.Widget.label" }
        )

        #expect(symbol.canonicalDeclaration == "func label(_ value: String = \"a  b\") -> Text")
    }

    @Test("Normalizes declaration whitespace without merging overloads")
    func normalizesDeclarationsAndPreservesOverloads() throws {
        let snapshot = SymbolGraphCanonicalizer().canonicalize(
            try loadFixtureGraph(),
            provenance: fixtureProvenance()
        )
        let overloads = snapshot.symbols.filter { $0.title == "render(_:)" }

        #expect(overloads.count == 2)
        #expect(Set(overloads.map(\.preciseIdentifier)).count == 2)
        #expect(overloads.map(\.canonicalDeclaration).sorted() == [
            "func render(_ value: Int) -> Text",
            "func render(_ value: String) -> Text",
        ])
    }

    @Test("Produces byte-identical JSON for equivalent input")
    func deterministicEncoding() throws {
        let canonicalizer = SymbolGraphCanonicalizer()
        let codec = SnapshotCodec()
        let graph = try loadFixtureGraph()

        let first = try codec.encode(
            canonicalizer.canonicalize(graph, provenance: fixtureProvenance())
        )
        let second = try codec.encode(
            canonicalizer.canonicalize(graph, provenance: fixtureProvenance())
        )

        #expect(first == second)
    }

    @Test("Binds exact extraction provenance to schema 3 snapshots")
    func bindsExtractionProvenance() throws {
        let provenance = fixtureProvenance()

        let snapshot = SymbolGraphCanonicalizer().canonicalize(
            try loadFixtureGraph(),
            provenance: provenance
        )

        #expect(snapshot.schemaVersion == 3)
        #expect(snapshot.provenance == provenance)
    }

    @Test("Rejects unsupported schemas and invalid provenance")
    func rejectsInvalidProvenance() throws {
        #expect(try encodingDiagnostic { $0.schemaVersion = 2 }?.code == "snapshot.schema-version")
        #expect(try encodingDiagnostic { $0.provenance.platform = " " }?.code == "snapshot.empty-provenance")
        #expect(
            try encodingDiagnostic { $0.provenance.targetTriple = " arm64-apple-macosx15.0" }?.code
                == "snapshot.noncanonical-provenance"
        )
        #expect(try encodingDiagnostic { $0.provenance.sdkName = "" }?.code == "snapshot.empty-provenance")
        #expect(try encodingDiagnostic { $0.provenance.sdkVersion = "\n" }?.code == "snapshot.empty-provenance")
        #expect(try encodingDiagnostic { $0.provenance.sdkBuild = "24A335 " }?.code == "snapshot.noncanonical-provenance")
        #expect(try encodingDiagnostic { $0.provenance.compilerVersion = "\t" }?.code == "snapshot.empty-provenance")
    }

    @Test("Rejects snapshots without provenance")
    func rejectsMissingProvenance() throws {
        let directory = try FixtureSupport.temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let snapshotURL = directory.appendingPathComponent("missing-provenance.json")
        let json = """
        {
          "schemaVersion": 3,
          "moduleName": "Fixture",
          "symbols": [],
          "relationships": []
        }
        """
        try Data(json.utf8).write(to: snapshotURL)

        let diagnostic = FixtureSupport.diagnostic {
            try SnapshotCodec().load(from: snapshotURL)
        }

        #expect(diagnostic?.code == "snapshot.invalid-json")
    }

    @Test("Preserves declaration fragment semantics in canonical JSON")
    func preservesDeclarationFragmentSemantics() throws {
        let first = try snapshotWithDeclarationTarget("s:Fixture.First")
        let second = try snapshotWithDeclarationTarget("s:Fixture.Second")
        let codec = SnapshotCodec()

        let firstData = try codec.encode(first)
        let secondData = try codec.encode(second)
        let firstJSON = try #require(String(data: firstData, encoding: .utf8))
        let secondJSON = try #require(String(data: secondData, encoding: .utf8))
        let fragments = first.symbols[0].declarationFragments

        #expect(first.symbols[0].canonicalDeclaration == second.symbols[0].canonicalDeclaration)
        #expect(fragments.map(\.kind) == ["keyword", "text", "identifier", "typeIdentifier"])
        #expect(fragments.map(\.spelling) == ["func", " ", "make", "() -> Value"])
        #expect(fragments.last?.preciseIdentifier == "s:Fixture.First")
        #expect(firstData != secondData)
        #expect(firstJSON.contains("s:Fixture.First"))
        #expect(secondJSON.contains("s:Fixture.Second"))
    }

    @Test("Rejects empty required symbol fields")
    func rejectsEmptyRequiredSymbolFields() throws {
        #expect(try encodingDiagnostic { $0.symbols[0].preciseIdentifier = " \n " }?.code == "snapshot.empty-symbol-id")
        #expect(try encodingDiagnostic { $0.symbols[0].kindIdentifier = "\t" }?.code == "snapshot.empty-symbol-kind")
        #expect(try encodingDiagnostic { $0.symbols[0].title = " " }?.code == "snapshot.empty-symbol-title")
        #expect(try encodingDiagnostic { $0.symbols[0].pathComponents = [] }?.code == "snapshot.invalid-symbol-path")
        #expect(
            try encodingDiagnostic { $0.symbols[0].pathComponents = ["Widget", " "] }?.code
                == "snapshot.invalid-symbol-path"
        )
        #expect(
            try encodingDiagnostic { $0.symbols[0].canonicalDeclaration = "\n" }?.code
                == "snapshot.empty-symbol-declaration"
        )
        #expect(try encodingDiagnostic { $0.symbols[0].accessLevel = " " }?.code == "snapshot.empty-symbol-access")
    }

    @Test("Rejects invalid declaration fragments")
    func rejectsInvalidDeclarationFragments() throws {
        #expect(
            try encodingDiagnostic { $0.symbols[0].declarationFragments[0].kind = " " }?.code
                == "snapshot.invalid-declaration-fragment"
        )
        #expect(
            try encodingDiagnostic { $0.symbols[0].declarationFragments[0].spelling = "" }?.code
                == "snapshot.invalid-declaration-fragment"
        )
        #expect(
            try encodingDiagnostic { $0.symbols[0].declarationFragments[0].preciseIdentifier = "\t" }?.code
                == "snapshot.invalid-declaration-fragment"
        )
        #expect(
            try encodingDiagnostic { $0.symbols[0].canonicalDeclaration = "struct Different" }?.code
                == "snapshot.declaration-mismatch"
        )
    }

    @Test("Rejects incomplete and duplicate snapshot relationships")
    func rejectsInvalidRelationships() throws {
        #expect(try encodingDiagnostic { $0.relationships[0].kind = " " }?.code == "snapshot.invalid-relationship")
        #expect(try encodingDiagnostic { $0.relationships[0].source = "\n" }?.code == "snapshot.invalid-relationship")
        #expect(try encodingDiagnostic { $0.relationships[0].target = "" }?.code == "snapshot.invalid-relationship")
        #expect(
            try encodingDiagnostic { $0.relationships[0].targetFallback = "\t" }?.code
                == "snapshot.invalid-relationship"
        )
        #expect(
            try encodingDiagnostic { $0.relationships[0].targetFallback = " Fixture.Widget " }?.code
                == "snapshot.noncanonical-relationship-fallback"
        )
        #expect(
            try encodingDiagnostic {
                $0.relationships[0].target = "s:External.Protocol"
                $0.relationships[0].targetFallback = nil
            }?.code == "snapshot.unknown-relationship-target"
        )
        #expect(
            try encodingDiagnostic { $0.relationships.append($0.relationships[0]) }?.code
                == "snapshot.duplicate-relationship"
        )
    }

    private func loadFixtureGraph() throws -> LoadedSymbolGraph {
        try SymbolGraphLoader().load(
            from: FixtureSupport.url("SymbolGraphs/Valid"),
            moduleName: "Fixture"
        )
    }

    private func snapshotWithDeclarationTarget(_ target: String) throws -> APISnapshot {
        let directory = try FixtureSupport.temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let graph = """
        {
          "module": { "name": "Fixture" },
          "symbols": [{
            "kind": { "identifier": "swift.function" },
            "identifier": { "precise": "s:Fixture.make" },
            "pathComponents": ["make()"],
            "names": { "title": "make()" },
            "declarationFragments": [
              { "kind": "keyword", "spelling": "func" },
              { "kind": "text", "spelling": " " },
              { "kind": "identifier", "spelling": "make" },
              { "kind": "typeIdentifier", "spelling": "() -> Value", "preciseIdentifier": "\(target)" }
            ],
            "accessLevel": "public"
          }],
          "relationships": []
        }
        """
        try Data(graph.utf8).write(to: directory.appendingPathComponent("Fixture.symbols.json"))
        let loaded = try SymbolGraphLoader().load(from: directory, moduleName: "Fixture")
        return SymbolGraphCanonicalizer().canonicalize(
            loaded,
            provenance: fixtureProvenance()
        )
    }

    private func encodingDiagnostic(
        mutate: (inout APISnapshot) -> Void
    ) throws -> APICheckDiagnostic? {
        var snapshot = SymbolGraphCanonicalizer().canonicalize(
            try loadFixtureGraph(),
            provenance: fixtureProvenance()
        )
        mutate(&snapshot)
        return FixtureSupport.diagnostic {
            try SnapshotCodec().encode(snapshot)
        }
    }

    private func fixtureProvenance() -> APISnapshotProvenance {
        APISnapshotProvenance(
            platform: "macOS",
            targetTriple: "arm64-apple-macosx15.0",
            sdkName: "macosx",
            sdkVersion: "15.0",
            sdkBuild: "24A335",
            compilerVersion: "Swift 6.0.3"
        )
    }
}

import Testing

@testable import APICompatibilityKit

@Suite("API snapshot comparator")
struct SnapshotComparatorTests {
    @Test("Matches overload changes by precise identifier and canonical declaration")
    func comparesOverloadsByPreciseIdentifier() throws {
        let reference = try fixtureSnapshot()
        var current = reference
        let index = try #require(
            current.symbols.firstIndex { $0.preciseIdentifier == "s:Fixture.Widget.render.count" }
        )
        current.symbols[index].canonicalDeclaration = "func render(_ value: Double) -> Text"

        let comparison = try SnapshotComparator().compare(reference: reference, current: current)

        #expect(comparison.changedSymbols.map(\.preciseIdentifier) == ["s:Fixture.Widget.render.count"])
        #expect(comparison.addedSymbols.isEmpty)
        #expect(comparison.removedSymbols.isEmpty)
    }

    @Test("Reports added and removed symbols and relationships deterministically")
    func reportsAddedAndRemovedSurface() throws {
        let reference = try fixtureSnapshot()
        var current = reference
        let removed = current.symbols.removeLast()
        current.symbols.append(
            CanonicalSymbol(
                preciseIdentifier: "s:Fixture.Widget.zebra",
                kindIdentifier: "swift.property",
                title: "zebra",
                pathComponents: ["Widget", "zebra"],
                canonicalDeclaration: "var zebra: Bool { get }",
                accessLevel: "public"
            )
        )
        current.relationships.removeAll { $0.source == removed.preciseIdentifier }
        current.relationships.append(
            CanonicalRelationship(
                kind: "memberOf",
                source: "s:Fixture.Widget.zebra",
                target: "s:Fixture.Widget",
                targetFallback: nil
            )
        )

        let comparison = try SnapshotComparator().compare(reference: reference, current: current)

        #expect(comparison.addedSymbols.map(\.preciseIdentifier) == ["s:Fixture.Widget.zebra"])
        #expect(comparison.removedSymbols.map(\.preciseIdentifier) == [removed.preciseIdentifier])
        #expect(comparison.addedRelationships.map(\.source) == ["s:Fixture.Widget.zebra"])
        #expect(comparison.removedRelationships.map(\.source) == [removed.preciseIdentifier])
    }

    @Test("Reports relationship semantic changes")
    func reportsRelationshipSemanticChanges() throws {
        let reference = try fixtureSnapshot()
        var current = reference
        current.relationships[0].semanticDetails = [
            "swiftConstraints": .array([
                .object([
                    "kind": .string("conformance"),
                    "lhs": .string("Content"),
                    "rhs": .string("Sendable"),
                ]),
            ]),
        ]

        let comparison = try SnapshotComparator().compare(reference: reference, current: current)

        #expect(comparison.addedRelationships.count == 1)
        #expect(comparison.removedRelationships.count == 1)
    }

    @Test("Rejects snapshots for different modules")
    func rejectsModuleMismatch() throws {
        let reference = try fixtureSnapshot()
        var current = reference
        current.moduleName = "Other"

        let diagnostic = FixtureSupport.diagnostic {
            try SnapshotComparator().compare(reference: reference, current: current)
        }

        #expect(diagnostic?.code == "snapshot.module-mismatch")
        #expect(
            diagnostic?.description
                == "error[snapshot.module-mismatch]: Cannot compare module 'Fixture' with module 'Other'"
        )
    }

    @Test("Rejects duplicate precise identifiers without trapping")
    func rejectsDuplicateIdentifiers() throws {
        var reference = try fixtureSnapshot()
        reference.symbols.append(reference.symbols[0])

        let diagnostic = FixtureSupport.diagnostic {
            try SnapshotComparator().compare(reference: reference, current: reference)
        }

        #expect(diagnostic?.code == "snapshot.duplicate-symbol")
        #expect(
            diagnostic?.description
                == "error[snapshot.duplicate-symbol]: Reference snapshot contains duplicate precise identifier 's:Fixture.Widget'"
        )
    }

    @Test("Rejects duplicate relationships instead of collapsing them")
    func rejectsDuplicateRelationships() throws {
        var reference = try fixtureSnapshot()
        reference.relationships.append(reference.relationships[0])

        let diagnostic = FixtureSupport.diagnostic {
            try SnapshotComparator().compare(reference: reference, current: reference)
        }

        #expect(diagnostic?.code == "snapshot.duplicate-relationship")
        let expectedDescription = "error[snapshot.duplicate-relationship]: Reference snapshot "
            + "contains a duplicate relationship from 's:Fixture.Widget.badge' to 's:Fixture.Widget'"
        #expect(diagnostic?.description == expectedDescription)
    }

    private func fixtureSnapshot() throws -> APISnapshot {
        let graph = try SymbolGraphLoader().load(
            from: FixtureSupport.url("SymbolGraphs/Valid"),
            moduleName: "Fixture"
        )
        return SymbolGraphCanonicalizer().canonicalize(
            graph,
            provenance: APISnapshotProvenance(
                platform: "macOS",
                targetTriple: "arm64-apple-macosx15.0",
                sdkName: "macosx",
                sdkVersion: "15.0",
                sdkBuild: "24A335",
                compilerVersion: "Swift 6.0.3"
            )
        )
    }
}

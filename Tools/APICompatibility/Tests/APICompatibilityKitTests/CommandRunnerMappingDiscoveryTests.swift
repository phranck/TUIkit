import Foundation
import Testing

@testable import APICompatibilityKit

@Suite("Mapping discovery command")
struct CommandRunnerMappingDiscoveryTests {
    @Test("Emits deterministic surface differences")
    func listsMappingCandidates() throws {
        let directory = try FixtureSupport.temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let referenceSetURL = directory.appendingPathComponent("reference-set.json")
        let tuikitSetURL = directory.appendingPathComponent("tuikit-set.json")
        try writeMappingSnapshotSet(
            descriptorURL: referenceSetURL,
            sourceID: "reference-macos",
            moduleName: "SwiftUI",
            symbolID: "s:SwiftUI.Widget"
        )
        try writeMappingSnapshotSet(
            descriptorURL: tuikitSetURL,
            sourceID: "tuikit-macos",
            moduleName: "TUIkit",
            symbolID: "s:TUIkit.Widget"
        )

        let result = CommandRunner().run(arguments: [
            "list-mapping-candidates",
            "--reference-set", referenceSetURL.path,
            "--tuikit-set", tuikitSetURL.path,
        ])

        #expect(result.exitCode == 0)
        #expect(result.standardError.isEmpty)
        #expect(
            result.standardOutput == "referenceID\ttuikitSymbolID\tdifferences\n"
                + "s:SwiftUI.Widget\ts:TUIkit.Widget\texact\n"
        )
    }
}

private func writeMappingSnapshotSet(
    descriptorURL: URL,
    sourceID: String,
    moduleName: String,
    symbolID: String
) throws {
    let snapshotPath = "snapshots/\(sourceID).json"
    let snapshotURL = descriptorURL.deletingLastPathComponent()
        .appendingPathComponent(snapshotPath)
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
            symbols: [mappingCommandSymbol(id: symbolID, moduleName: moduleName)],
            relationships: []
        ),
        to: snapshotURL
    )
    try SnapshotSetDescriptorCodec().write(
        APISnapshotSetDescriptor(
            schemaVersion: 2,
            name: moduleName,
            requiredCoverage: [
                APISnapshotCoverageRequirement(moduleName: moduleName, platform: "macOS"),
            ],
            sources: [source]
        ),
        to: descriptorURL
    )
}

private func mappingCommandSymbol(
    id: String,
    moduleName: String
) -> CanonicalSymbol {
    CanonicalSymbol(
        preciseIdentifier: id,
        kindIdentifier: "swift.func",
        title: "widget(_:)",
        pathComponents: ["Widget", "widget(_:)"],
        canonicalDeclaration: "func widget(_ value: \(moduleName).Value)",
        declarationFragments: [
            CanonicalDeclarationFragment(
                kind: "text",
                spelling: "func widget(_ value: ",
                preciseIdentifier: nil
            ),
            CanonicalDeclarationFragment(
                kind: "typeIdentifier",
                spelling: "\(moduleName).Value",
                preciseIdentifier: nil
            ),
            CanonicalDeclarationFragment(kind: "text", spelling: ")", preciseIdentifier: nil),
        ],
        accessLevel: "public"
    )
}

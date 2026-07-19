import Foundation
import Testing

@testable import APICompatibilityKit

@Suite("Manifest generation command")
struct CommandRunnerManifestGenerationTests {
    @Test("Generates and writes a canonical compatibility manifest")
    func generatesManifest() throws {
        let input = try ManifestCommandInput()
        defer { input.remove() }

        let result = CommandRunner().run(arguments: input.arguments)

        #expect(result.exitCode == 0)
        #expect(result.standardError.isEmpty)
        #expect(
            result.standardOutput
                == "Wrote compatibility manifest with 1 reference and 1 TUIkit symbol to \(input.output.path)\n"
        )
        guard FileManager.default.fileExists(atPath: input.output.path) else {
            Issue.record("Manifest command did not write its output")
            return
        }
        let manifest = try ManifestLoader().load(from: input.output)
        #expect(manifest.schemaVersion == 2)
        #expect(manifest.referenceIDs == ["s:SwiftUI.Widget"])
        #expect(manifest.tuikitDecisions.map(\.symbolID) == ["s:TUIkit.Widget"])
        #expect(try Data(contentsOf: input.output).last == 0x0A)
    }

    @Test("Requires each manifest generation option exactly once")
    func rejectsMissingAndDuplicateOptions() throws {
        let input = try ManifestCommandInput()
        defer { input.remove() }
        let missing = CommandRunner().run(arguments: Array(input.arguments.dropLast(2)))
        let duplicate = CommandRunner().run(arguments: input.arguments + [
            "--policy", input.policy.path,
        ])

        #expect(missing.exitCode == 2)
        #expect(missing.standardOutput.isEmpty)
        #expect(missing.standardError == CommandRunner.usage)
        #expect(duplicate.exitCode == 2)
        #expect(duplicate.standardOutput.isEmpty)
        #expect(duplicate.standardError == CommandRunner.usage)
    }

    @Test("Fails closed when the manifest cannot be written")
    func rejectsUnwritableOutput() throws {
        let input = try ManifestCommandInput()
        defer { input.remove() }
        var arguments = input.arguments
        arguments[arguments.count - 1] = input.directory.path

        let result = CommandRunner().run(arguments: arguments)

        #expect(result.exitCode == 1)
        #expect(result.standardOutput.isEmpty)
        #expect(
            result.standardError
                == "error[manifest.write-failed]: Unable to write \(input.directory.lastPathComponent)\n"
        )
    }
}

private struct ManifestCommandInput {
    let directory: URL
    let ownerRegistry: URL
    let policy: URL
    let referenceSet: URL
    let tuikitSet: URL
    let output: URL

    init() throws {
        directory = try FixtureSupport.temporaryDirectory()
        ownerRegistry = directory.appendingPathComponent("owner-registry.json")
        policy = directory.appendingPathComponent("policy.json")
        referenceSet = directory.appendingPathComponent("reference-set.json")
        tuikitSet = directory.appendingPathComponent("tuikit-set.json")
        output = directory.appendingPathComponent("manifest.json")

        try JSONArtifactCodec.encode(
            CompatibilityReviewPolicy(
                schemaVersion: 1,
                referenceRules: [
                    ReferenceReviewRule(
                        id: "include-widget",
                        referenceIDs: ["s:SwiftUI.Widget"],
                        action: ReferenceReviewAction(
                            kind: .include,
                            ownerIssue: "#17",
                            status: .implemented,
                            contractID: "compile.widget",
                            contractKind: .compile,
                            availability: AvailabilityDecision(policy: .matchesReference)
                        )
                    ),
                ],
                tuikitOverrides: []
            )
        ).write(to: policy)
        try JSONArtifactCodec.encode(
            CompatibilityOwnerRegistry(
                schemaVersion: 1,
                repository: "phranck/TUIkit",
                issues: [
                    CompatibilityOwnerIssue(
                        number: 17,
                        title: "Establish View foundations",
                        url: "https://github.com/phranck/TUIkit/issues/17"
                    ),
                ]
            )
        ).write(to: ownerRegistry)
        try writeManifestCommandSnapshotSet(
            descriptorURL: referenceSet,
            sourceID: "reference-macos",
            moduleName: "SwiftUI",
            symbol: manifestCommandSymbol(id: "s:SwiftUI.Widget", moduleName: "SwiftUI")
        )
        try writeManifestCommandSnapshotSet(
            descriptorURL: tuikitSet,
            sourceID: "tuikit-macos",
            moduleName: "TUIkit",
            symbol: manifestCommandSymbol(id: "s:TUIkit.Widget", moduleName: "TUIkit")
        )
    }

    var arguments: [String] {
        [
            "generate-manifest",
            "--policy", policy.path,
            "--owner-registry", ownerRegistry.path,
            "--reference-set", referenceSet.path,
            "--tuikit-set", tuikitSet.path,
            "--output", output.path,
        ]
    }

    func remove() {
        try? FileManager.default.removeItem(at: directory)
    }
}

private func writeManifestCommandSnapshotSet(
    descriptorURL: URL,
    sourceID: String,
    moduleName: String,
    symbol: CanonicalSymbol
) throws {
    let snapshotPath = "snapshots/\(sourceID).json"
    let source = APISnapshotSetSourceDescriptor(
        id: sourceID,
        moduleName: moduleName,
        platform: "macOS",
        targetTriple: "arm64-apple-macosx26.0",
        sdkName: "macosx",
        sdkVersion: "26.6",
        sdkBuild: "17F113",
        compilerVersion: "Swift 6.0.3",
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
            symbols: [symbol],
            relationships: []
        ),
        to: descriptorURL.deletingLastPathComponent().appendingPathComponent(snapshotPath)
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

private func manifestCommandSymbol(id: String, moduleName: String) -> CanonicalSymbol {
    let declaration = "func widget(_ value: \(moduleName).Value)"
    return CanonicalSymbol(
        preciseIdentifier: id,
        kindIdentifier: "swift.func",
        title: "widget(_:)",
        pathComponents: ["Widget", "widget(_:)"],
        canonicalDeclaration: declaration,
        declarationFragments: [
            CanonicalDeclarationFragment(kind: "keyword", spelling: "func", preciseIdentifier: nil),
            CanonicalDeclarationFragment(kind: "text", spelling: " ", preciseIdentifier: nil),
            CanonicalDeclarationFragment(kind: "identifier", spelling: "widget", preciseIdentifier: id),
            CanonicalDeclarationFragment(kind: "text", spelling: "(_ value: ", preciseIdentifier: nil),
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

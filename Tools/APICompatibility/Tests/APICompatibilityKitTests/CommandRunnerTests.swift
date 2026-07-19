import Foundation
import Testing

@testable import APICompatibilityKit

@Suite("TUIkit API check commands")
struct CommandRunnerTests {
    @Test("Canonicalize writes a deterministic local snapshot")
    func canonicalizeCommand() throws {
        let outputDirectory = try FixtureSupport.temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: outputDirectory) }
        let output = outputDirectory.appendingPathComponent("fixture-api.json")
        let graphs = try FixtureSupport.url("SymbolGraphs/Valid")

        let result = CommandRunner().run(arguments: [
            "canonicalize",
            "--module", "Fixture",
            "--symbol-graphs", graphs.path,
            "--output", output.path,
            "--extension-provenance", "disabled",
            "--platform", "macOS",
            "--target", "arm64-apple-macosx15.0",
            "--sdk-name", "macosx",
            "--sdk-version", "15.0",
            "--sdk-build", "24A335",
            "--compiler-version", "Swift 6.0.3",
        ])
        let snapshot = try SnapshotCodec().load(from: output)

        #expect(result.exitCode == 0)
        #expect(result.standardError.isEmpty)
        #expect(result.standardOutput == "Wrote 5 symbols for Fixture to \(output.path)\n")
        #expect(snapshot.symbols.count == 5)
        #expect(snapshot.provenance == commandProvenance())
    }

    @Test("Canonicalize requires an explicit extension provenance mode")
    func canonicalizeRequiresExtensionProvenance() throws {
        let graphs = try FixtureSupport.url("SymbolGraphs/Valid")

        let result = CommandRunner().run(arguments: [
            "canonicalize",
            "--module", "Fixture",
            "--symbol-graphs", graphs.path,
            "--output", "/tmp/fixture-api.json",
            "--platform", "macOS",
            "--target", "arm64-apple-macosx15.0",
            "--sdk-name", "macosx",
            "--sdk-version", "15.0",
            "--sdk-build", "24A335",
            "--compiler-version", "Swift 6.0.3",
        ])

        #expect(result.exitCode == 2)
        #expect(result.standardError == CommandRunner.usage)
    }

    @Test("Extract invokes the symbol graph extractor with managed inventory arguments")
    func extractCommand() throws {
        let setup = try ExtractionCommandSetup()
        defer { setup.remove() }
        try setup.prepare()

        let result = CommandRunner().run(arguments: setup.arguments)
        let extractorArguments = try String(contentsOf: setup.argumentLog, encoding: .utf8)
            .split(whereSeparator: \.isNewline)
            .map(String.init)

        #expect(result.exitCode == 0)
        #expect(
            result.standardOutput
                == "Extracted symbol graphs for Fixture to \(setup.resolvedOutputDirectory.path)\n"
        )
        #expect(result.standardError.isEmpty)
        #expect(extractorArguments == [
            "-module-name", "Fixture",
            "-target", "arm64-apple-macosx26.0",
            "-sdk", setup.resolvedSDK.path,
            "-output-dir", setup.resolvedOutputDirectory.path,
            "-minimum-access-level", "public",
            "-skip-inherited-docs",
            "-skip-synthesized-members",
            "-emit-extension-block-symbols",
            "-I", setup.resolvedSwiftModules.path,
            "-I", setup.resolvedClangModules.path,
        ])
    }

    @Test("Extract reports an extractor-specific executable diagnostic")
    func extractRejectsMissingExecutable() throws {
        let setup = try ExtractionCommandSetup()
        defer { setup.remove() }
        try setup.prepareDirectories()

        let result = CommandRunner().run(arguments: setup.arguments)

        #expect(result.exitCode == 1)
        #expect(result.standardOutput.isEmpty)
        #expect(
            result.standardError
                == "error[symbolgraph.extractor-executable]: Symbol graph extractor is not executable: \(setup.extractor.path)\n"
        )
    }

    @Test("Executable preflight preserves symlink invocation identity")
    func executablePreflightPreservesSymlink() throws {
        let directory = try FixtureSupport.temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let executable = directory.appendingPathComponent("swift-frontend")
        let symlink = directory.appendingPathComponent("swift-symbolgraph-extract")
        try Data("#!/bin/sh\nexit 0\n".utf8).write(to: executable)
        try FileManager.default.setAttributes(
            [.posixPermissions: 0o755],
            ofItemAtPath: executable.path
        )
        try FileManager.default.createSymbolicLink(at: symlink, withDestinationURL: executable)

        let checked = try CommandRunner().executableURL(
            symlink.path,
            code: "fixture.executable",
            noun: "Fixture executable"
        )

        #expect(checked.path == symlink.standardizedFileURL.path)
    }

    @Test("Compare exits successfully for identical local snapshots")
    func compareIdenticalSnapshots() throws {
        let directory = try FixtureSupport.temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let snapshotURL = directory.appendingPathComponent("snapshot.json")
        try SnapshotCodec().write(try fixtureSnapshot(), to: snapshotURL)

        let result = CommandRunner().run(arguments: [
            "compare",
            "--reference", snapshotURL.path,
            "--current", snapshotURL.path,
        ])

        #expect(result.exitCode == 0)
        #expect(result.standardOutput == "No API changes for Fixture.\n")
        #expect(result.standardError.isEmpty)
    }

    @Test("Compare emits a deterministic report and exits one for API changes")
    func compareChangedSnapshots() throws {
        let directory = try FixtureSupport.temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let referenceURL = directory.appendingPathComponent("reference.json")
        let currentURL = directory.appendingPathComponent("current.json")
        let reference = try fixtureSnapshot()
        var current = reference
        current.symbols.removeLast()
        try SnapshotCodec().write(reference, to: referenceURL)
        try SnapshotCodec().write(current, to: currentURL)

        let result = CommandRunner().run(arguments: [
            "compare",
            "--reference", referenceURL.path,
            "--current", currentURL.path,
        ])

        #expect(result.exitCode == 1)
        #expect(result.standardOutput.contains("\"removedSymbols\""))
        #expect(result.standardOutput.contains("s:Fixture.Widget.render.text"))
        #expect(result.standardError == "API changes detected for Fixture.\n")
    }

    @Test("Write-snapshot-set creates a canonical descriptor from source records")
    func writeSnapshotSetCommand() throws {
        let directory = try FixtureSupport.temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let sources = directory.appendingPathComponent("sources.tsv")
        let coverage = directory.appendingPathComponent("coverage.tsv")
        let output = directory.appendingPathComponent("snapshot-set.json")
        let records = [
            snapshotSourceLine(id: "source-z", platform: "macOS", snapshot: "snapshots/z.json"),
            snapshotSourceLine(id: "source-a", platform: "Linux", snapshot: "snapshots/a.json"),
        ].joined(separator: "\n") + "\n"
        try Data(records.utf8).write(to: sources)
        try Data("TUIkit\tLinux\nTUIkit\tmacOS\n".utf8).write(to: coverage)

        let result = CommandRunner().run(arguments: [
            "write-snapshot-set",
            "--name", "TUIkit Swift 6.0.3",
            "--sources", sources.path,
            "--coverage", coverage.path,
            "--output", output.path,
        ])
        let descriptor = try SnapshotSetDescriptorCodec().load(from: output)

        #expect(result.exitCode == 0)
        #expect(result.standardOutput == "Wrote snapshot set with 2 sources to \(output.path)\n")
        #expect(result.standardError.isEmpty)
        #expect(descriptor.name == "TUIkit Swift 6.0.3")
        #expect(descriptor.requiredCoverage == [
            APISnapshotCoverageRequirement(moduleName: "TUIkit", platform: "Linux"),
            APISnapshotCoverageRequirement(moduleName: "TUIkit", platform: "macOS"),
        ])
        #expect(descriptor.sources.map(\.id) == ["source-a", "source-z"])
    }

    @Test("Validate-manifest-schema reports stable validation diagnostics")
    func validateManifestSchemaCommand() throws {
        let manifest = try FixtureSupport.url("Manifests/unreviewed.json")

        let result = CommandRunner().run(arguments: [
            "validate-manifest-schema",
            "--manifest", manifest.path,
        ])

        #expect(result.exitCode == 1)
        #expect(result.standardOutput.isEmpty)
        #expect(result.standardError == "error[manifest.unreviewed]: Reference 's:SwiftUI.Pending' remains unreviewed\n")
    }

    @Test("Validate-manifest requires both snapshot sets and the contract registry")
    func validateManifestRequiresInventories() throws {
        let manifest = try FixtureSupport.url("Manifests/valid.json")

        let result = CommandRunner().run(arguments: [
            "validate-manifest",
            "--manifest", manifest.path,
        ])

        #expect(result.exitCode == 2)
        #expect(result.standardOutput.isEmpty)
        #expect(result.standardError == CommandRunner.usage)
    }

    @Test("Validate-manifest accepts complete snapshot sets and contract links")
    func validateManifestWithSnapshotSetsAndContracts() throws {
        let directory = try FixtureSupport.temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let manifestURL = try FixtureSupport.url("Manifests/valid.json")
        let manifest = try ManifestLoader().load(from: manifestURL)
        let referenceSetURL = directory.appendingPathComponent("reference-set.json")
        let tuikitSetURL = directory.appendingPathComponent("tuikit-set.json")
        let contractsURL = directory.appendingPathComponent("contracts.json")
        try writeCompatibilitySnapshotSets(
            manifest: manifest,
            referenceDescriptorURL: referenceSetURL,
            tuikitDescriptorURL: tuikitSetURL
        )
        try writeContractRegistry(for: manifest, to: contractsURL)

        let result = CommandRunner().run(arguments: [
            "validate-manifest",
            "--manifest", manifestURL.path,
            "--reference-set", referenceSetURL.path,
            "--tuikit-set", tuikitSetURL.path,
            "--contracts", contractsURL.path,
        ])

        #expect(result.exitCode == 0)
        #expect(result.standardOutput == "Compatibility manifest is valid.\n")
        #expect(result.standardError.isEmpty)
    }

    @Test("Validate-contracts accepts clean event-stream passes and ignores extra tests")
    func validateContractsCommand() throws {
        let directory = try FixtureSupport.temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let registry = directory.appendingPathComponent("contracts.json")
        let eventStream = directory.appendingPathComponent("events.jsonl")
        try ContractRegistryCodec().write(
            CompatibilityContractRegistry(
                schemaVersion: 1,
                contracts: [behaviorContract(id: "behavior.focus", testIdentifier: "Tests.Focus/focus")]
            ),
            to: registry
        )
        try Data(commandEventStream(passing: [
            "Tests.Focus/focus",
            "Tests.Unrelated/extra",
        ]).utf8).write(to: eventStream)

        let result = CommandRunner().run(arguments: [
            "validate-contracts",
            "--registry", registry.path,
            "--event-stream", eventStream.path,
        ])

        #expect(result.exitCode == 0)
        #expect(result.standardOutput == "Contract registry and behavior tests are valid.\n")
        #expect(result.standardError.isEmpty)
    }

    @Test("Validate-contracts reports an undiscovered behavior test")
    func validateContractsRejectsMissingTest() throws {
        let directory = try FixtureSupport.temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let registry = directory.appendingPathComponent("contracts.json")
        let eventStream = directory.appendingPathComponent("events.jsonl")
        try ContractRegistryCodec().write(
            CompatibilityContractRegistry(
                schemaVersion: 1,
                contracts: [behaviorContract(id: "behavior.focus", testIdentifier: "Tests.Focus/focus")]
            ),
            to: registry
        )
        try Data(commandEventStream(passing: ["Tests.Unrelated/extra"]).utf8)
            .write(to: eventStream)

        let result = CommandRunner().run(arguments: [
            "validate-contracts",
            "--registry", registry.path,
            "--event-stream", eventStream.path,
        ])

        #expect(result.exitCode == 1)
        #expect(result.standardOutput.isEmpty)
        #expect(
            result.standardError
                == "error[contract-registry.missing-behavior-test]: Behavior contract 'behavior.focus' references undiscovered test 'Tests.Focus/focus'\n"
        )
    }

    @Test("Validate-contracts fails closed when the event stream cannot be read")
    func validateContractsRejectsMissingEventStream() throws {
        let directory = try FixtureSupport.temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let registry = directory.appendingPathComponent("contracts.json")
        let eventStream = directory.appendingPathComponent("missing-events.jsonl")
        try ContractRegistryCodec().write(
            CompatibilityContractRegistry(schemaVersion: 1, contracts: []),
            to: registry
        )

        let result = CommandRunner().run(arguments: [
            "validate-contracts",
            "--registry", registry.path,
            "--event-stream", eventStream.path,
        ])

        #expect(result.exitCode == 1)
        #expect(result.standardOutput.isEmpty)
        #expect(
            result.standardError
                == "error[contract-test-results.read-failed]: Unable to read Swift test event stream missing-events.jsonl\n"
        )
    }

    @Test("Run-compile-contracts invokes swiftc directly with deterministic module paths")
    func runCompileContractsCommand() throws {
        let setup = try CompileCommandSetup()
        defer { setup.remove() }
        try setup.prepareAllPaths()
        try setup.writeRegistry()
        try setup.writeFakeCompiler()

        let result = CommandRunner().run(arguments: setup.arguments)
        let compilerArguments = try String(contentsOf: setup.argumentLog, encoding: .utf8)
            .split(whereSeparator: \.isNewline)
            .map(String.init)

        #expect(result.exitCode == 0)
        #expect(result.standardOutput == "Executed 1 compile contract successfully.\n")
        #expect(result.standardError.isEmpty)
        #expect(compilerArguments == [
            "-swift-version", "6",
            "-warnings-as-errors",
            "-typecheck",
            "-I", setup.resolvedSwiftModules.path,
            "-I", setup.resolvedClangModules.path,
            setup.resolvedFixture.path,
        ])
    }

    @Test("Run-compile-contracts validates every path before invoking swiftc", arguments: CompilePathFailure.allCases)
    func runCompileContractsRejectsInvalidPath(failure: CompilePathFailure) throws {
        let setup = try CompileCommandSetup()
        defer { setup.remove() }
        try setup.preparePaths(excluding: failure)
        try setup.writeRegistry()
        if failure != .compiler {
            try setup.writeFakeCompiler()
        }

        let result = CommandRunner().run(arguments: setup.arguments)

        #expect(result.exitCode == 1)
        #expect(result.standardOutput.isEmpty)
        #expect(result.standardError == "error[\(failure.code)]: \(failure.message(setup: setup))\n")
        #expect(!FileManager.default.fileExists(atPath: setup.argumentLog.path))
    }

    @Test("Contract commands require their complete option sets")
    func contractCommandsRequireOptions() {
        let validate = CommandRunner().run(arguments: ["validate-contracts", "--registry", "contracts.json"])
        let run = CommandRunner().run(arguments: ["run-compile-contracts", "--registry", "contracts.json"])

        #expect(validate.exitCode == 2)
        #expect(validate.standardError == CommandRunner.usage)
        #expect(run.exitCode == 2)
        #expect(run.standardError == CommandRunner.usage)
    }

    @Test("Unknown commands fail with stable usage output")
    func rejectsUnknownCommand() {
        let result = CommandRunner().run(arguments: ["unknown"])

        #expect(result.exitCode == 2)
        #expect(result.standardOutput.isEmpty)
        #expect(result.standardError == CommandRunner.usage)
    }

    private func fixtureSnapshot() throws -> APISnapshot {
        let graph = try SymbolGraphLoader().load(
            from: FixtureSupport.url("SymbolGraphs/Valid"),
            moduleName: "Fixture"
        )
        return SymbolGraphCanonicalizer().canonicalize(
            graph,
            provenance: commandProvenance()
        )
    }

    private func behaviorContract(id: String, testIdentifier: String) -> ContractDefinition {
        ContractDefinition(id: id, kind: .behavior, testIdentifier: testIdentifier)
    }

    private func commandProvenance() -> APISnapshotProvenance {
        APISnapshotProvenance(
            platform: "macOS",
            targetTriple: "arm64-apple-macosx15.0",
            sdkName: "macosx",
            sdkVersion: "15.0",
            sdkBuild: "24A335",
            compilerVersion: "Swift 6.0.3"
        )
    }

    private func commandEventStream(passing identifiers: [String]) -> String {
        var records: [String] = []
        for (index, identifier) in identifiers.enumerated() {
            let fullID = "\(identifier)/FixtureTests.swift:\(index + 1):1"
            records.append(
                "{\"kind\":\"test\",\"payload\":{\"id\":\"\(fullID)\",\"kind\":\"function\"},\"version\":0}"
            )
            records.append(
                "{\"kind\":\"event\",\"payload\":{\"kind\":\"testStarted\",\"testID\":\"\(fullID)\"},\"version\":0}"
            )
            records.append(
                "{\"kind\":\"event\",\"payload\":{\"kind\":\"testEnded\",\"messages\":[{\"symbol\":\"pass\"}],\"testID\":\"\(fullID)\"},\"version\":0}"
            )
        }
        return records.joined(separator: "\n") + "\n"
    }
}

import Foundation

@testable import APICompatibilityKit

enum CompilePathFailure: CaseIterable, Sendable {
    case clangModules
    case compiler
    case fixtures
    case swiftModules

    var code: String {
        switch self {
        case .clangModules: "compile-contract.clang-module-path"
        case .compiler: "compile-contract.compiler"
        case .fixtures: "compile-contract.fixtures-directory"
        case .swiftModules: "compile-contract.swift-module-path"
        }
    }

    func message(setup: CompileCommandSetup) -> String {
        switch self {
        case .clangModules: "Clang module path does not exist: \(setup.clangModules.path)"
        case .compiler: "Swift compiler is not executable: \(setup.compiler.path)"
        case .fixtures: "Compile fixture directory does not exist: \(setup.fixtures.path)"
        case .swiftModules: "Swift module path does not exist: \(setup.swiftModules.path)"
        }
    }
}

struct CompileCommandSetup {
    let directory: URL
    let registry: URL
    let fixtures: URL
    let fixture: URL
    let compiler: URL
    let argumentLog: URL
    let swiftModules: URL
    let clangModules: URL

    init() throws {
        directory = try FixtureSupport.temporaryDirectory()
        registry = directory.appendingPathComponent("contracts.json")
        fixtures = directory.appendingPathComponent("Compile Fixtures", isDirectory: true)
        fixture = fixtures.appendingPathComponent("Positive.swift")
        compiler = directory.appendingPathComponent("fake-swiftc")
        argumentLog = directory.appendingPathComponent("compiler-arguments.txt")
        swiftModules = directory.appendingPathComponent("Swift Modules", isDirectory: true)
        clangModules = directory.appendingPathComponent("Clang Modules", isDirectory: true)
    }

    var arguments: [String] {
        [
            "run-compile-contracts",
            "--registry", registry.path,
            "--fixtures", fixtures.path,
            "--swiftc", compiler.path,
            "--swift-module-path", swiftModules.path,
            "--clang-module-path", clangModules.path,
        ]
    }

    var resolvedSwiftModules: URL {
        swiftModules.standardizedFileURL.resolvingSymlinksInPath()
    }

    var resolvedClangModules: URL {
        clangModules.standardizedFileURL.resolvingSymlinksInPath()
    }

    var resolvedFixture: URL {
        fixture.standardizedFileURL.resolvingSymlinksInPath()
    }

    func prepareAllPaths() throws {
        try preparePaths(excluding: nil)
    }

    func preparePaths(excluding failure: CompilePathFailure?) throws {
        if failure != .fixtures {
            try FileManager.default.createDirectory(at: fixtures, withIntermediateDirectories: true)
            try Data("let fixtureValue = 1\n".utf8).write(to: fixture)
        }
        if failure != .swiftModules {
            try FileManager.default.createDirectory(at: swiftModules, withIntermediateDirectories: true)
        }
        if failure != .clangModules {
            try FileManager.default.createDirectory(at: clangModules, withIntermediateDirectories: true)
        }
    }

    func writeRegistry() throws {
        let definition = ContractDefinition(
            id: "compile.fixture",
            kind: .compile,
            compile: CompileContract(
                fixture: "Positive.swift",
                expectation: CompileContractExpectation(outcome: .succeeds)
            )
        )
        try ContractRegistryCodec().write(
            CompatibilityContractRegistry(schemaVersion: 1, contracts: [definition]),
            to: registry
        )
    }

    func writeFakeCompiler() throws {
        let script = """
        #!/bin/sh
        for argument in "$@"; do
          printf '%s\\n' "$argument"
        done > "\(argumentLog.path)"
        """
        try Data(script.utf8).write(to: compiler)
        try FileManager.default.setAttributes(
            [.posixPermissions: 0o755],
            ofItemAtPath: compiler.path
        )
    }

    func remove() {
        try? FileManager.default.removeItem(at: directory)
    }
}

struct ExtractionCommandSetup {
    let directory: URL
    let outputDirectory: URL
    let sdk: URL
    let swiftModules: URL
    let clangModules: URL
    let extractor: URL
    let argumentLog: URL

    init() throws {
        directory = try FixtureSupport.temporaryDirectory()
        outputDirectory = directory.appendingPathComponent("Symbol Graphs", isDirectory: true)
        sdk = directory.appendingPathComponent("Fixture.sdk", isDirectory: true)
        swiftModules = directory.appendingPathComponent("Swift Modules", isDirectory: true)
        clangModules = directory.appendingPathComponent("Clang Modules", isDirectory: true)
        extractor = directory.appendingPathComponent("fake-symbolgraph-extract")
        argumentLog = directory.appendingPathComponent("extractor-arguments.txt")
    }

    var arguments: [String] {
        [
            "extract",
            "--extractor", extractor.path,
            "--module", "Fixture",
            "--target", "arm64-apple-macosx26.0",
            "--sdk", sdk.path,
            "--output", outputDirectory.path,
            "--swift-module-path", swiftModules.path,
            "--clang-module-path", clangModules.path,
        ]
    }

    var resolvedOutputDirectory: URL {
        outputDirectory.standardizedFileURL.resolvingSymlinksInPath()
    }

    var resolvedSDK: URL {
        sdk.standardizedFileURL.resolvingSymlinksInPath()
    }

    var resolvedSwiftModules: URL {
        swiftModules.standardizedFileURL.resolvingSymlinksInPath()
    }

    var resolvedClangModules: URL {
        clangModules.standardizedFileURL.resolvingSymlinksInPath()
    }

    func prepare() throws {
        try prepareDirectories()
        let script = """
        #!/bin/sh
        for argument in "$@"; do
          printf '%s\\n' "$argument"
        done > "\(argumentLog.path)"
        module_name=
        output_directory=
        while [ "$#" -gt 0 ]; do
          case "$1" in
            -module-name)
              module_name="$2"
              shift 2
              ;;
            -output-dir)
              output_directory="$2"
              shift 2
              ;;
            -target|-sdk|-minimum-access-level|-I)
              shift 2
              ;;
            *)
              shift
              ;;
          esac
        done
        : > "$output_directory/$module_name.symbols.json"
        """
        try Data(script.utf8).write(to: extractor)
        try FileManager.default.setAttributes(
            [.posixPermissions: 0o755],
            ofItemAtPath: extractor.path
        )
    }

    func prepareDirectories() throws {
        for url in [outputDirectory, sdk, swiftModules, clangModules] {
            try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        }
    }

    func remove() {
        try? FileManager.default.removeItem(at: directory)
    }
}

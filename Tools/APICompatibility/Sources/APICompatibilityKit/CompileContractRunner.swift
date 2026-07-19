import Foundation

public struct SwiftCompilerProcessResult: Equatable, Sendable {
    public let exitCode: Int32
    public let standardOutput: String
    public let standardError: String

    public init(exitCode: Int32, standardOutput: String, standardError: String) {
        self.exitCode = exitCode
        self.standardOutput = standardOutput
        self.standardError = standardError
    }
}

public protocol SwiftCompilerProcess: Sendable {
    func run(executable: URL, arguments: [String]) throws -> SwiftCompilerProcessResult
}

public struct POSIXSwiftCompilerProcess: SwiftCompilerProcess {
    public init() {}

    public func run(executable: URL, arguments: [String]) throws -> SwiftCompilerProcessResult {
        let result: POSIXSubprocessResult
        do {
            result = try POSIXSubprocessRunner().run(
                executable: executable,
                arguments: arguments
            )
        } catch POSIXSubprocessError.outputCaptureSetup {
            throw contractDiagnostic(
                "compile-contract.process-output",
                "Unable to prepare Swift compiler output capture"
            )
        } catch POSIXSubprocessError.outputCaptureRead {
            throw contractDiagnostic("compile-contract.process-output", "Unable to read Swift compiler output")
        } catch {
            throw contractDiagnostic("compile-contract.process-launch", "Unable to run the Swift compiler process")
        }

        guard let standardOutput = String(data: result.standardOutput, encoding: .utf8),
              let standardError = String(data: result.standardError, encoding: .utf8) else {
            throw contractDiagnostic("compile-contract.process-output", "Unable to read Swift compiler output")
        }
        return SwiftCompilerProcessResult(
            exitCode: result.exitCode,
            standardOutput: standardOutput,
            standardError: standardError
        )
    }
}

public typealias FoundationSwiftCompilerProcess = POSIXSwiftCompilerProcess

public struct CompileContractExecution: Equatable, Sendable {
    public let contractID: String

    public init(contractID: String) {
        self.contractID = contractID
    }
}

public struct CompileContractRunner<CompilerProcess: SwiftCompilerProcess>: Sendable {
    public let compilerProcess: CompilerProcess
    public let compilerExecutable: URL
    public let leadingArguments: [String]
    public let compilerArguments: [String]

    public init(
        compilerProcess: CompilerProcess,
        compilerExecutable: URL,
        leadingArguments: [String] = [],
        compilerArguments: [String] = []
    ) {
        self.compilerProcess = compilerProcess
        self.compilerExecutable = compilerExecutable
        self.leadingArguments = leadingArguments
        self.compilerArguments = compilerArguments
    }

    public func run(
        _ definition: ContractDefinition,
        fixturesDirectory: URL
    ) throws -> CompileContractExecution {
        let structuralDiagnostics = ContractRegistryValidator().validateStructure(
            CompatibilityContractRegistry(schemaVersion: 1, contracts: [definition])
        )
        if let diagnostic = structuralDiagnostics.first {
            throw diagnostic
        }
        guard definition.kind == .compile, let contract = definition.compile else {
            throw contractDiagnostic(
                "compile-contract.invalid-definition",
                "Contract '\(definition.id)' is not a compile contract"
            )
        }
        let fixtureRoot = fixturesDirectory.standardizedFileURL.resolvingSymlinksInPath()
        let fixtureURL = fixtureRoot
            .appendingPathComponent(contract.fixture)
            .standardizedFileURL
            .resolvingSymlinksInPath()
        guard Self.isDescendant(fixtureURL, of: fixtureRoot) else {
            throw contractDiagnostic(
                "compile-contract.fixture-escape",
                "Compile fixture for contract '\(definition.id)' escapes the fixture root"
            )
        }
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: fixtureURL.path, isDirectory: &isDirectory),
              !isDirectory.boolValue else {
            throw contractDiagnostic(
                "compile-contract.missing-fixture",
                "Compile fixture for contract '\(definition.id)' does not exist"
            )
        }

        let result: SwiftCompilerProcessResult
        do {
            result = try compilerProcess.run(
                executable: compilerExecutable,
                arguments: arguments(for: fixtureURL)
            )
        } catch let diagnostic as APICheckDiagnostic {
            throw diagnostic
        } catch {
            throw contractDiagnostic(
                "compile-contract.process-failed",
                "Swift compiler process failed for contract '\(definition.id)'"
            )
        }

        switch contract.expectation.outcome {
        case .succeeds:
            try validatePositiveResult(result, contractID: definition.id)
        case .fails:
            try validateNegativeResult(
                result,
                contractID: definition.id,
                expectedDiagnosticSubstring: contract.expectation.expectedDiagnosticSubstring
            )
        }
        return CompileContractExecution(contractID: definition.id)
    }

    public func runCompileContracts(
        in registry: CompatibilityContractRegistry,
        fixturesDirectory: URL
    ) throws -> [CompileContractExecution] {
        let compileIDs = Set(registry.contracts.filter { $0.kind == .compile }.map(\.id))
        return try runCompileContracts(
            referencedContractIDs: compileIDs,
            in: registry,
            fixturesDirectory: fixturesDirectory
        )
    }

    public func runCompileContracts(
        referencedContractIDs: Set<String>,
        in registry: CompatibilityContractRegistry,
        fixturesDirectory: URL
    ) throws -> [CompileContractExecution] {
        var diagnostics = ContractRegistryValidator().validateStructure(registry)
        let registeredContracts = Dictionary(
            registry.contracts.map { ($0.id, $0) },
            uniquingKeysWith: { first, _ in first }
        )
        var selectedContracts: [ContractDefinition] = []
        for contractID in referencedContractIDs.sorted() {
            guard !contractID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                diagnostics.append(
                    code: "compile-contract.empty-reference",
                    message: "Referenced compile contract IDs must not be empty"
                )
                continue
            }
            guard let definition = registeredContracts[contractID] else {
                diagnostics.append(
                    code: "compile-contract.unknown-reference",
                    message: "Referenced compile contract '\(contractID)' is not registered"
                )
                continue
            }
            guard definition.kind == .compile else {
                diagnostics.append(
                    code: "compile-contract.noncompile-reference",
                    message: "Referenced contract '\(contractID)' is not a compile contract"
                )
                continue
            }
            selectedContracts.append(definition)
        }
        if let diagnostic = diagnostics.min() {
            throw diagnostic
        }
        return try selectedContracts.map {
            try run($0, fixturesDirectory: fixturesDirectory)
        }
    }
}

private extension Array where Element == APICheckDiagnostic {
    mutating func append(code: String, message: String) {
        append(contractDiagnostic(code, message))
    }
}

private func contractDiagnostic(_ code: String, _ message: String) -> APICheckDiagnostic {
    APICheckDiagnostic(code: code, message: message)
}

private extension CompileContractRunner {
    func arguments(for fixtureURL: URL) -> [String] {
        leadingArguments
            + ["-swift-version", "6", "-warnings-as-errors", "-typecheck"]
            + compilerArguments
            + [fixtureURL.path]
    }

    func validatePositiveResult(
        _ result: SwiftCompilerProcessResult,
        contractID: String
    ) throws {
        guard result.exitCode == 0 else {
            throw contractDiagnostic(
                "compile-contract.nonzero-exit",
                "Positive contract '\(contractID)' exited with status \(result.exitCode)"
            )
        }
        guard result.standardError.isEmpty else {
            throw contractDiagnostic(
                "compile-contract.unexpected-stderr",
                "Positive contract '\(contractID)' emitted compiler diagnostics"
            )
        }
    }

    func validateNegativeResult(
        _ result: SwiftCompilerProcessResult,
        contractID: String,
        expectedDiagnosticSubstring: String?
    ) throws {
        guard result.exitCode != 0 else {
            throw contractDiagnostic(
                "compile-contract.expected-failure",
                "Negative contract '\(contractID)' compiled successfully"
            )
        }
        if let expectedDiagnosticSubstring,
           !result.standardError.contains(expectedDiagnosticSubstring) {
            throw contractDiagnostic(
                "compile-contract.missing-diagnostic",
                "Negative contract '\(contractID)' did not emit its expected diagnostic"
            )
        }
    }

    static func isDescendant(_ candidate: URL, of root: URL) -> Bool {
        let rootComponents = root.pathComponents
        let candidateComponents = candidate.pathComponents
        return candidateComponents.count > rootComponents.count
            && candidateComponents.starts(with: rootComponents)
    }
}

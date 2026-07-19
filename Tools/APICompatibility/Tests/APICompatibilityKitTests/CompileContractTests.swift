import Foundation
import Testing

@testable import APICompatibilityKit

@Suite("Compatibility compile contracts")
struct CompileContractTests {
    @Test("Registry is Codable without losing contract details")
    func registryCodableRoundTrip() throws {
        let registry = CompatibilityContractRegistry(
            schemaVersion: 1,
            contracts: [
                compileDefinition(
                    id: "compile.text",
                    fixture: "Positive.swift",
                    outcome: .succeeds
                ),
                behaviorDefinition(id: "behavior.focus"),
            ]
        )

        let data = try JSONEncoder().encode(registry)
        let decoded = try JSONDecoder().decode(CompatibilityContractRegistry.self, from: data)

        #expect(decoded == registry)
    }

    @Test("Registry validation accepts an exact contract reference set")
    func registryValidationAcceptsExactReferences() {
        let registry = CompatibilityContractRegistry(
            schemaVersion: 1,
            contracts: [
                compileDefinition(id: "compile.text"),
                behaviorDefinition(id: "behavior.focus"),
            ]
        )

        let diagnostics = ContractRegistryValidator().validate(
            referencedContractIDs: ["compile.text", "behavior.focus"],
            registry: registry
        )

        #expect(diagnostics.isEmpty)
    }

    @Test("Registry validation reports empty, duplicate, unknown, and unused IDs")
    func registryValidationRejectsIdentityDrift() {
        let registry = CompatibilityContractRegistry(
            schemaVersion: 1,
            contracts: [
                compileDefinition(id: "compile.used"),
                compileDefinition(id: "compile.used"),
                behaviorDefinition(id: "behavior.unused"),
                behaviorDefinition(id: " \n"),
            ]
        )

        let diagnostics = ContractRegistryValidator().validate(
            referencedContractIDs: ["compile.used", "compile.unknown"],
            registry: registry
        )

        #expect(diagnostics == [
            APICheckDiagnostic(
                code: "contract-registry.duplicate-id",
                message: "Contract ID 'compile.used' is registered more than once"
            ),
            APICheckDiagnostic(
                code: "contract-registry.empty-id",
                message: "Contract IDs must not be empty"
            ),
            APICheckDiagnostic(
                code: "contract-registry.unknown-reference",
                message: "Referenced contract 'compile.unknown' is not registered"
            ),
            APICheckDiagnostic(
                code: "contract-registry.unused-contract",
                message: "Registered contract 'behavior.unused' is not referenced"
            ),
        ])
    }

    @Test("Compiler arguments are deterministic and passed without a shell")
    func deterministicCompilerArguments() throws {
        let fixtureRoot = try FixtureSupport.url("CompileContracts")
        let fixture = fixtureRoot.appendingPathComponent("Positive.swift")
        let compiler = CompilerSpy(result: .init(exitCode: 0, standardOutput: "", standardError: ""))
        let executable = URL(fileURLWithPath: "/toolchains/swiftc")
        let runner = CompileContractRunner(
            compilerProcess: compiler,
            compilerExecutable: executable,
            leadingArguments: ["--driver-mode=swiftc"],
            compilerArguments: ["-I", "/tmp/TUIkit Modules"]
        )

        let execution = try runner.run(
            compileDefinition(id: "compile.text"),
            fixturesDirectory: fixtureRoot
        )

        #expect(execution == CompileContractExecution(contractID: "compile.text"))
        #expect(compiler.invocations == [
            CompilerInvocation(
                executable: executable,
                arguments: [
                    "--driver-mode=swiftc",
                    "-swift-version", "6",
                    "-warnings-as-errors",
                    "-typecheck",
                    "-I", "/tmp/TUIkit Modules",
                    fixture.path,
                ]
            ),
        ])
    }

    @Test("A positive contract fails closed for a nonzero compiler exit")
    func positiveContractRejectsCompilerFailure() throws {
        let compiler = CompilerSpy(
            result: .init(exitCode: 1, standardOutput: "", standardError: "compile error")
        )
        let runner = fixtureRunner(compiler: compiler)

        let diagnostic = FixtureSupport.diagnostic {
            try runner.run(compileDefinition(id: "compile.positive"), fixturesDirectory: try fixtureRoot())
        }

        #expect(diagnostic == APICheckDiagnostic(
            code: "compile-contract.nonzero-exit",
            message: "Positive contract 'compile.positive' exited with status 1"
        ))
    }

    @Test("A positive contract requires empty compiler stderr")
    func positiveContractRejectsStandardError() throws {
        let compiler = CompilerSpy(
            result: .init(exitCode: 0, standardOutput: "", standardError: "warning: unstable")
        )
        let runner = fixtureRunner(compiler: compiler)

        let diagnostic = FixtureSupport.diagnostic {
            try runner.run(compileDefinition(id: "compile.positive"), fixturesDirectory: try fixtureRoot())
        }

        #expect(diagnostic == APICheckDiagnostic(
            code: "compile-contract.unexpected-stderr",
            message: "Positive contract 'compile.positive' emitted compiler diagnostics"
        ))
    }

    @Test("A negative contract requires a nonzero compiler exit")
    func negativeContractRejectsSuccessfulCompilation() throws {
        let compiler = CompilerSpy(result: .init(exitCode: 0, standardOutput: "", standardError: ""))
        let runner = fixtureRunner(compiler: compiler)
        let contract = compileDefinition(
            id: "compile.negative",
            fixture: "Negative.swift",
            outcome: .fails,
            expectedDiagnosticSubstring: "expected compiler failure"
        )

        let diagnostic = FixtureSupport.diagnostic {
            try runner.run(contract, fixturesDirectory: try fixtureRoot())
        }

        #expect(diagnostic == APICheckDiagnostic(
            code: "compile-contract.expected-failure",
            message: "Negative contract 'compile.negative' compiled successfully"
        ))
    }

    @Test("A negative contract can require a stable diagnostic substring")
    func negativeContractChecksDiagnosticSubstring() throws {
        let compiler = CompilerSpy(
            result: .init(
                exitCode: 1,
                standardOutput: "",
                standardError: "error: cannot convert value of type 'String' to specified type 'Int'"
            )
        )
        let runner = fixtureRunner(compiler: compiler)
        let contract = compileDefinition(
            id: "compile.negative",
            fixture: "Negative.swift",
            outcome: .fails,
            expectedDiagnosticSubstring: "cannot convert value of type"
        )

        let execution = try runner.run(contract, fixturesDirectory: try fixtureRoot())

        #expect(execution == CompileContractExecution(contractID: "compile.negative"))
    }

    @Test("A negative contract fails closed when its stable diagnostic is absent")
    func negativeContractRejectsDifferentDiagnostic() throws {
        let compiler = CompilerSpy(
            result: .init(exitCode: 1, standardOutput: "", standardError: "error: different failure")
        )
        let runner = fixtureRunner(compiler: compiler)
        let contract = compileDefinition(
            id: "compile.negative",
            fixture: "Negative.swift",
            outcome: .fails,
            expectedDiagnosticSubstring: "cannot convert value of type"
        )

        let diagnostic = FixtureSupport.diagnostic {
            try runner.run(contract, fixturesDirectory: try fixtureRoot())
        }

        #expect(diagnostic == APICheckDiagnostic(
            code: "compile-contract.missing-diagnostic",
            message: "Negative contract 'compile.negative' did not emit its expected diagnostic"
        ))
    }

    @Test("A missing compile fixture fails before invoking the compiler")
    func missingFixtureFailsClosed() throws {
        let compiler = CompilerSpy(result: .init(exitCode: 0, standardOutput: "", standardError: ""))
        let runner = fixtureRunner(compiler: compiler)
        let contract = compileDefinition(id: "compile.missing", fixture: "Missing.swift")

        let diagnostic = FixtureSupport.diagnostic {
            try runner.run(contract, fixturesDirectory: try fixtureRoot())
        }

        #expect(diagnostic == APICheckDiagnostic(
            code: "compile-contract.missing-fixture",
            message: "Compile fixture for contract 'compile.missing' does not exist"
        ))
        #expect(compiler.invocations.isEmpty)
    }

    @Test("Batch execution runs compile contracts in ID order and skips behavior contracts")
    func batchExecutionRunsOnlyCompileContracts() throws {
        let compiler = CompilerSpy(result: .init(exitCode: 0, standardOutput: "", standardError: ""))
        let runner = fixtureRunner(compiler: compiler)
        let registry = CompatibilityContractRegistry(
            schemaVersion: 1,
            contracts: [
                compileDefinition(id: "compile.zeta"),
                behaviorDefinition(id: "behavior.focus"),
                compileDefinition(id: "compile.alpha"),
            ]
        )

        let executions = try runner.runCompileContracts(
            in: registry,
            fixturesDirectory: try fixtureRoot()
        )

        #expect(executions.map(\.contractID) == ["compile.alpha", "compile.zeta"])
        #expect(compiler.invocations.count == 2)
    }

    @Test("Compiler process errors are converted to stable diagnostics")
    func compilerProcessErrorsFailClosed() throws {
        let compiler = CompilerSpy(error: CompilerSpyError.unavailable)
        let runner = fixtureRunner(compiler: compiler)

        let diagnostic = FixtureSupport.diagnostic {
            try runner.run(compileDefinition(id: "compile.process"), fixturesDirectory: try fixtureRoot())
        }

        #expect(diagnostic == APICheckDiagnostic(
            code: "compile-contract.process-failed",
            message: "Swift compiler process failed for contract 'compile.process'"
        ))
    }

    @Test("Real Swift compiler accepts the positive fixture and rejects the negative fixture")
    func realSwiftCompilerFixtures() throws {
        let runner = CompileContractRunner(
            compilerProcess: FoundationSwiftCompilerProcess(),
            compilerExecutable: URL(fileURLWithPath: "/usr/bin/env"),
            leadingArguments: ["swiftc"]
        )
        let registry = CompatibilityContractRegistry(
            schemaVersion: 1,
            contracts: [
                compileDefinition(id: "compile.real-positive"),
                compileDefinition(
                    id: "compile.real-negative",
                    fixture: "Negative.swift",
                    outcome: .fails,
                    expectedDiagnosticSubstring: "cannot convert value of type"
                ),
            ]
        )

        let executions = try runner.runCompileContracts(
            in: registry,
            fixturesDirectory: try fixtureRoot()
        )

        #expect(executions.map(\.contractID) == ["compile.real-negative", "compile.real-positive"])
    }
}

private extension CompileContractTests {
    func compileDefinition(
        id: String,
        fixture: String = "Positive.swift",
        outcome: CompileContractOutcome = .succeeds,
        expectedDiagnosticSubstring: String? = nil
    ) -> ContractDefinition {
        ContractDefinition(
            id: id,
            kind: .compile,
            compile: CompileContract(
                fixture: fixture,
                expectation: CompileContractExpectation(
                    outcome: outcome,
                    expectedDiagnosticSubstring: expectedDiagnosticSubstring
                )
            )
        )
    }

    func behaviorDefinition(id: String) -> ContractDefinition {
        ContractDefinition(
            id: id,
            kind: .behavior,
            testIdentifier: "APICompatibilityKitTests.BehaviorContractTests/focus"
        )
    }

    func fixtureRoot() throws -> URL {
        try FixtureSupport.url("CompileContracts")
    }

    func fixtureRunner(
        compiler: CompilerSpy
    ) -> CompileContractRunner<CompilerSpy> {
        CompileContractRunner(
            compilerProcess: compiler,
            compilerExecutable: URL(fileURLWithPath: "/toolchains/swiftc")
        )
    }
}

private struct CompilerInvocation: Equatable, Sendable {
    let executable: URL
    let arguments: [String]
}

private final class CompilerSpy: SwiftCompilerProcess, @unchecked Sendable {
    private let lock = NSLock()
    private let result: SwiftCompilerProcessResult?
    private let error: (any Error)?
    private var storedInvocations: [CompilerInvocation] = []

    init(result: SwiftCompilerProcessResult) {
        self.result = result
        self.error = nil
    }

    init(error: any Error) {
        self.result = nil
        self.error = error
    }

    var invocations: [CompilerInvocation] {
        lock.lock()
        defer { lock.unlock() }
        return storedInvocations
    }

    func run(executable: URL, arguments: [String]) throws -> SwiftCompilerProcessResult {
        lock.lock()
        storedInvocations.append(CompilerInvocation(executable: executable, arguments: arguments))
        lock.unlock()
        if let error {
            throw error
        }
        guard let result else {
            throw CompilerSpyError.unavailable
        }
        return result
    }
}

private enum CompilerSpyError: Error {
    case unavailable
}

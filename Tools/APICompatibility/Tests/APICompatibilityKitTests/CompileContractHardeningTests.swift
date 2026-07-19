import Foundation
import Testing

@testable import APICompatibilityKit

@Suite("Compatibility contract hardening")
struct CompileContractHardeningTests {
    @Test("Registry codec writes deterministic JSON and loads it back")
    func registryCodecRoundTrip() throws {
        let directory = try FixtureSupport.temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let output = directory.appendingPathComponent("nested/contracts.json")
        let registry = validRegistry()
        let codec = ContractRegistryCodec()

        let firstEncoding = try codec.encode(registry)
        let secondEncoding = try codec.encode(registry)
        try codec.write(registry, to: output)

        #expect(firstEncoding == secondEncoding)
        #expect(firstEncoding.last == 0x0A)
        #expect(try Data(contentsOf: output) == firstEncoding)
        #expect(try codec.load(from: output) == registry)
    }

    @Test("Registry loader rejects malformed JSON with a stable diagnostic")
    func registryLoaderRejectsMalformedJSON() throws {
        let directory = try FixtureSupport.temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let input = directory.appendingPathComponent("contracts.json")
        try Data("not-json".utf8).write(to: input)

        let diagnostic = FixtureSupport.diagnostic {
            try ContractRegistryCodec().load(from: input)
        }

        #expect(diagnostic == APICheckDiagnostic(
            code: "contract-registry.invalid-json",
            message: "contracts.json is not a valid contract registry"
        ))
    }

    @Test("Registry codec rejects structurally invalid data before writing")
    func registryWriterRejectsInvalidStructure() throws {
        let directory = try FixtureSupport.temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let output = directory.appendingPathComponent("contracts.json")
        let invalid = CompatibilityContractRegistry(schemaVersion: 2, contracts: [])

        let diagnostic = FixtureSupport.diagnostic {
            try ContractRegistryCodec().write(invalid, to: output)
        }

        #expect(diagnostic == APICheckDiagnostic(
            code: "contract-registry.schema-version",
            message: "Unsupported contract registry schema version 2"
        ))
        #expect(!FileManager.default.fileExists(atPath: output.path))
    }

    @Test("Registry loader rejects decoded data with an invalid structure")
    func registryLoaderRejectsInvalidStructure() throws {
        let directory = try FixtureSupport.temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let input = directory.appendingPathComponent("contracts.json")
        let invalid = CompatibilityContractRegistry(schemaVersion: 2, contracts: [])
        try JSONEncoder().encode(invalid).write(to: input)

        let diagnostic = FixtureSupport.diagnostic {
            try ContractRegistryCodec().load(from: input)
        }

        #expect(diagnostic == APICheckDiagnostic(
            code: "contract-registry.schema-version",
            message: "Unsupported contract registry schema version 2"
        ))
    }

    @Test("Structural validation rejects inconsistent contract records", arguments: structuralCases)
    func structuralValidation(testCase: StructuralCase) {
        let diagnostics = ContractRegistryValidator().validateStructure(testCase.registry)

        #expect(diagnostics.contains(testCase.diagnostic))
    }

    @Test("Referenced contract IDs cannot be empty")
    func emptyReferencedContractIDFailsClosed() {
        let diagnostics = ContractRegistryValidator().validate(
            referencedContractIDs: ["compile.valid", " \n"],
            registry: validRegistry(contracts: [validCompile(id: "compile.valid")])
        )

        #expect(diagnostics == [
            APICheckDiagnostic(
                code: "contract-registry.empty-reference",
                message: "Referenced contract IDs must not be empty"
            ),
        ])
    }

    @Test("Runner rejects a noncanonical fixture path before compiler invocation")
    func runnerRejectsParentTraversal() throws {
        let compiler = HardeningCompilerSpy()
        let runner = CompileContractRunner(
            compilerProcess: compiler,
            compilerExecutable: URL(fileURLWithPath: "/toolchains/swiftc")
        )
        let contract = validCompile(id: "compile.escape", fixture: "../Positive.swift")

        let diagnostic = FixtureSupport.diagnostic {
            try runner.run(contract, fixturesDirectory: try FixtureSupport.url("CompileContracts"))
        }

        #expect(diagnostic == fixturePathDiagnostic(id: "compile.escape", path: "../Positive.swift"))
        #expect(compiler.invocationCount == 0)
    }

    @Test("Runner rejects a fixture symlink escaping the fixture root")
    func runnerRejectsSymlinkEscape() throws {
        let directory = try FixtureSupport.temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let fixtureRoot = directory.appendingPathComponent("Fixtures", isDirectory: true)
        let outside = directory.appendingPathComponent("Outside.swift")
        let symlink = fixtureRoot.appendingPathComponent("Escape.swift")
        try FileManager.default.createDirectory(at: fixtureRoot, withIntermediateDirectories: true)
        try Data("let value = 1\n".utf8).write(to: outside)
        try FileManager.default.createSymbolicLink(at: symlink, withDestinationURL: outside)
        let compiler = HardeningCompilerSpy()
        let runner = CompileContractRunner(
            compilerProcess: compiler,
            compilerExecutable: URL(fileURLWithPath: "/toolchains/swiftc")
        )

        let diagnostic = FixtureSupport.diagnostic {
            try runner.run(validCompile(id: "compile.escape", fixture: "Escape.swift"), fixturesDirectory: fixtureRoot)
        }

        #expect(diagnostic == APICheckDiagnostic(
            code: "compile-contract.fixture-escape",
            message: "Compile fixture for contract 'compile.escape' escapes the fixture root"
        ))
        #expect(compiler.invocationCount == 0)
    }

    @Test("Behavior test verification accepts discovered IDs and ignores extra tests")
    func behaviorTestsMatchDiscoveredInventory() {
        let registry = validRegistry(contracts: [
            validBehavior(id: "behavior.focus", testIdentifier: "Tests.Focus/focus"),
        ])

        let diagnostics = ContractRegistryValidator().validateBehaviorTests(
            in: registry,
            discoveredTestIdentifiers: ["Tests.Focus/focus", "Tests.Unrelated/extra"],
            successfulTestIdentifiers: ["Tests.Focus/focus", "Tests.Unrelated/extra"]
        )

        #expect(diagnostics.isEmpty)
    }

    @Test("Behavior test verification reports missing tests deterministically")
    func behaviorTestsRejectMissingInventoryEntries() {
        let registry = validRegistry(contracts: [
            validBehavior(id: "behavior.zeta", testIdentifier: "Tests.Zeta/zeta"),
            validBehavior(id: "behavior.alpha", testIdentifier: "Tests.Alpha/alpha"),
        ])

        let diagnostics = ContractRegistryValidator().validateBehaviorTests(
            in: registry,
            discoveredTestIdentifiers: [],
            successfulTestIdentifiers: []
        )

        #expect(diagnostics == [
            APICheckDiagnostic(
                code: "contract-registry.missing-behavior-test",
                message: "Behavior contract 'behavior.alpha' references undiscovered test 'Tests.Alpha/alpha'"
            ),
            APICheckDiagnostic(
                code: "contract-registry.missing-behavior-test",
                message: "Behavior contract 'behavior.zeta' references undiscovered test 'Tests.Zeta/zeta'"
            ),
        ])
    }

    @Test("Behavior test verification rejects identifiers shared by multiple contracts")
    func behaviorTestsRejectDuplicateIdentifiers() {
        let registry = validRegistry(contracts: [
            validBehavior(id: "behavior.zeta", testIdentifier: "Tests.Shared/shared"),
            validBehavior(id: "behavior.alpha", testIdentifier: "Tests.Shared/shared"),
        ])

        let diagnostics = ContractRegistryValidator().validateBehaviorTests(
            in: registry,
            discoveredTestIdentifiers: ["Tests.Shared/shared"],
            successfulTestIdentifiers: ["Tests.Shared/shared"]
        )

        #expect(diagnostics == [
            APICheckDiagnostic(
                code: "contract-registry.duplicate-test-identifier",
                message: "Behavior testIdentifier 'Tests.Shared/shared' is shared by contracts 'behavior.alpha', 'behavior.zeta'"
            ),
        ])
    }

    @Test("Behavior test verification requires a clean passing execution")
    func behaviorTestsRejectNonpassingExecution() {
        let registry = validRegistry(contracts: [
            validBehavior(id: "behavior.focus", testIdentifier: "Tests.Focus/focus()"),
        ])

        let diagnostics = ContractRegistryValidator().validateBehaviorTests(
            in: registry,
            discoveredTestIdentifiers: ["Tests.Focus/focus()"],
            successfulTestIdentifiers: []
        )

        #expect(diagnostics == [
            APICheckDiagnostic(
                code: "contract-registry.behavior-test-not-passed",
                message: "Behavior contract 'behavior.focus' has no clean passing result for 'Tests.Focus/focus()'"
            ),
        ])
    }

    @Test("Event stream excludes skipped and known-issue tests from passing evidence")
    func eventStreamRequiresCleanPasses() throws {
        let directory = try FixtureSupport.temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let eventStream = directory.appendingPathComponent("events.jsonl")
        let records = [
            testDefinition("Tests.Focus/passes()/FocusTests.swift:1:1"),
            testDefinition("Tests.Focus/known()/FocusTests.swift:2:1"),
            testDefinition("Tests.Focus/skipped()/FocusTests.swift:3:1"),
            testEvent("testStarted", id: "Tests.Focus/passes()/FocusTests.swift:1:1"),
            testEvent("testEnded", id: "Tests.Focus/passes()/FocusTests.swift:1:1", symbol: "pass"),
            testEvent("testStarted", id: "Tests.Focus/known()/FocusTests.swift:2:1"),
            testEvent("issueRecorded", id: "Tests.Focus/known()/FocusTests.swift:2:1"),
            testEvent("testEnded", id: "Tests.Focus/known()/FocusTests.swift:2:1", symbol: "passWithKnownIssue"),
            testEvent("testSkipped", id: "Tests.Focus/skipped()/FocusTests.swift:3:1"),
        ].joined(separator: "\n") + "\n"
        try Data(records.utf8).write(to: eventStream)

        let results = try BehaviorTestEventStreamLoader().load(from: eventStream)

        #expect(results.discoveredTestIdentifiers == [
            "Tests.Focus/known()",
            "Tests.Focus/passes()",
            "Tests.Focus/skipped()",
        ])
        #expect(results.successfulTestIdentifiers == ["Tests.Focus/passes()"])
    }

    @Test("Explicit compile selection runs only referenced contracts in ID order")
    func runnerExecutesExplicitCompileSelection() throws {
        let compiler = HardeningCompilerSpy()
        let runner = CompileContractRunner(
            compilerProcess: compiler,
            compilerExecutable: URL(fileURLWithPath: "/toolchains/swiftc")
        )
        let registry = validRegistry(contracts: [
            validCompile(id: "compile.zeta"),
            validBehavior(id: "behavior.focus", testIdentifier: "Tests.Focus/focus"),
            validCompile(id: "compile.unused"),
            validCompile(id: "compile.alpha"),
        ])

        let executions = try runner.runCompileContracts(
            referencedContractIDs: ["compile.zeta", "compile.alpha"],
            in: registry,
            fixturesDirectory: try FixtureSupport.url("CompileContracts")
        )

        #expect(executions.map(\.contractID) == ["compile.alpha", "compile.zeta"])
        #expect(compiler.invocationCount == 2)
    }

    @Test("Explicit compile selection rejects an unknown contract before execution")
    func runnerRejectsUnknownCompileReference() throws {
        let compiler = HardeningCompilerSpy()
        let runner = CompileContractRunner(
            compilerProcess: compiler,
            compilerExecutable: URL(fileURLWithPath: "/toolchains/swiftc")
        )

        let diagnostic = FixtureSupport.diagnostic {
            try runner.runCompileContracts(
                referencedContractIDs: ["compile.unknown"],
                in: validRegistry(contracts: [validCompile(id: "compile.known")]),
                fixturesDirectory: try FixtureSupport.url("CompileContracts")
            )
        }

        #expect(diagnostic == APICheckDiagnostic(
            code: "compile-contract.unknown-reference",
            message: "Referenced compile contract 'compile.unknown' is not registered"
        ))
        #expect(compiler.invocationCount == 0)
    }

    @Test("Explicit compile selection rejects a behavior contract before execution")
    func runnerRejectsBehaviorReference() throws {
        let compiler = HardeningCompilerSpy()
        let runner = CompileContractRunner(
            compilerProcess: compiler,
            compilerExecutable: URL(fileURLWithPath: "/toolchains/swiftc")
        )
        let registry = validRegistry(contracts: [
            validBehavior(id: "behavior.focus", testIdentifier: "Tests.Focus/focus"),
        ])

        let diagnostic = FixtureSupport.diagnostic {
            try runner.runCompileContracts(
                referencedContractIDs: ["behavior.focus"],
                in: registry,
                fixturesDirectory: try FixtureSupport.url("CompileContracts")
            )
        }

        #expect(diagnostic == APICheckDiagnostic(
            code: "compile-contract.noncompile-reference",
            message: "Referenced contract 'behavior.focus' is not a compile contract"
        ))
        #expect(compiler.invocationCount == 0)
    }
}

private let structuralCases: [StructuralCase] = [
    StructuralCase(
        registry: CompatibilityContractRegistry(schemaVersion: 2, contracts: []),
        diagnostic: APICheckDiagnostic(
            code: "contract-registry.schema-version",
            message: "Unsupported contract registry schema version 2"
        )
    ),
    StructuralCase(
        registry: validRegistry(contracts: [ContractDefinition(id: "compile.missing", kind: .compile)]),
        diagnostic: APICheckDiagnostic(
            code: "contract-registry.compile-payload",
            message: "Compile contract 'compile.missing' requires exactly one compile payload"
        )
    ),
    StructuralCase(
        registry: validRegistry(contracts: [
            ContractDefinition(
                id: "compile.test-identifier",
                kind: .compile,
                compile: compilePayload(),
                testIdentifier: "Tests.Invalid/compile"
            ),
        ]),
        diagnostic: APICheckDiagnostic(
            code: "contract-registry.compile-test-identifier",
            message: "Compile contract 'compile.test-identifier' cannot define a testIdentifier"
        )
    ),
    StructuralCase(
        registry: validRegistry(contracts: [
            ContractDefinition(
                id: "behavior.payload",
                kind: .behavior,
                compile: compilePayload(),
                testIdentifier: "Tests.Behavior/payload"
            ),
        ]),
        diagnostic: APICheckDiagnostic(
            code: "contract-registry.behavior-payload",
            message: "Behavior contract 'behavior.payload' cannot define a compile payload"
        )
    ),
    StructuralCase(
        registry: validRegistry(contracts: [ContractDefinition(id: "behavior.missing", kind: .behavior)]),
        diagnostic: APICheckDiagnostic(
            code: "contract-registry.behavior-test-identifier",
            message: "Behavior contract 'behavior.missing' requires a stable testIdentifier"
        )
    ),
    StructuralCase(
        registry: validRegistry(contracts: [validCompile(id: "compile.empty", fixture: " \n")]),
        diagnostic: fixturePathDiagnostic(id: "compile.empty", path: " \n")
    ),
    StructuralCase(
        registry: validRegistry(contracts: [validCompile(id: "compile.absolute", fixture: "/tmp/Fixture.swift")]),
        diagnostic: fixturePathDiagnostic(id: "compile.absolute", path: "/tmp/Fixture.swift")
    ),
    StructuralCase(
        registry: validRegistry(contracts: [validCompile(id: "compile.parent", fixture: "Nested/../Fixture.swift")]),
        diagnostic: fixturePathDiagnostic(id: "compile.parent", path: "Nested/../Fixture.swift")
    ),
    StructuralCase(
        registry: validRegistry(contracts: [validCompile(id: "compile.dot", fixture: "./Fixture.swift")]),
        diagnostic: fixturePathDiagnostic(id: "compile.dot", path: "./Fixture.swift")
    ),
    StructuralCase(
        registry: validRegistry(contracts: [validCompile(id: "compile.extension", fixture: "Fixture.txt")]),
        diagnostic: fixturePathDiagnostic(id: "compile.extension", path: "Fixture.txt")
    ),
    StructuralCase(
        registry: validRegistry(contracts: [
            validCompile(id: "compile.missing-diagnostic", outcome: .fails),
        ]),
        diagnostic: APICheckDiagnostic(
            code: "contract-registry.negative-diagnostic",
            message: "Negative contract 'compile.missing-diagnostic' requires an expected diagnostic substring"
        )
    ),
    StructuralCase(
        registry: validRegistry(contracts: [
            validCompile(id: "compile.empty-diagnostic", outcome: .fails, diagnostic: " \n"),
        ]),
        diagnostic: APICheckDiagnostic(
            code: "contract-registry.diagnostic-substring",
            message: "Compile contract 'compile.empty-diagnostic' has an empty expected diagnostic substring"
        )
    ),
    StructuralCase(
        registry: validRegistry(contracts: [
            validCompile(id: "compile.positive-diagnostic", outcome: .succeeds, diagnostic: "error:"),
        ]),
        diagnostic: APICheckDiagnostic(
            code: "contract-registry.positive-diagnostic",
            message: "Positive contract 'compile.positive-diagnostic' cannot expect a compiler diagnostic"
        )
    ),
]

struct StructuralCase: Sendable {
    let registry: CompatibilityContractRegistry
    let diagnostic: APICheckDiagnostic
}

private func validRegistry(
    contracts: [ContractDefinition] = [
        validCompile(id: "compile.valid"),
        ContractDefinition(
            id: "behavior.valid",
            kind: .behavior,
            testIdentifier: "APICompatibilityKitTests.BehaviorContractTests/valid"
        ),
    ]
) -> CompatibilityContractRegistry {
    CompatibilityContractRegistry(schemaVersion: 1, contracts: contracts)
}

private func validCompile(
    id: String,
    fixture: String = "Positive.swift",
    outcome: CompileContractOutcome = .succeeds,
    diagnostic: String? = nil
) -> ContractDefinition {
    ContractDefinition(
        id: id,
        kind: .compile,
        compile: CompileContract(
            fixture: fixture,
            expectation: CompileContractExpectation(
                outcome: outcome,
                expectedDiagnosticSubstring: diagnostic
            )
        )
    )
}

private func validBehavior(id: String, testIdentifier: String) -> ContractDefinition {
    ContractDefinition(id: id, kind: .behavior, testIdentifier: testIdentifier)
}

private func compilePayload() -> CompileContract {
    CompileContract(
        fixture: "Positive.swift",
        expectation: CompileContractExpectation(outcome: .succeeds)
    )
}

private func fixturePathDiagnostic(id: String, path: String) -> APICheckDiagnostic {
    APICheckDiagnostic(
        code: "contract-registry.fixture-path",
        message: "Compile contract '\(id)' has a noncanonical Swift fixture path '\(path)'"
    )
}

private func testDefinition(_ id: String) -> String {
    "{\"kind\":\"test\",\"payload\":{\"id\":\"\(id)\",\"kind\":\"function\"},\"version\":0}"
}

private func testEvent(
    _ kind: String,
    id: String,
    symbol: String? = nil
) -> String {
    let messages = symbol.map { ",\"messages\":[{\"symbol\":\"\($0)\"}]" } ?? ""
    return "{\"kind\":\"event\",\"payload\":{\"kind\":\"\(kind)\"\(messages),\"testID\":\"\(id)\"},\"version\":0}"
}

private final class HardeningCompilerSpy: SwiftCompilerProcess, @unchecked Sendable {
    private let lock = NSLock()
    private var storedInvocationCount = 0

    var invocationCount: Int {
        lock.lock()
        defer { lock.unlock() }
        return storedInvocationCount
    }

    func run(executable: URL, arguments: [String]) -> SwiftCompilerProcessResult {
        lock.lock()
        storedInvocationCount += 1
        lock.unlock()
        return SwiftCompilerProcessResult(exitCode: 0, standardOutput: "", standardError: "")
    }
}

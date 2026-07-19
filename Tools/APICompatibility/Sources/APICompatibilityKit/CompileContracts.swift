import Foundation

public struct CompatibilityContractRegistry: Codable, Equatable, Sendable {
    public var schemaVersion: Int
    public var contracts: [ContractDefinition]

    public init(schemaVersion: Int, contracts: [ContractDefinition]) {
        self.schemaVersion = schemaVersion
        self.contracts = contracts
    }
}

public struct ContractDefinition: Codable, Equatable, Sendable {
    public var id: String
    public var kind: ContractKind
    public var compile: CompileContract?
    public var testIdentifier: String?

    public init(
        id: String,
        kind: ContractKind,
        compile: CompileContract? = nil,
        testIdentifier: String? = nil
    ) {
        self.id = id
        self.kind = kind
        self.compile = compile
        self.testIdentifier = testIdentifier
    }
}

public enum ContractKind: String, Codable, CaseIterable, Sendable {
    case behavior
    case compile
}

public struct CompileContract: Codable, Equatable, Sendable {
    public var fixture: String
    public var expectation: CompileContractExpectation

    public init(fixture: String, expectation: CompileContractExpectation) {
        self.fixture = fixture
        self.expectation = expectation
    }
}

public struct CompileContractExpectation: Codable, Equatable, Sendable {
    public var outcome: CompileContractOutcome
    public var expectedDiagnosticSubstring: String?

    public init(
        outcome: CompileContractOutcome,
        expectedDiagnosticSubstring: String? = nil
    ) {
        self.outcome = outcome
        self.expectedDiagnosticSubstring = expectedDiagnosticSubstring
    }
}

public enum CompileContractOutcome: String, Codable, CaseIterable, Sendable {
    case fails
    case succeeds
}

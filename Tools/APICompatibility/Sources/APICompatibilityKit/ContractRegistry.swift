import Foundation

public struct ContractRegistryCodec: Sendable {
    public init() {}

    public func encode(_ registry: CompatibilityContractRegistry) throws -> Data {
        try validate(registry)
        do {
            return try JSONArtifactCodec.encode(registry)
        } catch {
            throw contractDiagnostic("contract-registry.encoding", "Unable to encode contract registry")
        }
    }

    public func write(_ registry: CompatibilityContractRegistry, to url: URL) throws {
        let data = try encode(registry)
        do {
            try FileManager.default.createDirectory(
                at: url.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            try data.write(to: url, options: .atomic)
        } catch {
            throw contractDiagnostic("contract-registry.write-failed", "Unable to write \(url.lastPathComponent)")
        }
    }

    public func load(from url: URL) throws -> CompatibilityContractRegistry {
        let registry: CompatibilityContractRegistry
        do {
            let data = try Data(contentsOf: url)
            registry = try JSONDecoder().decode(CompatibilityContractRegistry.self, from: data)
        } catch {
            throw contractDiagnostic(
                "contract-registry.invalid-json",
                "\(url.lastPathComponent) is not a valid contract registry"
            )
        }
        try validate(registry)
        return registry
    }

    private func validate(_ registry: CompatibilityContractRegistry) throws {
        if let diagnostic = ContractRegistryValidator().validateStructure(registry).first {
            throw diagnostic
        }
    }
}

public struct ContractRegistryValidator: Sendable {
    public init() {}

    public func validateStructure(
        _ registry: CompatibilityContractRegistry
    ) -> [APICheckDiagnostic] {
        var diagnostics: [APICheckDiagnostic] = []
        if registry.schemaVersion != 1 {
            diagnostics.append(
                code: "contract-registry.schema-version",
                message: "Unsupported contract registry schema version \(registry.schemaVersion)"
            )
        }
        let registeredIDs = registry.contracts.map(\.id)
        if registeredIDs.contains(where: { !Self.isNonempty($0) }) {
            diagnostics.append(code: "contract-registry.empty-id", message: "Contract IDs must not be empty")
        }
        let validIDs = registeredIDs.filter(Self.isNonempty)
        let duplicateIDs = Dictionary(grouping: validIDs, by: { $0 })
            .filter { $0.value.count > 1 }
            .keys
            .sorted()
        diagnostics.append(contentsOf: duplicateIDs.map {
            contractDiagnostic("contract-registry.duplicate-id", "Contract ID '\($0)' is registered more than once")
        })
        for definition in registry.contracts {
            validate(definition, diagnostics: &diagnostics)
        }
        return diagnostics.sorted()
    }

    public func validate(
        referencedContractIDs: Set<String>,
        registry: CompatibilityContractRegistry
    ) -> [APICheckDiagnostic] {
        var diagnostics = validateStructure(registry)
        let registeredIDs = registry.contracts.map(\.id)
        let validRegisteredIDs = registeredIDs.filter(Self.isNonempty)
        let validReferencedIDs = referencedContractIDs.filter(Self.isNonempty)

        if validReferencedIDs.count != referencedContractIDs.count {
            diagnostics.append(
                code: "contract-registry.empty-reference",
                message: "Referenced contract IDs must not be empty"
            )
        }
        let registeredSet = Set(validRegisteredIDs)
        let referencedSet = Set(validReferencedIDs)
        diagnostics.append(contentsOf: referencedSet.subtracting(registeredSet).sorted().map {
            contractDiagnostic("contract-registry.unknown-reference", "Referenced contract '\($0)' is not registered")
        })
        diagnostics.append(contentsOf: registeredSet.subtracting(referencedSet).sorted().map {
            contractDiagnostic("contract-registry.unused-contract", "Registered contract '\($0)' is not referenced")
        })
        return diagnostics.sorted()
    }

    public func validateBehaviorTests(
        in registry: CompatibilityContractRegistry,
        discoveredTestIdentifiers: Set<String>,
        successfulTestIdentifiers: Set<String>
    ) -> [APICheckDiagnostic] {
        var diagnostics = validateStructure(registry)
        let behaviorTests = registry.contracts.compactMap { definition -> (String, String)? in
            guard definition.kind == .behavior,
                  let testIdentifier = definition.testIdentifier,
                  Self.isNonempty(testIdentifier) else {
                return nil
            }
            return (definition.id, testIdentifier)
        }
        let groupedTests = Dictionary(grouping: behaviorTests, by: { $0.1 })
        for testIdentifier in groupedTests.keys.sorted() {
            guard let contracts = groupedTests[testIdentifier] else { continue }
            let contractIDs = contracts.map(\.0).sorted()
            if contractIDs.count > 1 {
                diagnostics.append(
                    code: "contract-registry.duplicate-test-identifier",
                    message: "Behavior testIdentifier '\(testIdentifier)' is shared by contracts "
                        + contractIDs.map { "'\($0)'" }.joined(separator: ", ")
                )
            }
            if !discoveredTestIdentifiers.contains(testIdentifier) {
                diagnostics.append(contentsOf: contractIDs.map {
                    contractDiagnostic(
                        "contract-registry.missing-behavior-test",
                        "Behavior contract '\($0)' references undiscovered test '\(testIdentifier)'"
                    )
                })
            } else if !successfulTestIdentifiers.contains(testIdentifier) {
                diagnostics.append(contentsOf: contractIDs.map {
                    contractDiagnostic(
                        "contract-registry.behavior-test-not-passed",
                        "Behavior contract '\($0)' has no clean passing result for '\(testIdentifier)'"
                    )
                })
            }
        }
        return diagnostics.sorted()
    }

    private static func isNonempty(_ value: String) -> Bool {
        !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

private extension ContractRegistryValidator {
    func validate(
        _ definition: ContractDefinition,
        diagnostics: inout [APICheckDiagnostic]
    ) {
        switch definition.kind {
        case .behavior:
            if definition.compile != nil {
                diagnostics.append(
                    code: "contract-registry.behavior-payload",
                    message: "Behavior contract '\(definition.id)' cannot define a compile payload"
                )
            }
            if !Self.isNonempty(definition.testIdentifier) {
                diagnostics.append(
                    code: "contract-registry.behavior-test-identifier",
                    message: "Behavior contract '\(definition.id)' requires a stable testIdentifier"
                )
            }
        case .compile:
            if definition.testIdentifier != nil {
                diagnostics.append(
                    code: "contract-registry.compile-test-identifier",
                    message: "Compile contract '\(definition.id)' cannot define a testIdentifier"
                )
            }
            guard let contract = definition.compile else {
                diagnostics.append(
                    code: "contract-registry.compile-payload",
                    message: "Compile contract '\(definition.id)' requires exactly one compile payload"
                )
                return
            }
            validate(contract, id: definition.id, diagnostics: &diagnostics)
        }
    }

    func validate(
        _ contract: CompileContract,
        id: String,
        diagnostics: inout [APICheckDiagnostic]
    ) {
        if !Self.isCanonicalSwiftFixturePath(contract.fixture) {
            diagnostics.append(
                code: "contract-registry.fixture-path",
                message: "Compile contract '\(id)' has a noncanonical Swift fixture path '\(contract.fixture)'"
            )
        }
        if contract.expectation.outcome == .fails,
           contract.expectation.expectedDiagnosticSubstring == nil {
            diagnostics.append(
                code: "contract-registry.negative-diagnostic",
                message: "Negative contract '\(id)' requires an expected diagnostic substring"
            )
        }
        if let expected = contract.expectation.expectedDiagnosticSubstring,
           !Self.isNonempty(expected) {
            diagnostics.append(
                code: "contract-registry.diagnostic-substring",
                message: "Compile contract '\(id)' has an empty expected diagnostic substring"
            )
        }
        if contract.expectation.outcome == .succeeds,
           contract.expectation.expectedDiagnosticSubstring != nil {
            diagnostics.append(
                code: "contract-registry.positive-diagnostic",
                message: "Positive contract '\(id)' cannot expect a compiler diagnostic"
            )
        }
    }

    static func isCanonicalSwiftFixturePath(_ path: String) -> Bool {
        guard isNonempty(path),
              path == path.trimmingCharacters(in: .whitespacesAndNewlines),
              !(path as NSString).isAbsolutePath,
              !path.contains("\\"),
              (path as NSString).pathExtension == "swift" else {
            return false
        }
        return path.split(separator: "/", omittingEmptySubsequences: false).allSatisfy {
            !$0.isEmpty && $0 != "." && $0 != ".."
        }
    }

    static func isNonempty(_ value: String?) -> Bool {
        guard let value else { return false }
        return isNonempty(value)
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

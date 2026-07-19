import Foundation

extension CommandRunner {
    func runValidateContracts(_ arguments: [String]) throws -> CommandResult {
        guard let options = parseOptions(
            arguments,
            allowed: ["--event-stream", "--registry"],
            required: ["--event-stream", "--registry"]
        ) else {
            return usageFailure()
        }
        let registry = try ContractRegistryCodec().load(
            from: URL(fileURLWithPath: options["--registry"] ?? "")
        )
        let testResults = try BehaviorTestEventStreamLoader().load(
            from: URL(fileURLWithPath: options["--event-stream"] ?? "")
        )
        let diagnostics = ContractRegistryValidator().validateBehaviorTests(
            in: registry,
            discoveredTestIdentifiers: testResults.discoveredTestIdentifiers,
            successfulTestIdentifiers: testResults.successfulTestIdentifiers
        )
        guard diagnostics.isEmpty else {
            return diagnosticFailure(diagnostics)
        }
        return CommandResult(
            exitCode: 0,
            standardOutput: "Contract registry and behavior tests are valid.\n",
            standardError: ""
        )
    }

    func runCompileContracts(_ arguments: [String]) throws -> CommandResult {
        let optionNames: Set<String> = [
            "--clang-module-path",
            "--fixtures",
            "--registry",
            "--swift-module-path",
            "--swiftc",
        ]
        guard let options = parseOptions(
            arguments,
            allowed: optionNames,
            required: optionNames
        ) else {
            return usageFailure()
        }
        let registry = try ContractRegistryCodec().load(
            from: URL(fileURLWithPath: options["--registry"] ?? "")
        )
        let compiler = try executableURL(
            options["--swiftc"] ?? "",
            code: "compile-contract.compiler",
            noun: "Swift compiler"
        )
        let fixtures = try directoryURL(
            options["--fixtures"] ?? "",
            code: "compile-contract.fixtures-directory",
            noun: "Compile fixture directory"
        )
        let swiftModules = try directoryURL(
            options["--swift-module-path"] ?? "",
            code: "compile-contract.swift-module-path",
            noun: "Swift module path"
        )
        let clangModules = try directoryURL(
            options["--clang-module-path"] ?? "",
            code: "compile-contract.clang-module-path",
            noun: "Clang module path"
        )
        let executions = try CompileContractRunner(
            compilerProcess: FoundationSwiftCompilerProcess(),
            compilerExecutable: compiler,
            compilerArguments: ["-I", swiftModules.path, "-I", clangModules.path]
        ).runCompileContracts(in: registry, fixturesDirectory: fixtures)
        let noun = executions.count == 1 ? "contract" : "contracts"
        return CommandResult(
            exitCode: 0,
            standardOutput: "Executed \(executions.count) compile \(noun) successfully.\n",
            standardError: ""
        )
    }
}

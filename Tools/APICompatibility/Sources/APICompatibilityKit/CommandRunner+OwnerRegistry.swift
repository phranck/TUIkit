import Foundation

extension CommandRunner {
    func runListOwnerRegistry(_ arguments: [String]) throws -> CommandResult {
        let optionNames: Set<String> = ["--owner-registry"]
        guard let options = parseOptions(
            arguments,
            allowed: optionNames,
            required: optionNames
        ) else {
            return usageFailure()
        }

        let registry = try CompatibilityOwnerRegistryCodec().load(
            from: URL(fileURLWithPath: options["--owner-registry"] ?? "")
        )
        return CommandResult(
            exitCode: 0,
            standardOutput: try CompatibilityOwnerRegistryTSVEncoder().encode(registry),
            standardError: ""
        )
    }
}

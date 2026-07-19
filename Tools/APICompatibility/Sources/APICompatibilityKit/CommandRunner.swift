import Foundation

public struct CommandResult: Equatable, Sendable {
    public let exitCode: Int32
    public let standardOutput: String
    public let standardError: String

    public init(exitCode: Int32, standardOutput: String, standardError: String) {
        self.exitCode = exitCode
        self.standardOutput = standardOutput
        self.standardError = standardError
    }
}

public struct CommandRunner: Sendable {
    private static let canonicalizeUsage = [
        "TUIkitAPICheck canonicalize --module <name> --symbol-graphs <directory>",
        "--output <snapshot.json> --extension-provenance <strict|disabled>",
        "--platform <name> --target <triple> --sdk-name <name> --sdk-version <version>",
        "--sdk-build <build> --compiler-version <version>",
    ].joined(separator: " ")

    private static let extractUsage = [
        "TUIkitAPICheck extract --extractor <executable> --module <name> --target <triple>",
        "--output <directory> [--sdk <directory>] [--swift-module-path <directory>]",
        "[--clang-module-path <directory>]",
    ].joined(separator: " ")

    private static let generateManifestUsage = [
        "TUIkitAPICheck generate-manifest --policy <policy.json>",
        "--owner-registry <owners.json>",
        "--reference-set <descriptor.json> --tuikit-set <descriptor.json>",
        "--output <manifest.json>",
    ].joined(separator: " ")

    private static let runCompileContractsUsage = [
        "TUIkitAPICheck run-compile-contracts --registry <json> --fixtures <directory>",
        "--swiftc <executable> --swift-module-path <directory> --clang-module-path <directory>",
    ].joined(separator: " ")

    private static let listOwnerRegistryUsage =
        "TUIkitAPICheck list-owner-registry --owner-registry <owners.json>"

    private static let listMappingCandidatesUsage = [
        "TUIkitAPICheck list-mapping-candidates",
        "--reference-set <descriptor.json> --tuikit-set <descriptor.json>",
    ].joined(separator: " ")

    public static let usage = """
    Usage:
      \(canonicalizeUsage)
      TUIkitAPICheck compare --reference <snapshot.json> --current <snapshot.json>
      \(extractUsage)
      \(generateManifestUsage)
      \(listMappingCandidatesUsage)
      \(listOwnerRegistryUsage)
      \(runCompileContractsUsage)
      TUIkitAPICheck validate-contracts --registry <json> --event-stream <swift-test-events.jsonl>
      TUIkitAPICheck validate-manifest --manifest <manifest.json> --reference-set <descriptor.json> --tuikit-set <descriptor.json> --contracts <registry.json>
      TUIkitAPICheck validate-manifest-schema --manifest <manifest.json>
      TUIkitAPICheck write-snapshot-set --name <name> --sources <sources.tsv> --coverage <coverage.tsv> --output <descriptor.json>
    """ + "\n"

    public init() {}

    public func run(arguments: [String]) -> CommandResult {
        guard let command = arguments.first else {
            return usageFailure()
        }
        do {
            switch command {
            case "canonicalize":
                return try runCanonicalize(Array(arguments.dropFirst()))
            case "compare":
                return try runCompare(Array(arguments.dropFirst()))
            case "extract":
                return try runExtract(Array(arguments.dropFirst()))
            case "generate-manifest":
                return try runGenerateManifest(Array(arguments.dropFirst()))
            case "list-mapping-candidates":
                return try runListMappingCandidates(Array(arguments.dropFirst()))
            case "list-owner-registry":
                return try runListOwnerRegistry(Array(arguments.dropFirst()))
            case "run-compile-contracts":
                return try runCompileContracts(Array(arguments.dropFirst()))
            case "validate-contracts":
                return try runValidateContracts(Array(arguments.dropFirst()))
            case "validate-manifest":
                return try runValidateManifest(Array(arguments.dropFirst()))
            case "validate-manifest-schema":
                return try runValidateManifestSchema(Array(arguments.dropFirst()))
            case "write-snapshot-set":
                return try runWriteSnapshotSet(Array(arguments.dropFirst()))
            default:
                return usageFailure()
            }
        } catch let diagnostic as APICheckDiagnostic {
            return CommandResult(
                exitCode: 1,
                standardOutput: "",
                standardError: "\(diagnostic.description)\n"
            )
        } catch {
            return CommandResult(
                exitCode: 1,
                standardOutput: "",
                standardError: "error[command.internal]: API check failed\n"
            )
        }
    }
}

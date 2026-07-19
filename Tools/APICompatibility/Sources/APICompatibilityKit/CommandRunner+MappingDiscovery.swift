import Foundation

extension CommandRunner {
    func runListMappingCandidates(_ arguments: [String]) throws -> CommandResult {
        let optionNames: Set<String> = ["--reference-set", "--tuikit-set"]
        guard let options = parseOptions(
            arguments,
            allowed: optionNames,
            required: optionNames
        ) else {
            return usageFailure()
        }
        let loader = APISnapshotSetLoader()
        let referenceSet = try loader.load(
            descriptorAt: URL(fileURLWithPath: options["--reference-set"] ?? "")
        )
        let tuikitSet = try loader.load(
            descriptorAt: URL(fileURLWithPath: options["--tuikit-set"] ?? "")
        )
        let candidates = CompatibilityMappingDiscovery().discover(
            referenceSet: referenceSet,
            tuikitSet: tuikitSet
        )
        let records = candidates.map { candidate in
            let differences = candidate.differences.isEmpty
                ? "exact"
                : candidate.differences.map(\.rawValue).joined(separator: ",")
            return [
                candidate.referenceID,
                candidate.tuikitSymbolID,
                differences,
            ].joined(separator: "\t")
        }
        return CommandResult(
            exitCode: 0,
            standardOutput: (["referenceID\ttuikitSymbolID\tdifferences"] + records)
                .joined(separator: "\n") + "\n",
            standardError: ""
        )
    }
}

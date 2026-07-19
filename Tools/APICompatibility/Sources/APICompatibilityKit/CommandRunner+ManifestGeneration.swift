import Foundation

extension CommandRunner {
    func runGenerateManifest(_ arguments: [String]) throws -> CommandResult {
        let optionNames: Set<String> = [
            "--owner-registry",
            "--output",
            "--policy",
            "--reference-set",
            "--tuikit-set",
        ]
        guard let options = parseOptions(
            arguments,
            allowed: optionNames,
            required: optionNames
        ) else {
            return usageFailure()
        }

        let policy = try CompatibilityReviewPolicyCodec().load(
            from: URL(fileURLWithPath: options["--policy"] ?? "")
        )
        let ownerRegistry = try CompatibilityOwnerRegistryCodec().load(
            from: URL(fileURLWithPath: options["--owner-registry"] ?? "")
        )
        let setLoader = APISnapshotSetLoader()
        let referenceSet = try setLoader.load(
            descriptorAt: URL(fileURLWithPath: options["--reference-set"] ?? "")
        )
        let tuikitSet = try setLoader.load(
            descriptorAt: URL(fileURLWithPath: options["--tuikit-set"] ?? "")
        )
        let manifest = try CompatibilityManifestGenerator(ownerRegistry: ownerRegistry).generate(
            policy: policy,
            referenceSet: referenceSet,
            tuikitSet: tuikitSet
        )
        let outputURL = URL(fileURLWithPath: options["--output"] ?? "")
        try CompatibilityManifestCodec().write(manifest, to: outputURL)

        return CommandResult(
            exitCode: 0,
            standardOutput: "Wrote compatibility manifest with "
                + "\(manifest.referenceIDs.count) \(noun("reference", count: manifest.referenceIDs.count)) "
                + "and \(manifest.tuikitDecisions.count) "
                + "\(noun("TUIkit symbol", count: manifest.tuikitDecisions.count)) "
                + "to \(outputURL.path)\n",
            standardError: ""
        )
    }

    private func noun(_ singular: String, count: Int) -> String {
        count == 1 ? singular : "\(singular)s"
    }
}

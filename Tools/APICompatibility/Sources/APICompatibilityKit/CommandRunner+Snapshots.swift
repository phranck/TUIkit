import Foundation

extension CommandRunner {
    func runCanonicalize(_ arguments: [String]) throws -> CommandResult {
        let optionNames: Set<String> = [
            "--compiler-version",
            "--extension-provenance",
            "--module",
            "--output",
            "--platform",
            "--sdk-build",
            "--sdk-name",
            "--sdk-version",
            "--symbol-graphs",
            "--target",
        ]
        guard let options = parseOptions(
            arguments,
            allowed: optionNames,
            required: optionNames
        ) else {
            return usageFailure()
        }
        let moduleName = options["--module"] ?? ""
        let graphDirectory = URL(
            fileURLWithPath: options["--symbol-graphs"] ?? "",
            isDirectory: true
        )
        let outputURL = URL(fileURLWithPath: options["--output"] ?? "")
        let extensionProvenance = try extensionProvenanceMode(
            options["--extension-provenance"] ?? ""
        )
        let graph = try SymbolGraphLoader().load(
            from: graphDirectory,
            moduleName: moduleName,
            extensionProvenance: extensionProvenance
        )
        let snapshot = SymbolGraphCanonicalizer().canonicalize(
            graph,
            provenance: APISnapshotProvenance(
                platform: options["--platform"] ?? "",
                targetTriple: options["--target"] ?? "",
                sdkName: options["--sdk-name"] ?? "",
                sdkVersion: options["--sdk-version"] ?? "",
                sdkBuild: options["--sdk-build"] ?? "",
                compilerVersion: options["--compiler-version"] ?? ""
            )
        )
        try SnapshotCodec().write(snapshot, to: outputURL)
        return CommandResult(
            exitCode: 0,
            standardOutput: "Wrote \(snapshot.symbols.count) symbols for \(moduleName) to \(outputURL.path)\n",
            standardError: ""
        )
    }

    func runExtract(_ arguments: [String]) throws -> CommandResult {
        let allowedOptions: Set<String> = [
            "--clang-module-path",
            "--extractor",
            "--module",
            "--output",
            "--sdk",
            "--swift-module-path",
            "--target",
        ]
        let requiredOptions: Set<String> = [
            "--extractor",
            "--module",
            "--output",
            "--target",
        ]
        guard let options = parseOptions(
            arguments,
            allowed: allowedOptions,
            required: requiredOptions
        ) else {
            return usageFailure()
        }
        let extractor = try executableURL(
            options["--extractor"] ?? "",
            code: "symbolgraph.extractor-executable",
            noun: "Symbol graph extractor"
        )
        let outputDirectory = try directoryURL(
            options["--output"] ?? "",
            code: "symbolgraph.extractor-output-directory",
            noun: "Symbol graph output directory"
        )
        let sdkPath = try options["--sdk"].map {
            try directoryURL(
                $0,
                code: "symbolgraph.extractor-sdk",
                noun: "SDK directory"
            ).path
        }
        var extraArguments: [String] = []
        if let path = options["--swift-module-path"] {
            let directory = try directoryURL(
                path,
                code: "symbolgraph.extractor-swift-module-path",
                noun: "Swift module path"
            )
            extraArguments += ["-I", directory.path]
        }
        if let path = options["--clang-module-path"] {
            let directory = try directoryURL(
                path,
                code: "symbolgraph.extractor-clang-module-path",
                noun: "Clang module path"
            )
            extraArguments += ["-I", directory.path]
        }
        let moduleName = options["--module"] ?? ""
        _ = try SymbolGraphExtractor(executableURL: extractor).extract(
            SymbolGraphExtractionRequest(
                moduleName: moduleName,
                targetTriple: options["--target"] ?? "",
                sdkPath: sdkPath,
                outputDirectory: outputDirectory,
                emitExtensionBlockSymbols: true,
                extraArguments: extraArguments
            )
        )
        return CommandResult(
            exitCode: 0,
            standardOutput: "Extracted symbol graphs for \(moduleName) to \(outputDirectory.path)\n",
            standardError: ""
        )
    }

    func runCompare(_ arguments: [String]) throws -> CommandResult {
        guard let options = parseOptions(
            arguments,
            allowed: ["--current", "--reference"],
            required: ["--current", "--reference"]
        ) else {
            return usageFailure()
        }
        let codec = SnapshotCodec()
        let reference = try codec.load(
            from: URL(fileURLWithPath: options["--reference"] ?? "")
        )
        let current = try codec.load(
            from: URL(fileURLWithPath: options["--current"] ?? "")
        )
        let comparison = try SnapshotComparator().compare(reference: reference, current: current)
        guard comparison.hasChanges else {
            return CommandResult(
                exitCode: 0,
                standardOutput: "No API changes for \(comparison.moduleName).\n",
                standardError: ""
            )
        }
        let report = try ComparisonCodec().encode(comparison)
        guard let output = String(data: report, encoding: .utf8) else {
            throw APICheckDiagnostic(
                code: "comparison.encoding",
                message: "Unable to encode API comparison"
            )
        }
        return CommandResult(
            exitCode: 1,
            standardOutput: output,
            standardError: "API changes detected for \(comparison.moduleName).\n"
        )
    }

    func runValidateManifest(_ arguments: [String]) throws -> CommandResult {
        let optionNames: Set<String> = [
            "--contracts",
            "--manifest",
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
        let manifest = try ManifestLoader().load(
            from: URL(fileURLWithPath: options["--manifest"] ?? "")
        )
        let setLoader = APISnapshotSetLoader()
        let referenceSet = try setLoader.load(
            descriptorAt: URL(fileURLWithPath: options["--reference-set"] ?? "")
        )
        let tuikitSet = try setLoader.load(
            descriptorAt: URL(fileURLWithPath: options["--tuikit-set"] ?? "")
        )
        let registry = try ContractRegistryCodec().load(
            from: URL(fileURLWithPath: options["--contracts"] ?? "")
        )
        let diagnostics = (
            ManifestValidator().validate(manifest)
                + CompatibilitySurfaceValidator().validate(
                    manifest,
                    referenceSet: referenceSet,
                    tuikitSet: tuikitSet
                )
                + CompatibilityEvidenceValidator().validate(
                    manifest,
                    referenceSet: referenceSet,
                    tuikitSet: tuikitSet
                )
                + CompatibilityContractLinkValidator().validate(
                    manifest,
                    registry: registry
                )
        ).sorted()
        guard diagnostics.isEmpty else {
            return diagnosticFailure(diagnostics)
        }
        return CommandResult(
            exitCode: 0,
            standardOutput: "Compatibility manifest is valid.\n",
            standardError: ""
        )
    }

    func runValidateManifestSchema(_ arguments: [String]) throws -> CommandResult {
        guard let options = parseOptions(
            arguments,
            allowed: ["--manifest"],
            required: ["--manifest"]
        ) else {
            return usageFailure()
        }
        let manifest = try ManifestLoader().load(
            from: URL(fileURLWithPath: options["--manifest"] ?? "")
        )
        let diagnostics = ManifestValidator().validate(manifest)
        guard diagnostics.isEmpty else {
            return diagnosticFailure(diagnostics)
        }
        return CommandResult(
            exitCode: 0,
            standardOutput: "Compatibility manifest schema is valid.\n",
            standardError: ""
        )
    }

    func runWriteSnapshotSet(_ arguments: [String]) throws -> CommandResult {
        let optionNames: Set<String> = ["--coverage", "--name", "--output", "--sources"]
        guard let options = parseOptions(
            arguments,
            allowed: optionNames,
            required: optionNames
        ) else {
            return usageFailure()
        }
        let sourceListURL = URL(fileURLWithPath: options["--sources"] ?? "")
        let coverageListURL = URL(fileURLWithPath: options["--coverage"] ?? "")
        let outputURL = URL(fileURLWithPath: options["--output"] ?? "")
        let sources = try SnapshotSetSourceListLoader().load(from: sourceListURL)
        let requiredCoverage = try SnapshotSetCoverageListLoader().load(from: coverageListURL)
        try SnapshotSetDescriptorCodec().write(
            APISnapshotSetDescriptor(
                schemaVersion: 2,
                name: options["--name"] ?? "",
                requiredCoverage: requiredCoverage,
                sources: sources
            ),
            to: outputURL
        )
        return CommandResult(
            exitCode: 0,
            standardOutput: "Wrote snapshot set with \(sources.count) sources to \(outputURL.path)\n",
            standardError: ""
        )
    }

    func extensionProvenanceMode(_ value: String) throws -> ExtensionProvenanceMode {
        switch value {
        case "disabled":
            return .disabled
        case "strict":
            return .strict
        default:
            throw APICheckDiagnostic(
                code: "symbolgraph.extension-provenance-mode",
                message: "Extension provenance must be 'strict' or 'disabled'"
            )
        }
    }
}

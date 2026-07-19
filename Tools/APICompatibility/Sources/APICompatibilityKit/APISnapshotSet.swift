import Foundation

public struct APISnapshotSetDescriptor: Codable, Equatable, Sendable {
    public var schemaVersion: Int
    public var name: String
    public var requiredCoverage: [APISnapshotCoverageRequirement]
    public var sources: [APISnapshotSetSourceDescriptor]

    public init(
        schemaVersion: Int,
        name: String,
        requiredCoverage: [APISnapshotCoverageRequirement],
        sources: [APISnapshotSetSourceDescriptor]
    ) {
        self.schemaVersion = schemaVersion
        self.name = name
        self.requiredCoverage = requiredCoverage
        self.sources = sources
    }
}

public struct APISnapshotCoverageRequirement: Codable, Equatable, Hashable, Sendable {
    public var moduleName: String
    public var platform: String

    public init(moduleName: String, platform: String) {
        self.moduleName = moduleName
        self.platform = platform
    }
}

public struct APISnapshotSetSourceDescriptor: Codable, Equatable, Sendable {
    public var id: String
    public var moduleName: String
    public var platform: String
    public var targetTriple: String
    public var sdkName: String
    public var sdkVersion: String
    public var sdkBuild: String
    public var compilerVersion: String
    public var snapshotPath: String

    public init(
        id: String,
        moduleName: String,
        platform: String,
        targetTriple: String,
        sdkName: String,
        sdkVersion: String,
        sdkBuild: String,
        compilerVersion: String,
        snapshotPath: String
    ) {
        self.id = id
        self.moduleName = moduleName
        self.platform = platform
        self.targetTriple = targetTriple
        self.sdkName = sdkName
        self.sdkVersion = sdkVersion
        self.sdkBuild = sdkBuild
        self.compilerVersion = compilerVersion
        self.snapshotPath = snapshotPath
    }
}

public struct LoadedAPISnapshotSetSource: Equatable, Sendable {
    public let source: APISnapshotSetSourceDescriptor
    public let snapshot: APISnapshot

    public init(source: APISnapshotSetSourceDescriptor, snapshot: APISnapshot) {
        self.source = source
        self.snapshot = snapshot
    }
}

public struct APISnapshotSymbolOccurrence: Equatable, Sendable {
    public let source: APISnapshotSetSourceDescriptor
    public let symbol: CanonicalSymbol

    public init(source: APISnapshotSetSourceDescriptor, symbol: CanonicalSymbol) {
        self.source = source
        self.symbol = symbol
    }
}

public struct APISnapshotSet: Sendable {
    public let descriptor: APISnapshotSetDescriptor
    public let sources: [LoadedAPISnapshotSetSource]
    public let unionPreciseIdentifiers: [String]
    public let moduleNames: [String]

    private let occurrencesByIdentifier: [String: [APISnapshotSymbolOccurrence]]

    init(
        descriptor: APISnapshotSetDescriptor,
        sources: [LoadedAPISnapshotSetSource]
    ) throws {
        guard sources.map(\.source) == descriptor.sources else {
            throw APICheckDiagnostic(
                code: "snapshotset.runtime-source-mismatch",
                message: "Loaded sources do not match the snapshot set descriptor"
            )
        }

        var sourceIDs: Set<String> = []
        var sourceSymbolMappings: Set<SourceSymbolMapping> = []
        var occurrences: [String: [APISnapshotSymbolOccurrence]] = [:]
        for loadedSource in sources {
            guard sourceIDs.insert(loadedSource.source.id).inserted else {
                throw APICheckDiagnostic(
                    code: "snapshotset.duplicate-source-id",
                    message: "Duplicate source ID '\(loadedSource.source.id)'"
                )
            }
            guard loadedSource.source.moduleName == loadedSource.snapshot.moduleName else {
                throw APICheckDiagnostic(
                    code: "snapshotset.module-mismatch",
                    message: "Source '\(loadedSource.source.id)' expected module '\(loadedSource.source.moduleName)'"
                )
            }
            try validateSnapshotProvenance(
                loadedSource.snapshot.provenance,
                source: loadedSource.source
            )
            for symbol in loadedSource.snapshot.symbols {
                let mapping = SourceSymbolMapping(
                    sourceID: loadedSource.source.id,
                    preciseIdentifier: symbol.preciseIdentifier
                )
                guard sourceSymbolMappings.insert(mapping).inserted else {
                    throw APICheckDiagnostic(
                        code: "snapshotset.duplicate-source-symbol",
                        message: "Source '\(loadedSource.source.id)' maps '\(symbol.preciseIdentifier)' more than once"
                    )
                }
                occurrences[symbol.preciseIdentifier, default: []].append(
                    APISnapshotSymbolOccurrence(source: loadedSource.source, symbol: symbol)
                )
            }
        }

        self.descriptor = descriptor
        self.sources = sources
        self.unionPreciseIdentifiers = occurrences.keys.sorted()
        self.moduleNames = Set(sources.map { $0.snapshot.moduleName }).sorted()
        self.occurrencesByIdentifier = occurrences
    }

    public func contains(_ preciseIdentifier: String) -> Bool {
        occurrencesByIdentifier[preciseIdentifier] != nil
    }

    public func occurrences(for preciseIdentifier: String) -> [APISnapshotSymbolOccurrence] {
        occurrencesByIdentifier[preciseIdentifier] ?? []
    }
}

public struct SnapshotSetDescriptorCodec: Sendable {
    public init() {}

    public func encode(_ descriptor: APISnapshotSetDescriptor) throws -> Data {
        try SnapshotSetDescriptorValidator().validate(descriptor)
        return try JSONArtifactCodec.encode(descriptor)
    }

    public func write(_ descriptor: APISnapshotSetDescriptor, to url: URL) throws {
        let data = try encode(descriptor)
        do {
            try FileManager.default.createDirectory(
                at: url.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            try data.write(to: url, options: .atomic)
        } catch {
            throw APICheckDiagnostic(
                code: "snapshotset.write-failed",
                message: "Unable to write \(url.lastPathComponent)"
            )
        }
    }

    public func load(from url: URL) throws -> APISnapshotSetDescriptor {
        let descriptor: APISnapshotSetDescriptor
        do {
            let data = try Data(contentsOf: url)
            descriptor = try JSONDecoder().decode(APISnapshotSetDescriptor.self, from: data)
        } catch {
            throw APICheckDiagnostic(
                code: "snapshotset.invalid-json",
                message: "\(url.lastPathComponent) is not a valid snapshot set descriptor"
            )
        }
        try SnapshotSetDescriptorValidator().validate(descriptor)
        return descriptor
    }
}

public struct APISnapshotSetLoader: Sendable {
    public init() {}

    public func load(descriptorAt descriptorURL: URL) throws -> APISnapshotSet {
        let descriptor = try SnapshotSetDescriptorCodec().load(from: descriptorURL)
        let descriptorDirectory = descriptorURL
            .deletingLastPathComponent()
            .standardizedFileURL
            .resolvingSymlinksInPath()
        var loadedSources: [LoadedAPISnapshotSetSource] = []
        for source in descriptor.sources {
            let snapshotURL = try resolvedSnapshotURL(
                path: source.snapshotPath,
                descriptorDirectory: descriptorDirectory
            )
            var isDirectory: ObjCBool = false
            guard FileManager.default.fileExists(
                atPath: snapshotURL.path,
                isDirectory: &isDirectory
            ), !isDirectory.boolValue else {
                throw APICheckDiagnostic(
                    code: "snapshotset.missing-source",
                    message: "Snapshot source '\(source.id)' is missing"
                )
            }
            let snapshot = try SnapshotCodec().load(from: snapshotURL)
            guard snapshot.moduleName == source.moduleName else {
                throw APICheckDiagnostic(
                    code: "snapshotset.module-mismatch",
                    message: "Source '\(source.id)' declares module '\(snapshot.moduleName)'; expected '\(source.moduleName)'"
                )
            }
            try validateSnapshotProvenance(snapshot.provenance, source: source)
            loadedSources.append(
                LoadedAPISnapshotSetSource(source: source, snapshot: snapshot)
            )
        }
        return try APISnapshotSet(descriptor: descriptor, sources: loadedSources)
    }

    private func resolvedSnapshotURL(
        path: String,
        descriptorDirectory: URL
    ) throws -> URL {
        let candidate = descriptorDirectory
            .appendingPathComponent(path)
            .standardizedFileURL
            .resolvingSymlinksInPath()
        let directoryComponents = descriptorDirectory.pathComponents
        let candidateComponents = candidate.pathComponents
        guard candidateComponents.count > directoryComponents.count,
              candidateComponents.starts(with: directoryComponents)
        else {
            throw APICheckDiagnostic(
                code: "snapshotset.source-path-escape",
                message: "Snapshot path escapes the descriptor directory"
            )
        }
        return candidate
    }
}

private struct SnapshotSetDescriptorValidator: Sendable {
    func validate(_ descriptor: APISnapshotSetDescriptor) throws {
        guard descriptor.schemaVersion == 2 else {
            throw APICheckDiagnostic(
                code: "snapshotset.schema-version",
                message: "Unsupported snapshot set schema version \(descriptor.schemaVersion)"
            )
        }
        guard !descriptor.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw APICheckDiagnostic(
                code: "snapshotset.empty-name",
                message: "Snapshot set has an empty name"
            )
        }
        guard !descriptor.sources.isEmpty else {
            throw APICheckDiagnostic(
                code: "snapshotset.empty-sources",
                message: "Snapshot set has no sources"
            )
        }
        guard !descriptor.requiredCoverage.isEmpty else {
            throw APICheckDiagnostic(
                code: "snapshotset.empty-required-coverage",
                message: "Snapshot set has no required coverage"
            )
        }
        try validateRequiredCoverage(descriptor.requiredCoverage)

        var sourceIDs: Set<String> = []
        var snapshotPaths: Set<String> = []
        var metadata: Set<SourceMetadataIdentity> = []
        for source in descriptor.sources {
            try validateMetadata(source)
            try validatePath(source.snapshotPath)
            guard sourceIDs.insert(source.id).inserted else {
                throw APICheckDiagnostic(
                    code: "snapshotset.duplicate-source-id",
                    message: "Duplicate source ID '\(source.id)'"
                )
            }
            guard snapshotPaths.insert(source.snapshotPath).inserted else {
                throw APICheckDiagnostic(
                    code: "snapshotset.duplicate-source-path",
                    message: "Duplicate snapshot path '\(source.snapshotPath)'"
                )
            }
            guard metadata.insert(SourceMetadataIdentity(source)).inserted else {
                throw APICheckDiagnostic(
                    code: "snapshotset.duplicate-source-metadata",
                    message: "Source '\(source.id)' duplicates extraction metadata"
                )
            }
        }
        guard descriptor.sources.map(\.id) == descriptor.sources.map(\.id).sorted() else {
            throw APICheckDiagnostic(
                code: "snapshotset.noncanonical-source-order",
                message: "Snapshot sources are not sorted by ID"
            )
        }
        try validateCoverageSources(descriptor)
    }

    private func validateRequiredCoverage(
        _ coverage: [APISnapshotCoverageRequirement]
    ) throws {
        var seen: Set<APISnapshotCoverageRequirement> = []
        for requirement in coverage {
            let moduleName = requirement.moduleName.trimmingCharacters(in: .whitespacesAndNewlines)
            let platform = requirement.platform.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !moduleName.isEmpty,
                  !platform.isEmpty,
                  moduleName == requirement.moduleName,
                  platform == requirement.platform
            else {
                throw APICheckDiagnostic(
                    code: "snapshotset.empty-coverage-metadata",
                    message: "Snapshot coverage contains empty or padded metadata"
                )
            }
            guard seen.insert(requirement).inserted else {
                throw APICheckDiagnostic(
                    code: "snapshotset.duplicate-coverage",
                    message: "Duplicate required coverage for '\(requirement.moduleName)/\(requirement.platform)'"
                )
            }
        }
        let sorted = coverage.sorted(by: compareCoverage)
        guard coverage == sorted else {
            throw APICheckDiagnostic(
                code: "snapshotset.noncanonical-coverage-order",
                message: "Required snapshot coverage is not sorted by module and platform"
            )
        }
    }

    private func validateCoverageSources(_ descriptor: APISnapshotSetDescriptor) throws {
        let expected = Set(descriptor.requiredCoverage)
        let actual = Set(descriptor.sources.map {
            APISnapshotCoverageRequirement(
                moduleName: $0.moduleName,
                platform: $0.platform
            )
        })
        if let missing = expected.subtracting(actual).min(by: compareCoverage) {
            throw APICheckDiagnostic(
                code: "snapshotset.coverage-source-missing",
                message: "Required snapshot source '\(missing.moduleName)/\(missing.platform)' is missing"
            )
        }
        if let unexpected = actual.subtracting(expected).min(by: compareCoverage) {
            throw APICheckDiagnostic(
                code: "snapshotset.coverage-source-unexpected",
                message: "Snapshot source '\(unexpected.moduleName)/\(unexpected.platform)' is not declared in required coverage"
            )
        }
    }

    private func compareCoverage(
        _ lhs: APISnapshotCoverageRequirement,
        _ rhs: APISnapshotCoverageRequirement
    ) -> Bool {
        if lhs.moduleName != rhs.moduleName {
            return lhs.moduleName < rhs.moduleName
        }
        return lhs.platform < rhs.platform
    }

    private func validateMetadata(_ source: APISnapshotSetSourceDescriptor) throws {
        let values = [
            ("id", source.id),
            ("moduleName", source.moduleName),
            ("platform", source.platform),
            ("targetTriple", source.targetTriple),
            ("sdkName", source.sdkName),
            ("sdkVersion", source.sdkVersion),
            ("sdkBuild", source.sdkBuild),
            ("compilerVersion", source.compilerVersion),
            ("snapshotPath", source.snapshotPath),
        ]
        for (field, value) in values where value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            throw APICheckDiagnostic(
                code: "snapshotset.empty-source-metadata",
                message: "Source '\(source.id)' has empty \(field) metadata"
            )
        }
    }

    private func validatePath(_ path: String) throws {
        let components = path.split(separator: "/", omittingEmptySubsequences: false)
        let bytes = Array(path.utf8)
        let hasWindowsDrivePrefix = bytes.count >= 3
            && ((65 ... 90).contains(bytes[0]) || (97 ... 122).contains(bytes[0]))
            && bytes[1] == 58
            && bytes[2] == 47
        guard !path.hasPrefix("/"),
              !path.hasPrefix("~"),
              !path.contains("\\"),
              !hasWindowsDrivePrefix,
              components.allSatisfy({ !$0.isEmpty && $0 != "." && $0 != ".." })
        else {
            throw APICheckDiagnostic(
                code: "snapshotset.invalid-source-path",
                message: "Snapshot paths must be canonical paths relative to the descriptor"
            )
        }
    }
}

private func validateSnapshotProvenance(
    _ provenance: APISnapshotProvenance,
    source: APISnapshotSetSourceDescriptor
) throws {
    var fields: [String] = []
    if provenance.platform != source.platform { fields.append("platform") }
    if provenance.targetTriple != source.targetTriple { fields.append("targetTriple") }
    if provenance.sdkName != source.sdkName { fields.append("sdkName") }
    if provenance.sdkVersion != source.sdkVersion { fields.append("sdkVersion") }
    if provenance.sdkBuild != source.sdkBuild { fields.append("sdkBuild") }
    if provenance.compilerVersion != source.compilerVersion { fields.append("compilerVersion") }
    guard fields.isEmpty else {
        throw APICheckDiagnostic(
            code: "snapshotset.provenance-mismatch",
            message: "Source '\(source.id)' snapshot provenance differs in: \(fields.joined(separator: ", "))"
        )
    }
}

private struct SourceMetadataIdentity: Hashable {
    let moduleName: String
    let platform: String
    let targetTriple: String
    let sdkName: String
    let sdkVersion: String
    let sdkBuild: String
    let compilerVersion: String

    init(_ source: APISnapshotSetSourceDescriptor) {
        self.moduleName = source.moduleName
        self.platform = source.platform
        self.targetTriple = source.targetTriple
        self.sdkName = source.sdkName
        self.sdkVersion = source.sdkVersion
        self.sdkBuild = source.sdkBuild
        self.compilerVersion = source.compilerVersion
    }
}

private struct SourceSymbolMapping: Hashable {
    let sourceID: String
    let preciseIdentifier: String
}

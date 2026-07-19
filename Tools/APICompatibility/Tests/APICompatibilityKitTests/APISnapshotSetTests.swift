import Foundation
import Testing

@testable import APICompatibilityKit

@Suite("API snapshot sets")
struct APISnapshotSetTests {
    @Test("Descriptor codec is deterministic and round-trips ordered sources")
    func descriptorCodecRoundTrip() throws {
        let descriptor = APISnapshotSetDescriptor(
            schemaVersion: 2,
            name: "SwiftUI current SDK",
            requiredCoverage: [
                coverage(moduleName: "SwiftUI", platform: "iOS"),
                coverage(moduleName: "SwiftUI", platform: "macOS"),
            ],
            sources: [
                source(id: "swiftui-ios", platform: "iOS", snapshotPath: "snapshots/ios.json"),
                source(id: "swiftui-macos", platform: "macOS", snapshotPath: "snapshots/macos.json"),
            ]
        )
        let codec = SnapshotSetDescriptorCodec()
        let directory = try FixtureSupport.temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let descriptorURL = directory.appendingPathComponent("swiftui.snapshot-set.json")

        let first = try codec.encode(descriptor)
        let second = try codec.encode(descriptor)
        try codec.write(descriptor, to: descriptorURL)

        #expect(first == second)
        #expect(first.last == 0x0A)
        #expect(try Data(contentsOf: descriptorURL) == first)
        #expect(try codec.load(from: descriptorURL) == descriptor)
    }

    @Test("Descriptor validation rejects empty metadata")
    func rejectsEmptyMetadata() throws {
        var descriptor = validDescriptor()
        descriptor.name = " \n"
        #expect(descriptorDiagnostic(descriptor)?.code == "snapshotset.empty-name")

        descriptor = validDescriptor()
        descriptor.sources = []
        #expect(descriptorDiagnostic(descriptor)?.code == "snapshotset.empty-sources")

        #expect(sourceDiagnostic { $0.id = " " }?.code == "snapshotset.empty-source-metadata")
        #expect(sourceDiagnostic { $0.moduleName = "\t" }?.code == "snapshotset.empty-source-metadata")
        #expect(sourceDiagnostic { $0.platform = "\n" }?.code == "snapshotset.empty-source-metadata")
        #expect(sourceDiagnostic { $0.targetTriple = " " }?.code == "snapshotset.empty-source-metadata")
        #expect(sourceDiagnostic { $0.sdkName = "\t" }?.code == "snapshotset.empty-source-metadata")
        #expect(sourceDiagnostic { $0.sdkVersion = " " }?.code == "snapshotset.empty-source-metadata")
        #expect(sourceDiagnostic { $0.sdkBuild = "\n" }?.code == "snapshotset.empty-source-metadata")
        #expect(sourceDiagnostic { $0.compilerVersion = " " }?.code == "snapshotset.empty-source-metadata")
        #expect(sourceDiagnostic { $0.snapshotPath = "\t" }?.code == "snapshotset.empty-source-metadata")
    }

    @Test("Descriptor validation rejects duplicate and noncanonical sources")
    func rejectsDuplicateAndUnsortedSources() {
        let duplicateID = APISnapshotSetDescriptor(
            schemaVersion: 2,
            name: "Duplicate IDs",
            requiredCoverage: [
                coverage(moduleName: "SwiftUI", platform: "iOS"),
                coverage(moduleName: "SwiftUI", platform: "macOS"),
            ],
            sources: [
                source(id: "same", platform: "iOS", snapshotPath: "snapshots/ios.json"),
                source(id: "same", platform: "macOS", snapshotPath: "snapshots/macos.json"),
            ]
        )
        #expect(descriptorDiagnostic(duplicateID)?.code == "snapshotset.duplicate-source-id")

        let duplicatePath = APISnapshotSetDescriptor(
            schemaVersion: 2,
            name: "Duplicate paths",
            requiredCoverage: [
                coverage(moduleName: "SwiftUI", platform: "iOS"),
                coverage(moduleName: "SwiftUI", platform: "macOS"),
            ],
            sources: [
                source(id: "source-a", platform: "iOS", snapshotPath: "snapshots/shared.json"),
                source(id: "source-b", platform: "macOS", snapshotPath: "snapshots/shared.json"),
            ]
        )
        #expect(descriptorDiagnostic(duplicatePath)?.code == "snapshotset.duplicate-source-path")

        let duplicateMetadata = APISnapshotSetDescriptor(
            schemaVersion: 2,
            name: "Duplicate metadata",
            requiredCoverage: [coverage(moduleName: "SwiftUI", platform: "macOS")],
            sources: [
                source(id: "source-a", snapshotPath: "snapshots/a.json"),
                source(id: "source-b", snapshotPath: "snapshots/b.json"),
            ]
        )
        #expect(descriptorDiagnostic(duplicateMetadata)?.code == "snapshotset.duplicate-source-metadata")

        let unsorted = APISnapshotSetDescriptor(
            schemaVersion: 2,
            name: "Unsorted",
            requiredCoverage: [
                coverage(moduleName: "SwiftUI", platform: "iOS"),
                coverage(moduleName: "SwiftUI", platform: "macOS"),
            ],
            sources: [
                source(id: "z-source", platform: "macOS", snapshotPath: "snapshots/z.json"),
                source(id: "a-source", platform: "iOS", snapshotPath: "snapshots/a.json"),
            ]
        )
        #expect(descriptorDiagnostic(unsorted)?.code == "snapshotset.noncanonical-source-order")
    }

    @Test("Descriptor validation rejects invalid or incomplete required coverage")
    func rejectsInvalidRequiredCoverage() {
        var descriptor = validDescriptor()
        descriptor.requiredCoverage = []
        #expect(descriptorDiagnostic(descriptor)?.code == "snapshotset.empty-required-coverage")

        descriptor = validDescriptor()
        descriptor.requiredCoverage[0].moduleName = " "
        #expect(descriptorDiagnostic(descriptor)?.code == "snapshotset.empty-coverage-metadata")

        descriptor = validDescriptor()
        descriptor.requiredCoverage.append(descriptor.requiredCoverage[0])
        #expect(descriptorDiagnostic(descriptor)?.code == "snapshotset.duplicate-coverage")

        descriptor = APISnapshotSetDescriptor(
            schemaVersion: 2,
            name: "Unsorted coverage",
            requiredCoverage: [
                coverage(moduleName: "SwiftUI", platform: "macOS"),
                coverage(moduleName: "SwiftUI", platform: "iOS"),
            ],
            sources: [
                source(id: "swiftui-ios", platform: "iOS", snapshotPath: "snapshots/ios.json"),
                source(id: "swiftui-macos", platform: "macOS", snapshotPath: "snapshots/macos.json"),
            ]
        )
        #expect(descriptorDiagnostic(descriptor)?.code == "snapshotset.noncanonical-coverage-order")

        descriptor = validDescriptor()
        descriptor.requiredCoverage.append(coverage(moduleName: "SwiftUI", platform: "zOS"))
        #expect(descriptorDiagnostic(descriptor)?.code == "snapshotset.coverage-source-missing")

        descriptor = validDescriptor()
        descriptor.sources.insert(
            source(id: "swiftui-ios", platform: "iOS", snapshotPath: "snapshots/ios.json"),
            at: 0
        )
        #expect(descriptorDiagnostic(descriptor)?.code == "snapshotset.coverage-source-unexpected")
    }

    @Test("Descriptor validation rejects unsupported schemas and unsafe lexical paths")
    func rejectsSchemaAndUnsafePaths() {
        var descriptor = validDescriptor()
        descriptor.schemaVersion = 1
        #expect(descriptorDiagnostic(descriptor)?.code == "snapshotset.schema-version")

        #expect(sourceDiagnostic { $0.snapshotPath = "/tmp/absolute.json" }?.code == "snapshotset.invalid-source-path")
        #expect(sourceDiagnostic { $0.snapshotPath = "../outside.json" }?.code == "snapshotset.invalid-source-path")
        #expect(sourceDiagnostic { $0.snapshotPath = "snapshots/./current.json" }?.code == "snapshotset.invalid-source-path")
        #expect(sourceDiagnostic { $0.snapshotPath = "snapshots\\current.json" }?.code == "snapshotset.invalid-source-path")
    }

    @Test("Descriptor codec rejects malformed JSON")
    func rejectsMalformedDescriptor() throws {
        let directory = try FixtureSupport.temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let descriptorURL = directory.appendingPathComponent("invalid.json")
        try Data("{not-json".utf8).write(to: descriptorURL)

        let diagnostic = FixtureSupport.diagnostic {
            try SnapshotSetDescriptorCodec().load(from: descriptorURL)
        }

        #expect(diagnostic?.code == "snapshotset.invalid-json")
    }

    @Test("Loader rejects missing snapshots and module mismatches")
    func rejectsMissingSourceAndModuleMismatch() throws {
        let missingDirectory = try FixtureSupport.temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: missingDirectory) }
        let missingDescriptorURL = missingDirectory.appendingPathComponent("set.json")
        try SnapshotSetDescriptorCodec().write(validDescriptor(), to: missingDescriptorURL)

        let missingDiagnostic = FixtureSupport.diagnostic {
            try APISnapshotSetLoader().load(descriptorAt: missingDescriptorURL)
        }
        #expect(missingDiagnostic?.code == "snapshotset.missing-source")

        let mismatchDirectory = try FixtureSupport.temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: mismatchDirectory) }
        let mismatchDescriptorURL = mismatchDirectory.appendingPathComponent("set.json")
        try writeSnapshot(
            source: source(id: "unexpected-module"),
            moduleName: "Unexpected",
            symbolIDs: ["s:Unexpected.Text"],
            to: mismatchDirectory.appendingPathComponent("snapshots/current.json")
        )
        try SnapshotSetDescriptorCodec().write(validDescriptor(), to: mismatchDescriptorURL)

        let mismatchDiagnostic = FixtureSupport.diagnostic {
            try APISnapshotSetLoader().load(descriptorAt: mismatchDescriptorURL)
        }
        #expect(mismatchDiagnostic?.code == "snapshotset.module-mismatch")
    }

    @Test("Loader binds platform and toolchain provenance exactly")
    func rejectsProvenanceMismatch() throws {
        let directory = try FixtureSupport.temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let descriptor = validDescriptor()
        let descriptorURL = directory.appendingPathComponent("set.json")
        let snapshotURL = directory.appendingPathComponent("snapshots/current.json")
        var snapshotProvenance = provenance(for: descriptor.sources[0])
        snapshotProvenance.platform = "Linux"
        try writeSnapshot(
            moduleName: "SwiftUI",
            provenance: snapshotProvenance,
            symbolIDs: ["s:SwiftUI.Text"],
            to: snapshotURL
        )
        try SnapshotSetDescriptorCodec().write(descriptor, to: descriptorURL)

        let platformDiagnostic = FixtureSupport.diagnostic {
            try APISnapshotSetLoader().load(descriptorAt: descriptorURL)
        }

        #expect(platformDiagnostic?.code == "snapshotset.provenance-mismatch")
        #expect(platformDiagnostic?.message.contains("platform") == true)

        snapshotProvenance = provenance(for: descriptor.sources[0])
        snapshotProvenance.compilerVersion = "Swift 6.0.3"
        try writeSnapshot(
            moduleName: "SwiftUI",
            provenance: snapshotProvenance,
            symbolIDs: ["s:SwiftUI.Text"],
            to: snapshotURL
        )

        let compilerDiagnostic = FixtureSupport.diagnostic {
            try APISnapshotSetLoader().load(descriptorAt: descriptorURL)
        }

        #expect(compilerDiagnostic?.code == "snapshotset.provenance-mismatch")
        #expect(compilerDiagnostic?.message.contains("compilerVersion") == true)
    }

    @Test("Loader rejects a symlink that escapes the descriptor directory")
    func rejectsSymlinkEscape() throws {
        let descriptorDirectory = try FixtureSupport.temporaryDirectory()
        let outsideDirectory = try FixtureSupport.temporaryDirectory()
        defer {
            try? FileManager.default.removeItem(at: descriptorDirectory)
            try? FileManager.default.removeItem(at: outsideDirectory)
        }
        let outsideSource = source(id: "swiftui-macos")
        try writeSnapshot(
            source: outsideSource,
            moduleName: "SwiftUI",
            symbolIDs: ["s:SwiftUI.Text"],
            to: outsideDirectory.appendingPathComponent("outside.json")
        )
        try FileManager.default.createSymbolicLink(
            at: descriptorDirectory.appendingPathComponent("linked"),
            withDestinationURL: outsideDirectory
        )
        var descriptor = validDescriptor()
        descriptor.sources[0].snapshotPath = "linked/outside.json"
        let descriptorURL = descriptorDirectory.appendingPathComponent("set.json")
        try SnapshotSetDescriptorCodec().write(descriptor, to: descriptorURL)

        let diagnostic = FixtureSupport.diagnostic {
            try APISnapshotSetLoader().load(descriptorAt: descriptorURL)
        }

        #expect(diagnostic?.code == "snapshotset.source-path-escape")
    }

    @Test("Runtime set unions identical SwiftUI IDs across platforms")
    func unionsIDsAcrossPlatforms() throws {
        let directory = try FixtureSupport.temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let identifier = "s:SwiftUI.Text"
        let descriptor = APISnapshotSetDescriptor(
            schemaVersion: 2,
            name: "SwiftUI platform union",
            requiredCoverage: [
                coverage(moduleName: "SwiftUI", platform: "iOS"),
                coverage(moduleName: "SwiftUI", platform: "macOS"),
            ],
            sources: [
                source(id: "swiftui-ios", platform: "iOS", snapshotPath: "snapshots/ios.json"),
                source(id: "swiftui-macos", platform: "macOS", snapshotPath: "snapshots/macos.json"),
            ]
        )
        try writeSnapshot(
            source: descriptor.sources[0],
            moduleName: "SwiftUI",
            symbolIDs: [identifier],
            to: directory.appendingPathComponent("snapshots/ios.json")
        )
        try writeSnapshot(
            source: descriptor.sources[1],
            moduleName: "SwiftUI",
            symbolIDs: [identifier],
            to: directory.appendingPathComponent("snapshots/macos.json")
        )
        let descriptorURL = directory.appendingPathComponent("set.json")
        try SnapshotSetDescriptorCodec().write(descriptor, to: descriptorURL)

        let snapshotSet = try APISnapshotSetLoader().load(descriptorAt: descriptorURL)
        let occurrences = snapshotSet.occurrences(for: identifier)

        #expect(snapshotSet.unionPreciseIdentifiers == [identifier])
        #expect(snapshotSet.contains(identifier))
        #expect(occurrences.map { $0.source.id } == ["swiftui-ios", "swiftui-macos"])
        #expect(occurrences.map { $0.source.platform } == ["iOS", "macOS"])
    }

    @Test("Runtime set supports multiple TUIkit modules")
    func supportsMultipleModules() throws {
        let directory = try FixtureSupport.temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let descriptor = APISnapshotSetDescriptor(
            schemaVersion: 2,
            name: "TUIkit modules",
            requiredCoverage: [
                coverage(moduleName: "TUIkit", platform: "Linux"),
                coverage(moduleName: "TUIkitCore", platform: "Linux"),
            ],
            sources: [
                source(
                    id: "tuikit-core",
                    moduleName: "TUIkitCore",
                    platform: "Linux",
                    snapshotPath: "snapshots/core.json"
                ),
                source(
                    id: "tuikit-main",
                    moduleName: "TUIkit",
                    platform: "Linux",
                    snapshotPath: "snapshots/main.json"
                ),
            ]
        )
        try writeSnapshot(
            source: descriptor.sources[0],
            moduleName: "TUIkitCore",
            symbolIDs: ["s:TUIkitCore.Size"],
            to: directory.appendingPathComponent("snapshots/core.json")
        )
        try writeSnapshot(
            source: descriptor.sources[1],
            moduleName: "TUIkit",
            symbolIDs: ["s:TUIkit.Text"],
            to: directory.appendingPathComponent("snapshots/main.json")
        )
        let descriptorURL = directory.appendingPathComponent("set.json")
        try SnapshotSetDescriptorCodec().write(descriptor, to: descriptorURL)

        let snapshotSet = try APISnapshotSetLoader().load(descriptorAt: descriptorURL)

        #expect(snapshotSet.moduleNames == ["TUIkit", "TUIkitCore"])
        #expect(snapshotSet.unionPreciseIdentifiers == ["s:TUIkit.Text", "s:TUIkitCore.Size"])
        #expect(snapshotSet.sources.map { $0.snapshot.moduleName } == ["TUIkitCore", "TUIkit"])
    }

    @Test("Runtime indexing rejects duplicate source and precise ID mappings")
    func rejectsDuplicateSourceSymbolMapping() {
        let sourceDescriptor = source(id: "swiftui-macos")
        let symbol = canonicalSymbol("s:SwiftUI.Text")
        let snapshot = APISnapshot(
            schemaVersion: 3,
            moduleName: "SwiftUI",
            provenance: provenance(for: sourceDescriptor),
            symbols: [symbol, symbol],
            relationships: []
        )
        let descriptor = APISnapshotSetDescriptor(
            schemaVersion: 2,
            name: "Invalid runtime set",
            requiredCoverage: [coverage(moduleName: "SwiftUI", platform: "macOS")],
            sources: [sourceDescriptor]
        )

        let diagnostic = FixtureSupport.diagnostic {
            try APISnapshotSet(
                descriptor: descriptor,
                sources: [LoadedAPISnapshotSetSource(source: sourceDescriptor, snapshot: snapshot)]
            )
        }

        #expect(diagnostic?.code == "snapshotset.duplicate-source-symbol")
    }
}

private extension APISnapshotSetTests {
    func validDescriptor() -> APISnapshotSetDescriptor {
        APISnapshotSetDescriptor(
            schemaVersion: 2,
            name: "Current SwiftUI",
            requiredCoverage: [coverage(moduleName: "SwiftUI", platform: "macOS")],
            sources: [source(id: "swiftui-macos")]
        )
    }

    func source(
        id: String,
        moduleName: String = "SwiftUI",
        platform: String = "macOS",
        snapshotPath: String = "snapshots/current.json"
    ) -> APISnapshotSetSourceDescriptor {
        APISnapshotSetSourceDescriptor(
            id: id,
            moduleName: moduleName,
            platform: platform,
            targetTriple: "arm64-apple-macosx15.0",
            sdkName: "macosx",
            sdkVersion: "26.5",
            sdkBuild: "25F90",
            compilerVersion: "Swift 6.2",
            snapshotPath: snapshotPath
        )
    }

    func sourceDiagnostic(
        mutate: (inout APISnapshotSetSourceDescriptor) -> Void
    ) -> APICheckDiagnostic? {
        var descriptor = validDescriptor()
        mutate(&descriptor.sources[0])
        return descriptorDiagnostic(descriptor)
    }

    func descriptorDiagnostic(_ descriptor: APISnapshotSetDescriptor) -> APICheckDiagnostic? {
        FixtureSupport.diagnostic {
            try SnapshotSetDescriptorCodec().encode(descriptor)
        }
    }

    func writeSnapshot(
        source: APISnapshotSetSourceDescriptor,
        moduleName: String,
        symbolIDs: [String],
        to url: URL
    ) throws {
        try writeSnapshot(
            moduleName: moduleName,
            provenance: provenance(for: source),
            symbolIDs: symbolIDs,
            to: url
        )
    }

    func writeSnapshot(
        moduleName: String,
        provenance: APISnapshotProvenance,
        symbolIDs: [String],
        to url: URL
    ) throws {
        let snapshot = APISnapshot(
            schemaVersion: 3,
            moduleName: moduleName,
            provenance: provenance,
            symbols: symbolIDs.map(canonicalSymbol),
            relationships: []
        )
        try SnapshotCodec().write(snapshot, to: url)
    }

    func coverage(
        moduleName: String,
        platform: String
    ) -> APISnapshotCoverageRequirement {
        APISnapshotCoverageRequirement(moduleName: moduleName, platform: platform)
    }

    func provenance(
        for source: APISnapshotSetSourceDescriptor
    ) -> APISnapshotProvenance {
        APISnapshotProvenance(
            platform: source.platform,
            targetTriple: source.targetTriple,
            sdkName: source.sdkName,
            sdkVersion: source.sdkVersion,
            sdkBuild: source.sdkBuild,
            compilerVersion: source.compilerVersion
        )
    }

    func canonicalSymbol(_ identifier: String) -> CanonicalSymbol {
        CanonicalSymbol(
            preciseIdentifier: identifier,
            kindIdentifier: "swift.struct",
            title: identifier,
            pathComponents: [identifier],
            canonicalDeclaration: "struct \(identifier)",
            accessLevel: "public"
        )
    }
}

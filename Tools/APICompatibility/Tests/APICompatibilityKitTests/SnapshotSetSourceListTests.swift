import Foundation
import Testing

@testable import APICompatibilityKit

@Suite("Snapshot set source lists")
struct SnapshotSetSourceListTests {
    @Test("Loads tab-separated source metadata and canonicalizes source order")
    func loadsCanonicalSourceList() throws {
        let directory = try FixtureSupport.temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let sourceList = directory.appendingPathComponent("sources.tsv")
        let lines = [
            sourceLine(id: "tuikit-linux", platform: "Linux", snapshot: "snapshots/linux.json"),
            sourceLine(id: "tuikit-macos", platform: "macOS", snapshot: "snapshots/macos.json"),
        ].reversed().joined(separator: "\n") + "\n"
        try Data(lines.utf8).write(to: sourceList)

        let sources = try SnapshotSetSourceListLoader().load(from: sourceList)

        #expect(sources.map(\.id) == ["tuikit-linux", "tuikit-macos"])
        #expect(sources[0].sdkName == "none")
        #expect(sources[1].platform == "macOS")
    }

    @Test("Rejects malformed and whitespace-padded source records")
    func rejectsInvalidSourceRecords() throws {
        let directory = try FixtureSupport.temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let malformed = directory.appendingPathComponent("malformed.tsv")
        let padded = directory.appendingPathComponent("padded.tsv")
        try Data("only\ttwo\n".utf8).write(to: malformed)
        try Data(" \(sourceLine(id: "source", platform: "Linux", snapshot: "snapshots/a.json"))\n".utf8)
            .write(to: padded)

        let malformedDiagnostic = FixtureSupport.diagnostic {
            try SnapshotSetSourceListLoader().load(from: malformed)
        }
        let paddedDiagnostic = FixtureSupport.diagnostic {
            try SnapshotSetSourceListLoader().load(from: padded)
        }

        #expect(malformedDiagnostic?.code == "snapshotset.source-list-columns")
        #expect(paddedDiagnostic?.code == "snapshotset.source-list-whitespace")
    }

    @Test("Rejects an empty source list")
    func rejectsEmptySourceList() throws {
        let directory = try FixtureSupport.temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let sourceList = directory.appendingPathComponent("empty.tsv")
        try Data().write(to: sourceList)

        let diagnostic = FixtureSupport.diagnostic {
            try SnapshotSetSourceListLoader().load(from: sourceList)
        }

        #expect(diagnostic == APICheckDiagnostic(
            code: "snapshotset.source-list-empty",
            message: "Snapshot source list contains no records"
        ))
    }

    @Test("Loads an explicit canonical coverage matrix")
    func loadsCoverageList() throws {
        let directory = try FixtureSupport.temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let coverageList = directory.appendingPathComponent("coverage.tsv")
        try Data("TUIkit\tLinux\nTUIkit\tmacOS\nTUIkitCore\tLinux\n".utf8)
            .write(to: coverageList)

        let coverage = try SnapshotSetCoverageListLoader().load(from: coverageList)

        #expect(coverage == [
            APISnapshotCoverageRequirement(moduleName: "TUIkit", platform: "Linux"),
            APISnapshotCoverageRequirement(moduleName: "TUIkit", platform: "macOS"),
            APISnapshotCoverageRequirement(moduleName: "TUIkitCore", platform: "Linux"),
        ])
    }

    @Test("Rejects malformed, duplicate, and noncanonical coverage lists")
    func rejectsInvalidCoverageList() throws {
        let directory = try FixtureSupport.temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let coverageList = directory.appendingPathComponent("coverage.tsv")

        try Data("TUIkit\n".utf8).write(to: coverageList)
        #expect(coverageDiagnostic(coverageList)?.code == "snapshotset.coverage-list-columns")

        try Data("TUIkit\t macOS\n".utf8).write(to: coverageList)
        #expect(coverageDiagnostic(coverageList)?.code == "snapshotset.coverage-list-whitespace")

        try Data("TUIkit\tmacOS\nTUIkit\tmacOS\n".utf8).write(to: coverageList)
        #expect(coverageDiagnostic(coverageList)?.code == "snapshotset.duplicate-coverage")

        try Data("TUIkit\tmacOS\nTUIkit\tLinux\n".utf8).write(to: coverageList)
        #expect(coverageDiagnostic(coverageList)?.code == "snapshotset.noncanonical-coverage-order")

        try Data().write(to: coverageList)
        #expect(coverageDiagnostic(coverageList)?.code == "snapshotset.coverage-list-empty")
    }

    private func sourceLine(id: String, platform: String, snapshot: String) -> String {
        [
            id,
            "TUIkit",
            platform,
            platform == "Linux" ? "x86_64-unknown-linux-gnu" : "arm64-apple-macosx14.0",
            platform == "Linux" ? "none" : "macosx",
            platform == "Linux" ? "none" : "26.5",
            platform == "Linux" ? "none" : "17F113",
            "Swift 6.0.3",
            snapshot,
        ].joined(separator: "\t")
    }

    private func coverageDiagnostic(_ url: URL) -> APICheckDiagnostic? {
        FixtureSupport.diagnostic {
            try SnapshotSetCoverageListLoader().load(from: url)
        }
    }
}

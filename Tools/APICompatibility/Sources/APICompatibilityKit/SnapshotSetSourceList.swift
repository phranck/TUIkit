import Foundation

public struct SnapshotSetSourceListLoader: Sendable {
    public init() {}

    public func load(from url: URL) throws -> [APISnapshotSetSourceDescriptor] {
        let contents: String
        do {
            let data = try Data(contentsOf: url)
            guard let decoded = String(data: data, encoding: .utf8) else {
                throw SourceListDecodingError.invalidUTF8
            }
            contents = decoded
        } catch {
            throw APICheckDiagnostic(
                code: "snapshotset.source-list-read",
                message: "Unable to read snapshot source list \(url.lastPathComponent)"
            )
        }

        var lines = contents
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
            .split(separator: "\n", omittingEmptySubsequences: false)
            .map(String.init)
        if lines.last?.isEmpty == true {
            lines.removeLast()
        }
        guard !lines.isEmpty else {
            throw APICheckDiagnostic(
                code: "snapshotset.source-list-empty",
                message: "Snapshot source list contains no records"
            )
        }

        return try lines.enumerated().map { index, line in
            try source(from: line, lineNumber: index + 1)
        }.sorted { $0.id < $1.id }
    }

    private func source(
        from line: String,
        lineNumber: Int
    ) throws -> APISnapshotSetSourceDescriptor {
        let fields = line.split(
            separator: "\t",
            omittingEmptySubsequences: false
        ).map(String.init)
        guard fields.count == 9 else {
            throw APICheckDiagnostic(
                code: "snapshotset.source-list-columns",
                message: "Snapshot source list line \(lineNumber) must contain 9 tab-separated fields"
            )
        }
        guard fields.allSatisfy({
            $0 == $0.trimmingCharacters(in: .whitespacesAndNewlines)
        }) else {
            throw APICheckDiagnostic(
                code: "snapshotset.source-list-whitespace",
                message: "Snapshot source list line \(lineNumber) contains padded fields"
            )
        }
        return APISnapshotSetSourceDescriptor(
            id: fields[0],
            moduleName: fields[1],
            platform: fields[2],
            targetTriple: fields[3],
            sdkName: fields[4],
            sdkVersion: fields[5],
            sdkBuild: fields[6],
            compilerVersion: fields[7],
            snapshotPath: fields[8]
        )
    }
}

public struct SnapshotSetCoverageListLoader: Sendable {
    public init() {}

    public func load(from url: URL) throws -> [APISnapshotCoverageRequirement] {
        let contents: String
        do {
            let data = try Data(contentsOf: url)
            guard let decoded = String(data: data, encoding: .utf8) else {
                throw SourceListDecodingError.invalidUTF8
            }
            contents = decoded
        } catch {
            throw APICheckDiagnostic(
                code: "snapshotset.coverage-list-read",
                message: "Unable to read snapshot coverage list \(url.lastPathComponent)"
            )
        }

        var lines = contents
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
            .split(separator: "\n", omittingEmptySubsequences: false)
            .map(String.init)
        if lines.last?.isEmpty == true {
            lines.removeLast()
        }
        guard !lines.isEmpty else {
            throw APICheckDiagnostic(
                code: "snapshotset.coverage-list-empty",
                message: "Snapshot coverage list contains no records"
            )
        }

        let coverage = try lines.enumerated().map { index, line in
            try requirement(from: line, lineNumber: index + 1)
        }
        var seen: Set<APISnapshotCoverageRequirement> = []
        for requirement in coverage {
            guard seen.insert(requirement).inserted else {
                throw APICheckDiagnostic(
                    code: "snapshotset.duplicate-coverage",
                    message: "Duplicate required coverage for '\(requirement.moduleName)/\(requirement.platform)'"
                )
            }
        }
        guard coverage == coverage.sorted(by: compareCoverage) else {
            throw APICheckDiagnostic(
                code: "snapshotset.noncanonical-coverage-order",
                message: "Snapshot coverage list is not sorted by module and platform"
            )
        }
        return coverage
    }

    private func requirement(
        from line: String,
        lineNumber: Int
    ) throws -> APISnapshotCoverageRequirement {
        let fields = line.split(
            separator: "\t",
            omittingEmptySubsequences: false
        ).map(String.init)
        guard fields.count == 2 else {
            throw APICheckDiagnostic(
                code: "snapshotset.coverage-list-columns",
                message: "Snapshot coverage list line \(lineNumber) must contain 2 tab-separated fields"
            )
        }
        guard fields.allSatisfy({
            !$0.isEmpty && $0 == $0.trimmingCharacters(in: .whitespacesAndNewlines)
        }) else {
            throw APICheckDiagnostic(
                code: "snapshotset.coverage-list-whitespace",
                message: "Snapshot coverage list line \(lineNumber) contains empty or padded fields"
            )
        }
        return APISnapshotCoverageRequirement(
            moduleName: fields[0],
            platform: fields[1]
        )
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
}

private enum SourceListDecodingError: Error {
    case invalidUTF8
}

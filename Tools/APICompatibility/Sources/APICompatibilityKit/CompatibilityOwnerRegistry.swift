import Foundation

public struct CompatibilityOwnerRegistry: Codable, Equatable, Sendable {
    public var schemaVersion: Int
    public var repository: String
    public var issues: [CompatibilityOwnerIssue]

    public init(
        schemaVersion: Int,
        repository: String,
        issues: [CompatibilityOwnerIssue]
    ) {
        self.schemaVersion = schemaVersion
        self.repository = repository
        self.issues = issues
    }
}

public struct CompatibilityOwnerIssue: Codable, Equatable, Sendable {
    public var number: Int
    public var title: String
    public var url: String

    public init(number: Int, title: String, url: String) {
        self.number = number
        self.title = title
        self.url = url
    }
}

public struct CompatibilityOwnerRegistryCodec: Sendable {
    public init() {}

    public func load(from url: URL) throws -> CompatibilityOwnerRegistry {
        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode(CompatibilityOwnerRegistry.self, from: data)
        } catch {
            throw APICheckDiagnostic(
                code: "owner-registry.invalid-json",
                message: "\(url.lastPathComponent) is not a valid compatibility owner registry"
            )
        }
    }
}

public struct CompatibilityOwnerRegistryValidator: Sendable {
    public init() {}

    public func validate(_ registry: CompatibilityOwnerRegistry) throws {
        guard registry.schemaVersion == 1 else {
            throw ownerRegistryDiagnostic(
                "owner-registry.schema-version",
                "Unsupported compatibility owner registry schema version \(registry.schemaVersion)"
            )
        }
        let repositoryComponents = registry.repository.split(
            separator: "/",
            omittingEmptySubsequences: false
        )
        guard repositoryComponents.count == 2,
              repositoryComponents.allSatisfy({ isRepositoryComponent(String($0)) }) else {
            throw ownerRegistryDiagnostic(
                "owner-registry.repository",
                "Owner registry repository must use the GitHub owner/name form"
            )
        }
        guard !registry.issues.isEmpty else {
            throw ownerRegistryDiagnostic(
                "owner-registry.empty",
                "Owner registry must list at least one issue"
            )
        }
        let issueNumbers = registry.issues.map(\.number)
        guard issueNumbers.allSatisfy({ $0 > 0 }),
              Set(issueNumbers).count == issueNumbers.count,
              issueNumbers == issueNumbers.sorted() else {
            throw ownerRegistryDiagnostic(
                "owner-registry.issue-number",
                "Owner registry issue numbers must be positive, unique, and sorted"
            )
        }
        for issue in registry.issues {
            guard isSafeTitle(issue.title) else {
                throw ownerRegistryDiagnostic(
                    "owner-registry.issue-title",
                    "Owner issue #\(issue.number) requires a nonempty single-line title without surrounding whitespace"
                )
            }
            let expectedURL = "https://github.com/\(registry.repository)/issues/\(issue.number)"
            guard issue.url == expectedURL else {
                throw ownerRegistryDiagnostic(
                    "owner-registry.issue-url",
                    "Owner issue #\(issue.number) must use '\(expectedURL)'"
                )
            }
        }
    }

    func allowedIssueReferences(
        in registry: CompatibilityOwnerRegistry
    ) throws -> Set<String> {
        try validate(registry)
        return Set(registry.issues.map { "#\($0.number)" })
    }

    private func isRepositoryComponent(_ value: String) -> Bool {
        guard !value.isEmpty else { return false }
        return value.unicodeScalars.allSatisfy { scalar in
            CharacterSet.alphanumerics.contains(scalar)
                || scalar == "-" || scalar == "_" || scalar == "."
        }
    }

    private func isSafeTitle(_ value: String) -> Bool {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmed.isEmpty
            && trimmed == value
            && value.unicodeScalars.allSatisfy {
                !CharacterSet.controlCharacters.contains($0)
            }
    }
}

public struct CompatibilityOwnerRegistryTSVEncoder: Sendable {
    public init() {}

    public func encode(_ registry: CompatibilityOwnerRegistry) throws -> String {
        try CompatibilityOwnerRegistryValidator().validate(registry)
        var lines = ["repository\tissueNumber\ttitle\turl"]
        lines += registry.issues.map { issue in
            [registry.repository, String(issue.number), issue.title, issue.url]
                .joined(separator: "\t")
        }
        return lines.joined(separator: "\n") + "\n"
    }
}

private func ownerRegistryDiagnostic(
    _ code: String,
    _ message: String
) -> APICheckDiagnostic {
    APICheckDiagnostic(code: code, message: message)
}

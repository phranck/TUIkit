import Foundation
import Testing

@testable import APICompatibilityKit

enum FixtureSupport {
    static func url(_ relativePath: String) throws -> URL {
        guard let url = Bundle.module.url(
            forResource: relativePath,
            withExtension: nil,
            subdirectory: "Fixtures"
        ) else {
            Issue.record("Missing fixture: \(relativePath)")
            throw FixtureError.missing(relativePath)
        }
        return url
    }

    static func temporaryDirectory() throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("TUIkitAPICheckTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    static func diagnostic(
        from operation: () throws -> some Any
    ) -> APICheckDiagnostic? {
        do {
            _ = try operation()
            Issue.record("Expected an APICheckDiagnostic")
            return nil
        } catch let diagnostic as APICheckDiagnostic {
            return diagnostic
        } catch {
            Issue.record("Unexpected error: \(error)")
            return nil
        }
    }
}

private enum FixtureError: Error {
    case missing(String)
}

import Foundation

extension CommandRunner {
    func executableURL(_ path: String, code: String, noun: String) throws -> URL {
        let url = URL(fileURLWithPath: path).standardizedFileURL
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory),
              !isDirectory.boolValue,
              FileManager.default.isExecutableFile(atPath: url.path) else {
            throw APICheckDiagnostic(
                code: code,
                message: "\(noun) is not executable: \(path)"
            )
        }
        return url
    }

    func directoryURL(_ path: String, code: String, noun: String) throws -> URL {
        let url = URL(fileURLWithPath: path).standardizedFileURL.resolvingSymlinksInPath()
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory),
              isDirectory.boolValue else {
            throw APICheckDiagnostic(code: code, message: "\(noun) does not exist: \(path)")
        }
        return url
    }

    func diagnosticFailure(_ diagnostics: [APICheckDiagnostic]) -> CommandResult {
        CommandResult(
            exitCode: 1,
            standardOutput: "",
            standardError: diagnostics.map(\.description).joined(separator: "\n") + "\n"
        )
    }

    func parseOptions(
        _ arguments: [String],
        allowed: Set<String>,
        required: Set<String>
    ) -> [String: String]? {
        guard arguments.count.isMultiple(of: 2) else { return nil }
        var options: [String: String] = [:]
        var index = 0
        while index < arguments.count {
            let key = arguments[index]
            let value = arguments[index + 1]
            guard allowed.contains(key), options[key] == nil, !value.isEmpty else {
                return nil
            }
            options[key] = value
            index += 2
        }
        guard required.isSubset(of: Set(options.keys)) else { return nil }
        return options
    }

    func usageFailure() -> CommandResult {
        CommandResult(exitCode: 2, standardOutput: "", standardError: Self.usage)
    }
}

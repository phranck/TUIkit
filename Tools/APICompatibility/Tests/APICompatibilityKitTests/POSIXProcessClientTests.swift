import Foundation
import Testing

@testable import APICompatibilityKit

@Suite("POSIX process clients")
struct POSIXProcessClientTests {
    @Test("Compiler and symbol graph clients run concurrently through the shared runner")
    func runsConcurrentProcessClients() async throws {
        let rootDirectory = try FixtureSupport.temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: rootDirectory) }
        let executableURL = rootDirectory.appendingPathComponent("shared process tool")
        try writeExecutable(to: executableURL)

        let invocationCount = 24
        let startGate = SubprocessStartGate(participantCount: invocationCount * 2)
        let observations = try await withThrowingTaskGroup(
            of: String.self,
            returning: Set<String>.self
        ) { group in
            for index in 0..<invocationCount {
                let outputDirectory = rootDirectory.appendingPathComponent(
                    "Symbol Graph \(index)",
                    isDirectory: true
                )
                try FileManager.default.createDirectory(
                    at: outputDirectory,
                    withIntermediateDirectories: true
                )
                group.addTask {
                    await startGate.wait()
                    let result = try POSIXSwiftCompilerProcess().run(
                        executable: executableURL,
                        arguments: ["--compiler-mode", "compiler \(index)"]
                    )
                    guard result.exitCode == 0, result.standardError.isEmpty else {
                        throw ProcessClientTestError.unexpectedCompilerResult
                    }
                    return "compiler:\(result.standardOutput)"
                }
                group.addTask {
                    await startGate.wait()
                    let graphURL = try SymbolGraphExtractor(executableURL: executableURL).extract(
                        SymbolGraphExtractionRequest(
                            moduleName: "Fixture\(index)",
                            targetTriple: "x86_64-unknown-linux-gnu",
                            outputDirectory: outputDirectory
                        )
                    )
                    return "graph:\(graphURL.lastPathComponent)"
                }
            }

            var collected: Set<String> = []
            for try await observation in group {
                collected.insert(observation)
            }
            return collected
        }

        let expectedCompilerResults = (0..<invocationCount).map { "compiler:compiler \($0)" }
        let expectedGraphResults = (0..<invocationCount).map { "graph:Fixture\($0).symbols.json" }
        #expect(observations == Set(expectedCompilerResults + expectedGraphResults))
    }
}

private extension POSIXProcessClientTests {
    func writeExecutable(to executableURL: URL) throws {
        let script = """
        #!/bin/sh
        if [ "$1" = "--compiler-mode" ]; then
            printf '%s' "$2"
            exit 0
        fi
        module_name=
        output_directory=
        while [ "$#" -gt 0 ]; do
            case "$1" in
                -module-name)
                    module_name="$2"
                    shift 2
                    ;;
                -output-dir)
                    output_directory="$2"
                    shift 2
                    ;;
                -target|-sdk|-minimum-access-level)
                    shift 2
                    ;;
                *)
                    shift
                    ;;
            esac
        done
        : > "$output_directory/$module_name.symbols.json"
        """
        try Data(script.utf8).write(to: executableURL)
        try FileManager.default.setAttributes(
            [.posixPermissions: 0o755],
            ofItemAtPath: executableURL.path
        )
    }
}

private enum ProcessClientTestError: Error {
    case unexpectedCompilerResult
}

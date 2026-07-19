import Foundation
import Testing

@testable import APICompatibilityKit

@Suite("POSIX subprocess runner")
struct POSIXSubprocessRunnerTests {
    @Test("Runs concurrent commands directly with isolated output")
    func runsConcurrentCommandsDirectly() async throws {
        let rootDirectory = try FixtureSupport.temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: rootDirectory) }
        let executableURL = rootDirectory.appendingPathComponent("fake subprocess runner")
        let markerURL = rootDirectory.appendingPathComponent("shell-evaluation-ran")
        try writeExecutable(to: executableURL)

        let invocationCount = 48
        let startGate = SubprocessStartGate(participantCount: invocationCount)
        let observations = try await withThrowingTaskGroup(
            of: SubprocessObservation.self,
            returning: [SubprocessObservation].self
        ) { group in
            for index in 0..<invocationCount {
                group.addTask {
                    await startGate.wait()
                    let standardOutput = "stdout \(index) $(touch \(markerURL.path))"
                    let standardError = "stderr \(index) with spaces"
                    let result = try POSIXSubprocessRunner().run(
                        executable: executableURL,
                        arguments: [standardOutput, standardError, "7"]
                    )
                    return SubprocessObservation(
                        result: result,
                        expectedStandardOutput: standardOutput,
                        expectedStandardError: standardError
                    )
                }
            }

            var collected: [SubprocessObservation] = []
            for try await observation in group {
                collected.append(observation)
            }
            return collected
        }

        #expect(observations.count == invocationCount)
        for observation in observations {
            #expect(observation.result.exitCode == 7)
            #expect(observation.result.standardOutput == Data(observation.expectedStandardOutput.utf8))
            #expect(observation.result.standardError == Data(observation.expectedStandardError.utf8))
        }
        #expect(!FileManager.default.fileExists(atPath: markerURL.path))
    }
}

private extension POSIXSubprocessRunnerTests {
    func writeExecutable(to executableURL: URL) throws {
        let script = """
        #!/bin/sh
        printf '%s' "$1"
        printf '%s' "$2" >&2
        exit "$3"
        """
        try Data(script.utf8).write(to: executableURL)
        try FileManager.default.setAttributes(
            [.posixPermissions: 0o755],
            ofItemAtPath: executableURL.path
        )
    }
}

private struct SubprocessObservation: Sendable {
    let result: POSIXSubprocessResult
    let expectedStandardOutput: String
    let expectedStandardError: String
}

actor SubprocessStartGate {
    private let participantCount: Int
    private var arrivals = 0
    private var waiters: [CheckedContinuation<Void, Never>] = []

    init(participantCount: Int) {
        self.participantCount = participantCount
    }

    func wait() async {
        arrivals += 1
        guard arrivals < participantCount else {
            let waitersToResume = waiters
            waiters.removeAll()
            for waiter in waitersToResume {
                waiter.resume()
            }
            return
        }

        await withCheckedContinuation { continuation in
            waiters.append(continuation)
        }
    }
}

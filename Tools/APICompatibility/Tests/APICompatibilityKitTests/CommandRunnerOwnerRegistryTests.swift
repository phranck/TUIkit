import Foundation
import Testing

@testable import APICompatibilityKit

@Suite("Compatibility owner registry command")
struct CommandRunnerOwnerRegistryTests {
    @Test("Writes a validated deterministic TSV inventory")
    func writesOwnerRegistryTSV() throws {
        let registry = try FixtureSupport.url("Policies/owners.json")

        let result = CommandRunner().run(arguments: [
            "list-owner-registry",
            "--owner-registry", registry.path,
        ])

        #expect(result.exitCode == 0)
        #expect(result.standardError.isEmpty)
        #expect(
            result.standardOutput == """
            repository\tissueNumber\ttitle\turl
            phranck/TUIkit\t17\t[P1-12] Align View, ContentBuilder, ViewModifier, and ModifiedContent with SwiftUI\thttps://github.com/phranck/TUIkit/issues/17
            phranck/TUIkit\t18\t[P1-13] Align Binding, State, Environment, AppStorage, and Observation with SwiftUI\thttps://github.com/phranck/TUIkit/issues/18
            phranck/TUIkit\t35\t[P2-30] Reduce the public implementation surface and namespace TUI-only APIs\thttps://github.com/phranck/TUIkit/issues/35

            """
        )
    }

    @Test("Requires the owner registry option exactly once")
    func rejectsInvalidOptions() throws {
        let registry = try FixtureSupport.url("Policies/owners.json")
        let missing = CommandRunner().run(arguments: ["list-owner-registry"])
        let duplicate = CommandRunner().run(arguments: [
            "list-owner-registry",
            "--owner-registry", registry.path,
            "--owner-registry", registry.path,
        ])
        let unknown = CommandRunner().run(arguments: [
            "list-owner-registry",
            "--registry", registry.path,
        ])

        for result in [missing, duplicate, unknown] {
            #expect(result.exitCode == 2)
            #expect(result.standardOutput.isEmpty)
            #expect(result.standardError == CommandRunner.usage)
        }
    }

    @Test("Rejects owner titles that cannot be represented safely in TSV")
    func rejectsUnsafeTitle() throws {
        let directory = try FixtureSupport.temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let registryURL = directory.appendingPathComponent("owners.json")
        var registry = try CompatibilityOwnerRegistryCodec().load(
            from: FixtureSupport.url("Policies/owners.json")
        )
        registry.issues[0].title = "Unsafe\ttitle"
        let data = try JSONEncoder().encode(registry)
        try data.write(to: registryURL)

        let result = CommandRunner().run(arguments: [
            "list-owner-registry",
            "--owner-registry", registryURL.path,
        ])

        #expect(result.exitCode == 1)
        #expect(result.standardOutput.isEmpty)
        #expect(
            result.standardError
                == "error[owner-registry.issue-title]: Owner issue #17 requires a nonempty single-line title without surrounding whitespace\n"
        )
    }
}

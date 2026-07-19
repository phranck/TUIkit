import Foundation
import Testing

@testable import APICompatibilityKit

@Suite("Symbol graph extractor")
struct SymbolGraphExtractorTests {
    @Test("Builds deterministic arguments without shell interpolation")
    func buildsDeterministicArguments() throws {
        let outputDirectory = try FixtureSupport.temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: outputDirectory) }
        let expectedGraphURL = outputDirectory.appendingPathComponent("Fixture.symbols.json")
        let executableURL = URL(fileURLWithPath: "/tool path/swift-symbolgraph-extract")
        let executor = StubSymbolGraphProcessExecutor(
            expectedExecutableURL: executableURL,
            expectedArguments: [
                "-module-name", "Fixture",
                "-target", "x86_64-unknown-linux-gnu",
                "-sdk", "/SDK Path",
                "-output-dir", outputDirectory.path,
                "-minimum-access-level", "public",
                "-skip-inherited-docs",
                "-skip-synthesized-members",
                "-emit-extension-block-symbols",
                "-pretty-print",
                "-I", "/include path",
                "$(touch should-not-run)",
            ],
            result: SymbolGraphProcessResult(
                exitCode: 0,
                standardOutput: "extracted\n",
                standardError: ""
            ),
            producedGraphURL: expectedGraphURL
        )
        let extractor = SymbolGraphExtractor(
            executableURL: executableURL,
            processExecutor: executor
        )

        let graphURL = try extractor.extract(
            SymbolGraphExtractionRequest(
                moduleName: "Fixture",
                targetTriple: "x86_64-unknown-linux-gnu",
                sdkPath: "/SDK Path",
                outputDirectory: outputDirectory,
                prettyPrint: true,
                emitExtensionBlockSymbols: true,
                extraArguments: ["-I", "/include path", "$(touch should-not-run)"]
            )
        )

        #expect(graphURL == expectedGraphURL)
    }

    @Test("Omits pretty-print unless explicitly requested")
    func omitsPrettyPrintByDefault() throws {
        let outputDirectory = try FixtureSupport.temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: outputDirectory) }
        let expectedGraphURL = outputDirectory.appendingPathComponent("Fixture.symbols.json")
        let executableURL = URL(fileURLWithPath: "/usr/bin/swift-symbolgraph-extract")
        let executor = StubSymbolGraphProcessExecutor(
            expectedExecutableURL: executableURL,
            expectedArguments: [
                "-module-name", "Fixture",
                "-target", "arm64-apple-macosx15.0",
                "-sdk", "/SDK",
                "-output-dir", outputDirectory.path,
                "-minimum-access-level", "public",
                "-skip-inherited-docs",
                "-skip-synthesized-members",
            ],
            result: SymbolGraphProcessResult(
                exitCode: 0,
                standardOutput: "",
                standardError: ""
            ),
            producedGraphURL: expectedGraphURL
        )

        _ = try SymbolGraphExtractor(
            executableURL: executableURL,
            processExecutor: executor
        ).extract(
            SymbolGraphExtractionRequest(
                moduleName: "Fixture",
                targetTriple: "arm64-apple-macosx15.0",
                sdkPath: "/SDK",
                outputDirectory: outputDirectory
            )
        )
    }

    @Test("Omits the SDK arguments for non-Apple targets")
    func omitsSDKArguments() throws {
        let outputDirectory = try FixtureSupport.temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: outputDirectory) }
        let expectedGraphURL = outputDirectory.appendingPathComponent("Fixture.symbols.json")
        let executableURL = URL(fileURLWithPath: "/usr/bin/swift-symbolgraph-extract")
        let executor = StubSymbolGraphProcessExecutor(
            expectedExecutableURL: executableURL,
            expectedArguments: [
                "-module-name", "Fixture",
                "-target", "x86_64-unknown-linux-gnu",
                "-output-dir", outputDirectory.path,
                "-minimum-access-level", "public",
                "-skip-inherited-docs",
                "-skip-synthesized-members",
            ],
            result: SymbolGraphProcessResult(
                exitCode: 0,
                standardOutput: "",
                standardError: ""
            ),
            producedGraphURL: expectedGraphURL
        )

        _ = try SymbolGraphExtractor(
            executableURL: executableURL,
            processExecutor: executor
        ).extract(
            SymbolGraphExtractionRequest(
                moduleName: "Fixture",
                targetTriple: "x86_64-unknown-linux-gnu",
                outputDirectory: outputDirectory
            )
        )
    }

    @Test("Rejects an explicitly empty SDK path before launching the extractor")
    func rejectsEmptySDKPath() throws {
        let outputDirectory = try FixtureSupport.temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: outputDirectory) }
        let extractor = SymbolGraphExtractor(
            executableURL: URL(fileURLWithPath: "/usr/bin/swift-symbolgraph-extract"),
            processExecutor: UnexpectedSymbolGraphProcessExecutor()
        )

        let diagnostic = FixtureSupport.diagnostic {
            try extractor.extract(
                SymbolGraphExtractionRequest(
                    moduleName: "Fixture",
                    targetTriple: "x86_64-unknown-linux-gnu",
                    sdkPath: "  ",
                    outputDirectory: outputDirectory
                )
            )
        }

        #expect(diagnostic?.code == "symbolgraph.extractor-empty-sdk")
        #expect(
            diagnostic?.description
                == "error[symbolgraph.extractor-empty-sdk]: SDK path must not be empty; omit sdkPath for targets without an SDK"
        )
    }

    @Test("Rejects empty module and target identities before launching the extractor")
    func rejectsEmptyExtractionIdentities() throws {
        let outputDirectory = try FixtureSupport.temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: outputDirectory) }
        let extractor = SymbolGraphExtractor(
            executableURL: URL(fileURLWithPath: "/usr/bin/swift-symbolgraph-extract"),
            processExecutor: UnexpectedSymbolGraphProcessExecutor()
        )

        let emptyModule = FixtureSupport.diagnostic {
            try extractor.extract(
                SymbolGraphExtractionRequest(
                    moduleName: " \n",
                    targetTriple: "x86_64-unknown-linux-gnu",
                    outputDirectory: outputDirectory
                )
            )
        }
        let emptyTarget = FixtureSupport.diagnostic {
            try extractor.extract(
                SymbolGraphExtractionRequest(
                    moduleName: "Fixture",
                    targetTriple: "\t",
                    outputDirectory: outputDirectory
                )
            )
        }

        #expect(emptyModule?.code == "symbolgraph.extractor-empty-module")
        #expect(emptyTarget?.code == "symbolgraph.extractor-empty-target")
    }

    @Test("Requires a fresh empty output directory before launching the extractor")
    func rejectsStaleOutputDirectory() throws {
        let outputDirectory = try FixtureSupport.temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: outputDirectory) }
        try Data("stale".utf8).write(
            to: outputDirectory.appendingPathComponent("Fixture.symbols.json")
        )
        let extractor = SymbolGraphExtractor(
            executableURL: URL(fileURLWithPath: "/usr/bin/swift-symbolgraph-extract"),
            processExecutor: UnexpectedSymbolGraphProcessExecutor()
        )

        let diagnostic = FixtureSupport.diagnostic {
            try extractor.extract(
                SymbolGraphExtractionRequest(
                    moduleName: "Fixture",
                    targetTriple: "x86_64-unknown-linux-gnu",
                    outputDirectory: outputDirectory
                )
            )
        }

        #expect(diagnostic == APICheckDiagnostic(
            code: "symbolgraph.extractor-output-not-empty",
            message: "Symbol graph output directory must be empty before extraction"
        ))
    }

    @Test(
        "Rejects managed inventory options in extra arguments",
        arguments: [
            "-skip-protocol-implementations",
            "-minimum-access-level",
            "-skip-synthesized-members",
            "-emit-extension-block-symbols",
        ]
    )
    func rejectsManagedExtraArgument(argument: String) throws {
        let outputDirectory = try FixtureSupport.temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: outputDirectory) }
        let extractor = SymbolGraphExtractor(
            executableURL: URL(fileURLWithPath: "/usr/bin/swift-symbolgraph-extract"),
            processExecutor: UnexpectedSymbolGraphProcessExecutor()
        )

        let diagnostic = FixtureSupport.diagnostic {
            try extractor.extract(
                SymbolGraphExtractionRequest(
                    moduleName: "Fixture",
                    targetTriple: "x86_64-unknown-linux-gnu",
                    outputDirectory: outputDirectory,
                    extraArguments: [argument]
                )
            )
        }

        #expect(diagnostic?.code == "symbolgraph.extractor-reserved-argument")
        #expect(
            diagnostic?.description
                == "error[symbolgraph.extractor-reserved-argument]: Extra argument '\(argument)' overrides a managed symbol inventory option"
        )
    }

    @Test("Runs the executable directly without evaluating argument contents")
    func runsExecutableWithoutShellEvaluation() throws {
        let rootDirectory = try FixtureSupport.temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: rootDirectory) }
        let outputDirectory = rootDirectory.appendingPathComponent("output", isDirectory: true)
        try FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)
        let executableURL = rootDirectory.appendingPathComponent("fake extractor")
        let markerURL = rootDirectory.appendingPathComponent("shell-interpolation-ran")
        let script = """
        #!/bin/sh
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

        let graphURL = try SymbolGraphExtractor(executableURL: executableURL).extract(
            SymbolGraphExtractionRequest(
                moduleName: "Fixture",
                targetTriple: "x86_64-unknown-linux-gnu",
                sdkPath: "/SDK Path",
                outputDirectory: outputDirectory,
                prettyPrint: true,
                extraArguments: ["$(touch \(markerURL.path))"]
            )
        )

        #expect(graphURL.lastPathComponent == "Fixture.symbols.json")
        #expect(!FileManager.default.fileExists(atPath: markerURL.path))
    }

    @Test(
        "Rejects nonzero extractor exit codes",
        arguments: [Int32(1), Int32(7), Int32(255)]
    )
    func rejectsNonzeroExit(exitCode: Int32) throws {
        let outputDirectory = try FixtureSupport.temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: outputDirectory) }
        let extractor = stubbedExtractor(
            outputDirectory: outputDirectory,
            result: SymbolGraphProcessResult(
                exitCode: exitCode,
                standardOutput: "",
                standardError: ""
            )
        )

        let diagnostic = FixtureSupport.diagnostic {
            try extractor.extract(request(outputDirectory: outputDirectory))
        }

        #expect(diagnostic?.code == "symbolgraph.extractor-nonzero-exit")
        #expect(
            diagnostic?.description
                == "error[symbolgraph.extractor-nonzero-exit]: Symbol graph extraction for 'Fixture' exited with status \(exitCode)"
        )
    }

    @Test("Rejects stderr even when the extractor exits successfully")
    func rejectsStandardErrorOnSuccess() throws {
        let outputDirectory = try FixtureSupport.temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: outputDirectory) }
        let extractor = stubbedExtractor(
            outputDirectory: outputDirectory,
            result: SymbolGraphProcessResult(
                exitCode: 0,
                standardOutput: "",
                standardError: "\n"
            )
        )

        let diagnostic = FixtureSupport.diagnostic {
            try extractor.extract(request(outputDirectory: outputDirectory))
        }

        #expect(diagnostic?.code == "symbolgraph.extractor-stderr")
        #expect(
            diagnostic?.description
                == "error[symbolgraph.extractor-stderr]: Symbol graph extraction for 'Fixture' emitted stderr"
        )
    }

    @Test("Requires the expected main module graph")
    func requiresMainGraph() throws {
        let outputDirectory = try FixtureSupport.temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: outputDirectory) }
        let extractor = stubbedExtractor(
            outputDirectory: outputDirectory,
            result: SymbolGraphProcessResult(
                exitCode: 0,
                standardOutput: "",
                standardError: ""
            )
        )

        let diagnostic = FixtureSupport.diagnostic {
            try extractor.extract(request(outputDirectory: outputDirectory))
        }

        #expect(diagnostic?.code == "symbolgraph.extractor-missing-main")
        #expect(
            diagnostic?.description
                == "error[symbolgraph.extractor-missing-main]: Symbol graph extraction did not produce Fixture.symbols.json"
        )
    }

    @Test("Wraps process launch failures in a stable diagnostic")
    func wrapsLaunchFailure() throws {
        let outputDirectory = try FixtureSupport.temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: outputDirectory) }
        let executableURL = URL(fileURLWithPath: "/missing/swift-symbolgraph-extract")
        let executor = ThrowingSymbolGraphProcessExecutor()
        let extractor = SymbolGraphExtractor(
            executableURL: executableURL,
            processExecutor: executor
        )

        let diagnostic = FixtureSupport.diagnostic {
            try extractor.extract(request(outputDirectory: outputDirectory))
        }

        #expect(diagnostic?.code == "symbolgraph.extractor-launch")
        #expect(
            diagnostic?.description
                == "error[symbolgraph.extractor-launch]: Unable to run symbol graph extractor at /missing/swift-symbolgraph-extract"
        )
    }

    private func stubbedExtractor(
        outputDirectory: URL,
        result: SymbolGraphProcessResult
    ) -> SymbolGraphExtractor {
        let executableURL = URL(fileURLWithPath: "/usr/bin/swift-symbolgraph-extract")
        return SymbolGraphExtractor(
            executableURL: executableURL,
            processExecutor: StubSymbolGraphProcessExecutor(
                expectedExecutableURL: executableURL,
                expectedArguments: [
                    "-module-name", "Fixture",
                    "-target", "x86_64-unknown-linux-gnu",
                    "-sdk", "/SDK",
                    "-output-dir", outputDirectory.path,
                    "-minimum-access-level", "public",
                    "-skip-inherited-docs",
                    "-skip-synthesized-members",
                ],
                result: result
            )
        )
    }

    private func request(outputDirectory: URL) -> SymbolGraphExtractionRequest {
        SymbolGraphExtractionRequest(
            moduleName: "Fixture",
            targetTriple: "x86_64-unknown-linux-gnu",
            sdkPath: "/SDK",
            outputDirectory: outputDirectory
        )
    }
}

private struct StubSymbolGraphProcessExecutor: SymbolGraphProcessExecuting {
    let expectedExecutableURL: URL
    let expectedArguments: [String]
    let result: SymbolGraphProcessResult
    var producedGraphURL: URL?

    func execute(executableURL: URL, arguments: [String]) throws -> SymbolGraphProcessResult {
        #expect(executableURL == expectedExecutableURL)
        #expect(arguments == expectedArguments)
        if let producedGraphURL {
            try Data("{}".utf8).write(to: producedGraphURL)
        }
        return result
    }
}

private struct ThrowingSymbolGraphProcessExecutor: SymbolGraphProcessExecuting {
    func execute(executableURL: URL, arguments: [String]) throws -> SymbolGraphProcessResult {
        throw StubProcessError.launchFailed
    }
}

private struct UnexpectedSymbolGraphProcessExecutor: SymbolGraphProcessExecuting {
    func execute(executableURL: URL, arguments: [String]) throws -> SymbolGraphProcessResult {
        Issue.record("The extractor process must not be launched")
        return SymbolGraphProcessResult(exitCode: 0, standardOutput: "", standardError: "")
    }
}

private enum StubProcessError: Error {
    case launchFailed
}

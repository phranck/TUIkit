import Foundation

public struct SymbolGraphExtractionRequest: Equatable, Sendable {
    public let moduleName: String
    public let targetTriple: String
    public let sdkPath: String?
    public let outputDirectory: URL
    public let prettyPrint: Bool
    public let emitExtensionBlockSymbols: Bool
    public let extraArguments: [String]

    public init(
        moduleName: String,
        targetTriple: String,
        sdkPath: String? = nil,
        outputDirectory: URL,
        prettyPrint: Bool = false,
        emitExtensionBlockSymbols: Bool = false,
        extraArguments: [String] = []
    ) {
        self.moduleName = moduleName
        self.targetTriple = targetTriple
        self.sdkPath = sdkPath
        self.outputDirectory = outputDirectory
        self.prettyPrint = prettyPrint
        self.emitExtensionBlockSymbols = emitExtensionBlockSymbols
        self.extraArguments = extraArguments
    }
}

public struct SymbolGraphExtractor: Sendable {
    private let executableURL: URL
    private let processExecutor: any SymbolGraphProcessExecuting

    public init(executableURL: URL) {
        self.init(
            executableURL: executableURL,
            processExecutor: FoundationSymbolGraphProcessExecutor()
        )
    }

    init(
        executableURL: URL,
        processExecutor: any SymbolGraphProcessExecuting
    ) {
        self.executableURL = executableURL
        self.processExecutor = processExecutor
    }

    public func extract(_ request: SymbolGraphExtractionRequest) throws -> URL {
        try validate(request)
        let processArguments = try arguments(for: request)
        let result: SymbolGraphProcessResult
        do {
            result = try processExecutor.execute(
                executableURL: executableURL,
                arguments: processArguments
            )
        } catch {
            throw APICheckDiagnostic(
                code: "symbolgraph.extractor-launch",
                message: "Unable to run symbol graph extractor at \(executableURL.path)"
            )
        }

        guard result.exitCode == 0 else {
            throw APICheckDiagnostic(
                code: "symbolgraph.extractor-nonzero-exit",
                message: "Symbol graph extraction for '\(request.moduleName)' exited with status \(result.exitCode)"
            )
        }
        guard result.standardError.isEmpty else {
            throw APICheckDiagnostic(
                code: "symbolgraph.extractor-stderr",
                message: "Symbol graph extraction for '\(request.moduleName)' emitted stderr"
            )
        }

        let mainFileName = "\(request.moduleName).symbols.json"
        let mainURL = request.outputDirectory.appendingPathComponent(mainFileName)
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: mainURL.path, isDirectory: &isDirectory),
              !isDirectory.boolValue
        else {
            throw APICheckDiagnostic(
                code: "symbolgraph.extractor-missing-main",
                message: "Symbol graph extraction did not produce \(mainFileName)"
            )
        }
        return mainURL
    }

    private func validate(_ request: SymbolGraphExtractionRequest) throws {
        guard !request.moduleName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw APICheckDiagnostic(
                code: "symbolgraph.extractor-empty-module",
                message: "Module name must not be empty"
            )
        }
        guard !request.targetTriple.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw APICheckDiagnostic(
                code: "symbolgraph.extractor-empty-target",
                message: "Target triple must not be empty"
            )
        }
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(
            atPath: request.outputDirectory.path,
            isDirectory: &isDirectory
        ), isDirectory.boolValue else {
            throw APICheckDiagnostic(
                code: "symbolgraph.extractor-output-directory",
                message: "Symbol graph output directory does not exist"
            )
        }
        let contents: [String]
        do {
            contents = try FileManager.default.contentsOfDirectory(
                atPath: request.outputDirectory.path
            )
        } catch {
            throw APICheckDiagnostic(
                code: "symbolgraph.extractor-output-directory",
                message: "Unable to inspect symbol graph output directory"
            )
        }
        guard contents.isEmpty else {
            throw APICheckDiagnostic(
                code: "symbolgraph.extractor-output-not-empty",
                message: "Symbol graph output directory must be empty before extraction"
            )
        }
    }

    private func arguments(for request: SymbolGraphExtractionRequest) throws -> [String] {
        var arguments = [
            "-module-name", request.moduleName,
            "-target", request.targetTriple,
        ]
        if let sdkPath = request.sdkPath {
            guard !sdkPath.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                throw APICheckDiagnostic(
                    code: "symbolgraph.extractor-empty-sdk",
                    message: "SDK path must not be empty; omit sdkPath for targets without an SDK"
                )
            }
            arguments.append(contentsOf: ["-sdk", sdkPath])
        }
        arguments.append(contentsOf: [
            "-output-dir", request.outputDirectory.path,
            "-minimum-access-level", "public",
            "-skip-inherited-docs",
            "-skip-synthesized-members",
        ])
        if request.emitExtensionBlockSymbols {
            arguments.append("-emit-extension-block-symbols")
        }
        if request.prettyPrint {
            arguments.append("-pretty-print")
        }
        if let reservedArgument = request.extraArguments.first(where: isManagedOption) {
            throw APICheckDiagnostic(
                code: "symbolgraph.extractor-reserved-argument",
                message: "Extra argument '\(reservedArgument)' overrides a managed symbol inventory option"
            )
        }
        arguments.append(contentsOf: request.extraArguments)
        return arguments
    }

    private func isManagedOption(_ argument: String) -> Bool {
        let option = argument.split(
            separator: "=",
            maxSplits: 1,
            omittingEmptySubsequences: false
        ).first.map(String.init) ?? argument
        return Self.managedOptions.contains(option)
    }

    private static let managedOptions: Set<String> = [
        "-active-platform-availability-only",
        "-allow-availability-platforms",
        "-block-availability-platforms",
        "-emit-extension-block-symbols",
        "-include-spi-symbols",
        "-minimum-access-level",
        "-module-name",
        "-omit-extension-block-symbols",
        "-output-dir",
        "-pretty-print",
        "-sdk",
        "-skip-inherited-docs",
        "-skip-protocol-implementations",
        "-skip-synthesized-members",
        "-target",
    ]
}

struct SymbolGraphProcessResult: Equatable, Sendable {
    let exitCode: Int32
    let standardOutput: String
    let standardError: String
}

protocol SymbolGraphProcessExecuting: Sendable {
    func execute(executableURL: URL, arguments: [String]) throws -> SymbolGraphProcessResult
}

private struct FoundationSymbolGraphProcessExecutor: SymbolGraphProcessExecuting {
    func execute(executableURL: URL, arguments: [String]) throws -> SymbolGraphProcessResult {
        let fileManager = FileManager.default
        let captureDirectory = fileManager.temporaryDirectory.appendingPathComponent(
            "TUIkitAPICheck-\(UUID().uuidString)",
            isDirectory: true
        )
        try fileManager.createDirectory(at: captureDirectory, withIntermediateDirectories: true)
        defer { try? fileManager.removeItem(at: captureDirectory) }

        let standardOutputURL = captureDirectory.appendingPathComponent("stdout")
        let standardErrorURL = captureDirectory.appendingPathComponent("stderr")
        try Data().write(to: standardOutputURL)
        try Data().write(to: standardErrorURL)

        let standardOutputHandle = try FileHandle(forWritingTo: standardOutputURL)
        defer { try? standardOutputHandle.close() }
        let standardErrorHandle = try FileHandle(forWritingTo: standardErrorURL)
        defer { try? standardErrorHandle.close() }

        let process = Process()
        process.executableURL = executableURL
        process.arguments = arguments
        process.standardOutput = standardOutputHandle
        process.standardError = standardErrorHandle
        try process.run()
        process.waitUntilExit()

        try standardOutputHandle.close()
        try standardErrorHandle.close()
        let standardOutput = try Data(contentsOf: standardOutputURL)
        let standardError = try Data(contentsOf: standardErrorURL)
        return SymbolGraphProcessResult(
            exitCode: process.terminationStatus,
            standardOutput: decode(standardOutput),
            standardError: decode(standardError)
        )
    }

    private func decode(_ data: Data) -> String {
        String(data: data, encoding: .utf8) ?? "<non-UTF-8 output>"
    }
}

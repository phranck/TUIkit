import Foundation

#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#endif

struct POSIXSubprocessResult: Equatable, Sendable {
    let exitCode: Int32
    let standardOutput: Data
    let standardError: Data
}

enum POSIXSubprocessError: Error {
    case launch
    case outputCaptureRead
    case outputCaptureSetup
}

struct POSIXSubprocessRunner: Sendable {
    func run(executable: URL, arguments: [String]) throws -> POSIXSubprocessResult {
        let fileManager = FileManager.default
        let captureDirectory = fileManager.temporaryDirectory.appendingPathComponent(
            "TUIkitAPICheck-\(UUID().uuidString)",
            isDirectory: true
        )
        do {
            try fileManager.createDirectory(at: captureDirectory, withIntermediateDirectories: true)
        } catch {
            throw POSIXSubprocessError.outputCaptureSetup
        }
        defer { try? fileManager.removeItem(at: captureDirectory) }

        let standardOutputURL = captureDirectory.appendingPathComponent("stdout")
        let standardErrorURL = captureDirectory.appendingPathComponent("stderr")
        let exitCode: Int32
        do {
            let standardOutputDescriptor = openOutputFile(at: standardOutputURL)
            guard standardOutputDescriptor >= 0 else {
                throw POSIXSubprocessError.outputCaptureSetup
            }
            defer { close(standardOutputDescriptor) }

            let standardErrorDescriptor = openOutputFile(at: standardErrorURL)
            guard standardErrorDescriptor >= 0 else {
                throw POSIXSubprocessError.outputCaptureSetup
            }
            defer { close(standardErrorDescriptor) }

            exitCode = try runProcess(
                executable: executable,
                arguments: arguments,
                standardOutputDescriptor: standardOutputDescriptor,
                standardErrorDescriptor: standardErrorDescriptor
            )
        }

        do {
            return try POSIXSubprocessResult(
                exitCode: exitCode,
                standardOutput: Data(contentsOf: standardOutputURL),
                standardError: Data(contentsOf: standardErrorURL)
            )
        } catch {
            throw POSIXSubprocessError.outputCaptureRead
        }
    }
}

private extension POSIXSubprocessRunner {
    func openOutputFile(at url: URL) -> Int32 {
        url.path.withCString { path in
            open(path, O_WRONLY | O_CREAT | O_TRUNC, S_IRUSR | S_IWUSR)
        }
    }

    func runProcess(
        executable: URL,
        arguments: [String],
        standardOutputDescriptor: Int32,
        standardErrorDescriptor: Int32
    ) throws -> Int32 {
        #if canImport(Darwin)
        var fileActions: posix_spawn_file_actions_t?
        #elseif canImport(Glibc)
        var fileActions = posix_spawn_file_actions_t()
        #endif
        guard posix_spawn_file_actions_init(&fileActions) == 0 else {
            throw POSIXSubprocessError.launch
        }
        defer { posix_spawn_file_actions_destroy(&fileActions) }

        guard posix_spawn_file_actions_adddup2(
            &fileActions,
            standardOutputDescriptor,
            STDOUT_FILENO
        ) == 0,
        posix_spawn_file_actions_adddup2(
            &fileActions,
            standardErrorDescriptor,
            STDERR_FILENO
        ) == 0 else {
            throw POSIXSubprocessError.outputCaptureSetup
        }
        if standardOutputDescriptor != STDOUT_FILENO,
           standardOutputDescriptor != STDERR_FILENO,
           posix_spawn_file_actions_addclose(&fileActions, standardOutputDescriptor) != 0 {
            throw POSIXSubprocessError.launch
        }
        if standardErrorDescriptor != STDOUT_FILENO,
           standardErrorDescriptor != STDERR_FILENO,
           posix_spawn_file_actions_addclose(&fileActions, standardErrorDescriptor) != 0 {
            throw POSIXSubprocessError.launch
        }

        let environment = ProcessInfo.processInfo.environment
            .map { "\($0.key)=\($0.value)" }
            .sorted()
        var processID = pid_t()
        let spawnStatus = try withMutableCStringArray([executable.path] + arguments) { argumentVector in
            try withMutableCStringArray(environment) { environmentVector in
                executable.path.withCString { executablePath in
                    posix_spawn(
                        &processID,
                        executablePath,
                        &fileActions,
                        nil,
                        argumentVector,
                        environmentVector
                    )
                }
            }
        }
        guard spawnStatus == 0 else {
            throw POSIXSubprocessError.launch
        }

        return try waitForProcess(processID)
    }

    func withMutableCStringArray<Result>(
        _ strings: [String],
        body: (UnsafeMutablePointer<UnsafeMutablePointer<CChar>?>) throws -> Result
    ) throws -> Result {
        var pointers: [UnsafeMutablePointer<CChar>?] = []
        pointers.reserveCapacity(strings.count + 1)
        for string in strings {
            guard let pointer = strdup(string) else {
                throw POSIXSubprocessError.launch
            }
            pointers.append(pointer)
        }
        defer {
            for pointer in pointers {
                free(pointer)
            }
        }
        pointers.append(nil)
        return try pointers.withUnsafeMutableBufferPointer { buffer in
            guard let baseAddress = buffer.baseAddress else {
                throw POSIXSubprocessError.launch
            }
            return try body(baseAddress)
        }
    }

    func waitForProcess(_ processID: pid_t) throws -> Int32 {
        var processStatus = Int32()
        while true {
            let waitResult = waitpid(processID, &processStatus, 0)
            if waitResult == processID {
                return processExitCode(from: processStatus)
            }
            if waitResult == -1, errno == EINTR {
                continue
            }
            throw POSIXSubprocessError.launch
        }
    }

    func processExitCode(from status: Int32) -> Int32 {
        let signal = status & 0x7F
        return signal == 0 ? (status >> 8) & 0xFF : signal
    }
}

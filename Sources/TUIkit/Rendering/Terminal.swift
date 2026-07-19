//  🖥️ TUIKit — Terminal UI Kit for Swift
//  Terminal.swift
//
//  Created by LAYERED.work
//  License: MIT

import Foundation

#if canImport(Glibc)
    import Glibc
#elseif canImport(Musl)
    import Musl
#elseif canImport(Darwin)
    import Darwin
#endif

// MARK: - Terminal System Calls

/// Injectable POSIX calls used by terminal input and output.
internal struct TerminalSystemCalls: Sendable {
    /// Reads bytes from a file descriptor.
    let read: @Sendable (Int32, UnsafeMutableRawPointer?, Int) -> Int

    /// Writes bytes to a file descriptor.
    let write: @Sendable (Int32, UnsafeRawPointer?, Int) -> Int

    /// Returns the current thread-local POSIX error code.
    let errorCode: @Sendable () -> Int32

    /// Production calls supplied by the active platform module.
    static let system = Self(
        read: platformRead,
        write: platformWrite,
        errorCode: { errno }
    )
}

/// Calls the active platform's POSIX `read` function.
private func platformRead(
    _ fileDescriptor: Int32,
    _ buffer: UnsafeMutableRawPointer?,
    _ count: Int
) -> Int {
    #if canImport(Glibc)
        Glibc.read(fileDescriptor, buffer, count)
    #elseif canImport(Musl)
        Musl.read(fileDescriptor, buffer, count)
    #else
        Darwin.read(fileDescriptor, buffer, count)
    #endif
}

/// Calls the active platform's POSIX `write` function.
private func platformWrite(
    _ fileDescriptor: Int32,
    _ buffer: UnsafeRawPointer?,
    _ count: Int
) -> Int {
    #if canImport(Glibc)
        Glibc.write(fileDescriptor, buffer, count)
    #elseif canImport(Musl)
        Musl.write(fileDescriptor, buffer, count)
    #else
        Darwin.write(fileDescriptor, buffer, count)
    #endif
}

/// Platform-specific type for `termios` flag fields.
///
/// Darwin uses `UInt` (64-bit), Linux uses `tcflag_t` (`UInt32`).
/// This typealias ensures flag bitmask operations compile on both.
#if os(Linux)
    private typealias TermFlag = UInt32
#else
    private typealias TermFlag = UInt
#endif

/// Represents the terminal and controls input and output.
///
/// `Terminal` is the central interface to the terminal. It provides:
/// - Terminal size queries
/// - Raw mode configuration
/// - Safe input and output
/// - Frame-buffered output (all writes collected, flushed in one syscall)
///
/// ## Output Buffering
///
/// During rendering, call ``beginFrame()`` before writing and ``endFrame()``
/// after. All ``write(_:)`` calls between them are collected in an internal
/// `[UInt8]` buffer and flushed as a single `write()` syscall, reducing
/// per-frame syscalls from ~40+ to exactly 1.
///
/// Outside of a frame (setup, teardown), ``write(_:)`` writes immediately
/// as before — safe by default.
///
/// ## Thread Safety
///
/// `Terminal` is `@MainActor` isolated. All terminal operations must occur
/// on the main thread, which is enforced by the Swift concurrency system.
@MainActor
final class Terminal: TerminalProtocol, TerminalFailureReporting {
    /// File descriptor used for terminal input.
    private let inputFileDescriptor: Int32

    /// File descriptor used for terminal output.
    private let outputFileDescriptor: Int32

    /// POSIX calls used for input and output.
    private let systemCalls: TerminalSystemCalls

    /// The first terminal I/O failure not yet consumed by the runtime.
    private var pendingIOFailure: TerminalIOFailure?

    /// Whether raw mode is active.
    private var isRawMode = false

    /// The original terminal settings.
    private var originalTermios: termios?

    /// Whether frame buffering is active.
    ///
    /// When `true`, ``write(_:)`` appends to ``frameBuffer`` instead of
    /// writing to `STDOUT_FILENO` immediately.
    private var isBuffering = false

    /// Collects all output bytes during a buffered frame.
    ///
    /// Starts empty, grows via ``write(_:)`` calls, flushed by ``endFrame()``.
    /// Initial capacity of 16 KB covers typical frames without reallocation.
    private var frameBuffer: [UInt8] = []

    /// Creates a new terminal instance.
    init(
        inputFileDescriptor: Int32 = STDIN_FILENO,
        outputFileDescriptor: Int32 = STDOUT_FILENO,
        systemCalls: TerminalSystemCalls = .system
    ) {
        self.inputFileDescriptor = inputFileDescriptor
        self.outputFileDescriptor = outputFileDescriptor
        self.systemCalls = systemCalls
        frameBuffer.reserveCapacity(16_384)
    }

    /// Destructor ensures raw mode is disabled.
    ///
    /// Note: `deinit` cannot be actor-isolated, so we use `MainActor.assumeIsolated`
    /// which is safe because Terminal instances are only created and destroyed
    /// on the main thread (in AppRunner).
    deinit {
        if isRawMode {
            MainActor.assumeIsolated {
                disableRawMode()
            }
        }
    }
}

// MARK: - Internal API

extension Terminal {
    /// Returns the current terminal size.
    ///
    /// - Returns: A tuple with width and height in characters/lines.
    func getSize() -> (width: Int, height: Int) {
        var windowSize = winsize()

        #if canImport(Glibc) || canImport(Musl)
            let result = ioctl(outputFileDescriptor, UInt(TIOCGWINSZ), &windowSize)
        #else
            let result = ioctl(outputFileDescriptor, TIOCGWINSZ, &windowSize)
        #endif

        if result == 0 && windowSize.ws_col > 0 && windowSize.ws_row > 0 {
            return (Int(windowSize.ws_col), Int(windowSize.ws_row))
        }

        // Fallback to environment variables
        let cols = ProcessInfo.processInfo.environment["COLUMNS"].flatMap(Int.init) ?? 80
        let rows = ProcessInfo.processInfo.environment["LINES"].flatMap(Int.init) ?? 24

        return (cols, rows)
    }

    /// Enables raw mode for direct character handling.
    ///
    /// In raw mode:
    /// - Each keystroke is reported immediately (without Enter)
    /// - Echo is disabled
    /// - Signals like Ctrl+C are not automatically processed
    func enableRawMode() {
        guard !isRawMode else { return }

        var raw = termios()
        tcgetattr(inputFileDescriptor, &raw)
        originalTermios = raw

        raw.c_lflag &= ~TermFlag(ECHO | ICANON | ISIG | IEXTEN)
        raw.c_iflag &= ~TermFlag(IXON | ICRNL | BRKINT | INPCK | ISTRIP)
        raw.c_oflag &= ~TermFlag(OPOST)
        raw.c_cflag |= TermFlag(CS8)

        // Safe: termios.c_cc is a fixed-size array; rebinding to cc_t is valid.
        withUnsafeMutablePointer(to: &raw.c_cc) { pointer in
            pointer.withMemoryRebound(to: cc_t.self, capacity: Int(NCCS)) { buffer in
                buffer[Int(VMIN)] = 0
                buffer[Int(VTIME)] = 0
            }
        }

        tcsetattr(inputFileDescriptor, TCSAFLUSH, &raw)
        isRawMode = true

        // Enable bracketed paste mode so that terminal paste operations
        // are wrapped in ESC[200~ ... ESC[201~ markers. This allows the
        // application to detect pasted text and insert it as a single
        // bulk operation instead of processing each character individually.
        writeImmediate("\u{1B}[?2004h")
    }

    /// Disables raw mode and restores normal terminal operation.
    func disableRawMode() {
        guard isRawMode, var original = originalTermios else { return }

        // Disable bracketed paste mode before restoring terminal state.
        writeImmediate("\u{1B}[?2004l")

        tcsetattr(inputFileDescriptor, TCSAFLUSH, &original)
        isRawMode = false
    }

    /// Begins a buffered frame.
    ///
    /// After this call, all ``write(_:)`` calls append to an internal
    /// `[UInt8]` buffer instead of issuing syscalls. Call ``endFrame()``
    /// to flush the collected output in a single `write()` syscall.
    func beginFrame() {
        guard !isBuffering else { return }
        isBuffering = true
        frameBuffer.removeAll(keepingCapacity: true)
    }

    /// Ends a buffered frame and flushes all collected output.
    func endFrame() {
        guard isBuffering else { return }
        isBuffering = false
        flushBuffer()
    }

    /// Writes a string to the terminal.
    ///
    /// When frame buffering is active (between ``beginFrame()`` and
    /// ``endFrame()``), the string's UTF-8 bytes are appended to the
    /// internal buffer. Otherwise, the bytes are written directly to
    /// `STDOUT_FILENO` via the POSIX `write` syscall.
    ///
    /// - Parameter string: The string to write.
    func write(_ string: String) {
        if isBuffering {
            appendToBuffer(string)
        } else {
            writeImmediate(string)
        }
    }

    /// Moves the cursor to the specified position.
    ///
    /// - Parameters:
    ///   - row: The row (1-based).
    ///   - column: The column (1-based).
    func moveCursor(toRow row: Int, column: Int) {
        write(ANSIRenderer.moveCursor(toRow: row, column: column))
    }

    /// Hides the cursor.
    func hideCursor() {
        write(ANSIRenderer.hideCursor)
    }

    /// Shows the cursor.
    func showCursor() {
        write(ANSIRenderer.showCursor)
    }

    /// Switches to the alternate screen buffer.
    func enterAlternateScreen() {
        write(ANSIRenderer.enterAlternateScreen)
    }

    /// Exits the alternate screen buffer.
    func exitAlternateScreen() {
        write(ANSIRenderer.exitAlternateScreen)
    }

    /// Removes and returns the first pending terminal I/O failure.
    func takeIOFailure() -> TerminalIOFailure? {
        defer { pendingIOFailure = nil }
        return pendingIOFailure
    }

    /// Reads raw bytes from the terminal, handling escape sequences.
    ///
    /// Reads exactly one key event worth of bytes. For escape sequences,
    /// reads byte-by-byte until a CSI terminator is found, preventing
    /// multiple sequences from being read at once during fast key repeat.
    ///
    /// - Parameter maxBytes: Maximum bytes to read (default: 8).
    /// - Returns: The bytes read, or empty array on timeout/error.
    func readBytes(maxBytes: Int = 8) -> [UInt8] {
        guard let firstByte = readByte() else { return [] }

        // Not an escape sequence - return single byte
        guard firstByte == 0x1B else {
            return [firstByte]
        }

        // Read the next byte to determine sequence type
        var result: [UInt8] = [0x1B]
        guard let nextByte = readByte() else {
            // Just ESC alone
            return result
        }

        result.append(nextByte)

        // CSI sequence: ESC [
        if nextByte == 0x5B {  // '['
            // Read until we find a CSI terminator (letter A-Za-z or ~)
            for _ in 0..<(maxBytes - 2) {
                guard let parameterByte = readByte() else { break }

                result.append(parameterByte)

                // CSI terminators: letters (0x40-0x7E) mark end of sequence
                // Common: A-D (arrows), H/F (home/end), Z (shift-tab), ~ (extended)
                if parameterByte >= 0x40 && parameterByte <= 0x7E {
                    break
                }
            }
        } else if nextByte == 0x4F {  // SS3 sequence: ESC O
            // Read one more byte for F1-F4 keys
            if let functionByte = readByte() {
                result.append(functionByte)
            }
        }
        // Alt+key: ESC followed by single key - already have both bytes

        return result
    }

    /// Reads a key event from the terminal.
    ///
    /// When bracketed paste mode is active the terminal wraps pasted text
    /// in `ESC[200~` ... `ESC[201~` markers. This method detects the start
    /// marker, buffers all bytes until the end marker, and returns the
    /// entire pasted text as a single `Key.paste(String)` event.
    ///
    /// - Returns: The key event, or nil on timeout/error.
    func readKeyEvent() -> KeyEvent? {
        let bytes = readBytes()
        guard !bytes.isEmpty else { return nil }

        // Detect bracketed paste start: ESC [ 2 0 0 ~
        if bytes == [0x1B, 0x5B, 0x32, 0x30, 0x30, 0x7E] {
            let pastedText = readBracketedPasteContent()
            return KeyEvent(key: .paste(pastedText))
        }

        return KeyEvent.parse(bytes)
    }

    /// Reads bytes until the bracketed paste end marker `ESC[201~` is found.
    ///
    /// Called after the paste start marker `ESC[200~` has been detected.
    /// Reads byte-by-byte, watching for the 6-byte end sequence. All bytes
    /// before the end marker are collected and returned as a UTF-8 string.
    ///
    /// - Returns: The pasted text content.
    private func readBracketedPasteContent() -> String {
        var content: [UInt8] = []
        // The end marker is: ESC [ 2 0 1 ~
        let endMarker: [UInt8] = [0x1B, 0x5B, 0x32, 0x30, 0x31, 0x7E]

        // Safety limit to prevent infinite buffering on malformed input.
        let maxPasteBytes = 65_536

        while content.count < maxPasteBytes {
            guard let byte = readByte() else {
                // No more data available right now. For non-blocking reads
                // (VMIN=0, VTIME=0) this means the paste end marker has not
                // yet arrived. Wait briefly and retry.
                usleep(1_000)  // 1ms
                continue
            }

            content.append(byte)

            // Check if content ends with the paste end marker.
            if content.count >= endMarker.count {
                let tail = Array(content.suffix(endMarker.count))
                if tail == endMarker {
                    // Remove the end marker from the content.
                    content.removeLast(endMarker.count)
                    break
                }
            }
        }

        return String(bytes: content, encoding: .utf8) ?? String(content.map { Character(UnicodeScalar($0)) })
    }
}

// MARK: - Private Helpers

private extension Terminal {
    /// Reads one byte, retrying when the system call is interrupted.
    func readByte() -> UInt8? {
        var byte: UInt8 = 0

        while true {
            let result = withUnsafeMutableBytes(of: &byte) { buffer in
                systemCalls.read(inputFileDescriptor, buffer.baseAddress, 1)
            }

            if result > 0 {
                return byte
            }
            if result < 0, systemCalls.errorCode() == EINTR {
                continue
            }
            if result < 0 {
                recordIOFailure(
                    operation: .read,
                    errorCode: systemCalls.errorCode(),
                    remainingByteCount: 1
                )
            }
            return nil
        }
    }

    /// Records the first terminal I/O failure until the runtime consumes it.
    func recordIOFailure(
        operation: TerminalIOFailure.Operation,
        errorCode: Int32,
        remainingByteCount: Int
    ) {
        guard pendingIOFailure == nil else { return }
        pendingIOFailure = TerminalIOFailure(
            operation: operation,
            errorCode: errorCode,
            remainingByteCount: remainingByteCount
        )
    }

    /// Appends a string's UTF-8 bytes to the frame buffer.
    func appendToBuffer(_ string: String) {
        frameBuffer.append(contentsOf: string.utf8)
    }

    /// Writes all buffered bytes to `STDOUT_FILENO` in a single syscall.
    func flushBuffer() {
        guard !frameBuffer.isEmpty else { return }
        frameBuffer.withUnsafeBufferPointer { buffer in
            guard let baseAddress = buffer.baseAddress else { return }
            writeBytes(baseAddress, count: buffer.count)
        }
        frameBuffer.removeAll(keepingCapacity: true)
    }

    /// Writes a string directly to `STDOUT_FILENO` without buffering.
    func writeImmediate(_ string: String) {
        // Safe: UTF8 string is valid UInt8 sequence; rebinding preserves memory layout.
        string.utf8CString.withUnsafeBufferPointer { buffer in
            let count = buffer.count - 1
            guard count >= 1, let baseAddress = buffer.baseAddress else { return }
            baseAddress.withMemoryRebound(to: UInt8.self, capacity: count) { pointer in
                writeBytes(pointer, count: count)
            }
        }
    }

    /// Writes every byte, retrying interrupted and partial system calls.
    func writeBytes(_ baseAddress: UnsafePointer<UInt8>, count: Int) {
        var written = 0

        while written < count {
            let result = systemCalls.write(outputFileDescriptor, baseAddress + written, count - written)
            if result > 0 {
                written += result
            } else if result < 0, systemCalls.errorCode() == EINTR {
                continue
            } else {
                recordIOFailure(
                    operation: .write,
                    errorCode: result < 0 ? systemCalls.errorCode() : EIO,
                    remainingByteCount: count - written
                )
                return
            }
        }
    }
}

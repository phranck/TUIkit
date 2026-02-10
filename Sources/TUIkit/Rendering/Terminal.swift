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
final class Terminal: TerminalProtocol {
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
    init() {
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
            let result = ioctl(STDOUT_FILENO, UInt(TIOCGWINSZ), &windowSize)
        #else
            let result = ioctl(STDOUT_FILENO, TIOCGWINSZ, &windowSize)
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
        tcgetattr(STDIN_FILENO, &raw)
        originalTermios = raw

        raw.c_lflag &= ~TermFlag(ECHO | ICANON | ISIG | IEXTEN)
        raw.c_iflag &= ~TermFlag(IXON | ICRNL | BRKINT | INPCK | ISTRIP)
        raw.c_oflag &= ~TermFlag(OPOST)
        raw.c_cflag |= TermFlag(CS8)

        withUnsafeMutablePointer(to: &raw.c_cc) { pointer in
            pointer.withMemoryRebound(to: cc_t.self, capacity: Int(NCCS)) { buffer in
                buffer[Int(VMIN)] = 0
                buffer[Int(VTIME)] = 0
            }
        }

        tcsetattr(STDIN_FILENO, TCSAFLUSH, &raw)
        isRawMode = true
    }

    /// Disables raw mode and restores normal terminal operation.
    func disableRawMode() {
        guard isRawMode, var original = originalTermios else { return }
        tcsetattr(STDIN_FILENO, TCSAFLUSH, &original)
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

    /// Reads raw bytes from the terminal, handling escape sequences.
    ///
    /// Reads exactly one key event worth of bytes. For escape sequences,
    /// reads byte-by-byte until a CSI terminator is found, preventing
    /// multiple sequences from being read at once during fast key repeat.
    ///
    /// - Parameter maxBytes: Maximum bytes to read (default: 8).
    /// - Returns: The bytes read, or empty array on timeout/error.
    func readBytes(maxBytes: Int = 8) -> [UInt8] {
        var buffer = [UInt8](repeating: 0, count: 1)
        let bytesRead = read(STDIN_FILENO, &buffer, 1)

        guard bytesRead > 0 else { return [] }

        // Not an escape sequence - return single byte
        guard buffer[0] == 0x1B else {
            return [buffer[0]]
        }

        // Read the next byte to determine sequence type
        var result: [UInt8] = [0x1B]
        var nextByte = [UInt8](repeating: 0, count: 1)

        let nextRead = read(STDIN_FILENO, &nextByte, 1)
        guard nextRead > 0 else {
            // Just ESC alone
            return result
        }

        result.append(nextByte[0])

        // CSI sequence: ESC [
        if nextByte[0] == 0x5B {  // '['
            // Read until we find a CSI terminator (letter A-Za-z or ~)
            for _ in 0..<(maxBytes - 2) {
                let paramRead = read(STDIN_FILENO, &nextByte, 1)
                guard paramRead > 0 else { break }

                result.append(nextByte[0])

                // CSI terminators: letters (0x40-0x7E) mark end of sequence
                // Common: A-D (arrows), H/F (home/end), Z (shift-tab), ~ (extended)
                if nextByte[0] >= 0x40 && nextByte[0] <= 0x7E {
                    break
                }
            }
        } else if nextByte[0] == 0x4F {  // SS3 sequence: ESC O
            // Read one more byte for F1-F4 keys
            let funcRead = read(STDIN_FILENO, &nextByte, 1)
            if funcRead > 0 {
                result.append(nextByte[0])
            }
        }
        // Alt+key: ESC followed by single key - already have both bytes

        return result
    }

    /// Reads a key event from the terminal.
    ///
    /// - Returns: The key event, or nil on timeout/error.
    func readKeyEvent() -> KeyEvent? {
        let bytes = readBytes()
        guard !bytes.isEmpty else { return nil }
        return KeyEvent.parse(bytes)
    }
}

// MARK: - Private Helpers

private extension Terminal {
    /// Appends a string's UTF-8 bytes to the frame buffer.
    func appendToBuffer(_ string: String) {
        frameBuffer.append(contentsOf: string.utf8)
    }

    /// Writes all buffered bytes to `STDOUT_FILENO` in a single syscall.
    func flushBuffer() {
        guard !frameBuffer.isEmpty else { return }
        frameBuffer.withUnsafeBufferPointer { buffer in
            guard let baseAddress = buffer.baseAddress else { return }
            let count = buffer.count
            var written = 0
            while written < count {
                let result = Foundation.write(STDOUT_FILENO, baseAddress + written, count - written)
                if result <= 0 { break }
                written += result
            }
        }
        frameBuffer.removeAll(keepingCapacity: true)
    }

    /// Writes a string directly to `STDOUT_FILENO` without buffering.
    func writeImmediate(_ string: String) {
        string.utf8CString.withUnsafeBufferPointer { buffer in
            let count = buffer.count - 1
            guard count >= 1, let baseAddress = buffer.baseAddress else { return }
            baseAddress.withMemoryRebound(to: UInt8.self, capacity: count) { pointer in
                var written = 0
                while written < count {
                    let result = Foundation.write(STDOUT_FILENO, pointer + written, count - written)
                    if result <= 0 { break }
                    written += result
                }
            }
        }
    }
}

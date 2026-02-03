//
//  Terminal.swift
//  TUIkit
//
//  Terminal abstraction for input and output.
//

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
final class Terminal: @unchecked Sendable {
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
    deinit {
        if isRawMode {
            disableRawMode()
        }
    }

    // MARK: - Terminal Size

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

    // MARK: - Raw Mode

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

        // Disable:
        // ECHO: Input is not displayed
        // ICANON: Canonical mode (line by line)
        // ISIG: Ctrl+C/Ctrl+Z signals
        // IEXTEN: Ctrl+V
        raw.c_lflag &= ~TermFlag(ECHO | ICANON | ISIG | IEXTEN)

        // Disable:
        // IXON: Ctrl+S/Ctrl+Q software flow control
        // ICRNL: CR to NL translation
        // BRKINT: Break signal
        // INPCK: Parity check
        // ISTRIP: Strip 8th bit
        raw.c_iflag &= ~TermFlag(IXON | ICRNL | BRKINT | INPCK | ISTRIP)

        // Disable output processing
        raw.c_oflag &= ~TermFlag(OPOST)

        // Set character size to 8 bits
        raw.c_cflag |= TermFlag(CS8)

        // Set timeouts: VMIN=0, VTIME=0 (non-blocking read).
        // Polling rate is controlled by usleep in the run loop (~40ms = 25 FPS).
        // c_cc is a tuple in Swift, so we need to use withUnsafeMutablePointer
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

    // MARK: - Output Buffering

    /// Begins a buffered frame.
    ///
    /// After this call, all ``write(_:)`` calls append to an internal
    /// `[UInt8]` buffer instead of issuing syscalls. Call ``endFrame()``
    /// to flush the collected output in a single `write()` syscall.
    ///
    /// This reduces per-frame syscalls from ~40+ (one per `moveCursor` +
    /// `write` pair) to exactly 1.
    ///
    /// Calling `beginFrame()` while already buffering is a no-op —
    /// nested frames are not supported.
    func beginFrame() {
        guard !isBuffering else { return }
        isBuffering = true
        frameBuffer.removeAll(keepingCapacity: true)
    }

    /// Ends a buffered frame and flushes all collected output.
    ///
    /// Writes the entire frame buffer to `STDOUT_FILENO` in a single
    /// syscall, then resets the buffer for the next frame.
    ///
    /// Calling `endFrame()` without a preceding ``beginFrame()`` is a
    /// no-op.
    func endFrame() {
        guard isBuffering else { return }
        isBuffering = false
        flushBuffer()
    }

    // MARK: - Output

    /// Writes a string to the terminal.
    ///
    /// When frame buffering is active (between ``beginFrame()`` and
    /// ``endFrame()``), the string's UTF-8 bytes are appended to the
    /// internal buffer. Otherwise, the bytes are written directly to
    /// `STDOUT_FILENO` via the POSIX `write` syscall.
    ///
    /// Direct writes bypass `stdout` entirely. On Linux (Glibc),
    /// `stdout` is a shared mutable global that Swift 6 strict
    /// concurrency rejects. Writing to `STDOUT_FILENO` avoids the
    /// issue without `@preconcurrency` or `nonisolated(unsafe)`
    /// workarounds.
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

    // MARK: - Alternate Screen

    /// Switches to the alternate screen buffer.
    ///
    /// The alternate buffer is useful for TUI apps, as the original
    /// terminal content is restored when exiting.
    func enterAlternateScreen() {
        write(ANSIRenderer.enterAlternateScreen)
    }

    /// Exits the alternate screen buffer.
    func exitAlternateScreen() {
        write(ANSIRenderer.exitAlternateScreen)
    }

    // MARK: - Private Output Helpers

    /// Appends a string's UTF-8 bytes to the frame buffer.
    ///
    /// - Parameter string: The string to buffer.
    private func appendToBuffer(_ string: String) {
        frameBuffer.append(contentsOf: string.utf8)
    }

    /// Writes all buffered bytes to `STDOUT_FILENO` in a single syscall.
    ///
    /// Handles partial writes by looping until all bytes are written.
    /// Resets the buffer after flushing.
    private func flushBuffer() {
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
    ///
    /// Used outside of frames (setup, teardown) where immediate
    /// output is required.
    ///
    /// - Parameter string: The string to write immediately.
    private func writeImmediate(_ string: String) {
        string.utf8CString.withUnsafeBufferPointer { buffer in
            // buffer includes null terminator — exclude it
            let count = buffer.count - 1
            guard count >= 1 else { return }
            buffer.baseAddress!.withMemoryRebound(to: UInt8.self, capacity: count) { pointer in
                var written = 0
                while written < count {
                    let result = Foundation.write(STDOUT_FILENO, pointer + written, count - written)
                    if result <= 0 { break }
                    written += result
                }
            }
        }
    }

    // MARK: - Input

    /// Reads raw bytes from the terminal, handling escape sequences.
    ///
    /// This method reads up to `maxBytes` bytes, which is needed for
    /// parsing escape sequences (arrow keys, function keys, etc.).
    ///
    /// - Parameter maxBytes: Maximum bytes to read (default: 8).
    /// - Returns: The bytes read, or empty array on timeout/error.
    func readBytes(maxBytes: Int = 8) -> [UInt8] {
        var buffer = [UInt8](repeating: 0, count: maxBytes)
        let bytesRead = read(STDIN_FILENO, &buffer, 1)

        guard bytesRead > 0 else { return [] }

        // If first byte is ESC, try to read more (escape sequence)
        if buffer[0] == 0x1B {
            // Short timeout read for rest of sequence
            var seqBuffer = [UInt8](repeating: 0, count: maxBytes - 1)
            let seqBytesRead = read(STDIN_FILENO, &seqBuffer, maxBytes - 1)

            if seqBytesRead > 0 {
                return [buffer[0]] + Array(seqBuffer.prefix(Int(seqBytesRead)))
            }
        }

        return [buffer[0]]
    }

    /// Reads a key event from the terminal.
    ///
    /// This is the preferred method for reading keyboard input,
    /// as it properly handles escape sequences.
    ///
    /// - Returns: The key event, or nil on timeout/error.
    func readKeyEvent() -> KeyEvent? {
        let bytes = readBytes()
        guard !bytes.isEmpty else { return nil }
        return KeyEvent.parse(bytes)
    }

}

//
//  Terminal.swift
//  TUIKit
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
public final class Terminal: @unchecked Sendable {
    /// The shared terminal instance.
    public static let shared = Terminal()

    /// The width of the terminal in characters.
    public var width: Int {
        getSize().width
    }

    /// The height of the terminal in lines.
    public var height: Int {
        getSize().height
    }

    /// Whether raw mode is active.
    private var isRawMode = false

    /// The original terminal settings.
    private var originalTermios: termios?

    /// Private initializer for singleton.
    private init() {}

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
    public func getSize() -> (width: Int, height: Int) {
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
    public func enableRawMode() {
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

        // Set timeouts: VMIN=0, VTIME=1 (100ms timeout)
        // c_cc is a tuple in Swift, so we need to use withUnsafeMutablePointer
        withUnsafeMutablePointer(to: &raw.c_cc) { pointer in
            pointer.withMemoryRebound(to: cc_t.self, capacity: Int(NCCS)) { buffer in
                buffer[Int(VMIN)] = 0
                buffer[Int(VTIME)] = 1
            }
        }

        tcsetattr(STDIN_FILENO, TCSAFLUSH, &raw)
        isRawMode = true
    }

    /// Disables raw mode and restores normal terminal operation.
    public func disableRawMode() {
        guard isRawMode, var original = originalTermios else { return }
        tcsetattr(STDIN_FILENO, TCSAFLUSH, &original)
        isRawMode = false
    }

    // MARK: - Output

    /// Writes a string to the terminal.
    ///
    /// - Parameter string: The string to write.
    public func write(_ string: String) {
        print(string, terminator: "")
        fflush(stdout)
    }

    /// Writes a string and moves to a new line.
    ///
    /// - Parameter string: The string to write.
    public func writeLine(_ string: String = "") {
        print(string)
        fflush(stdout)
    }

    /// Clears the screen and moves cursor to position (1,1).
    public func clear() {
        write(ANSIRenderer.clearScreen + ANSIRenderer.moveCursor(toRow: 1, column: 1))
    }

    /// Fills the entire screen with a background color.
    ///
    /// This clears the screen and fills every cell with the specified color.
    /// Use this to set a consistent background before rendering content.
    ///
    /// - Parameter color: The background color to fill.
    public func fillBackground(_ color: Color) {
        let size = getSize()
        let bgCode = ANSIRenderer.backgroundCode(for: color)

        // Move to top-left and fill each line
        var output = ANSIRenderer.moveCursor(toRow: 1, column: 1)
        let emptyLine = bgCode + String(repeating: " ", count: size.width) + ANSIRenderer.reset

        for _ in 0..<size.height {
            output += emptyLine
        }

        // Move cursor back to top-left
        output += ANSIRenderer.moveCursor(toRow: 1, column: 1)
        write(output)
    }

    /// Moves the cursor to the specified position.
    ///
    /// - Parameters:
    ///   - row: The row (1-based).
    ///   - column: The column (1-based).
    public func moveCursor(toRow row: Int, column: Int) {
        write(ANSIRenderer.moveCursor(toRow: row, column: column))
    }

    /// Hides the cursor.
    public func hideCursor() {
        write(ANSIRenderer.hideCursor)
    }

    /// Shows the cursor.
    public func showCursor() {
        write(ANSIRenderer.showCursor)
    }

    // MARK: - Alternate Screen

    /// Switches to the alternate screen buffer.
    ///
    /// The alternate buffer is useful for TUI apps, as the original
    /// terminal content is restored when exiting.
    public func enterAlternateScreen() {
        write(ANSIRenderer.enterAlternateScreen)
    }

    /// Exits the alternate screen buffer.
    public func exitAlternateScreen() {
        write(ANSIRenderer.exitAlternateScreen)
    }

    // MARK: - Input

    /// Reads a single character from the terminal.
    ///
    /// Blocks until a character is available (if raw mode is active,
    /// for a maximum of 100ms).
    ///
    /// - Returns: The read character or nil on timeout/error.
    public func readChar() -> Character? {
        var byte: UInt8 = 0
        let bytesRead = read(STDIN_FILENO, &byte, 1)

        if bytesRead == 1 {
            return Character(UnicodeScalar(byte))
        }
        return nil
    }

    /// Reads raw bytes from the terminal, handling escape sequences.
    ///
    /// This method reads up to `maxBytes` bytes, which is needed for
    /// parsing escape sequences (arrow keys, function keys, etc.).
    ///
    /// - Parameter maxBytes: Maximum bytes to read (default: 8).
    /// - Returns: The bytes read, or empty array on timeout/error.
    public func readBytes(maxBytes: Int = 8) -> [UInt8] {
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
    public func readKeyEvent() -> KeyEvent? {
        let bytes = readBytes()
        guard !bytes.isEmpty else { return nil }
        return KeyEvent.parse(bytes)
    }

    /// Reads a complete line from the terminal.
    ///
    /// - Returns: The input line without newline.
    public func readLine() -> String? {
        Swift.readLine()
    }
}

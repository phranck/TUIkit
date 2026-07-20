//  TUIKit - Terminal UI Kit for Swift
//  TerminalProtocol.swift
//
//  Created by LAYERED.work
//  License: MIT

/// A protocol abstracting terminal operations for testability.
///
/// `TerminalProtocol` defines the interface for terminal I/O operations,
/// allowing the real `Terminal` implementation to be replaced with mocks
/// in tests. This enables testing of rendering logic without actual
/// terminal interaction.
///
/// ## Conforming Types
///
/// - `Terminal`: The real implementation that interacts with the terminal.
/// - `MockTerminal`: A test double that captures output for verification.
///
/// ## Thread Safety
///
/// All conforming types must be `@MainActor` isolated since terminal
/// operations are part of the render loop and must occur on the main thread.
///
/// ## Example
///
/// ```swift
/// // In production code:
/// let terminal: any TerminalProtocol = Terminal()
///
/// // In tests:
/// let mockTerminal = MockTerminal()
/// mockTerminal.size = (80, 24)
/// mockTerminal.keyEventQueue = [.init(key: .enter)]
/// ```
@MainActor
public protocol TerminalProtocol: AnyObject, Sendable {
    /// Returns the current terminal size.
    ///
    /// - Returns: A tuple with width (columns) and height (rows).
    func getSize() -> (width: Int, height: Int)

    /// Writes a string to the terminal.
    ///
    /// When frame buffering is active (between ``beginFrame()`` and
    /// ``endFrame()``), the string may be buffered. Otherwise, it is
    /// written immediately.
    ///
    /// - Parameter string: The string to write.
    func write(_ string: String)

    /// Reads a key event from the terminal.
    ///
    /// - Returns: The key event, or `nil` if no input is available.
    func readKeyEvent() -> KeyEvent?

    /// Enables raw mode for direct character handling.
    ///
    /// In raw mode:
    /// - Each keystroke is reported immediately (without Enter)
    /// - Echo is disabled
    /// - Signals like Ctrl+C are not automatically processed
    func enableRawMode()

    /// Disables raw mode and restores normal terminal operation.
    func disableRawMode()

    /// Begins a buffered frame.
    ///
    /// After this call, all ``write(_:)`` calls may be collected in an
    /// internal buffer instead of issuing syscalls. Call ``endFrame()``
    /// to flush the collected output.
    func beginFrame()

    /// Ends a buffered frame and flushes all collected output.
    func endFrame()

    /// Moves the cursor to the specified position.
    ///
    /// - Parameters:
    ///   - row: The row (1-based).
    ///   - column: The column (1-based).
    func moveCursor(toRow row: Int, column: Int)

    /// Hides the cursor.
    func hideCursor()

    /// Shows the cursor.
    func showCursor()

    /// Switches to the alternate screen buffer.
    func enterAlternateScreen()

    /// Exits the alternate screen buffer.
    func exitAlternateScreen()
}

// MARK: - Terminal I/O Failure Reporting

/// A terminal system call that failed permanently.
internal struct TerminalIOFailure: Error, Equatable, Sendable, CustomStringConvertible {
    /// The terminal operation that failed.
    enum Operation: String, Equatable, Sendable {
        case read
        case write
    }

    /// The terminal operation that failed.
    let operation: Operation

    /// The POSIX error code returned by the platform.
    let errorCode: Int32

    /// Bytes that could not be transferred.
    let remainingByteCount: Int

    var description: String {
        "Terminal \(operation.rawValue) failed with POSIX error \(errorCode); "
            + "\(remainingByteCount) byte(s) remained."
    }
}

/// Supplies terminal I/O failures to the application runtime.
@MainActor
internal protocol TerminalFailureReporting: AnyObject {
    /// Removes and returns the first pending terminal I/O failure.
    func takeIOFailure() -> TerminalIOFailure?
}

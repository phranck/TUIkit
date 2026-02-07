//  TUIKit - Terminal UI Kit for Swift
//  MockTerminal.swift
//
//  Created by LAYERED.work
//  License: MIT

@testable import TUIkit

/// A mock terminal for testing that captures output and simulates input.
///
/// `MockTerminal` implements ``TerminalProtocol`` without performing actual
/// terminal I/O. Use it to:
/// - Capture rendered output for verification
/// - Simulate key events for testing input handling
/// - Control terminal size for layout tests
///
/// ## Example
///
/// ```swift
/// @Test func rendersCorrectOutput() async {
///     let terminal = MockTerminal()
///     terminal.size = (80, 24)
///
///     // ... render something using terminal ...
///
///     #expect(terminal.writtenOutput.contains("Expected text"))
/// }
///
/// @Test func handlesKeyPress() async {
///     let terminal = MockTerminal()
///     terminal.keyEventQueue = [KeyEvent(key: .enter)]
///
///     let event = terminal.readKeyEvent()
///     #expect(event?.key == .enter)
/// }
/// ```
@MainActor
final class MockTerminal: TerminalProtocol {
    /// The simulated terminal size.
    var size: (width: Int, height: Int) = (80, 24)

    /// All strings written via ``write(_:)``.
    private(set) var writtenOutput: [String] = []

    /// Key events to return from ``readKeyEvent()``.
    ///
    /// Events are removed from the front of the queue as they are read.
    var keyEventQueue: [KeyEvent] = []

    /// Whether raw mode is currently enabled.
    private(set) var isRawModeEnabled = false

    /// Whether the cursor is currently hidden.
    private(set) var isCursorHidden = false

    /// Whether we are in the alternate screen buffer.
    private(set) var isInAlternateScreen = false

    /// The current cursor position (row, column), 1-based.
    private(set) var cursorPosition: (row: Int, column: Int) = (1, 1)

    /// Whether frame buffering is active.
    private var isBuffering = false

    /// Buffer for collecting writes during a frame.
    private var frameBuffer: [String] = []

    /// Creates a new mock terminal with default settings.
    init() {}
}

// MARK: - TerminalProtocol

extension MockTerminal {
    func getSize() -> (width: Int, height: Int) {
        size
    }

    func write(_ string: String) {
        if isBuffering {
            frameBuffer.append(string)
        } else {
            writtenOutput.append(string)
        }
    }

    func readKeyEvent() -> KeyEvent? {
        guard !keyEventQueue.isEmpty else { return nil }
        return keyEventQueue.removeFirst()
    }

    func enableRawMode() {
        isRawModeEnabled = true
    }

    func disableRawMode() {
        isRawModeEnabled = false
    }

    func beginFrame() {
        guard !isBuffering else { return }
        isBuffering = true
        frameBuffer.removeAll()
    }

    func endFrame() {
        guard isBuffering else { return }
        isBuffering = false
        writtenOutput.append(contentsOf: frameBuffer)
        frameBuffer.removeAll()
    }

    func moveCursor(toRow row: Int, column: Int) {
        cursorPosition = (row, column)
        write(ANSIRenderer.moveCursor(toRow: row, column: column))
    }

    func hideCursor() {
        isCursorHidden = true
        write(ANSIRenderer.hideCursor)
    }

    func showCursor() {
        isCursorHidden = false
        write(ANSIRenderer.showCursor)
    }

    func enterAlternateScreen() {
        isInAlternateScreen = true
        write(ANSIRenderer.enterAlternateScreen)
    }

    func exitAlternateScreen() {
        isInAlternateScreen = false
        write(ANSIRenderer.exitAlternateScreen)
    }
}

// MARK: - Test Helpers

extension MockTerminal {
    /// Resets all state to defaults.
    func reset() {
        writtenOutput.removeAll()
        keyEventQueue.removeAll()
        frameBuffer.removeAll()
        isRawModeEnabled = false
        isCursorHidden = false
        isInAlternateScreen = false
        isBuffering = false
        cursorPosition = (1, 1)
        size = (80, 24)
    }

    /// Returns all written output joined as a single string.
    var allOutput: String {
        writtenOutput.joined()
    }

    /// Checks if any written output contains the given substring.
    func outputContains(_ substring: String) -> Bool {
        writtenOutput.contains { $0.contains(substring) }
    }
}

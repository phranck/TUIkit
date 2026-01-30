//
//  KeyEvent.swift
//  TUIKit
//
//  Keyboard event handling for TUIKit.
//

import Foundation

// MARK: - Key Event

/// Represents a keyboard event.
public struct KeyEvent: Equatable, Sendable {
    /// The key that was pressed.
    public let key: Key

    /// Whether the Ctrl modifier was held.
    public let ctrl: Bool

    /// Whether the Alt/Option modifier was held.
    public let alt: Bool

    /// Whether the Shift modifier was held.
    public let shift: Bool

    /// Creates a key event.
    public init(key: Key, ctrl: Bool = false, alt: Bool = false, shift: Bool = false) {
        self.key = key
        self.ctrl = ctrl
        self.alt = alt
        self.shift = shift
    }

    /// Creates a key event from a character.
    public init(character: Character) {
        self.key = .character(character)
        self.ctrl = false
        self.alt = false
        self.shift = character.isUppercase
    }
}

// MARK: - Key

/// Represents a keyboard key.
public enum Key: Hashable, Sendable {
    // Special keys
    case escape
    case enter
    case tab
    case backspace
    case delete

    // Arrow keys
    case up
    case down
    case left
    case right

    // Function keys
    case home
    case end
    case pageUp
    case pageDown

    // Character key
    case character(Character)

    /// Creates a Key from a character if it's a simple character.
    public static func from(_ char: Character) -> Self {
        .character(char)
    }
}

// MARK: - ASCII Byte Constants

/// Named constants for ASCII byte values used in terminal input parsing.
///
/// Replaces raw hex literals (e.g. `0x1B`, `0x0D`) with readable names,
/// making the key parsing logic self-documenting.
private enum ASCIIByte {
    // Control characters
    static let backspace: UInt8 = 0x08
    static let tab: UInt8 = 0x09
    static let lineFeed: UInt8 = 0x0A
    static let carriageReturn: UInt8 = 0x0D
    static let escape: UInt8 = 0x1B
    static let delete: UInt8 = 0x7F

    // Ctrl+key range (Ctrl+A = 0x01 … Ctrl+Z = 0x1A)
    static let ctrlRangeStart: UInt8 = 0x01
    static let ctrlRangeEnd: UInt8 = 0x1A
    static let ctrlToLowerOffset: UInt8 = 0x60

    // Printable ASCII range
    static let printableStart: UInt8 = 0x20
    static let printableEnd: UInt8 = 0x7E

    // CSI introducer
    static let openBracket: UInt8 = 0x5B  // '['

    // Arrow / navigation keys (CSI final byte)
    static let arrowUp: UInt8 = 0x41  // 'A'
    static let arrowDown: UInt8 = 0x42  // 'B'
    static let arrowRight: UInt8 = 0x43  // 'C'
    static let arrowLeft: UInt8 = 0x44  // 'D'
    static let home: UInt8 = 0x48  // 'H'
    static let end: UInt8 = 0x46  // 'F'
    static let tilde: UInt8 = 0x7E  // '~' (extended key terminator)
}

// MARK: - Key Parsing

extension KeyEvent {
    /// Parses raw terminal input into a KeyEvent.
    ///
    /// Terminal sends escape sequences for special keys:
    /// - Arrow keys: ESC [ A/B/C/D
    /// - Function keys: ESC [ 1~, ESC [ 2~, etc.
    /// - Ctrl+key: ASCII 1-26
    ///
    /// - Parameter bytes: The raw input bytes.
    /// - Returns: The parsed key event, or nil if incomplete.
    public static func parse(_ bytes: [UInt8]) -> KeyEvent? {
        guard !bytes.isEmpty else { return nil }

        // Single byte
        if bytes.count == 1 {
            return parseSingleByte(bytes[0])
        }

        // Escape sequence
        if bytes[0] == ASCIIByte.escape {
            return parseEscapeSequence(bytes)
        }

        // UTF-8 character
        if let string = String(bytes: bytes, encoding: .utf8),
            let char = string.first
        {
            return KeyEvent(character: char)
        }

        return nil
    }

    /// Parses a single byte into a key event.
    private static func parseSingleByte(_ byte: UInt8) -> KeyEvent? {
        switch byte {
        case ASCIIByte.escape:
            return KeyEvent(key: .escape)
        case ASCIIByte.carriageReturn, ASCIIByte.lineFeed:
            return KeyEvent(key: .enter)
        case ASCIIByte.tab:
            return KeyEvent(key: .tab)
        case ASCIIByte.delete, ASCIIByte.backspace:
            return KeyEvent(key: .backspace)
        case ASCIIByte.ctrlRangeStart...ASCIIByte.ctrlRangeEnd:
            let char = Character(UnicodeScalar(byte + ASCIIByte.ctrlToLowerOffset))
            return KeyEvent(key: .character(char), ctrl: true)
        case ASCIIByte.printableStart...ASCIIByte.printableEnd:
            let char = Character(UnicodeScalar(byte))
            return KeyEvent(character: char)
        default:
            return nil
        }
    }

    /// Parses an escape sequence into a key event.
    private static func parseEscapeSequence(_ bytes: [UInt8]) -> KeyEvent? {
        guard bytes.count >= 2 else {
            // Just ESC alone
            return KeyEvent(key: .escape)
        }

        // CSI sequences: ESC [
        if bytes[1] == ASCIIByte.openBracket {
            return parseCSISequence(Array(bytes.dropFirst(2)))
        }

        // Alt+key: ESC followed by key
        if bytes.count == 2 {
            if let keyEvent = parseSingleByte(bytes[1]) {
                return KeyEvent(key: keyEvent.key, ctrl: keyEvent.ctrl, alt: true, shift: keyEvent.shift)
            }
        }

        return KeyEvent(key: .escape)
    }

    /// Parses a CSI (Control Sequence Introducer) sequence.
    private static func parseCSISequence(_ params: [UInt8]) -> KeyEvent? {
        guard !params.isEmpty else { return nil }

        // Arrow keys: A=up, B=down, C=right, D=left
        switch params.last {
        case ASCIIByte.arrowUp:
            return KeyEvent(key: .up)
        case ASCIIByte.arrowDown:
            return KeyEvent(key: .down)
        case ASCIIByte.arrowRight:
            return KeyEvent(key: .right)
        case ASCIIByte.arrowLeft:
            return KeyEvent(key: .left)
        case ASCIIByte.home:
            return KeyEvent(key: .home)
        case ASCIIByte.end:
            return KeyEvent(key: .end)
        case ASCIIByte.tilde:
            return parseExtendedKey(params)
        default:
            return nil
        }
    }

    /// Parses extended key sequences (ESC [ n ~).
    private static func parseExtendedKey(_ params: [UInt8]) -> KeyEvent? {
        // Parse the number before '~'
        let numberBytes = params.dropLast()
        guard let string = String(bytes: numberBytes, encoding: .ascii),
            let number = Int(string)
        else {
            return nil
        }

        switch number {
        case 1:
            return KeyEvent(key: .home)
        case 2:
            return nil  // Insert - not commonly used
        case 3:
            return KeyEvent(key: .delete)
        case 4:
            return KeyEvent(key: .end)
        case 5:
            return KeyEvent(key: .pageUp)
        case 6:
            return KeyEvent(key: .pageDown)
        default:
            return nil
        }
    }
}

// MARK: - Key Event Handler

/// Global key event handler.
///
/// Views can register handlers that are called when keys are pressed.
/// Handlers are processed in reverse order (most recent first).
public final class KeyEventDispatcher: @unchecked Sendable {
    /// The shared dispatcher instance.
    public static let shared = KeyEventDispatcher()

    /// Registered key handlers.
    private var handlers: [(KeyEvent) -> Bool] = []

    private init() {}

    /// Registers a key handler.
    ///
    /// - Parameter handler: A closure that returns true if the key was handled.
    public func addHandler(_ handler: @escaping (KeyEvent) -> Bool) {
        handlers.append(handler)
    }

    /// Clears all handlers.
    public func clearHandlers() {
        handlers.removeAll()
    }

    /// Dispatches a key event to handlers.
    ///
    /// - Parameter event: The key event to dispatch.
    /// - Returns: True if any handler consumed the event.
    @discardableResult
    public func dispatch(_ event: KeyEvent) -> Bool {
        // Process in reverse order (most recent handlers first)
        for handler in handlers.reversed() where handler(event) {
            return true
        }
        return false
    }
}

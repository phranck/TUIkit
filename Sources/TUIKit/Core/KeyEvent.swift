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
    public static func from(_ char: Character) -> Key {
        .character(char)
    }
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
        if bytes[0] == 0x1B {
            return parseEscapeSequence(bytes)
        }

        // UTF-8 character
        if let string = String(bytes: bytes, encoding: .utf8),
           let char = string.first {
            return KeyEvent(character: char)
        }

        return nil
    }

    /// Parses a single byte into a key event.
    private static func parseSingleByte(_ byte: UInt8) -> KeyEvent? {
        switch byte {
        case 0x1B:  // Escape
            return KeyEvent(key: .escape)
        case 0x0D, 0x0A:  // Enter (CR or LF)
            return KeyEvent(key: .enter)
        case 0x09:  // Tab
            return KeyEvent(key: .tab)
        case 0x7F, 0x08:  // Backspace (DEL or BS)
            return KeyEvent(key: .backspace)
        case 0x01...0x1A:  // Ctrl+A through Ctrl+Z
            let char = Character(UnicodeScalar(byte + 0x60))
            return KeyEvent(key: .character(char), ctrl: true)
        case 0x20...0x7E:  // Printable ASCII
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
        if bytes[1] == 0x5B {  // '['
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
        case 0x41:  // 'A'
            return KeyEvent(key: .up)
        case 0x42:  // 'B'
            return KeyEvent(key: .down)
        case 0x43:  // 'C'
            return KeyEvent(key: .right)
        case 0x44:  // 'D'
            return KeyEvent(key: .left)
        case 0x48:  // 'H' - Home
            return KeyEvent(key: .home)
        case 0x46:  // 'F' - End
            return KeyEvent(key: .end)
        case 0x7E:  // '~' - Extended keys
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
              let number = Int(string) else {
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
        for handler in handlers.reversed() {
            if handler(event) {
                return true
            }
        }
        return false
    }
}

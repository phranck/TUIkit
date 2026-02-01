//
//  KeyEventTests.swift
//  TUIkit
//
//  Tests for Key enum, KeyEvent creation, and KeyEvent.parse() terminal input parsing.
//

import Testing

@testable import TUIkit

// MARK: - Key Enum Tests

@Suite("Key Enum Tests")
struct KeyEnumTests {

    @Test("Key.from creates character key")
    func keyFromCharacter() {
        let key = Key.from("a")
        #expect(key == .character("a"))
    }

    @Test("Key is Hashable")
    func keyHashable() {
        let set: Set<Key> = [.enter, .tab, .escape, .enter]
        #expect(set.count == 3) // .enter deduped
    }

    @Test("Character keys with different characters are not equal")
    func characterKeysInequality() {
        #expect(Key.character("a") != Key.character("b"))
    }

    @Test("Same character keys are equal")
    func characterKeysEquality() {
        #expect(Key.character("x") == Key.character("x"))
    }

    @Test("Special keys are distinct")
    func specialKeysDistinct() {
        let keys: [Key] = [.escape, .enter, .tab, .backspace, .delete,
                           .up, .down, .left, .right,
                           .home, .end, .pageUp, .pageDown]
        let set = Set(keys)
        #expect(set.count == 13)
    }
}

// MARK: - KeyEvent Creation Tests

@Suite("KeyEvent Creation Tests")
struct KeyEventCreationTests {

    @Test("KeyEvent character init detects uppercase as shift")
    func characterInitShift() {
        let upper = KeyEvent(character: "A")
        #expect(upper.shift == true)
        #expect(upper.key == .character("A"))

        let lower = KeyEvent(character: "a")
        #expect(lower.shift == false)
        #expect(lower.key == .character("a"))
    }

    @Test("KeyEvent character init with non-letter")
    func characterInitNonLetter() {
        let event = KeyEvent(character: "5")
        #expect(event.key == .character("5"))
        #expect(event.shift == false)
    }

    @Test("KeyEvent is Equatable")
    func equatable() {
        let eventA = KeyEvent(key: .enter, ctrl: false, alt: false, shift: false)
        let eventB = KeyEvent(key: .enter)
        #expect(eventA == eventB)

        let eventC = KeyEvent(key: .enter, ctrl: true)
        #expect(eventA != eventC)
    }
}

// MARK: - KeyEvent Parsing Tests

@Suite("KeyEvent Parse Tests")
struct KeyEventParseTests {

    @Test("Parse empty bytes returns nil")
    func parseEmpty() {
        #expect(KeyEvent.parse([]) == nil)
    }

    @Test("Parse escape byte")
    func parseEscape() {
        let event = KeyEvent.parse([0x1B])
        #expect(event?.key == .escape)
    }

    @Test("Parse enter (carriage return)")
    func parseEnter() {
        let event = KeyEvent.parse([0x0D])
        #expect(event?.key == .enter)
    }

    @Test("Parse enter (line feed)")
    func parseLineFeed() {
        let event = KeyEvent.parse([0x0A])
        #expect(event?.key == .enter)
    }

    @Test("Parse tab")
    func parseTab() {
        let event = KeyEvent.parse([0x09])
        #expect(event?.key == .tab)
    }

    @Test("Parse backspace (0x7F)")
    func parseBackspaceDelete() {
        let event = KeyEvent.parse([0x7F])
        #expect(event?.key == .backspace)
    }

    @Test("Parse backspace (0x08)")
    func parseBackspace() {
        let event = KeyEvent.parse([0x08])
        #expect(event?.key == .backspace)
    }

    @Test("Parse printable character")
    func parsePrintable() {
        let event = KeyEvent.parse([0x41]) // 'A'
        #expect(event?.key == .character("A"))
        #expect(event?.shift == true)
    }

    @Test("Parse lowercase character")
    func parseLowercase() {
        let event = KeyEvent.parse([0x61]) // 'a'
        #expect(event?.key == .character("a"))
        #expect(event?.shift == false)
    }

    @Test("Parse space character")
    func parseSpace() {
        let event = KeyEvent.parse([0x20])
        #expect(event?.key == .character(" "))
    }

    @Test("Parse Ctrl+A")
    func parseCtrlA() {
        let event = KeyEvent.parse([0x01])
        #expect(event?.key == .character("a"))
        #expect(event?.ctrl == true)
    }

    @Test("Parse Ctrl+C")
    func parseCtrlC() {
        let event = KeyEvent.parse([0x03])
        #expect(event?.key == .character("c"))
        #expect(event?.ctrl == true)
    }

    @Test("Parse Ctrl+Z")
    func parseCtrlZ() {
        let event = KeyEvent.parse([0x1A])
        #expect(event?.key == .character("z"))
        #expect(event?.ctrl == true)
    }

    // MARK: Arrow Keys (CSI Sequences)

    @Test("Parse arrow up (ESC [ A)")
    func parseArrowUp() {
        let event = KeyEvent.parse([0x1B, 0x5B, 0x41])
        #expect(event?.key == .up)
    }

    @Test("Parse arrow down (ESC [ B)")
    func parseArrowDown() {
        let event = KeyEvent.parse([0x1B, 0x5B, 0x42])
        #expect(event?.key == .down)
    }

    @Test("Parse arrow right (ESC [ C)")
    func parseArrowRight() {
        let event = KeyEvent.parse([0x1B, 0x5B, 0x43])
        #expect(event?.key == .right)
    }

    @Test("Parse arrow left (ESC [ D)")
    func parseArrowLeft() {
        let event = KeyEvent.parse([0x1B, 0x5B, 0x44])
        #expect(event?.key == .left)
    }

    // MARK: Navigation Keys

    @Test("Parse home (ESC [ H)")
    func parseHome() {
        let event = KeyEvent.parse([0x1B, 0x5B, 0x48])
        #expect(event?.key == .home)
    }

    @Test("Parse end (ESC [ F)")
    func parseEnd() {
        let event = KeyEvent.parse([0x1B, 0x5B, 0x46])
        #expect(event?.key == .end)
    }

    // MARK: Extended Keys (ESC [ n ~)

    @Test("Parse home via extended (ESC [ 1 ~)")
    func parseHomeExtended() {
        let event = KeyEvent.parse([0x1B, 0x5B, 0x31, 0x7E])
        #expect(event?.key == .home)
    }

    @Test("Parse delete (ESC [ 3 ~)")
    func parseDelete() {
        let event = KeyEvent.parse([0x1B, 0x5B, 0x33, 0x7E])
        #expect(event?.key == .delete)
    }

    @Test("Parse end via extended (ESC [ 4 ~)")
    func parseEndExtended() {
        let event = KeyEvent.parse([0x1B, 0x5B, 0x34, 0x7E])
        #expect(event?.key == .end)
    }

    @Test("Parse page up (ESC [ 5 ~)")
    func parsePageUp() {
        let event = KeyEvent.parse([0x1B, 0x5B, 0x35, 0x7E])
        #expect(event?.key == .pageUp)
    }

    @Test("Parse page down (ESC [ 6 ~)")
    func parsePageDown() {
        let event = KeyEvent.parse([0x1B, 0x5B, 0x36, 0x7E])
        #expect(event?.key == .pageDown)
    }

    @Test("Parse insert returns nil (ESC [ 2 ~)")
    func parseInsertReturnsNil() {
        let event = KeyEvent.parse([0x1B, 0x5B, 0x32, 0x7E])
        #expect(event == nil)
    }

    // MARK: Alt+Key

    @Test("Parse Alt+a")
    func parseAltA() {
        let event = KeyEvent.parse([0x1B, 0x61]) // ESC + 'a'
        #expect(event?.key == .character("a"))
        #expect(event?.alt == true)
    }

    @Test("Parse Alt+Enter")
    func parseAltEnter() {
        let event = KeyEvent.parse([0x1B, 0x0D]) // ESC + CR
        #expect(event?.key == .enter)
        #expect(event?.alt == true)
    }

    // MARK: UTF-8

    @Test("Parse UTF-8 multi-byte character")
    func parseUtf8() {
        // "ü" = 0xC3 0xBC
        let event = KeyEvent.parse([0xC3, 0xBC])
        #expect(event?.key == .character("ü"))
    }

    @Test("Parse emoji UTF-8")
    func parseEmoji() {
        // "😀" = 0xF0 0x9F 0x98 0x80
        let event = KeyEvent.parse([0xF0, 0x9F, 0x98, 0x80])
        #expect(event?.key == .character("😀"))
    }

    // MARK: Edge Cases

    @Test("Parse incomplete CSI returns nil")
    func parseIncompleteCSI() {
        let event = KeyEvent.parse([0x1B, 0x5B])
        #expect(event == nil)
    }

    @Test("Parse unknown CSI final byte returns nil")
    func parseUnknownCSI() {
        let event = KeyEvent.parse([0x1B, 0x5B, 0x5A])
        #expect(event == nil)
    }

    @Test("Parse bare escape sequence returns escape")
    func parseBareEscape() {
        let event = KeyEvent.parse([0x1B])
        #expect(event?.key == .escape)
    }
}

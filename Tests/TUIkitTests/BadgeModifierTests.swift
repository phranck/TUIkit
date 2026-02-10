//  🖥️ TUIKit — Terminal UI Kit for Swift
//  BadgeModifierTests.swift
//
//  Created by LAYERED.work
//  License: MIT

import Testing
@testable import TUIkit

@Suite("Badge Modifier Tests")
struct BadgeModifierTests {
    // MARK: - Int Badge Tests

    @Test("Badge with count 5 displays")
    func testIntBadgeDisplaysCount() {
        let badge = BadgeValue.int(5)
        #expect(badge.displayText == "5")
        #expect(!badge.isHidden)
    }

    @Test("Badge with count 0 hides")
    func testIntBadgeZeroHides() {
        let badge = BadgeValue.int(0)
        #expect(badge.isHidden)
    }

    @Test("Badge with negative count displays")
    func testIntBadgeNegativeDisplays() {
        let badge = BadgeValue.int(-1)
        #expect(badge.displayText == "-1")
        #expect(!badge.isHidden)
    }

    @Test("Badge with large count displays")
    func testIntBadgeLargeCount() {
        let badge = BadgeValue.int(999)
        #expect(badge.displayText == "999")
        #expect(!badge.isHidden)
    }

    // MARK: - String Badge Tests

    @Test("Badge with string displays text")
    func testStringBadgeDisplaysText() {
        let badge = BadgeValue.string("New")
        #expect(badge.displayText == "New")
        #expect(!badge.isHidden)
    }

    @Test("Badge with nil string hides")
    func testStringBadgeNilHides() {
        let badge = BadgeValue.string(Optional<String>(nil))
        #expect(badge.isHidden)
    }

    @Test("Badge with empty string hides")
    func testStringBadgeEmptyHides() {
        let badge = BadgeValue.string("")
        #expect(badge.isHidden)
    }

    @Test("Badge with whitespace string displays")
    func testStringBadgeWhitespaceDisplays() {
        let badge = BadgeValue.string("   ")
        #expect(badge.displayText == "   ")
        #expect(!badge.isHidden)
    }

    // MARK: - Equatable Tests

    @Test("Equal int badges")
    func testEqualIntBadges() {
        let badge1 = BadgeValue.int(5)
        let badge2 = BadgeValue.int(5)
        #expect(badge1 == badge2)
    }

    @Test("Different int badges")
    func testDifferentIntBadges() {
        let badge1 = BadgeValue.int(5)
        let badge2 = BadgeValue.int(3)
        #expect(badge1 != badge2)
    }

    @Test("Equal string badges")
    func testEqualStringBadges() {
        let badge1 = BadgeValue.string("New")
        let badge2 = BadgeValue.string("New")
        #expect(badge1 == badge2)
    }

    @Test("Different string badges")
    func testDifferentStringBadges() {
        let badge1 = BadgeValue.string("New")
        let badge2 = BadgeValue.string("Updated")
        #expect(badge1 != badge2)
    }

    @Test("Int and string badges are not equal")
    func testIntAndStringBadgesNotEqual() {
        let badge1 = BadgeValue.int(5)
        let badge2 = BadgeValue.string("5")
        #expect(badge1 != badge2)
    }

    // MARK: - Edge Cases

    @Test("Badge displayText with special characters")
    func testBadgeSpecialCharacters() {
        let badge = BadgeValue.string("●○▸")
        #expect(badge.displayText == "●○▸")
        #expect(!badge.isHidden)
    }

    @Test("Badge displayText with numbers")
    func testBadgeNumbers() {
        let badge = BadgeValue.string("123")
        #expect(badge.displayText == "123")
        #expect(!badge.isHidden)
    }

    @Test("Badge with very long string")
    func testBadgeLongString() {
        let longString = String(repeating: "x", count: 50)
        let badge = BadgeValue.string(longString)
        #expect(badge.displayText == longString)
        #expect(!badge.isHidden)
    }

    // MARK: - Environment Integration

    @Test("Badge stores in environment")
    func testBadgeEnvironmentStorage() {
        var env = EnvironmentValues()
        let badge = BadgeValue.int(5)
        env.badgeValue = badge
        #expect(env.badgeValue == badge)
    }

    @Test("Environment badge default is nil")
    func testEnvironmentBadgeDefault() {
        let env = EnvironmentValues()
        #expect(env.badgeValue == nil)
    }

    @Test("Badge environment can be cleared")
    func testClearBadgeEnvironment() {
        var env = EnvironmentValues()
        env.badgeValue = .int(5)
        env.badgeValue = nil
        #expect(env.badgeValue == nil)
    }

    @Test("BadgeValue is Sendable")
    func testBadgeValueSendable() {
        let badge = BadgeValue.int(5)
        let _: BadgeValue = badge  // Type check
    }
}

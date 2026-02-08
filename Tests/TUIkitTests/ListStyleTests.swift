//  🖥️ TUIKit — Terminal UI Kit for Swift
//  ListStyleTests.swift
//
//  Created by LAYERED.work
//  License: MIT

import Testing
@testable import TUIkit

@Suite("List Style Tests")
struct ListStyleTests {
    // MARK: - Plain List Style Tests

    @Test("PlainListStyle has no border")
    func testPlainListStyleNoBorder() {
        let style = PlainListStyle()
        #expect(!style.showsBorder)
    }

    @Test("PlainListStyle has zero padding")
    func testPlainListStyleZeroPadding() {
        let style = PlainListStyle()
        #expect(style.rowPadding == EdgeInsets(all: 0))
    }

    @Test("PlainListStyle uses plain grouping")
    func testPlainListStyleGrouping() {
        let style = PlainListStyle()
        #expect(style.groupingStyle == .plain)
    }

    @Test("PlainListStyle has no alternating rows")
    func testPlainListStyleNoAlternating() {
        let style = PlainListStyle()
        #expect(!style.alternatingRowColors)
    }

    // MARK: - Inset Grouped List Style Tests

    @Test("InsetGroupedListStyle has border")
    func testInsetGroupedListStyleHasBorder() {
        let style = InsetGroupedListStyle()
        #expect(style.showsBorder)
    }

    @Test("InsetGroupedListStyle has inset padding")
    func testInsetGroupedListStylePadding() {
        let style = InsetGroupedListStyle()
        let expectedPadding = EdgeInsets(top: 0, leading: 1, bottom: 0, trailing: 1)
        #expect(style.rowPadding == expectedPadding)
    }

    @Test("InsetGroupedListStyle uses insetGrouped grouping")
    func testInsetGroupedListStyleGrouping() {
        let style = InsetGroupedListStyle()
        #expect(style.groupingStyle == .insetGrouped)
    }

    @Test("InsetGroupedListStyle has alternating rows")
    func testInsetGroupedListStyleAlternating() {
        let style = InsetGroupedListStyle()
        #expect(style.alternatingRowColors)
    }

    // MARK: - Edge Cases

    @Test("PlainListStyle color pair is nil")
    func testPlainListStyleColorPair() {
        let style = PlainListStyle()
        #expect(style.alternatingColorPair == nil)
    }

    @Test("InsetGroupedListStyle color pair is nil")
    func testInsetGroupedListStyleColorPair() {
        let style = InsetGroupedListStyle()
        #expect(style.alternatingColorPair == nil)
    }

    // MARK: - Direct Instantiation Tests

    @Test("PlainListStyle instantiation works")
    func testPlainInstantiation() {
        let style = PlainListStyle()
        #expect(!style.showsBorder)
        #expect(!style.alternatingRowColors)
    }

    @Test("InsetGroupedListStyle instantiation works")
    func testInsetGroupedInstantiation() {
        let style = InsetGroupedListStyle()
        #expect(style.showsBorder)
        #expect(style.alternatingRowColors)
    }

    // MARK: - Environment Integration

    @Test("List style stores in environment")
    func testListStyleEnvironmentStorage() {
        var env = EnvironmentValues()
        let style = PlainListStyle()
        env.listStyle = style
        #expect(!env.listStyle.showsBorder)
    }

    @Test("Environment list style default is InsetGroupedListStyle")
    func testEnvironmentListStyleDefault() {
        let env = EnvironmentValues()
        #expect(env.listStyle.showsBorder)
        #expect(env.listStyle.alternatingRowColors)
    }

    @Test("List style environment can be changed")
    func testChangeListStyleEnvironment() {
        var env = EnvironmentValues()
        env.listStyle = PlainListStyle()
        #expect(!env.listStyle.showsBorder)
        env.listStyle = InsetGroupedListStyle()
        #expect(env.listStyle.showsBorder)
    }

    // MARK: - Grouping Style Tests

    @Test("Plain grouping style value")
    func testPlainGroupingStyle() {
        let style: ListGroupingStyle = .plain
        let plain = PlainListStyle()
        #expect(plain.groupingStyle == style)
    }

    @Test("Inset grouping style value")
    func testInsetGroupingStyle() {
        let style: ListGroupingStyle = .insetGrouped
        let inset = InsetGroupedListStyle()
        #expect(inset.groupingStyle == style)
    }

    // MARK: - Sendable Tests

    @Test("PlainListStyle is Sendable")
    func testPlainListStyleSendable() {
        let style = PlainListStyle()
        let _: PlainListStyle = style
    }

    @Test("InsetGroupedListStyle is Sendable")
    func testInsetGroupedListStyleSendable() {
        let style = InsetGroupedListStyle()
        let _: InsetGroupedListStyle = style
    }

    @Test("ListGroupingStyle is Sendable")
    func testGroupingStyleSendable() {
        let style: ListGroupingStyle = .plain
        let _: ListGroupingStyle = style
    }
}

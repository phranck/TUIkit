//  🖥️ TUIKit — Terminal UI Kit for Swift
//  ViewModifierContentTests.swift
//
//  Created by LAYERED.work
//  License: MIT

import Foundation
import Testing

@testable import TUIkit

@MainActor
@Suite("ViewModifier body(content:) Contract")
struct ViewModifierContentTests {

    /// Creates an isolated render context for modifier assertions.
    private func testContext(width: Int = 40, height: Int = 10) -> RenderContext {
        RenderContext(
            availableWidth: width,
            availableHeight: height,
            tuiContext: TUIContext()
        )
    }

    // MARK: - Test Modifiers

    /// Wraps its content between two marker lines.
    struct Framed: ViewModifier {
        func body(content: Content) -> some View {
            VStack {
                Text("top")
                content
                Text("bottom")
            }
        }
    }

    /// Passes its content through unchanged.
    struct Passthrough: ViewModifier {
        func body(content: Content) -> some View {
            content
        }
    }

    /// Tints its content through the environment.
    struct Tinted: ViewModifier, Equatable {
        let color: Color

        func body(content: Content) -> some View {
            content.foregroundStyle(color)
        }
    }

    // MARK: - Contract

    @Test("modifier(_:) returns ModifiedContent")
    func modifierReturnsModifiedContent() {
        let modified = Text("base").modifier(Passthrough())

        #expect(type(of: modified) == ModifiedContent<Text, Passthrough>.self)
    }

    @Test("A body-based modifier renders content inside its body")
    func bodyModifierWrapsContent() {
        let modified = Text("mid").modifier(Framed())

        let buffer = renderToBuffer(modified, context: testContext())

        #expect(buffer.lines.count == 3)
        #expect(buffer.lines[0].stripped.trimmingCharacters(in: .whitespaces) == "top")
        #expect(buffer.lines[1].stripped.trimmingCharacters(in: .whitespaces) == "mid")
        #expect(buffer.lines[2].stripped.trimmingCharacters(in: .whitespaces) == "bottom")
    }

    @Test("A passthrough modifier renders content unchanged")
    func passthroughRendersContentUnchanged() {
        let plain = renderToBuffer(Text("same"), context: testContext())
        let modified = renderToBuffer(
            Text("same").modifier(Passthrough()),
            context: testContext()
        )

        #expect(modified.lines.map(\.stripped) == plain.lines.map(\.stripped))
    }

    @Test("Environment values set in the modifier body reach the content")
    func environmentFlowsThroughModifierBody() {
        let tinted = renderToBuffer(
            Text("tinted").modifier(Tinted(color: .red)),
            context: testContext()
        )
        let plain = renderToBuffer(Text("tinted"), context: testContext())

        #expect(tinted.lines != plain.lines)
        #expect(tinted.lines[0].contains("31") || tinted.lines[0].contains("38;"))
    }

    @Test("Nested modifiers apply outside-in")
    func nestedModifiersApply() {
        let nested = Text("core")
            .modifier(Passthrough())
            .modifier(Framed())

        let buffer = renderToBuffer(nested, context: testContext())

        #expect(buffer.lines.count == 3)
        #expect(buffer.lines[1].stripped.trimmingCharacters(in: .whitespaces) == "core")
    }

    // MARK: - Value Semantics

    @Test("ModifiedContent exposes content and modifier and equates by parts")
    func modifiedContentValueSemantics() {
        let first = ModifiedContent(content: Text("a"), modifier: Tinted(color: .red))
        let second = ModifiedContent(content: Text("a"), modifier: Tinted(color: .red))
        let third = ModifiedContent(content: Text("a"), modifier: Tinted(color: .blue))

        #expect(first.content == Text("a"))
        #expect(first.modifier == Tinted(color: .red))
        #expect(first == second)
        #expect(first != third)
    }

    // MARK: - Buffer Modifier Regression

    @Test("Padding still wraps content after the contract change")
    func paddingStillWorks() {
        let padded = renderToBuffer(
            Text("pad").padding(1),
            context: testContext()
        )

        #expect(padded.lines.count == 3)
        #expect(padded.lines[1].stripped == " pad ")
    }
}

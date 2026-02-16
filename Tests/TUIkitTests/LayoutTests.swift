//  🖥️ TUIKit — Terminal UI Kit for Swift
//  LayoutTests.swift
//
//  Created by LAYERED.work
//  License: MIT

import Observation
import Testing

@testable import TUIkit

@Observable
private class LayoutTestModel {
    var value = 42
    init() {}
}

// MARK: - ProposedSize Tests

@Suite("ProposedSize Tests")
struct ProposedSizeTests {

    @Test("unspecified has nil dimensions")
    func unspecifiedIsNil() {
        let size = ProposedSize.unspecified
        #expect(size.width == nil)
        #expect(size.height == nil)
    }

    @Test("fixed creates specific dimensions")
    func fixedDimensions() {
        let size = ProposedSize.fixed(80, 24)
        #expect(size.width == 80)
        #expect(size.height == 24)
    }

    @Test("init with partial dimensions")
    func partialDimensions() {
        let widthOnly = ProposedSize(width: 40, height: nil)
        #expect(widthOnly.width == 40)
        #expect(widthOnly.height == nil)

        let heightOnly = ProposedSize(width: nil, height: 10)
        #expect(heightOnly.width == nil)
        #expect(heightOnly.height == 10)
    }

    @Test("ProposedSize is equatable")
    func equatable() {
        let a = ProposedSize.fixed(80, 24)
        let b = ProposedSize.fixed(80, 24)
        let c = ProposedSize.fixed(40, 24)

        #expect(a == b)
        #expect(a != c)
    }
}

// MARK: - ViewSize Tests

@Suite("ViewSize Tests")
struct ViewSizeTests {

    @Test("fixed creates non-flexible size")
    func fixedIsNotFlexible() {
        let size = ViewSize.fixed(10, 5)
        #expect(size.width == 10)
        #expect(size.height == 5)
        #expect(size.isWidthFlexible == false)
        #expect(size.isHeightFlexible == false)
    }

    @Test("flexible creates fully flexible size")
    func flexibleIsBothFlexible() {
        let size = ViewSize.flexible(minWidth: 1, minHeight: 1)
        #expect(size.width == 1)
        #expect(size.height == 1)
        #expect(size.isWidthFlexible == true)
        #expect(size.isHeightFlexible == true)
    }

    @Test("flexibleWidth is only width-flexible")
    func flexibleWidthOnly() {
        let size = ViewSize.flexibleWidth(minWidth: 5, height: 3)
        #expect(size.width == 5)
        #expect(size.height == 3)
        #expect(size.isWidthFlexible == true)
        #expect(size.isHeightFlexible == false)
    }

    @Test("flexibleHeight is only height-flexible")
    func flexibleHeightOnly() {
        let size = ViewSize.flexibleHeight(width: 10, minHeight: 2)
        #expect(size.width == 10)
        #expect(size.height == 2)
        #expect(size.isWidthFlexible == false)
        #expect(size.isHeightFlexible == true)
    }

    @Test("ViewSize is equatable")
    func equatable() {
        let a = ViewSize.fixed(10, 5)
        let b = ViewSize.fixed(10, 5)
        let c = ViewSize.flexible(minWidth: 10, minHeight: 5)

        #expect(a == b)
        #expect(a != c)  // Same dimensions but different flexibility
    }
}

// MARK: - Layoutable Tests

@MainActor
@Suite("Layoutable Tests")
struct LayoutableTests {

    @Test("Text sizeThatFits returns content size")
    func textSizeThatFits() {
        let text = Text("Hello")
        let context = RenderContext(availableWidth: 80, availableHeight: 24, tuiContext: TUIContext())

        let size = text.sizeThatFits(proposal: .unspecified, context: context)

        #expect(size.width == 5)  // "Hello" is 5 chars
        #expect(size.height == 1)
        #expect(size.isWidthFlexible == false)
        #expect(size.isHeightFlexible == false)
    }

    @Test("Text sizeThatFits wraps with proposed width")
    func textSizeThatFitsWraps() {
        let text = Text("Hello World")
        let context = RenderContext(availableWidth: 80, availableHeight: 24, tuiContext: TUIContext())

        // With narrow proposed width, text should wrap
        let size = text.sizeThatFits(proposal: ProposedSize(width: 6, height: nil), context: context)

        #expect(size.width == 5)  // "Hello" or "World" (5 chars each)
        #expect(size.height == 2) // Two lines after wrap
    }

    @Test("Spacer sizeThatFits is flexible")
    func spacerSizeThatFits() {
        let spacer = Spacer()
        let context = RenderContext(availableWidth: 80, availableHeight: 24, tuiContext: TUIContext())

        let size = spacer.sizeThatFits(proposal: .unspecified, context: context)

        #expect(size.width == 0)  // No minimum
        #expect(size.height == 0)
        #expect(size.isWidthFlexible == true)
        #expect(size.isHeightFlexible == true)
    }

    @Test("Spacer with minLength has minimum size")
    func spacerWithMinLength() {
        let spacer = Spacer(minLength: 5)
        let context = RenderContext(availableWidth: 80, availableHeight: 24, tuiContext: TUIContext())

        let size = spacer.sizeThatFits(proposal: .unspecified, context: context)

        #expect(size.width == 5)
        #expect(size.height == 5)
        #expect(size.isWidthFlexible == true)
        #expect(size.isHeightFlexible == true)
    }

    @Test("Divider sizeThatFits is width-flexible")
    func dividerSizeThatFits() {
        let divider = Divider()
        let context = RenderContext(availableWidth: 80, availableHeight: 24, tuiContext: TUIContext())

        let size = divider.sizeThatFits(proposal: .unspecified, context: context)

        #expect(size.height == 1)  // Always 1 line
        #expect(size.isWidthFlexible == true)
        #expect(size.isHeightFlexible == false)
    }

    @Test("HStack with Text and flexible TextField fits available width")
    func hstackTextFieldWidth() {
        var text = ""
        let binding = Binding(get: { text }, set: { text = $0 })
        let hstack = HStack(spacing: 1) {
            Text("Search:")
            TextField("Search", text: binding, prompt: Text("Enter search term..."))
        }
        let context = RenderContext(availableWidth: 80, availableHeight: 24, tuiContext: TUIContext())
        let buffer = renderToBuffer(hstack, context: context)

        #expect(buffer.width == 80, "HStack should fill exactly available width, got \(buffer.width)")
        #expect(buffer.height == 1)
    }

    @Test("measureChild traverses composite View body for Layoutable")
    func measureChildTraversesBody() {
        var text = ""
        let binding = Binding(get: { text }, set: { text = $0 })
        let textField = TextField("Test", text: binding)
        let context = RenderContext(availableWidth: 80, availableHeight: 24, tuiContext: TUIContext())

        let size = measureChild(textField, proposal: .unspecified, context: context)

        #expect(size.isWidthFlexible == true, "TextField should report flexible width through body traversal")
        #expect(size.width == 20, "TextField default width should be 20, got \(size.width)")
    }

    @Test("measureChild sets up hydration context for @Environment(Observable.self)")
    func measureChildSetsUpEnvironment() {
        struct ChildView: View {
            @Environment(LayoutTestModel.self) var model
            var body: some View { Text("v\(model.value)") }
        }

        let model = LayoutTestModel()
        let view = ChildView().environment(model)
        let context = RenderContext(availableWidth: 80, availableHeight: 24, tuiContext: TUIContext())

        // Before the fix, this would crash with:
        // "@Environment(LayoutTestModel.self): No object of type LayoutTestModel found"
        let size = measureChild(view, proposal: .unspecified, context: context)
        #expect(size.width > 0)
    }
}

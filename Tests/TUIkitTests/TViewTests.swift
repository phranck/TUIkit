//
//  ViewTests.swift
//  TUIkit
//
//  Tests for the View protocol, ViewBuilder, and basic views.
//

import Testing

@testable import TUIkit

@Suite("View Protocol Tests")
struct ViewTests {

    @Test("Text view can be created")
    func textViewCreation() {
        let text = Text("Hello, World!")
        #expect(text.content == "Hello, World!")
    }

    @Test("Text view with style")
    func textViewWithStyle() {
        let text = Text("Bold").bold().foregroundColor(.red)
        #expect(text.style.isBold == true)
        #expect(text.style.foregroundColor == .red)
    }

    @Test("EmptyView has no content")
    func emptyView() {
        _ = EmptyView()
        // EmptyView should just be able to exist
    }

    @Test("Spacer can be created")
    func spacerCreation() {
        let spacer = Spacer()
        #expect(spacer.minLength == nil)

        let spacerWithLength = Spacer(minLength: 5)
        #expect(spacerWithLength.minLength == 5)
    }

    @Test("Divider uses default character")
    func dividerDefaultCharacter() {
        let divider = Divider()
        #expect(divider.character == "─")
    }

    @Test("Divider with custom character")
    func dividerCustomCharacter() {
        let divider = Divider(character: "=")
        #expect(divider.character == "=")
    }
}

@Suite("ViewBuilder Tests")
struct ViewBuilderTests {

    @Test("ViewBuilder with single view")
    func singleView() {
        @ViewBuilder
        func buildView() -> some View {
            Text("Single")
        }

        let view = buildView()
        #expect(view is Text)
    }

    @Test("ViewBuilder with two views")
    func twoViews() {
        @ViewBuilder
        func buildViews() -> some View {
            Text("First")
            Text("Second")
        }

        let views = buildViews()
        #expect(views is TupleView<Text, Text>)
    }

    @Test("ViewBuilder with three views")
    func threeViews() {
        @ViewBuilder
        func buildViews() -> some View {
            Text("One")
            Text("Two")
            Text("Three")
        }

        let views = buildViews()
        #expect(views is TupleView<Text, Text, Text>)
    }

    @Test("VStack can contain views")
    func vstackWithViews() {
        let stack = VStack {
            Text("Line 1")
            Text("Line 2")
        }

        #expect(stack.alignment == .leading)
        #expect(stack.spacing == 0)
    }

    @Test("HStack can contain views")
    func hstackWithViews() {
        let stack = HStack {
            Text("Left")
            Text("Right")
        }

        #expect(stack.alignment == .center)
        #expect(stack.spacing == 1)
    }

    @Test("VStack with alignment and spacing")
    func vstackWithOptions() {
        let stack = VStack(alignment: .center, spacing: 2) {
            Text("Centered")
        }

        #expect(stack.alignment == .center)
        #expect(stack.spacing == 2)
    }
}

@Suite("Alignment Tests")
struct AlignmentTests {

    @Test("Preset alignments are correct")
    func presetAlignments() {
        #expect(Alignment.topLeading.horizontal == .leading)
        #expect(Alignment.topLeading.vertical == .top)

        #expect(Alignment.center.horizontal == .center)
        #expect(Alignment.center.vertical == .center)

        #expect(Alignment.bottomTrailing.horizontal == .trailing)
        #expect(Alignment.bottomTrailing.vertical == .bottom)
    }
}

@Suite("AnyView Tests")
struct AnyViewTests {

    @Test("AnyView wraps view correctly")
    func anyViewWrapping() {
        let text = Text("Hello")
        let anyView = AnyView(text)
        let context = RenderContext(availableWidth: 80, availableHeight: 24)
        let buffer = renderToBuffer(anyView, context: context)
        #expect(buffer.lines[0] == "Hello")
    }

    @Test("asAnyView extension works")
    func asAnyViewExtension() {
        let anyView = Text("Test").bold().asAnyView()
        let context = RenderContext(availableWidth: 80, availableHeight: 24)
        let buffer = renderToBuffer(anyView, context: context)
        #expect(!buffer.isEmpty)
    }
}

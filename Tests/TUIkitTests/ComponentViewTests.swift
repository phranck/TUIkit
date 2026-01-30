//
//  ComponentViewTests.swift
//  TUIkit
//
//  Tests for Box, Card, Panel, ContainerConfig, ContainerView, and ForEach views.
//

import Testing

@testable import TUIkit

// MARK: - Test Helpers

/// Creates a default render context for testing.
private func testContext(width: Int = 40, height: Int = 24) -> RenderContext {
    RenderContext(availableWidth: width, availableHeight: height)
}

// MARK: - Box Tests

@Suite("Box Tests")
struct BoxTests {

    @Test("Box can be created with default style")
    func boxDefaultCreation() {
        let box = Box {
            Text("Hello")
        }
        #expect(box.borderStyle == nil)
        #expect(box.borderColor == nil)
    }

    @Test("Box can be created with explicit border style")
    func boxExplicitStyle() {
        let box = Box(.doubleLine, color: .cyan) {
            Text("Styled")
        }
        #expect(box.borderStyle == .doubleLine)
        #expect(box.borderColor == .cyan)
    }

    @Test("Box renders with border around content")
    func boxRendersWithBorder() {
        let box = Box(.line) {
            Text("Hi")
        }
        let context = testContext()
        let buffer = renderToBuffer(box, context: context)

        // Box = border top + content + border bottom = 3 lines minimum
        #expect(buffer.height >= 3)
        // Width = content width + 2 (left + right border)
        #expect(buffer.width >= 4) // "Hi" (2) + borders (2)
    }

    @Test("Box renders empty content")
    func boxEmptyContent() {
        let box = Box(.line) {
            EmptyView()
        }
        let context = testContext()
        let buffer = renderToBuffer(box, context: context)

        // EmptyView produces empty buffer, so bordered empty = empty
        #expect(buffer.isEmpty)
    }

    @Test("Box with multiple children renders vertically")
    func boxMultipleChildren() {
        let box = Box(.line) {
            Text("Line 1")
            Text("Line 2")
        }
        let context = testContext()
        let buffer = renderToBuffer(box, context: context)

        // Top border + 2 content lines + bottom border = 4
        #expect(buffer.height >= 4)
    }

    @Test("Box delegates to body (is composite, not Renderable)")
    func boxIsComposite() {
        let box = Box {
            Text("Test")
        }
        // Box should NOT conform to Renderable — it uses body
        #expect(!(box is Renderable))
    }
}

// MARK: - Card Tests

@Suite("Card Tests")
struct CardTests {

    @Test("Card can be created without title")
    func cardNoTitle() {
        let card = Card {
            Text("Content")
        }
        #expect(card.title == nil)
        #expect(card.footer == nil)
        #expect(card.backgroundColor == nil)
    }

    @Test("Card can be created with title")
    func cardWithTitle() {
        let card = Card(title: "My Card") {
            Text("Content")
        }
        #expect(card.title == "My Card")
    }

    @Test("Card can be created with footer")
    func cardWithFooter() {
        let card = Card(title: "Info") {
            Text("Body")
        } footer: {
            Text("Footer")
        }
        #expect(card.title == "Info")
        #expect(card.footer != nil)
    }

    @Test("Card can be created with custom border style")
    func cardCustomStyle() {
        let card = Card(
            title: "Styled",
            borderStyle: .doubleLine,
            borderColor: .cyan,
            titleColor: .brightYellow,
            backgroundColor: .blue
        ) {
            Text("Content")
        }
        #expect(card.title == "Styled")
        #expect(card.config.borderStyle == .doubleLine)
        #expect(card.config.borderColor == .cyan)
        #expect(card.config.titleColor == .brightYellow)
        #expect(card.backgroundColor == .blue)
    }

    @Test("Card renders with border")
    func cardRenders() {
        let card = Card(title: "Test") {
            Text("Hello")
        }
        let context = testContext()
        let buffer = card.renderToBuffer(context: context)

        // Should have top border + content + bottom border
        #expect(buffer.height >= 3)
        #expect(!buffer.isEmpty)
    }

    @Test("Card without title renders")
    func cardNoTitleRenders() {
        let card = Card {
            Text("Content")
        }
        let context = testContext()
        let buffer = card.renderToBuffer(context: context)

        #expect(buffer.height >= 3)
        #expect(!buffer.isEmpty)
    }

    @Test("Card with footer is taller than without")
    func cardFooterAddsHeight() {
        let cardWithout = Card(title: "Test") {
            Text("Body")
        }
        let cardWith = Card(title: "Test") {
            Text("Body")
        } footer: {
            Text("Footer")
        }
        let context = testContext()

        let bufferWithout = cardWithout.renderToBuffer(context: context)
        let bufferWith = cardWith.renderToBuffer(context: context)

        #expect(bufferWith.height > bufferWithout.height)
    }

    @Test("Card conforms to Renderable")
    func cardIsRenderable() {
        let card = Card { Text("Test") }
        #expect(card is Renderable)
    }
}

// MARK: - Panel Tests

@Suite("Panel Tests")
struct PanelTests {

    @Test("Panel can be created with title")
    func panelCreation() {
        let panel = Panel("Settings") {
            Text("Option 1")
        }
        #expect(panel.title == "Settings")
        #expect(panel.footer == nil)
    }

    @Test("Panel can be created with footer")
    func panelWithFooter() {
        let panel = Panel("Info") {
            Text("Content")
        } footer: {
            Text("Done")
        }
        #expect(panel.title == "Info")
        #expect(panel.footer != nil)
    }

    @Test("Panel can be created with custom style")
    func panelCustomStyle() {
        let panel = Panel(
            "Styled",
            borderStyle: .heavy,
            borderColor: .red,
            titleColor: .yellow
        ) {
            Text("Content")
        }
        #expect(panel.config.borderStyle == .heavy)
        #expect(panel.config.borderColor == .red)
        #expect(panel.config.titleColor == .yellow)
    }

    @Test("Panel renders with border and title")
    func panelRenders() {
        let panel = Panel("Test Panel") {
            Text("Hello")
        }
        let context = testContext()
        let buffer = panel.renderToBuffer(context: context)

        // Top border (with title) + content + bottom border
        #expect(buffer.height >= 3)
        #expect(!buffer.isEmpty)
    }

    @Test("Panel with footer is taller")
    func panelFooterAddsHeight() {
        let panelWithout = Panel("Test") {
            Text("Body")
        }
        let panelWith = Panel("Test") {
            Text("Body")
        } footer: {
            Text("Footer")
        }
        let context = testContext()

        let bufferWithout = panelWithout.renderToBuffer(context: context)
        let bufferWith = panelWith.renderToBuffer(context: context)

        #expect(bufferWith.height > bufferWithout.height)
    }

    @Test("Panel conforms to Renderable")
    func panelIsRenderable() {
        let panel = Panel("Title") { Text("Content") }
        #expect(panel is Renderable)
    }

    @Test("Panel default padding is horizontal only")
    func panelDefaultPadding() {
        let panel = Panel("Test") {
            Text("Content")
        }
        #expect(panel.config.padding.leading == 1)
        #expect(panel.config.padding.trailing == 1)
        #expect(panel.config.padding.top == 0)
        #expect(panel.config.padding.bottom == 0)
    }
}

// MARK: - ContainerConfig Tests

@Suite("ContainerConfig Tests")
struct ContainerConfigTests {

    @Test("Default config has expected values")
    func defaultConfig() {
        let config = ContainerConfig.default
        #expect(config.borderStyle == nil)
        #expect(config.borderColor == nil)
        #expect(config.titleColor == nil)
        #expect(config.padding.leading == 1)
        #expect(config.padding.trailing == 1)
        #expect(config.showFooterSeparator == true)
    }

    @Test("Custom config stores all values")
    func customConfig() {
        let config = ContainerConfig(
            borderStyle: .doubleLine,
            borderColor: .cyan,
            titleColor: .yellow,
            padding: EdgeInsets(all: 2),
            showFooterSeparator: false
        )
        #expect(config.borderStyle == .doubleLine)
        #expect(config.borderColor == .cyan)
        #expect(config.titleColor == .yellow)
        #expect(config.padding.top == 2)
        #expect(config.padding.leading == 2)
        #expect(config.showFooterSeparator == false)
    }
}

// MARK: - ContainerView Tests

@Suite("ContainerView Direct Tests")
struct ContainerViewDirectTests {

    @Test("ContainerView can be created without title")
    func containerViewNoTitle() {
        let container = ContainerView {
            Text("Content")
        }
        #expect(container.title == nil)
        #expect(container.footer == nil)
    }

    @Test("ContainerView can be created with title and footer")
    func containerViewWithTitleAndFooter() {
        let container = ContainerView(title: "Header") {
            Text("Body")
        } footer: {
            Text("Footer")
        }
        #expect(container.title == "Header")
        #expect(container.footer != nil)
    }

    @Test("ContainerView renders with border")
    func containerViewRenders() {
        let container = ContainerView(title: "Test") {
            Text("Content")
        }
        let context = testContext()
        let buffer = container.renderToBuffer(context: context)

        #expect(buffer.height >= 3)
        #expect(!buffer.isEmpty)
    }

    @Test("ContainerView conforms to Renderable")
    func containerViewIsRenderable() {
        let container = ContainerView { Text("Test") }
        #expect(container is Renderable)
    }
}

// MARK: - ForEach Tests

@Suite("ForEach Tests")
struct ForEachTests {

    struct TestItem: Identifiable {
        let id: String
        let name: String
    }

    @Test("ForEach can be created with Identifiable data")
    func forEachIdentifiable() {
        let items = [TestItem(id: "1", name: "One"), TestItem(id: "2", name: "Two")]
        let forEach = ForEach(items) { item in
            Text(item.name)
        }
        #expect(forEach.data.count == 2)
    }

    @Test("ForEach can be created with explicit ID key path")
    func forEachExplicitId() {
        let names = ["Anna", "Bob", "Clara"]
        let forEach = ForEach(names, id: \.self) { name in
            Text(name)
        }
        #expect(forEach.data.count == 3)
    }

    @Test("ForEach can be created with Range")
    func forEachRange() {
        let forEach = ForEach(0..<5) { index in
            Text("Item \(index)")
        }
        #expect(forEach.data.count == 5)
    }

    @Test("ForEach generates correct number of views")
    func forEachViewGeneration() {
        let items = [TestItem(id: "a", name: "Alpha"), TestItem(id: "b", name: "Beta")]
        let forEach = ForEach(items) { item in
            Text(item.name)
        }

        // Verify content closure works
        var generatedTexts: [String] = []
        for item in forEach.data {
            let view = forEach.content(item)
            generatedTexts.append(view.content)
        }
        #expect(generatedTexts == ["Alpha", "Beta"])
    }

    // NOTE: ForEach inside VStack/HStack cannot be tested via renderToBuffer
    // directly. ForEach is flattened into ViewArray by @ViewBuilder.buildArray
    // at compile time — not at render time. Direct construction in tests
    // bypasses the builder, so ForEach remains unflattened and produces
    // an empty buffer. This is expected behavior, matching SwiftUI's pattern.
}

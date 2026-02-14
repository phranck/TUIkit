//  🖥️ TUIKit — Terminal UI Kit for Swift
//  ListTests.swift
//
//  Created by LAYERED.work
//  License: MIT

import Testing

@testable import TUIkit

// MARK: - Test Helpers

@MainActor
private func createTestContext(width: Int = 80, height: Int = 24) -> RenderContext {
    let focusManager = FocusManager()
    var environment = EnvironmentValues()
    environment.focusManager = focusManager

    return RenderContext(
        availableWidth: width,
        availableHeight: height,
        environment: environment,
        tuiContext: TUIContext()
    )
}

// MARK: - List Rendering Tests

@MainActor
@Suite("List Rendering Tests")
struct ListRenderingTests {

    @Test("Empty list shows placeholder")
    func emptyListPlaceholder() {
        let context = createTestContext()

        var selection: String?
        let list = List(selection: Binding(
            get: { selection },
            set: { selection = $0 }
        )) {
            EmptyView()
        }

        let buffer = renderToBuffer(list, context: context)
        let content = buffer.lines.joined()

        #expect(content.contains("No items"))
    }

    @Test("Custom empty placeholder is shown")
    func customEmptyPlaceholder() {
        let context = createTestContext()

        var selection: String?
        let list = List(
            selection: Binding(
                get: { selection },
                set: { selection = $0 }
            )
        ) {
            EmptyView()
        }
        .listEmptyPlaceholder("Nothing here")

        let buffer = renderToBuffer(list, context: context)
        let content = buffer.lines.joined()

        #expect(content.contains("Nothing here"))
    }

    @Test("List renders ForEach items")
    func listRendersForEachItems() {
        let context = createTestContext()

        struct Item: Identifiable {
            let id: String
            let name: String
        }
        let items = [
            Item(id: "1", name: "First"),
            Item(id: "2", name: "Second"),
            Item(id: "3", name: "Third")
        ]

        var selection: String?
        let list = List(selection: Binding(
            get: { selection },
            set: { selection = $0 }
        )) {
            ForEach(items) { item in
                Text(item.name)
            }
        }

        let buffer = renderToBuffer(list, context: context)
        let content = buffer.lines.joined()

        #expect(content.contains("First"))
        #expect(content.contains("Second"))
        #expect(content.contains("Third"))
    }

    @Test("Selected item has accent indicator")
    func selectedItemIndicator() {
        let context = createTestContext()

        struct Item: Identifiable {
            let id: String
            let name: String
        }
        let items = [
            Item(id: "1", name: "First"),
            Item(id: "2", name: "Second")
        ]

        var selection: String? = "2"
        let list = List(selection: Binding(
            get: { selection },
            set: { selection = $0 }
        )) {
            ForEach(items) { item in
                Text(item.name)
            }
        }

        let buffer = renderToBuffer(list, context: context)
        let content = buffer.lines.joined()

        // Selected item should have a background color (ANSI 48;2 = RGB background)
        #expect(content.contains("[48;2;"))
    }

    @Test("Scroll indicators appear when needed")
    func scrollIndicatorsAppear() {
        struct Item: Identifiable {
            let id: Int
            let name: String
        }
        // Create list with more items than will fit in available height
        let items = (0..<20).map { Item(id: $0, name: "Item \($0)") }

        var selection: Int?
        let list = List(
            selection: Binding(
                get: { selection },
                set: { selection = $0 }
            )
        ) {
            ForEach(items) { item in
                Text(item.name)
            }
        }

        // Use a small height context so scrolling is triggered
        let context = createTestContext(width: 40, height: 8)
        let buffer = renderToBuffer(list, context: context)
        let content = buffer.lines.joined()

        // Should have "more below" indicator since we have 20 items in height 8
        #expect(content.contains("▼") || content.contains("more below"))
    }

    @Test("Disabled list modifier works")
    func disabledListModifier() {
        var selection: String?
        let list = List(selection: Binding(
            get: { selection },
            set: { selection = $0 }
        )) {
            EmptyView()
        }.disabled()

        #expect(list.isDisabled == true)
    }

    @Test("Multi-selection list can be created")
    func multiSelectionListCreation() {
        var selection: Set<String> = []
        let list = List(selection: Binding(
            get: { selection },
            set: { selection = $0 }
        )) {
            Text("Item")
        }

        #expect(list.selectionMode == .multi)
    }

    @Test("Single-selection list can be created")
    func singleSelectionListCreation() {
        var selection: String?
        let list = List(selection: Binding(
            get: { selection },
            set: { selection = $0 }
        )) {
            Text("Item")
        }

        #expect(list.selectionMode == .single)
    }

    @Test("List respects frame width constraint")
    func listRespectsFrameWidth() {
        let context = createTestContext(width: 80)

        var selection: String?
        let list = List("Items", selection: Binding(
            get: { selection },
            set: { selection = $0 }
        )) {
            ForEach(["Alpha", "Beta", "Gamma"], id: \.self) { item in
                Text(item)
            }
        }
        .frame(width: 20)

        let buffer = renderToBuffer(list, context: context)

        // The list should be constrained to 20 characters width
        #expect(buffer.width == 20, "Expected width 20, got \(buffer.width)")

        // The border should also be 20 characters wide (not just padded)
        let firstLine = buffer.lines.first ?? ""
        #expect(firstLine.strippedLength == 20, "Border should be 20 chars wide")
    }

    @Test("Two Lists in HStack both render")
    func twoListsInHStack() {
        // Use wider terminal to match real usage, with explicit width like WindowGroup
        var context = createTestContext(width: 160, height: 40)
        context.hasExplicitWidth = true

        var sel1: String?
        var sel2: Set<String> = []

        let items: [(String, String, String)] = [
            ("1", "README.md", "📄"), ("2", "Package.swift", "📦"),
            ("3", "Sources", "📁"), ("4", "Tests", "📁"),
            ("5", ".gitignore", "📄"), ("6", "LICENSE", "📄"),
            ("7", "docs", "📁"), ("8", "plans", "📁"),
            ("9", ".swiftlint.yml", "⚙️"), ("10", ".github", "📁"),
            ("11", "Makefile", "📄"), ("12", ".claude", "📁"),
        ]

        let view = HStack(spacing: 2) {
            List("Single Selection", selection: Binding(get: { sel1 }, set: { sel1 = $0 })) {
                ForEach(items, id: \.0) { item in
                    HStack(spacing: 1) {
                        Text(item.2)
                        Text(item.1)
                    }
                }
            }
            List("Multi Selection", selection: Binding(get: { sel2 }, set: { sel2 = $0 })) {
                ForEach(items, id: \.0) { item in
                    HStack(spacing: 1) {
                        Text(item.2)
                        Text(item.1)
                    }
                }
            }
        }

        let buffer = renderToBuffer(view, context: context)
        let allContent = buffer.lines.map { $0.stripped }.joined()

        #expect(allContent.contains("Single Selection"), "Should contain first list title")
        #expect(allContent.contains("Multi Selection"), "Should contain second list title, got buffer width \(buffer.width)")
        #expect(buffer.width <= 160, "Buffer should not exceed available width 160, got \(buffer.width)")

        // All lines should have the same visible width (consistent borders)
        let lineWidths = buffer.lines.map { $0.strippedLength }
        let maxLineWidth = lineWidths.max() ?? 0
        let minLineWidth = lineWidths.filter { $0 > 0 }.min() ?? 0
        #expect(minLineWidth == maxLineWidth,
                "All lines should have same width but min=\(minLineWidth) max=\(maxLineWidth)")
    }
}

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
        environment: environment
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
            ),
            emptyPlaceholder: "Nothing here"
        ) {
            EmptyView()
        }

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
        let context = createTestContext(height: 5)

        struct Item: Identifiable {
            let id: Int
            let name: String
        }
        let items = (0..<20).map { Item(id: $0, name: "Item \($0)") }

        var selection: Int?
        let list = List(
            selection: Binding(
                get: { selection },
                set: { selection = $0 }
            ),
            maxVisibleRows: 3
        ) {
            ForEach(items) { item in
                Text(item.name)
            }
        }

        let buffer = renderToBuffer(list, context: context)
        let content = buffer.lines.joined()

        // Should have "more below" indicator
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
}

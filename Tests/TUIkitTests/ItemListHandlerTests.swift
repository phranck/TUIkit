//  🖥️ TUIKit — Terminal UI Kit for Swift
//  ItemListHandlerTests.swift
//
//  Created by LAYERED.work
//  License: MIT

import Testing

@testable import TUIkit

// MARK: - Item List Handler Navigation Tests

@MainActor
@Suite("ItemListHandler Navigation Tests")
struct ItemListHandlerNavigationTests {

    @Test("Down arrow moves focus forward")
    func moveDownSimple() {
        let handler = ItemListHandler<String>(
            focusID: "test",
            itemCount: 5,
            viewportHeight: 3,
            selectionMode: .single
        )

        let event = KeyEvent(key: .down)
        let handled = handler.handleKeyEvent(event)

        #expect(handled == true)
        #expect(handler.focusedIndex == 1)
    }

    @Test("Up arrow moves focus backward")
    func moveUpSimple() {
        let handler = ItemListHandler<String>(
            focusID: "test",
            itemCount: 5,
            viewportHeight: 3,
            selectionMode: .single
        )
        handler.focusedIndex = 2

        let event = KeyEvent(key: .up)
        let handled = handler.handleKeyEvent(event)

        #expect(handled == true)
        #expect(handler.focusedIndex == 1)
    }

    @Test("Down arrow wraps to start at end")
    func wrapDownToStart() {
        let handler = ItemListHandler<String>(
            focusID: "test",
            itemCount: 3,
            viewportHeight: 3,
            selectionMode: .single
        )
        handler.focusedIndex = 2  // Last item

        let event = KeyEvent(key: .down)
        _ = handler.handleKeyEvent(event)

        #expect(handler.focusedIndex == 0)  // Wrapped to first
    }

    @Test("Up arrow wraps to end at start")
    func wrapUpToEnd() {
        let handler = ItemListHandler<String>(
            focusID: "test",
            itemCount: 3,
            viewportHeight: 3,
            selectionMode: .single
        )
        handler.focusedIndex = 0  // First item

        let event = KeyEvent(key: .up)
        _ = handler.handleKeyEvent(event)

        #expect(handler.focusedIndex == 2)  // Wrapped to last
    }

    @Test("Home key jumps to first item")
    func homeJumpsToFirst() {
        let handler = ItemListHandler<String>(
            focusID: "test",
            itemCount: 10,
            viewportHeight: 5,
            selectionMode: .single
        )
        handler.focusedIndex = 7

        let event = KeyEvent(key: .home)
        let handled = handler.handleKeyEvent(event)

        #expect(handled == true)
        #expect(handler.focusedIndex == 0)
    }

    @Test("End key jumps to last item")
    func endJumpsToLast() {
        let handler = ItemListHandler<String>(
            focusID: "test",
            itemCount: 10,
            viewportHeight: 5,
            selectionMode: .single
        )
        handler.focusedIndex = 2

        let event = KeyEvent(key: .end)
        let handled = handler.handleKeyEvent(event)

        #expect(handled == true)
        #expect(handler.focusedIndex == 9)
    }

    @Test("PageDown moves by viewport height")
    func pageDownMovesViewport() {
        let handler = ItemListHandler<String>(
            focusID: "test",
            itemCount: 20,
            viewportHeight: 5,
            selectionMode: .single
        )
        handler.focusedIndex = 2

        let event = KeyEvent(key: .pageDown)
        let handled = handler.handleKeyEvent(event)

        #expect(handled == true)
        #expect(handler.focusedIndex == 7)  // 2 + 5
    }

    @Test("PageUp moves by viewport height")
    func pageUpMovesViewport() {
        let handler = ItemListHandler<String>(
            focusID: "test",
            itemCount: 20,
            viewportHeight: 5,
            selectionMode: .single
        )
        handler.focusedIndex = 10

        let event = KeyEvent(key: .pageUp)
        let handled = handler.handleKeyEvent(event)

        #expect(handled == true)
        #expect(handler.focusedIndex == 5)  // 10 - 5
    }

    @Test("PageDown clamps at end without wrapping")
    func pageDownClampsAtEnd() {
        let handler = ItemListHandler<String>(
            focusID: "test",
            itemCount: 10,
            viewportHeight: 5,
            selectionMode: .single
        )
        handler.focusedIndex = 8

        let event = KeyEvent(key: .pageDown)
        _ = handler.handleKeyEvent(event)

        #expect(handler.focusedIndex == 9)  // Clamped to last
    }

    @Test("PageUp clamps at start without wrapping")
    func pageUpClampsAtStart() {
        let handler = ItemListHandler<String>(
            focusID: "test",
            itemCount: 10,
            viewportHeight: 5,
            selectionMode: .single
        )
        handler.focusedIndex = 2

        let event = KeyEvent(key: .pageUp)
        _ = handler.handleKeyEvent(event)

        #expect(handler.focusedIndex == 0)  // Clamped to first
    }

    @Test("Empty list handles navigation gracefully")
    func emptyListNavigation() {
        let handler = ItemListHandler<String>(
            focusID: "test",
            itemCount: 0,
            viewportHeight: 5,
            selectionMode: .single
        )

        let event = KeyEvent(key: .down)
        let handled = handler.handleKeyEvent(event)

        #expect(handled == false)
        #expect(handler.focusedIndex == 0)
    }
}

// MARK: - Item List Handler Selection Tests

@MainActor
@Suite("ItemListHandler Selection Tests")
struct ItemListHandlerSelectionTests {

    @Test("Enter toggles single selection")
    func enterTogglesSingle() {
        var selectedID: String?
        let handler = ItemListHandler<String>(
            focusID: "test",
            itemCount: 3,
            viewportHeight: 3,
            selectionMode: .single
        )
        handler.itemIDs = ["a", "b", "c"]
        handler.singleSelection = Binding(
            get: { selectedID },
            set: { selectedID = $0 }
        )
        handler.focusedIndex = 1

        let event = KeyEvent(key: .enter)
        let handled = handler.handleKeyEvent(event)

        #expect(handled == true)
        #expect(selectedID == "b")
    }

    @Test("Space toggles single selection")
    func spaceTogglesSingle() {
        var selectedID: String?
        let handler = ItemListHandler<String>(
            focusID: "test",
            itemCount: 3,
            viewportHeight: 3,
            selectionMode: .single
        )
        handler.itemIDs = ["a", "b", "c"]
        handler.singleSelection = Binding(
            get: { selectedID },
            set: { selectedID = $0 }
        )
        handler.focusedIndex = 2

        let event = KeyEvent(key: .space)
        let handled = handler.handleKeyEvent(event)

        #expect(handled == true)
        #expect(selectedID == "c")
    }

    @Test("Single selection can be deselected by selecting again")
    func singleDeselect() {
        var selectedID: String? = "a"
        let handler = ItemListHandler<String>(
            focusID: "test",
            itemCount: 3,
            viewportHeight: 3,
            selectionMode: .single
        )
        handler.itemIDs = ["a", "b", "c"]
        handler.singleSelection = Binding(
            get: { selectedID },
            set: { selectedID = $0 }
        )
        handler.focusedIndex = 0  // Already selected

        let event = KeyEvent(key: .enter)
        _ = handler.handleKeyEvent(event)

        #expect(selectedID == nil)  // Deselected
    }

    @Test("Multi selection adds to set")
    func multiSelectionAdds() {
        var selected: Set<String> = []
        let handler = ItemListHandler<String>(
            focusID: "test",
            itemCount: 3,
            viewportHeight: 3,
            selectionMode: .multi
        )
        handler.itemIDs = ["a", "b", "c"]
        handler.multiSelection = Binding(
            get: { selected },
            set: { selected = $0 }
        )
        handler.focusedIndex = 1

        let event = KeyEvent(key: .enter)
        _ = handler.handleKeyEvent(event)

        #expect(selected.contains("b"))
        #expect(selected.count == 1)
    }

    @Test("Multi selection toggles items")
    func multiSelectionToggles() {
        var selected: Set<String> = ["b"]
        let handler = ItemListHandler<String>(
            focusID: "test",
            itemCount: 3,
            viewportHeight: 3,
            selectionMode: .multi
        )
        handler.itemIDs = ["a", "b", "c"]
        handler.multiSelection = Binding(
            get: { selected },
            set: { selected = $0 }
        )
        handler.focusedIndex = 1  // Already selected

        let event = KeyEvent(key: .enter)
        _ = handler.handleKeyEvent(event)

        #expect(!selected.contains("b"))  // Removed
        #expect(selected.isEmpty)
    }

    @Test("isSelected returns correct state")
    func isSelectedReturnsCorrectState() {
        var selectedID: String? = "b"
        let handler = ItemListHandler<String>(
            focusID: "test",
            itemCount: 3,
            viewportHeight: 3,
            selectionMode: .single
        )
        handler.itemIDs = ["a", "b", "c"]
        handler.singleSelection = Binding(
            get: { selectedID },
            set: { selectedID = $0 }
        )

        #expect(handler.isSelected(at: 0) == false)
        #expect(handler.isSelected(at: 1) == true)
        #expect(handler.isSelected(at: 2) == false)
    }

    @Test("isFocused returns correct state")
    func isFocusedReturnsCorrectState() {
        let handler = ItemListHandler<String>(
            focusID: "test",
            itemCount: 3,
            viewportHeight: 3,
            selectionMode: .single
        )
        handler.focusedIndex = 1

        #expect(handler.isFocused(at: 0) == false)
        #expect(handler.isFocused(at: 1) == true)
        #expect(handler.isFocused(at: 2) == false)
    }
}

// MARK: - Item List Handler Scroll Tests

@MainActor
@Suite("ItemListHandler Scroll Tests")
struct ItemListHandlerScrollTests {

    @Test("Scroll offset adjusts when focus moves below viewport")
    func scrollDownOnFocusBelowViewport() {
        let handler = ItemListHandler<String>(
            focusID: "test",
            itemCount: 10,
            viewportHeight: 3,
            selectionMode: .single
        )
        handler.focusedIndex = 5
        handler.ensureFocusedItemVisible()

        #expect(handler.scrollOffset == 3)  // 5 - 3 + 1 = 3
    }

    @Test("Scroll offset adjusts when focus moves above viewport")
    func scrollUpOnFocusAboveViewport() {
        let handler = ItemListHandler<String>(
            focusID: "test",
            itemCount: 10,
            viewportHeight: 3,
            selectionMode: .single
        )
        handler.scrollOffset = 5
        handler.focusedIndex = 2
        handler.ensureFocusedItemVisible()

        #expect(handler.scrollOffset == 2)
    }

    @Test("hasContentAbove returns correct state")
    func hasContentAboveState() {
        let handler = ItemListHandler<String>(
            focusID: "test",
            itemCount: 10,
            viewportHeight: 3,
            selectionMode: .single
        )

        handler.scrollOffset = 0
        #expect(handler.hasContentAbove == false)

        handler.scrollOffset = 3
        #expect(handler.hasContentAbove == true)
    }

    @Test("hasContentBelow returns correct state")
    func hasContentBelowState() {
        let handler = ItemListHandler<String>(
            focusID: "test",
            itemCount: 10,
            viewportHeight: 3,
            selectionMode: .single
        )

        handler.scrollOffset = 0
        #expect(handler.hasContentBelow == true)

        handler.scrollOffset = 7  // 7 + 3 = 10 = itemCount
        #expect(handler.hasContentBelow == false)
    }

    @Test("visibleRange returns correct range")
    func visibleRangeCorrect() {
        let handler = ItemListHandler<String>(
            focusID: "test",
            itemCount: 10,
            viewportHeight: 3,
            selectionMode: .single
        )
        handler.scrollOffset = 4

        let range = handler.visibleRange
        #expect(range == 4..<7)
    }

    @Test("visibleRange clamps to item count")
    func visibleRangeClampsToItemCount() {
        let handler = ItemListHandler<String>(
            focusID: "test",
            itemCount: 5,
            viewportHeight: 10,
            selectionMode: .single
        )
        handler.scrollOffset = 0

        let range = handler.visibleRange
        #expect(range == 0..<5)
    }
}

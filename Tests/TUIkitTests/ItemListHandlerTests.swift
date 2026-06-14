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

// MARK: - Item List Handler Vim Motion Tests

@MainActor
@Suite("ItemListHandler Vim Motion Tests")
struct ItemListHandlerVimMotionTests {

    // Helper that creates a handler with vim vertical navigation active.
    func makeVimHandler(itemCount: Int, viewportHeight: Int) -> ItemListHandler<String> {
        let handler = ItemListHandler<String>(
            focusID: "test",
            itemCount: itemCount,
            viewportHeight: viewportHeight,
            selectionMode: .single
        )
        handler.verticalNavigationStyles = [.vim]
        return handler
    }

    // MARK: j / k

    @Test("j moves focus down")
    func jMovesDown() {
        let handler = makeVimHandler(itemCount: 5, viewportHeight: 5)

        let handled = handler.handleKeyEvent(KeyEvent(key: .character("j")))

        #expect(handled == true)
        #expect(handler.focusedIndex == 1)
    }

    @Test("j wraps to start when at last item")
    func jWrapsToStart() {
        let handler = makeVimHandler(itemCount: 3, viewportHeight: 3)
        handler.focusedIndex = 2

        _ = handler.handleKeyEvent(KeyEvent(key: .character("j")))

        #expect(handler.focusedIndex == 0)
    }

    @Test("k moves focus up")
    func kMovesUp() {
        let handler = makeVimHandler(itemCount: 5, viewportHeight: 5)
        handler.focusedIndex = 3

        let handled = handler.handleKeyEvent(KeyEvent(key: .character("k")))

        #expect(handled == true)
        #expect(handler.focusedIndex == 2)
    }

    @Test("k wraps to end when at first item")
    func kWrapsToEnd() {
        let handler = makeVimHandler(itemCount: 3, viewportHeight: 3)
        handler.focusedIndex = 0

        _ = handler.handleKeyEvent(KeyEvent(key: .character("k")))

        #expect(handler.focusedIndex == 2)
    }

    // MARK: g / G

    @Test("g jumps to first item")
    func gJumpsToFirst() {
        let handler = makeVimHandler(itemCount: 10, viewportHeight: 5)
        handler.focusedIndex = 7

        let handled = handler.handleKeyEvent(KeyEvent(key: .character("g")))

        #expect(handled == true)
        #expect(handler.focusedIndex == 0)
    }

    @Test("G jumps to last item")
    func bigGJumpsToLast() {
        let handler = makeVimHandler(itemCount: 10, viewportHeight: 5)
        handler.focusedIndex = 2

        let handled = handler.handleKeyEvent(KeyEvent(key: .character("G")))

        #expect(handled == true)
        #expect(handler.focusedIndex == 9)
    }

    @Test("g respects selectableIndices — jumps to first selectable")
    func gRespectsSelectableIndices() {
        let handler = makeVimHandler(itemCount: 5, viewportHeight: 5)
        handler.selectableIndices = [1, 2, 3, 4]  // index 0 is a section header
        handler.focusedIndex = 3

        _ = handler.handleKeyEvent(KeyEvent(key: .character("g")))

        #expect(handler.focusedIndex == 1)
    }

    @Test("G respects selectableIndices — jumps to last selectable")
    func bigGRespectsSelectableIndices() {
        let handler = makeVimHandler(itemCount: 5, viewportHeight: 5)
        handler.selectableIndices = [0, 1, 2, 3]  // index 4 is a section footer
        handler.focusedIndex = 1

        _ = handler.handleKeyEvent(KeyEvent(key: .character("G")))

        #expect(handler.focusedIndex == 3)
    }

    // MARK: Ctrl+d / Ctrl+u (half page)

    @Test("Ctrl+d moves half a viewport down")
    func ctrlDHalfPageDown() {
        let handler = makeVimHandler(itemCount: 20, viewportHeight: 6)
        handler.focusedIndex = 2

        let handled = handler.handleKeyEvent(KeyEvent(key: .character("d"), ctrl: true))

        #expect(handled == true)
        #expect(handler.focusedIndex == 5)  // 2 + max(1, 6/2) = 2 + 3
    }

    @Test("Ctrl+u moves half a viewport up")
    func ctrlUHalfPageUp() {
        let handler = makeVimHandler(itemCount: 20, viewportHeight: 6)
        handler.focusedIndex = 8

        let handled = handler.handleKeyEvent(KeyEvent(key: .character("u"), ctrl: true))

        #expect(handled == true)
        #expect(handler.focusedIndex == 5)  // 8 - max(1, 6/2) = 8 - 3
    }

    @Test("Ctrl+d clamps at last item")
    func ctrlDClampsAtEnd() {
        let handler = makeVimHandler(itemCount: 10, viewportHeight: 6)
        handler.focusedIndex = 8  // 8 + 3 = 11, clamped to 9

        _ = handler.handleKeyEvent(KeyEvent(key: .character("d"), ctrl: true))

        #expect(handler.focusedIndex == 9)
    }

    @Test("Ctrl+u clamps at first item")
    func ctrlUClampsAtStart() {
        let handler = makeVimHandler(itemCount: 10, viewportHeight: 6)
        handler.focusedIndex = 1  // 1 - 3 = -2, clamped to 0

        _ = handler.handleKeyEvent(KeyEvent(key: .character("u"), ctrl: true))

        #expect(handler.focusedIndex == 0)
    }

    @Test("Ctrl+d moves at least 1 step when viewport is 1")
    func ctrlDMinimumStep() {
        let handler = makeVimHandler(itemCount: 10, viewportHeight: 1)
        handler.focusedIndex = 0

        _ = handler.handleKeyEvent(KeyEvent(key: .character("d"), ctrl: true))

        #expect(handler.focusedIndex == 1)  // max(1, 1/2) = 1
    }

    // MARK: Ctrl+f / Ctrl+b (full page)

    @Test("Ctrl+f moves a full viewport down")
    func ctrlFFullPageDown() {
        let handler = makeVimHandler(itemCount: 20, viewportHeight: 5)
        handler.focusedIndex = 2

        let handled = handler.handleKeyEvent(KeyEvent(key: .character("f"), ctrl: true))

        #expect(handled == true)
        #expect(handler.focusedIndex == 7)  // 2 + 5
    }

    @Test("Ctrl+b moves a full viewport up")
    func ctrlBFullPageUp() {
        let handler = makeVimHandler(itemCount: 20, viewportHeight: 5)
        handler.focusedIndex = 10

        let handled = handler.handleKeyEvent(KeyEvent(key: .character("b"), ctrl: true))

        #expect(handled == true)
        #expect(handler.focusedIndex == 5)  // 10 - 5
    }
}

// MARK: - Item List Handler Navigation Style Gating Tests

@MainActor
@Suite("ItemListHandler Navigation Style Gating Tests")
struct ItemListHandlerNavigationStyleGatingTests {

    @Test("Default style is arrowKey — j/k are ignored")
    func defaultStyleIgnoresVimKeys() {
        let handler = ItemListHandler<String>(
            focusID: "test", itemCount: 5, viewportHeight: 5, selectionMode: .single
        )
        // verticalNavigationStyles defaults to [.arrowKey]

        let jHandled = handler.handleKeyEvent(KeyEvent(key: .character("j")))
        let kHandled = handler.handleKeyEvent(KeyEvent(key: .character("k")))

        #expect(jHandled == false)
        #expect(kHandled == false)
        #expect(handler.focusedIndex == 0)  // Unchanged
    }

    @Test("Default style is arrowKey — arrow keys still work")
    func defaultStyleArrowKeysWork() {
        let handler = ItemListHandler<String>(
            focusID: "test", itemCount: 5, viewportHeight: 5, selectionMode: .single
        )

        let handled = handler.handleKeyEvent(KeyEvent(key: .down))

        #expect(handled == true)
        #expect(handler.focusedIndex == 1)
    }

    @Test("Vim-only style — j moves focus, arrow keys are ignored")
    func vimOnlyStyleArrowKeysIgnored() {
        let handler = ItemListHandler<String>(
            focusID: "test", itemCount: 5, viewportHeight: 5, selectionMode: .single
        )
        handler.verticalNavigationStyles = [.vim]

        let downHandled = handler.handleKeyEvent(KeyEvent(key: .down))
        let homeHandled = handler.handleKeyEvent(KeyEvent(key: .home))
        let pageDownHandled = handler.handleKeyEvent(KeyEvent(key: .pageDown))

        #expect(downHandled == false)
        #expect(homeHandled == false)
        #expect(pageDownHandled == false)
        #expect(handler.focusedIndex == 0)  // Unchanged by arrow keys
    }

    @Test("Vim-only style — j/k/g/G all work")
    func vimOnlyStyleVimKeysWork() {
        let handler = ItemListHandler<String>(
            focusID: "test", itemCount: 5, viewportHeight: 5, selectionMode: .single
        )
        handler.verticalNavigationStyles = [.vim]

        let jHandled = handler.handleKeyEvent(KeyEvent(key: .character("j")))
        #expect(jHandled == true)
        #expect(handler.focusedIndex == 1)

        let bigGHandled = handler.handleKeyEvent(KeyEvent(key: .character("G")))
        #expect(bigGHandled == true)
        #expect(handler.focusedIndex == 4)

        let gHandled = handler.handleKeyEvent(KeyEvent(key: .character("g")))
        #expect(gHandled == true)
        #expect(handler.focusedIndex == 0)
    }

    @Test("Both styles — arrow keys and vim keys all work")
    func bothStylesAllKeysWork() {
        let handler = ItemListHandler<String>(
            focusID: "test", itemCount: 10, viewportHeight: 5, selectionMode: .single
        )
        handler.verticalNavigationStyles = [.arrowKey, .vim]

        let downHandled = handler.handleKeyEvent(KeyEvent(key: .down))
        #expect(downHandled == true)
        #expect(handler.focusedIndex == 1)

        let jHandled = handler.handleKeyEvent(KeyEvent(key: .character("j")))
        #expect(jHandled == true)
        #expect(handler.focusedIndex == 2)

        let homeHandled = handler.handleKeyEvent(KeyEvent(key: .home))
        #expect(homeHandled == true)
        #expect(handler.focusedIndex == 0)

        let gHandled = handler.handleKeyEvent(KeyEvent(key: .character("G")))
        #expect(gHandled == true)
        #expect(handler.focusedIndex == 9)
    }

    @Test("Empty style set — all navigation keys ignored")
    func emptyStyleIgnoresAll() {
        let handler = ItemListHandler<String>(
            focusID: "test", itemCount: 5, viewportHeight: 5, selectionMode: .single
        )
        handler.verticalNavigationStyles = []

        #expect(handler.handleKeyEvent(KeyEvent(key: .down)) == false)
        #expect(handler.handleKeyEvent(KeyEvent(key: .character("j"))) == false)
        #expect(handler.handleKeyEvent(KeyEvent(key: .home)) == false)
        #expect(handler.handleKeyEvent(KeyEvent(key: .character("g"))) == false)
        #expect(handler.focusedIndex == 0)
    }
}

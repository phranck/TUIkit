//  🖥️ TUIKit — Terminal UI Kit for Swift
//  ListTests.swift
//
//  Created by LAYERED.work
//  License: MIT

import Testing

@testable import TUIkit

// MARK: - Test Helpers

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

// MARK: - List Creation Tests

@Suite("List Creation Tests")
struct ListCreationTests {
    
    @Test("List can be created without selection")
    func listCreationNoSelection() {
        let list = List {
            Text("Item 1")
            Text("Item 2")
        }
        
        #expect(list.selection == nil)
        #expect(list.isDisabled == false)
    }
    
    @Test("List can be created with selection binding")
    func listCreationWithSelection() {
        var selectedID: String?
        let binding = Binding(
            get: { selectedID },
            set: { selectedID = $0 }
        )
        
        let list = List(selection: binding) {
            Text("Item 1").tag("id-1")
            Text("Item 2").tag("id-2")
        }
        
        #expect(list.selection != nil)
        #expect(list.isDisabled == false)
    }
    
    @Test("List can be created with fixed height")
    func listCreationWithHeight() {
        let list = List(height: 10) {
            Text("Item")
        }
        
        #expect(list.height == 10)
    }
    
    @Test("List can be disabled")
    func listDisabled() {
        let list = List {
            Text("Item")
        }
        .disabled()
        
        #expect(list.isDisabled == true)
    }
}

// MARK: - List Handler Navigation Tests

@Suite("ListHandler Navigation Tests", .serialized)
struct ListHandlerNavigationTests {
    
    @Test("Handler focuses first item on creation")
    func autoFocusFirstItem() {
        let handler = ListHandler(
            focusID: "test",
            selection: nil,
            rowCount: 3,
            canBeFocused: true
        )
        
        #expect(handler.focusedIndex == 0)
    }
    
    @Test("Handler does not focus empty list")
    func emptyListNoFocus() {
        let handler = ListHandler(
            focusID: "test",
            selection: nil,
            rowCount: 0,
            canBeFocused: true
        )
        
        #expect(handler.focusedIndex == -1)
    }
    
    @Test("Handler navigates down within bounds")
    func navigateDown() {
        let handler = ListHandler(
            focusID: "test",
            selection: nil,
            rowCount: 5,
            canBeFocused: true
        )
        handler.viewportHeight = 5
        
        let event = KeyEvent(key: .down)
        let handled = handler.handleKeyEvent(event)
        
        #expect(handled == true)
        #expect(handler.focusedIndex == 1)
    }
    
    @Test("Handler navigates up within bounds")
    func navigateUp() {
        let handler = ListHandler(
            focusID: "test",
            selection: nil,
            rowCount: 5,
            canBeFocused: true
        )
        handler.viewportHeight = 5
        handler.focusedIndex = 2
        
        let event = KeyEvent(key: .up)
        let handled = handler.handleKeyEvent(event)
        
        #expect(handled == true)
        #expect(handler.focusedIndex == 1)
    }
    
    @Test("Handler wraps down at end")
    func wrapDown() {
        let handler = ListHandler(
            focusID: "test",
            selection: nil,
            rowCount: 5,
            canBeFocused: true
        )
        handler.viewportHeight = 5
        handler.focusedIndex = 4  // Last item
        
        let event = KeyEvent(key: .down)
        let handled = handler.handleKeyEvent(event)
        
        #expect(handled == true)
        #expect(handler.focusedIndex == 0)  // Wrap to start
    }
    
    @Test("Handler wraps up at start")
    func wrapUp() {
        let handler = ListHandler(
            focusID: "test",
            selection: nil,
            rowCount: 5,
            canBeFocused: true
        )
        handler.viewportHeight = 5
        handler.focusedIndex = 0  // First item
        
        let event = KeyEvent(key: .up)
        let handled = handler.handleKeyEvent(event)
        
        #expect(handled == true)
        #expect(handler.focusedIndex == 4)  // Wrap to end
    }
    
    @Test("Handler jumps to home")
    func jumpHome() {
        let handler = ListHandler(
            focusID: "test",
            selection: nil,
            rowCount: 10,
            canBeFocused: true
        )
        handler.viewportHeight = 5
        handler.focusedIndex = 7
        
        let event = KeyEvent(key: .home)
        let handled = handler.handleKeyEvent(event)
        
        #expect(handled == true)
        #expect(handler.focusedIndex == 0)
    }
    
    @Test("Handler jumps to end")
    func jumpEnd() {
        let handler = ListHandler(
            focusID: "test",
            selection: nil,
            rowCount: 10,
            canBeFocused: true
        )
        handler.viewportHeight = 5
        handler.focusedIndex = 2
        
        let event = KeyEvent(key: .end)
        let handled = handler.handleKeyEvent(event)
        
        #expect(handled == true)
        #expect(handler.focusedIndex == 9)
    }
    
    @Test("Handler pages down")
    func pageDown() {
        let handler = ListHandler(
            focusID: "test",
            selection: nil,
            rowCount: 20,
            canBeFocused: true
        )
        handler.viewportHeight = 5
        handler.focusedIndex = 0
        
        let event = KeyEvent(key: .pageDown)
        let handled = handler.handleKeyEvent(event)
        
        #expect(handled == true)
        #expect(handler.focusedIndex == 5)
    }
    
    @Test("Handler pages up")
    func pageUp() {
        let handler = ListHandler(
            focusID: "test",
            selection: nil,
            rowCount: 20,
            canBeFocused: true
        )
        handler.viewportHeight = 5
        handler.focusedIndex = 10
        
        let event = KeyEvent(key: .pageUp)
        let handled = handler.handleKeyEvent(event)
        
        #expect(handled == true)
        #expect(handler.focusedIndex == 5)
    }
    
    @Test("Handler auto-scrolls focused row into view (down)")
    func autoScrollDown() {
        let handler = ListHandler(
            focusID: "test",
            selection: nil,
            rowCount: 20,
            canBeFocused: true
        )
        handler.viewportHeight = 5
        handler.scrollOffset = 0
        handler.focusedIndex = 0
        
        // Navigate down past viewport
        for _ in 0..<8 {
            let event = KeyEvent(key: .down)
            _ = handler.handleKeyEvent(event)
        }
        
        // Focused index is 8, viewport is 5, so scrollOffset should be 4 (8 - 5 + 1)
        #expect(handler.focusedIndex == 8)
        #expect(handler.scrollOffset == 4)
    }
    
    @Test("Handler auto-scrolls focused row into view (up)")
    func autoScrollUp() {
        let handler = ListHandler(
            focusID: "test",
            selection: nil,
            rowCount: 20,
            canBeFocused: true
        )
        handler.viewportHeight = 5
        handler.scrollOffset = 10
        handler.focusedIndex = 15
        
        // Navigate up past viewport
        for _ in 0..<10 {
            let event = KeyEvent(key: .up)
            _ = handler.handleKeyEvent(event)
        }
        
        // Focused index is 5, scrollOffset should follow
        #expect(handler.focusedIndex == 5)
        #expect(handler.scrollOffset == 5)
    }
    
    @Test("Handler prevents over-scrolling")
    func preventOverScroll() {
        let handler = ListHandler(
            focusID: "test",
            selection: nil,
            rowCount: 10,
            canBeFocused: true
        )
        handler.viewportHeight = 5
        handler.focusedIndex = 9  // Last item
        
        let event = KeyEvent(key: .pageDown)
        _ = handler.handleKeyEvent(event)
        
        // scrollOffset should be 5 (10 - 5), not beyond
        #expect(handler.scrollOffset == 5)
        #expect(handler.focusedIndex == 9)
    }
}

// MARK: - List Rendering Tests

@Suite("List Rendering Tests")
struct ListRenderingTests {
    
    @Test("List renders single item correctly")
    func renderSingleCorrectly() {
        let context = createTestContext()
        
        let list = List(height: 5) {
            Text("Item")
        }
        
        let buffer = TUIkit.renderToBuffer(list, context: context)
        
        // Single item should render with focus indicator
        #expect(buffer.height >= 1)
        let content = buffer.lines.joined()
        #expect(content.contains("Item"))
    }
    
    @Test("List renders with single item")
    func renderSingleItem() {
        let context = createTestContext()
        
        let list = List {
            Text("Item 1")
        }
        
        let buffer = TUIkit.renderToBuffer(list, context: context)
        
        // Should have at least 1 line
        #expect(buffer.height >= 1)
        let content = buffer.lines.joined()
        #expect(content.contains("Item 1"))
    }
    
    @Test("List renders multiple items vertically")
    func renderMultipleItems() {
        let context = createTestContext()
        
        let list = List {
            Text("Item 1")
            Text("Item 2")
            Text("Item 3")
            Text("Item 4")
            Text("Item 5")
        }
        
        let buffer = TUIkit.renderToBuffer(list, context: context)
        
        // Should have at least 5 lines (one per item)
        #expect(buffer.height >= 5)
        
        let content = buffer.lines.joined()
        #expect(content.contains("Item 1"))
        #expect(content.contains("Item 2"))
        #expect(content.contains("Item 3"))
        #expect(content.contains("Item 4"))
        #expect(content.contains("Item 5"))
    }
    
    @Test("List shows focus indicator on focused item")
    func renderFocusIndicator() {
        let context = createTestContext()
        
        let list = List(focusID: "test-list") {
            Text("Item 1")
        }
        
        let buffer = TUIkit.renderToBuffer(list, context: context)
        let content = buffer.lines.joined()
        
        // Focused item should have pulsing indicator (ANSI codes)
        #expect(content.contains("\u{1b}["))
    }
    
    @Test("List renders with viewport height")
    func renderWithHeight() {
        let context = createTestContext(height: 10)
        
        let list = List(height: 5, focusID: "test-list") {
            Text("Item 1")
        }
        
        let buffer = TUIkit.renderToBuffer(list, context: context)
        
        // List should respect height parameter
        #expect(buffer.height >= 1)
    }
}

// MARK: - List with Selection Tests

@Suite("List Selection Tests", .serialized)
struct ListSelectionTests {
    
    @Test("List with selection binding")
    func selectionBinding() {
        var selectedID: String?
        let binding = Binding(
            get: { selectedID },
            set: { selectedID = $0 }
        )
        
        let list = List(selection: binding, focusID: "test") {
            Text("Item 1")
        }
        
        let context = createTestContext()
        let buffer = TUIkit.renderToBuffer(list, context: context)
        
        #expect(buffer.height >= 1)
        #expect(selectedID == nil)  // No selection yet
    }
    
    @Test("List respects disabled state")
    func disabledList() {
        let list = List {
            Text("Item")
        }
        .disabled()
        
        #expect(list.isDisabled == true)
    }
}

// MARK: - List Handler Tests

@Suite("ListHandler Tests")
struct ListHandlerTests {
    
    @Test("Handler respects canBeFocused property")
    func respectsCanBeFocused() {
        let handler = ListHandler(
            focusID: "test",
            selection: nil,
            rowCount: 3,
            canBeFocused: false
        )
        
        #expect(handler.canBeFocused == false)
    }
    
    @Test("Handler ignores navigation when empty")
    func ignoreNavigationWhenEmpty() {
        let handler = ListHandler(
            focusID: "test",
            selection: nil,
            rowCount: 0,
            canBeFocused: true
        )
        
        let event = KeyEvent(key: .down)
        let handled = handler.handleKeyEvent(event)
        
        #expect(handled == false)
        #expect(handler.focusedIndex == -1)
    }
    
    @Test("Handler initializes viewport height")
    func viewportHeight() {
        let handler = ListHandler(
            focusID: "test",
            selection: nil,
            rowCount: 10,
            canBeFocused: true
        )
        
        #expect(handler.viewportHeight == 5)  // Default
    }
}

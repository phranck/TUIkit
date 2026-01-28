//
//  TViewTests.swift
//  SwiftTUI
//
//  Tests for the TView protocol and ViewBuilder.
//

import Testing
@testable import SwiftTUI

@Suite("TView Protocol Tests")
struct TViewTests {

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
        @TViewBuilder
        func buildView() -> some TView {
            Text("Single")
        }

        let view = buildView()
        #expect(view is Text)
    }

    @Test("ViewBuilder with two views")
    func twoViews() {
        @TViewBuilder
        func buildViews() -> some TView {
            Text("First")
            Text("Second")
        }

        let views = buildViews()
        #expect(views is TupleView2<Text, Text>)
    }

    @Test("ViewBuilder with three views")
    func threeViews() {
        @TViewBuilder
        func buildViews() -> some TView {
            Text("One")
            Text("Two")
            Text("Three")
        }

        let views = buildViews()
        #expect(views is TupleView3<Text, Text, Text>)
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

@Suite("Color Tests")
struct ColorTests {

    @Test("Standard colors are available")
    func standardColors() {
        let colors: [Color] = [
            .black, .red, .green, .yellow,
            .blue, .magenta, .cyan, .white
        ]

        #expect(colors.count == 8)
    }

    @Test("Bright colors are available")
    func brightColors() {
        let colors: [Color] = [
            .brightBlack, .brightRed, .brightGreen, .brightYellow,
            .brightBlue, .brightMagenta, .brightCyan, .brightWhite
        ]

        #expect(colors.count == 8)
    }

    @Test("RGB color can be created")
    func rgbColor() {
        let color = Color.rgb(255, 128, 64)
        #expect(color == Color.rgb(255, 128, 64))
    }

    @Test("Hex color can be created")
    func hexColor() {
        let color = Color.hex(0xFF8040)
        #expect(color == Color.rgb(255, 128, 64))
    }

    @Test("Palette color can be created")
    func paletteColor() {
        let color = Color.palette(196)
        #expect(color == Color.palette(196))
    }

    @Test("Semantic colors are defined")
    func semanticColors() {
        _ = Color.primary
        _ = Color.secondary
        _ = Color.accent
        _ = Color.warning
        _ = Color.error
        _ = Color.success
    }
}

@Suite("ANSI Renderer Tests")
struct ANSIRendererTests {

    @Test("Reset code is correct")
    func resetCode() {
        #expect(ANSIRenderer.reset == "\u{1B}[0m")
    }

    @Test("Text without style is returned unchanged")
    func plainText() {
        let result = ANSIRenderer.render("Hello", with: TextStyle())
        #expect(result == "Hello")
    }

    @Test("Bold text has correct code")
    func boldText() {
        var style = TextStyle()
        style.isBold = true
        let result = ANSIRenderer.render("Bold", with: style)
        #expect(result.contains("\u{1B}[1m"))
        #expect(result.contains("\u{1B}[0m"))
    }

    @Test("Cursor movement generates correct codes")
    func cursorMovement() {
        let moveCode = ANSIRenderer.moveCursor(toRow: 5, column: 10)
        #expect(moveCode == "\u{1B}[5;10H")
    }

    @Test("Clear screen generates correct code")
    func clearScreen() {
        #expect(ANSIRenderer.clearScreen == "\u{1B}[2J")
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

@Suite("FrameBuffer Tests")
struct FrameBufferTests {

    @Test("Empty buffer has zero dimensions")
    func emptyBuffer() {
        let buffer = FrameBuffer()
        #expect(buffer.width == 0)
        #expect(buffer.height == 0)
        #expect(buffer.isEmpty)
    }

    @Test("Single line buffer has correct dimensions")
    func singleLine() {
        let buffer = FrameBuffer(text: "Hello")
        #expect(buffer.width == 5)
        #expect(buffer.height == 1)
        #expect(buffer.lines == ["Hello"])
    }

    @Test("Vertical append stacks lines")
    func verticalAppend() {
        var buffer = FrameBuffer(text: "Line 1")
        buffer.appendVertically(FrameBuffer(text: "Line 2"))
        #expect(buffer.height == 2)
        #expect(buffer.lines == ["Line 1", "Line 2"])
    }

    @Test("Vertical append with spacing")
    func verticalAppendWithSpacing() {
        var buffer = FrameBuffer(text: "Top")
        buffer.appendVertically(FrameBuffer(text: "Bottom"), spacing: 2)
        #expect(buffer.height == 4)
        #expect(buffer.lines == ["Top", "", "", "Bottom"])
    }

    @Test("Horizontal append places side by side")
    func horizontalAppend() {
        var buffer = FrameBuffer(text: "Left")
        buffer.appendHorizontally(FrameBuffer(text: "Right"), spacing: 1)
        #expect(buffer.height == 1)
        #expect(buffer.lines == ["Left Right"])
    }

    @Test("Horizontal append with different heights pads correctly")
    func horizontalAppendDifferentHeights() {
        var left = FrameBuffer(lines: ["AB", "CD"])
        let right = FrameBuffer(text: "X")
        left.appendHorizontally(right, spacing: 1)
        #expect(left.height == 2)
        #expect(left.lines[0] == "AB X")
        // Row 1: "CD" padded to width 2, spacing " ", no right content
        #expect(left.lines[1] == "CD ")
    }

    @Test("ANSI codes are excluded from width calculation")
    func ansiStrippedWidth() {
        let styled = "\u{1B}[1mBold\u{1B}[0m"
        let buffer = FrameBuffer(text: styled)
        #expect(buffer.width == 4) // "Bold" is 4 chars
    }

    @Test("Horizontal append with ANSI codes pads correctly")
    func horizontalAppendWithAnsi() {
        let styled = "\u{1B}[1mHi\u{1B}[0m"
        var left = FrameBuffer(text: styled)
        left.appendHorizontally(FrameBuffer(text: "There"), spacing: 1)
        #expect(left.height == 1)
        // "Hi" (styled) + " " (spacing) + "There"
        #expect(left.lines[0].stripped == "Hi There")
    }
}

@Suite("Rendering Tests")
struct RenderingTests {

    @Test("Text renders to single line buffer")
    func textBuffer() {
        let text = Text("Hello")
        let context = RenderContext(availableWidth: 80, availableHeight: 24)
        let buffer = renderToBuffer(text, context: context)
        #expect(buffer.height == 1)
        #expect(buffer.lines[0] == "Hello")
    }

    @Test("EmptyView renders to empty buffer")
    func emptyViewBuffer() {
        let empty = EmptyView()
        let context = RenderContext(availableWidth: 80, availableHeight: 24)
        let buffer = renderToBuffer(empty, context: context)
        #expect(buffer.isEmpty)
    }

    @Test("VStack renders children vertically")
    func vstackBuffer() {
        let stack = VStack {
            Text("Line 1")
            Text("Line 2")
        }
        let context = RenderContext(availableWidth: 80, availableHeight: 24)
        let buffer = renderToBuffer(stack, context: context)
        #expect(buffer.height == 2)
        #expect(buffer.lines[0] == "Line 1")
        #expect(buffer.lines[1] == "Line 2")
    }

    @Test("VStack renders with spacing")
    func vstackWithSpacing() {
        let stack = VStack(spacing: 1) {
            Text("A")
            Text("B")
        }
        let context = RenderContext(availableWidth: 80, availableHeight: 24)
        let buffer = renderToBuffer(stack, context: context)
        #expect(buffer.height == 3)
        #expect(buffer.lines[0] == "A")
        #expect(buffer.lines[1] == "")
        #expect(buffer.lines[2] == "B")
    }

    @Test("HStack renders children horizontally")
    func hstackBuffer() {
        let stack = HStack {
            Text("Left")
            Text("Right")
        }
        let context = RenderContext(availableWidth: 80, availableHeight: 24)
        let buffer = renderToBuffer(stack, context: context)
        #expect(buffer.height == 1)
        #expect(buffer.lines[0] == "Left Right")
    }

    @Test("HStack renders with custom spacing")
    func hstackCustomSpacing() {
        let stack = HStack(spacing: 3) {
            Text("A")
            Text("B")
        }
        let context = RenderContext(availableWidth: 80, availableHeight: 24)
        let buffer = renderToBuffer(stack, context: context)
        #expect(buffer.height == 1)
        #expect(buffer.lines[0] == "A   B")
    }

    @Test("Nested VStack in HStack works")
    func nestedStacks() {
        let layout = HStack(spacing: 2) {
            Text("Label:")
            Text("Value")
        }
        let context = RenderContext(availableWidth: 80, availableHeight: 24)
        let buffer = renderToBuffer(layout, context: context)
        #expect(buffer.height == 1)
        #expect(buffer.lines[0] == "Label:  Value")
    }

    @Test("Composite view renders through body")
    func compositeView() {
        struct MyView: TView {
            var body: some TView {
                VStack {
                    Text("Hello")
                    Text("World")
                }
            }
        }

        let view = MyView()
        let context = RenderContext(availableWidth: 80, availableHeight: 24)
        let buffer = renderToBuffer(view, context: context)
        #expect(buffer.height == 2)
        #expect(buffer.lines[0] == "Hello")
        #expect(buffer.lines[1] == "World")
    }

    @Test("Divider renders to full width")
    func dividerBuffer() {
        let divider = Divider()
        let context = RenderContext(availableWidth: 20, availableHeight: 24)
        let buffer = renderToBuffer(divider, context: context)
        #expect(buffer.height == 1)
        #expect(buffer.lines[0] == String(repeating: "─", count: 20))
    }

    @Test("Spacer renders empty lines")
    func spacerBuffer() {
        let spacer = Spacer(minLength: 3)
        let context = RenderContext(availableWidth: 80, availableHeight: 24)
        let buffer = renderToBuffer(spacer, context: context)
        #expect(buffer.height == 3)
    }
}

@Suite("Overlay Tests")
struct OverlayTests {

    @Test("Overlay modifier renders overlay on top of base")
    func overlayRendering() {
        let view = Text("Base Content")
            .overlay {
                Text("Top")
            }
        let context = RenderContext(availableWidth: 80, availableHeight: 24)
        let buffer = renderToBuffer(view, context: context)
        // The overlay "Top" should be centered on "Base Content"
        #expect(buffer.height >= 1)
        #expect(!buffer.isEmpty)
    }

    @Test("Dimmed modifier applies dim effect")
    func dimmedRendering() {
        let view = Text("Dimmed text").dimmed()
        let context = RenderContext(availableWidth: 80, availableHeight: 24)
        let buffer = renderToBuffer(view, context: context)
        #expect(buffer.height == 1)
        // Check that the ANSI dim code is present
        #expect(buffer.lines[0].contains("\u{1B}[2m"))
    }

    @Test("Modal helper combines dimmed and overlay")
    func modalRendering() {
        let view = Text("Background")
            .modal {
                Text("Modal")
            }
        let context = RenderContext(availableWidth: 80, availableHeight: 24)
        let buffer = renderToBuffer(view, context: context)
        // The result should contain both the dimmed background and the modal
        #expect(!buffer.isEmpty)
    }

    @Test("FrameBuffer compositing places overlay at correct position")
    func frameBufferCompositing() {
        let base = FrameBuffer(lines: ["AAAA", "AAAA", "AAAA"])
        let overlay = FrameBuffer(text: "X")

        // Place overlay at position (1, 1)
        let result = base.composited(with: overlay, at: (x: 1, y: 1))

        #expect(result.height == 3)
        #expect(result.lines[0] == "AAAA")
        #expect(result.lines[1].contains("X"))
        #expect(result.lines[2] == "AAAA")
    }

    @Test("FrameBuffer compositing with offset")
    func frameBufferCompositingOffset() {
        let base = FrameBuffer(lines: ["1234567890"])
        let overlay = FrameBuffer(text: "XXX")

        // Place overlay at column 3
        let result = base.composited(with: overlay, at: (x: 3, y: 0))

        #expect(result.lines[0].stripped == "123XXX7890")
    }
}

@Suite("Alert Tests")
struct AlertTests {

    @Test("Alert can be created with title and message")
    func alertCreation() {
        let alert = Alert(title: "Test", message: "Test message")
        #expect(alert.title == "Test")
        #expect(alert.message == "Test message")
    }

    @Test("Alert renders with border")
    func alertRendering() {
        let alert = Alert(title: "Warning", message: "Something happened")
        let context = RenderContext(availableWidth: 80, availableHeight: 24)
        let buffer = renderToBuffer(alert, context: context)
        #expect(buffer.height > 2)
        // Should have border characters
        let allContent = buffer.lines.joined()
        #expect(allContent.contains("Warning"))
        #expect(allContent.contains("Something happened"))
    }
}

@Suite("Dialog Tests")
struct DialogTests {

    @Test("Dialog can be created with title and content")
    func dialogCreation() {
        let dialog = Dialog(title: "Settings") {
            Text("Option 1")
            Text("Option 2")
        }
        #expect(dialog.title == "Settings")
    }

    @Test("Dialog renders with panel styling")
    func dialogRendering() {
        let dialog = Dialog(title: "Test Dialog") {
            Text("Content here")
        }
        let context = RenderContext(availableWidth: 80, availableHeight: 24)
        let buffer = renderToBuffer(dialog, context: context)
        #expect(buffer.height > 1)
        // Should contain title and content
        let allContent = buffer.lines.joined()
        #expect(allContent.contains("Test Dialog"))
        #expect(allContent.contains("Content here"))
    }
}

@Suite("Menu Tests")
struct MenuTests {

    @Test("MenuItem can be created with label")
    func menuItemCreation() {
        let item = MenuItem(label: "Option 1")
        #expect(item.label == "Option 1")
        #expect(item.id == "Option 1")
        #expect(item.shortcut == nil)
    }

    @Test("MenuItem can have shortcut")
    func menuItemWithShortcut() {
        let item = MenuItem(label: "Quit", shortcut: "q")
        #expect(item.label == "Quit")
        #expect(item.shortcut == "q")
    }

    @Test("Menu can be created with items")
    func menuCreation() {
        let menu = Menu(
            title: "Test Menu",
            items: [
                MenuItem(label: "Option 1", shortcut: "1"),
                MenuItem(label: "Option 2", shortcut: "2")
            ],
            selectedIndex: 0
        )
        #expect(menu.title == "Test Menu")
        #expect(menu.items.count == 2)
        #expect(menu.selectedIndex == 0)
    }

    @Test("Menu renders with title and border")
    func menuRendering() {
        let menu = Menu(
            title: "My Menu",
            items: [
                MenuItem(label: "First"),
                MenuItem(label: "Second")
            ]
        )
        let context = RenderContext(availableWidth: 80, availableHeight: 24)
        let buffer = renderToBuffer(menu, context: context)
        #expect(!buffer.isEmpty)
        let allContent = buffer.lines.joined()
        // Title should be present
        #expect(allContent.contains("My Menu"))
        // Border characters should be present (rounded style)
        #expect(allContent.contains("╭") || allContent.contains("│"))
        // Note: Menu items via ForEach are not fully rendered yet (known limitation)
    }

    @Test("Menu clamps selectedIndex to valid range")
    func menuClampsIndex() {
        let menu = Menu(
            items: [MenuItem(label: "Only")],
            selectedIndex: 99
        )
        #expect(menu.selectedIndex == 0)
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

@Suite("Focus System Tests")
struct FocusSystemTests {

    init() {
        // Clear focus state before each test
        FocusManager.shared.clear()
    }

    @Test("FocusManager is singleton")
    func focusManagerSingleton() {
        let manager1 = FocusManager.shared
        let manager2 = FocusManager.shared
        #expect(manager1 === manager2)
    }

    @Test("FocusState tracks focus correctly")
    func focusStateTracking() {
        let focusState = FocusState(id: "test-focus")
        // Initially not focused (no focusables registered)
        #expect(!focusState.isFocused)
    }

    @Test("FocusManager handles tab navigation")
    func tabNavigation() {
        FocusManager.shared.clear()

        // Tab should trigger focus next
        let tabEvent = KeyEvent(key: .tab)
        let handled = FocusManager.shared.dispatchKeyEvent(tabEvent)
        // Even without focusables, tab is "handled" by focus system
        #expect(handled == true)
    }

    @Test("FocusManager handles shift+tab navigation")
    func shiftTabNavigation() {
        FocusManager.shared.clear()

        let shiftTabEvent = KeyEvent(key: .tab, shift: true)
        let handled = FocusManager.shared.dispatchKeyEvent(shiftTabEvent)
        #expect(handled == true)
    }
}

@Suite("Button Tests")
struct ButtonTests {

    init() {
        // Clear focus state before each test
        FocusManager.shared.clear()
    }

    @Test("Button can be created with label and action")
    func buttonCreation() {
        var wasPressed = false
        let button = Button("Click Me") {
            wasPressed = true
        }
        #expect(button.label == "Click Me")
        #expect(button.isDisabled == false)
        #expect(wasPressed == false)  // Not pressed yet
    }

    @Test("Button renders with border by default")
    func buttonRendering() {
        FocusManager.shared.clear()
        let button = Button("OK") { }
        let context = RenderContext(availableWidth: 80, availableHeight: 24)
        let buffer = renderToBuffer(button, context: context)

        #expect(buffer.height == 3)  // Top border + content + bottom border
        let allContent = buffer.lines.joined()
        #expect(allContent.contains("OK"))
        // Should have rounded border characters
        #expect(allContent.contains("╭") || allContent.contains("─"))
    }

    @Test("Button with primary style")
    func primaryButtonStyle() {
        FocusManager.shared.clear()
        let button = Button("Submit", style: .primary) { }
        let context = RenderContext(availableWidth: 80, availableHeight: 24)
        let buffer = renderToBuffer(button, context: context)

        #expect(!buffer.isEmpty)
        let allContent = buffer.lines.joined()
        #expect(allContent.contains("Submit"))
    }

    @Test("Button with destructive style")
    func destructiveButtonStyle() {
        FocusManager.shared.clear()
        let button = Button("Delete", style: .destructive) { }
        let context = RenderContext(availableWidth: 80, availableHeight: 24)
        let buffer = renderToBuffer(button, context: context)

        #expect(!buffer.isEmpty)
        let allContent = buffer.lines.joined()
        #expect(allContent.contains("Delete"))
    }

    @Test("Button with plain style has no border")
    func plainButtonStyle() {
        FocusManager.shared.clear()
        let button = Button("Link", style: .plain) { }
        let context = RenderContext(availableWidth: 80, availableHeight: 24)
        let buffer = renderToBuffer(button, context: context)

        // Plain style should have only 1 line (no border)
        #expect(buffer.height == 1)
        // The button may have a focus indicator (▸) if it's the first focusable element
        #expect(buffer.lines[0].stripped.contains("Link"))
    }

    @Test("Disabled button has dimmed appearance")
    func disabledButton() {
        FocusManager.shared.clear()
        let button = Button("Disabled") { }.disabled()
        #expect(button.isDisabled == true)

        let context = RenderContext(availableWidth: 80, availableHeight: 24)
        let buffer = renderToBuffer(button, context: context)
        #expect(!buffer.isEmpty)
    }

    @Test("ButtonStyle default preset")
    func buttonStyleDefault() {
        let style = ButtonStyle.default
        #expect(style.borderStyle == .rounded)
        #expect(style.isBold == false)
        #expect(style.horizontalPadding == 2)
    }

    @Test("ButtonStyle primary preset")
    func buttonStylePrimary() {
        let style = ButtonStyle.primary
        #expect(style.foregroundColor == .cyan)
        #expect(style.borderColor == .cyan)
        #expect(style.isBold == true)
    }

    @Test("ButtonStyle destructive preset")
    func buttonStyleDestructive() {
        let style = ButtonStyle.destructive
        #expect(style.foregroundColor == .red)
        #expect(style.borderColor == .red)
    }

    @Test("ButtonStyle success preset")
    func buttonStyleSuccess() {
        let style = ButtonStyle.success
        #expect(style.foregroundColor == .green)
        #expect(style.borderColor == .green)
    }
}

@Suite("ButtonRow Tests")
struct ButtonRowTests {

    init() {
        FocusManager.shared.clear()
    }

    @Test("ButtonRow renders multiple buttons horizontally")
    func buttonRowRendering() {
        FocusManager.shared.clear()
        let row = ButtonRow {
            Button("Cancel") { }
            Button("OK") { }
        }

        let context = RenderContext(availableWidth: 80, availableHeight: 24)
        let buffer = renderToBuffer(row, context: context)

        #expect(!buffer.isEmpty)
        let allContent = buffer.lines.joined()
        #expect(allContent.contains("Cancel"))
        #expect(allContent.contains("OK"))
    }

    @Test("ButtonRow handles empty builder")
    func emptyButtonRow() {
        FocusManager.shared.clear()
        let row = ButtonRow { }

        let context = RenderContext(availableWidth: 80, availableHeight: 24)
        let buffer = renderToBuffer(row, context: context)

        #expect(buffer.isEmpty)
    }
}

@Suite("StatusBar Item Tests")
struct StatusBarItemTests {

    init() {
        StatusBarManager.shared.clear()
    }

    @Test("TStatusBarItem can be created with shortcut and label")
    func statusBarItemCreation() {
        let item = TStatusBarItem(shortcut: "q", label: "quit")
        #expect(item.shortcut == "q")
        #expect(item.label == "quit")
        #expect(item.id == "q-quit")
    }

    @Test("TStatusBarItem derives trigger key from single character shortcut")
    func statusBarItemTriggerKey() {
        let item = TStatusBarItem(shortcut: "x", label: "delete")
        #expect(item.triggerKey == .character("x"))
    }

    @Test("TStatusBarItem with escape shortcut")
    func statusBarItemEscapeKey() {
        let item = TStatusBarItem(shortcut: "⎋", label: "close")
        #expect(item.triggerKey == .escape)
    }

    @Test("TStatusBarItem with enter shortcut")
    func statusBarItemEnterKey() {
        let item = TStatusBarItem(shortcut: "↵", label: "confirm")
        #expect(item.triggerKey == .enter)
    }

    @Test("TStatusBarItem matches arrow key combinations")
    func statusBarItemArrowKeys() {
        let item = TStatusBarItem(shortcut: "↑↓", label: "nav")

        let upEvent = KeyEvent(key: .up)
        let downEvent = KeyEvent(key: .down)
        let leftEvent = KeyEvent(key: .left)

        #expect(item.matches(upEvent) == true)
        #expect(item.matches(downEvent) == true)
        #expect(item.matches(leftEvent) == false)
    }

    @Test("TStatusBarItem is case-sensitive for character shortcuts")
    func statusBarItemCaseSensitive() {
        let lowerItem = TStatusBarItem(shortcut: "n", label: "next")
        let upperItem = TStatusBarItem(shortcut: "N", label: "new")

        let lowerEvent = KeyEvent(key: .character("n"))
        let upperEvent = KeyEvent(key: .character("N"))

        // Lowercase "n" should only match lowercase
        #expect(lowerItem.matches(lowerEvent) == true)
        #expect(lowerItem.matches(upperEvent) == false)

        // Uppercase "N" should only match uppercase
        #expect(upperItem.matches(lowerEvent) == false)
        #expect(upperItem.matches(upperEvent) == true)
    }

    @Test("TStatusBarItem executes action")
    func statusBarItemAction() {
        // Use a class to track execution (reference type is Sendable-safe)
        final class ExecutionTracker: @unchecked Sendable {
            var wasExecuted = false
        }
        let tracker = ExecutionTracker()

        let item = TStatusBarItem(shortcut: "t", label: "test") {
            tracker.wasExecuted = true
        }

        item.execute()
        #expect(tracker.wasExecuted == true)
    }

    @Test("TStatusBarItem without action does not crash")
    func statusBarItemNoAction() {
        let item = TStatusBarItem(shortcut: "i", label: "info")
        item.execute()  // Should not crash
    }
}

@Suite("StatusBar Manager Tests")
struct StatusBarManagerTests {

    /// Clears the manager and removes any callbacks that might interfere.
    private func resetManager() {
        StatusBarManager.shared.onItemsChanged = nil
        StatusBarManager.shared.clear()
    }

    @Test("StatusBarManager is singleton")
    func managerSingleton() {
        let manager1 = StatusBarManager.shared
        let manager2 = StatusBarManager.shared
        #expect(manager1 === manager2)
    }

    @Test("StatusBarManager can be cleared")
    func managerCanBeCleared() {
        resetManager()

        // Add some items
        StatusBarManager.shared.setGlobalItems([
            TStatusBarItem(shortcut: "x", label: "test")
        ])
        #expect(StatusBarManager.shared.hasItems == true)

        // Clear and verify
        StatusBarManager.shared.clear()
        #expect(StatusBarManager.shared.hasItems == false)
        #expect(StatusBarManager.shared.currentItems.isEmpty)
    }

    @Test("StatusBarManager global items can be set")
    func managerGlobalItems() {
        resetManager()
        StatusBarManager.shared.setGlobalItems([
            TStatusBarItem(shortcut: "q", label: "quit"),
            TStatusBarItem(shortcut: "h", label: "help")
        ])

        #expect(StatusBarManager.shared.hasItems == true)
        #expect(StatusBarManager.shared.currentItems.count == 2)
    }

    @Test("StatusBarManager context stack")
    func managerContextStack() {
        resetManager()

        // Set global items
        StatusBarManager.shared.setGlobalItems([
            TStatusBarItem(shortcut: "q", label: "quit")
        ])
        #expect(StatusBarManager.shared.currentItems.count == 1)

        // Push a context
        StatusBarManager.shared.push(context: "dialog", items: [
            TStatusBarItem(shortcut: "⎋", label: "close"),
            TStatusBarItem(shortcut: "↵", label: "confirm")
        ])
        #expect(StatusBarManager.shared.currentItems.count == 2)
        #expect(StatusBarManager.shared.currentItems[0].shortcut == "⎋")

        // Pop the context
        StatusBarManager.shared.pop(context: "dialog")
        #expect(StatusBarManager.shared.currentItems.count == 1)
        #expect(StatusBarManager.shared.currentItems[0].shortcut == "q")
    }

    @Test("StatusBarManager handles key events")
    func managerKeyEvents() {
        resetManager()

        // Use a class to track execution (reference type is Sendable-safe)
        final class ExecutionTracker: @unchecked Sendable {
            var wasHandled = false
        }
        let tracker = ExecutionTracker()

        StatusBarManager.shared.setGlobalItems([
            TStatusBarItem(shortcut: "t", label: "test") {
                tracker.wasHandled = true
            }
        ])

        let event = KeyEvent(key: .character("t"))
        let handled = StatusBarManager.shared.handleKeyEvent(event)

        #expect(handled == true)
        #expect(tracker.wasHandled == true)
    }

    @Test("StatusBarManager does not handle unmatched events")
    func managerUnmatchedEvents() {
        resetManager()
        StatusBarManager.shared.setGlobalItems([
            TStatusBarItem(shortcut: "a", label: "action")
        ])

        let event = KeyEvent(key: .character("z"))
        let handled = StatusBarManager.shared.handleKeyEvent(event)

        #expect(handled == false)
    }
}

@Suite("TStatusBar Tests")
struct TStatusBarTests {

    init() {
        StatusBarManager.shared.clear()
    }

    @Test("TStatusBar compact style renders single line")
    func statusBarCompactStyle() {
        let statusBar = TStatusBar(
            items: [TStatusBarItem(shortcut: "q", label: "quit")],
            style: .compact
        )

        #expect(statusBar.height == 1)

        let context = RenderContext(availableWidth: 80, availableHeight: 24)
        let buffer = renderToBuffer(statusBar, context: context)

        #expect(buffer.height == 1)
        #expect(buffer.lines[0].stripped.contains("q"))
        #expect(buffer.lines[0].stripped.contains("quit"))
    }

    @Test("TStatusBar bordered style renders three lines")
    func statusBarBorderedStyle() {
        let statusBar = TStatusBar(
            items: [TStatusBarItem(shortcut: "q", label: "quit")],
            style: .bordered
        )

        #expect(statusBar.height == 3)

        let context = RenderContext(availableWidth: 80, availableHeight: 24)
        let buffer = renderToBuffer(statusBar, context: context)

        #expect(buffer.height == 3)
        // Check for block border characters
        let topLine = buffer.lines[0]
        #expect(topLine.contains("█") || topLine.contains("▀"))
    }

    @Test("TStatusBar with multiple items")
    func statusBarMultipleItems() {
        let statusBar = TStatusBar(
            items: [
                TStatusBarItem(shortcut: "q", label: "quit"),
                TStatusBarItem(shortcut: "↑↓", label: "nav"),
                TStatusBarItem(shortcut: "⎋", label: "close")
            ],
            style: .compact
        )

        let context = RenderContext(availableWidth: 80, availableHeight: 24)
        let buffer = renderToBuffer(statusBar, context: context)

        let content = buffer.lines[0].stripped
        #expect(content.contains("quit"))
        #expect(content.contains("nav"))
        #expect(content.contains("close"))
    }

    @Test("TStatusBar with empty items renders nothing")
    func statusBarEmptyItems() {
        let statusBar = TStatusBar(items: [], style: .compact)

        let context = RenderContext(availableWidth: 80, availableHeight: 24)
        let buffer = renderToBuffer(statusBar, context: context)

        #expect(buffer.isEmpty)
    }

    @Test("TStatusBar uses StatusBarManager items")
    func statusBarFromManager() {
        StatusBarManager.shared.clear()
        StatusBarManager.shared.setGlobalItems([
            TStatusBarItem(shortcut: "h", label: "help")
        ])

        let statusBar = TStatusBar()

        let context = RenderContext(availableWidth: 80, availableHeight: 24)
        let buffer = renderToBuffer(statusBar, context: context)

        #expect(buffer.lines[0].stripped.contains("help"))
    }

    @Test("TStatusBar with explicit items array")
    func statusBarExplicitItems() {
        let items: [any TStatusBarItemProtocol] = [
            TStatusBarItem(shortcut: "1", label: "one"),
            TStatusBarItem(shortcut: "2", label: "two")
        ]
        let statusBar = TStatusBar(items: items, style: .compact)

        #expect(statusBar.items.count == 2)
    }
}

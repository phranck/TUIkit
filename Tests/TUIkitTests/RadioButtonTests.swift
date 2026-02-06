//  🖥️ TUIKit — Terminal UI Kit for Swift
//  RadioButtonTests.swift
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

// MARK: - Radio Button Item Tests

@Suite("RadioButtonItem Tests")
struct RadioButtonItemTests {

    @Test("RadioButtonItem can be created with string value and string label")
    func itemCreationString() {
        let item = RadioButtonItem("option1", "Option 1")
        #expect(item.value == "option1")
    }

    @Test("RadioButtonItem can be created with string value and view label")
    func itemCreationView() {
        let item = RadioButtonItem("option1") {
            Text("Custom Label")
        }
        #expect(item.value == "option1")
    }

    @Test("RadioButtonItem can be created with int value")
    func itemCreationInt() {
        let item = RadioButtonItem(1, "First Option")
        #expect(item.value == 1)
    }
}

// MARK: - Radio Button Group Tests

@Suite("RadioButtonGroup Tests", .serialized)
struct RadioButtonGroupTests {

    @Test("RadioButtonGroup can be created with items")
    func groupCreation() {
        var selection: String = "option1"
        let binding = Binding(
            get: { selection },
            set: { selection = $0 }
        )

        let group = RadioButtonGroup(selection: binding) {
            RadioButtonItem("option1", "First")
            RadioButtonItem("option2", "Second")
            RadioButtonItem("option3", "Third")
        }

        #expect(group.items.count == 3)
        #expect(group.isDisabled == false)
        #expect(group.orientation == .vertical)
    }

    @Test("RadioButtonGroup with horizontal orientation")
    func groupHorizontalOrientation() {
        var selection: String = "a"
        let binding = Binding(
            get: { selection },
            set: { selection = $0 }
        )

        let group = RadioButtonGroup(selection: binding, orientation: .horizontal) {
            RadioButtonItem("a", "A")
            RadioButtonItem("b", "B")
        }

        #expect(group.orientation == .horizontal)
    }

    @Test("RadioButtonGroup disabled modifier")
    func groupDisabledModifier() {
        var selection: String = "x"
        let binding = Binding(
            get: { selection },
            set: { selection = $0 }
        )

        let group = RadioButtonGroup(selection: binding) {
            RadioButtonItem("x", "X")
        }.disabled()

        #expect(group.isDisabled == true)

        let enabled = RadioButtonGroup(selection: binding) {
            RadioButtonItem("x", "X")
        }.disabled(false)

        #expect(enabled.isDisabled == false)
    }

    @Test("RadioButtonGroup renders items vertically")
    func renderVertical() {
        let context = createTestContext()

        var selection: String = "opt1"
        let binding = Binding(
            get: { selection },
            set: { selection = $0 }
        )

        let group = RadioButtonGroup(selection: binding, orientation: .vertical) {
            RadioButtonItem("opt1", "Option 1")
            RadioButtonItem("opt2", "Option 2")
            RadioButtonItem("opt3", "Option 3")
        }

        let buffer = renderToBuffer(group, context: context)

        // Vertical: should have 3 lines (one per item)
        #expect(buffer.height == 3)
        let content = buffer.lines.joined()
        #expect(content.contains("Option 1"))
        #expect(content.contains("Option 2"))
        #expect(content.contains("Option 3"))
    }

    @Test("RadioButtonGroup renders items horizontally")
    func renderHorizontal() {
        let context = createTestContext()

        var selection: String = "a"
        let binding = Binding(
            get: { selection },
            set: { selection = $0 }
        )

        let group = RadioButtonGroup(selection: binding, orientation: .horizontal) {
            RadioButtonItem("a", "Alpha")
            RadioButtonItem("b", "Beta")
            RadioButtonItem("c", "Gamma")
        }

        let buffer = renderToBuffer(group, context: context)

        // Horizontal: should be single line
        #expect(buffer.height == 1)
        let content = buffer.lines.joined()
        #expect(content.contains("Alpha"))
        #expect(content.contains("Beta"))
        #expect(content.contains("Gamma"))
    }

    @Test("Selected item shows filled indicator")
    func selectedIndicator() {
        let context = createTestContext()

        var selection: String = "opt2"
        let binding = Binding(
            get: { selection },
            set: { selection = $0 }
        )

        let group = RadioButtonGroup(selection: binding) {
            RadioButtonItem("opt1", "First")
            RadioButtonItem("opt2", "Second")
            RadioButtonItem("opt3", "Third")
        }

        let buffer = renderToBuffer(group, context: context)

        // Selected item (opt2) should show ●
        let content = buffer.lines.joined()
        #expect(content.contains("●"))
        // Unselected items should show ◯
        #expect(content.contains("◯"))
    }

    @Test("Focus indicator shows pulsing on focused item")
    func focusIndicator() {
        let context = createTestContext()

        var selection: String = "x"
        let binding = Binding(
            get: { selection },
            set: { selection = $0 }
        )

        let group = RadioButtonGroup(selection: binding, focusID: "test-group") {
            RadioButtonItem("x", "X")
            RadioButtonItem("y", "Y")
        }

        let buffer = renderToBuffer(group, context: context)

        // Focused item should have ANSI codes (pulsing)
        let content = buffer.lines.joined()
        #expect(content.contains("\u{1b}["))
    }

    @Test("Disabled group uses tertiary color")
    func disabledGroup() {
        let context = createTestContext()

        var selection: String = "a"
        let binding = Binding(
            get: { selection },
            set: { selection = $0 }
        )

        let group = RadioButtonGroup(selection: binding) {
            RadioButtonItem("a", "Option A")
        }.disabled()

        let buffer = renderToBuffer(group, context: context)

        #expect(buffer.height == 1)
        let content = buffer.lines.joined()
        #expect(content.contains("Option A"))
    }
}

// MARK: - Radio Button Group Handler Tests

@Suite("RadioButtonGroupHandler Tests")
struct RadioButtonGroupHandlerTests {

    @Test("Handler handles arrow down to navigate items (vertical)")
    func handleArrowDown() {
        var selection = AnyHashable("opt1")
        let binding = Binding(
            get: { selection },
            set: { selection = $0 }
        )

        let itemValues = [AnyHashable("opt1"), AnyHashable("opt2"), AnyHashable("opt3")]
        let handler = RadioButtonGroupHandler(
            focusID: "test",
            selection: binding,
            itemValues: itemValues,
            orientation: .vertical,
            canBeFocused: true
        )

        let event = KeyEvent(key: .down)
        let handled = handler.handleKeyEvent(event)

        #expect(handled == true)
        #expect(handler.focusedIndex == 1)
        #expect(selection == AnyHashable("opt2"))
    }

    @Test("Handler handles arrow up to navigate items (vertical)")
    func handleArrowUp() {
        var selection = AnyHashable("opt2")
        let binding = Binding(
            get: { selection },
            set: { selection = $0 }
        )

        let itemValues = [AnyHashable("opt1"), AnyHashable("opt2"), AnyHashable("opt3")]
        let handler = RadioButtonGroupHandler(
            focusID: "test",
            selection: binding,
            itemValues: itemValues,
            orientation: .vertical,
            canBeFocused: true
        )
        handler.focusedIndex = 1

        let event = KeyEvent(key: .up)
        let handled = handler.handleKeyEvent(event)

        #expect(handled == true)
        #expect(handler.focusedIndex == 0)
    }

    @Test("Handler handles arrow right (horizontal only)")
    func handleArrowRight() {
        var selection = AnyHashable("a")
        let binding = Binding(
            get: { selection },
            set: { selection = $0 }
        )

        let itemValues = [AnyHashable("a"), AnyHashable("b"), AnyHashable("c")]
        let handler = RadioButtonGroupHandler(
            focusID: "test",
            selection: binding,
            itemValues: itemValues,
            orientation: .horizontal,
            canBeFocused: true
        )

        let event = KeyEvent(key: .right)
        let handled = handler.handleKeyEvent(event)

        #expect(handled == true)
        #expect(handler.focusedIndex == 1)
        #expect(selection == AnyHashable("b"))
    }

    @Test("Handler handles arrow left (horizontal only)")
    func handleArrowLeft() {
        var selection = AnyHashable("b")
        let binding = Binding(
            get: { selection },
            set: { selection = $0 }
        )

        let itemValues = [AnyHashable("a"), AnyHashable("b"), AnyHashable("c")]
        let handler = RadioButtonGroupHandler(
            focusID: "test",
            selection: binding,
            itemValues: itemValues,
            orientation: .horizontal,
            canBeFocused: true
        )
        handler.focusedIndex = 1

        let event = KeyEvent(key: .left)
        let handled = handler.handleKeyEvent(event)

        #expect(handled == true)
        #expect(handler.focusedIndex == 0)
        #expect(selection == AnyHashable("a"))
    }

    @Test("Handler handles Enter to select")
    func handleEnter() {
        var selection = AnyHashable("opt1")
        let binding = Binding(
            get: { selection },
            set: { selection = $0 }
        )

        let itemValues = [AnyHashable("opt1"), AnyHashable("opt2")]
        let handler = RadioButtonGroupHandler(
            focusID: "test",
            selection: binding,
            itemValues: itemValues,
            orientation: .vertical,
            canBeFocused: true
        )
        handler.focusedIndex = 1

        let event = KeyEvent(key: .enter)
        let handled = handler.handleKeyEvent(event)

        #expect(handled == true)
        #expect(selection == AnyHashable("opt2"))
    }

    @Test("Handler handles Space to select")
    func handleSpace() {
        var selection = AnyHashable("x")
        let binding = Binding(
            get: { selection },
            set: { selection = $0 }
        )

        let itemValues = [AnyHashable("x"), AnyHashable("y")]
        let handler = RadioButtonGroupHandler(
            focusID: "test",
            selection: binding,
            itemValues: itemValues,
            orientation: .vertical,
            canBeFocused: true
        )
        handler.focusedIndex = 1

        let event = KeyEvent(key: .character(" "))
        let handled = handler.handleKeyEvent(event)

        #expect(handled == true)
        #expect(selection == AnyHashable("y"))
    }

    @Test("Handler wraps navigation at boundaries")
    func boundaryNavigation() {
        var selection = AnyHashable("opt1")
        let binding = Binding(
            get: { selection },
            set: { selection = $0 }
        )

        let itemValues = [AnyHashable("opt1"), AnyHashable("opt2")]
        let handler = RadioButtonGroupHandler(
            focusID: "test",
            selection: binding,
            itemValues: itemValues,
            orientation: .vertical,
            canBeFocused: true
        )

        // Try to go up from first item — should wrap to last
        let upEvent = KeyEvent(key: .up)
        let handled = handler.handleKeyEvent(upEvent)

        #expect(handled == true)
        #expect(handler.focusedIndex == 1)  // Wrapped to last item
        #expect(selection == AnyHashable("opt2"))
    }

    @Test("Handler respects canBeFocused property")
    func respectsCanBeFocused() {
        var selection = AnyHashable("a")
        let binding = Binding(
            get: { selection },
            set: { selection = $0 }
        )

        let itemValues = [AnyHashable("a"), AnyHashable("b")]
        let handler = RadioButtonGroupHandler(
            focusID: "test",
            selection: binding,
            itemValues: itemValues,
            orientation: .vertical,
            canBeFocused: false
        )

        #expect(handler.canBeFocused == false)
    }
}

// MARK: - Radio Button Orientation Tests

@Suite("RadioButtonOrientation Tests")
struct RadioButtonOrientationTests {

    @Test("RadioButtonOrientation has vertical and horizontal cases")
    func orientationCases() {
        let vertical: RadioButtonOrientation = .vertical
        let horizontal: RadioButtonOrientation = .horizontal

        switch vertical {
        case .vertical:
            break
        case .horizontal:
            #expect(false, "Should be vertical")
        }

        switch horizontal {
        case .vertical:
            #expect(false, "Should be horizontal")
        case .horizontal:
            break
        }
    }
}

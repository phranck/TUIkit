//  🖥️ TUIKit — Terminal UI Kit for Swift
//  RadioButton.swift
//
//  Created by LAYERED.work
//  License: MIT

import Foundation

// MARK: - Radio Button Orientation

/// Defines the layout direction of a radio button group.
public enum RadioButtonOrientation: Sendable {
    /// Items stacked vertically (default).
    case vertical

    /// Items arranged horizontally.
    case horizontal
}

// MARK: - Radio Button Item

/// A single option in a radio button group.
///
/// Contains a value (for selection binding) and a label view.
public struct RadioButtonItem<Value: Hashable> {
    /// The value associated with this option.
    let value: Value

    /// The label view builder.
    let labelBuilder: @MainActor () -> AnyView

    /// Creates a radio button item with a view label.
    ///
    /// - Parameters:
    ///   - value: The value for this option.
    ///   - label: A view builder closure that returns the label.
    @MainActor
    public init<Label: View>(
        _ value: Value,
        @ViewBuilder label: @escaping () -> Label
    ) {
        self.value = value
        self.labelBuilder = { AnyView(label()) }
    }

    /// Creates a radio button item with a string label.
    ///
    /// - Parameters:
    ///   - value: The value for this option.
    ///   - label: The label text.
    @MainActor
    public init(
        _ value: Value,
        _ label: String
    ) {
        self.value = value
        self.labelBuilder = { AnyView(Text(label)) }
    }
}

// MARK: - Radio Button Group Builder

/// Result builder for radio button items.
@resultBuilder
public enum RadioButtonGroupBuilder<Value: Hashable> {
    public static func buildBlock(_ items: RadioButtonItem<Value>...) -> [RadioButtonItem<Value>] {
        Array(items)
    }

    public static func buildOptional(_ items: [RadioButtonItem<Value>]?) -> [RadioButtonItem<Value>] {
        items ?? []
    }

    public static func buildEither(first items: [RadioButtonItem<Value>]) -> [RadioButtonItem<Value>] {
        items
    }

    public static func buildEither(second items: [RadioButtonItem<Value>]) -> [RadioButtonItem<Value>] {
        items
    }

    public static func buildArray(_ itemGroups: [[RadioButtonItem<Value>]]) -> [RadioButtonItem<Value>] {
        itemGroups.flatMap { $0 }
    }
}

// MARK: - Radio Button Group

/// An interactive radio button group for single-selection from multiple options.
///
/// Radio buttons can be arranged vertically or horizontally. Each option is focusable
/// and supports keyboard navigation with arrow keys. Selection can be changed with Enter or Space.
///
/// ## Rendering
///
/// Vertical layout:
/// ```
/// ◯ Option 1
/// ● Option 2  (selected)
/// ◯ Option 3
/// ```
///
/// Horizontal layout:
/// ```
/// ◯ Option 1  ● Option 2  ◯ Option 3
/// ```
///
/// # Basic Example
///
/// ```swift
/// @State var selection: String = "option1"
///
/// RadioButtonGroup(selection: $selection) {
///     RadioButtonItem("option1") { Text("First Choice") }
///     RadioButtonItem("option2") { Text("Second Choice") }
///     RadioButtonItem("option3") { Text("Third Choice") }
/// }
/// ```
public struct RadioButtonGroup<Value: Hashable>: View {
    /// The binding to the selected value.
    let selection: Binding<Value>

    /// The items in the group.
    let items: [RadioButtonItem<Value>]

    /// The layout orientation.
    let orientation: RadioButtonOrientation

    /// The unique focus identifier for the group.
    /// Auto-generated if not provided, but must be stable across renders.
    let focusID: String?

    /// Whether the group is disabled.
    var isDisabled: Bool

    /// Creates a radio button group with items and a selection binding.
    ///
    /// - Parameters:
    ///   - selection: A binding to the selected value.
    ///   - orientation: The layout orientation (default: `.vertical`).
    ///   - focusID: The unique focus identifier (default: auto-generated from identity).
    ///   - isDisabled: Whether the group is disabled (default: false).
    ///   - builder: A builder closure that returns radio button items.
    public init(
        selection: Binding<Value>,
        orientation: RadioButtonOrientation = .vertical,
        focusID: String? = nil,
        isDisabled: Bool = false,
        @RadioButtonGroupBuilder<Value> builder: () -> [RadioButtonItem<Value>]
    ) {
        self.selection = selection
        self.items = builder()
        self.orientation = orientation
        self.focusID = focusID
        self.isDisabled = isDisabled
    }

    public var body: Never {
        fatalError("RadioButtonGroup renders via Renderable")
    }
}

// MARK: - Radio Button Handler

/// Internal handler class for radio button group focus and selection management.
///
/// Persisted across renders via StateStorage to maintain focusedIndex and enable
/// Tab navigation between radio button groups.
final class RadioButtonGroupHandler: Focusable {
    let focusID: String
    var selection: Binding<AnyHashable>
    var itemValues: [AnyHashable]
    let orientation: RadioButtonOrientation
    var canBeFocused: Bool
    
    /// The currently focused item index within the group.
    /// Persisted across renders to maintain focus position.
    var focusedIndex: Int = 0

    init(
        focusID: String,
        selection: Binding<AnyHashable>,
        itemValues: [AnyHashable],
        orientation: RadioButtonOrientation,
        canBeFocused: Bool
    ) {
        self.focusID = focusID
        self.selection = selection
        self.itemValues = itemValues
        self.orientation = orientation
        self.canBeFocused = canBeFocused

        // Find current focused index based on selection
        if let currentIndex = itemValues.firstIndex(of: selection.wrappedValue) {
            self.focusedIndex = currentIndex
        }
    }
}

// MARK: - Focus Lifecycle

extension RadioButtonGroupHandler {
    func onFocusLost() {
        // Reset focusedIndex to the selected item when the group loses focus
        if let selectedIndex = itemValues.firstIndex(of: selection.wrappedValue) {
            focusedIndex = selectedIndex
        }
    }
}

// MARK: - Key Event Handling

extension RadioButtonGroupHandler {
    func handleKeyEvent(_ event: KeyEvent) -> Bool {
        switch event.key {
        case .up:
            // Vertical: navigate focus up (don't change selection); Horizontal: consume but do nothing
            if orientation == .vertical {
                focusedIndex = focusedIndex > 0 ? focusedIndex - 1 : itemValues.count - 1
            }
            return true

        case .down:
            // Vertical: navigate focus down (don't change selection); Horizontal: consume but do nothing
            if orientation == .vertical {
                focusedIndex = focusedIndex < itemValues.count - 1 ? focusedIndex + 1 : 0
            }
            return true

        case .left:
            // Horizontal: navigate focus left (don't change selection); Vertical: consume but do nothing
            if orientation == .horizontal {
                focusedIndex = focusedIndex > 0 ? focusedIndex - 1 : itemValues.count - 1
            }
            return true

        case .right:
            // Horizontal: navigate focus right (don't change selection); Vertical: consume but do nothing
            if orientation == .horizontal {
                focusedIndex = focusedIndex < itemValues.count - 1 ? focusedIndex + 1 : 0
            }
            return true

        case .enter, .character(" "):
            // Select the currently focused item (make it the selection)
            selection.wrappedValue = itemValues[focusedIndex]
            return true

        default:
            return false
        }
    }
}

// MARK: - Radio Button Group Rendering

extension RadioButtonGroup: Renderable {
    func renderToBuffer(context: RenderContext) -> FrameBuffer {
        let focusManager = context.environment.focusManager
        let palette = context.environment.palette
        let stateStorage = context.tuiContext.stateStorage

        // Create type-erased selection binding and item values
        let erasedSelection = Binding<AnyHashable>(
            get: { AnyHashable(selection.wrappedValue) },
            set: { newValue in
                if let typedValue = newValue.base as? Value {
                    selection.wrappedValue = typedValue
                }
            }
        )
        let itemValues = items.map { AnyHashable($0.value) }

        // Get or create persistent focusID from state storage.
        // focusID must be stable across renders for focus state to persist.
        let focusIDKey = StateStorage.StateKey(identity: context.identity, propertyIndex: 1)
        let focusIDBox: StateBox<String> = stateStorage.storage(
            for: focusIDKey,
            default: focusID ?? "radio-group-\(context.identity.path)"
        )
        let persistedFocusID = focusIDBox.value

        // Get or create persistent handler from state storage.
        // The handler maintains focusedIndex across renders, enabling Tab navigation.
        let handlerKey = StateStorage.StateKey(identity: context.identity, propertyIndex: 0)
        let handlerBox: StateBox<RadioButtonGroupHandler> = stateStorage.storage(
            for: handlerKey,
            default: RadioButtonGroupHandler(
                focusID: persistedFocusID,
                selection: erasedSelection,
                itemValues: itemValues,
                orientation: orientation,
                canBeFocused: !isDisabled
            )
        )
        let handler = handlerBox.value
        
        // Keep handler in sync with current values (in case items changed)
        handler.selection = erasedSelection
        handler.itemValues = itemValues
        handler.canBeFocused = !isDisabled
        
        focusManager.register(handler, inSection: context.activeFocusSectionID)
        stateStorage.markActive(context.identity)

        // Check if this group has focus (after registering, so isFocused works correctly)
        let groupHasFocus = focusManager.isFocused(id: persistedFocusID)

        // Render items based on orientation
        let lines: [String]
        switch orientation {
        case .vertical:
            lines = renderVertical(context: context, handler: handler, groupHasFocus: groupHasFocus, palette: palette)
        case .horizontal:
            lines = renderHorizontal(context: context, handler: handler, groupHasFocus: groupHasFocus, palette: palette)
        }

        return FrameBuffer(lines: lines)
    }

    private func renderVertical(
        context: RenderContext,
        handler: RadioButtonGroupHandler,
        groupHasFocus: Bool,
        palette: Palette
    ) -> [String] {
        items.enumerated().map { index, item in
            renderRadioButton(
                index: index,
                item: item,
                isFocused: handler.focusedIndex == index && groupHasFocus,
                groupHasFocus: groupHasFocus,
                isSelected: selection.wrappedValue == item.value,
                context: context,
                palette: palette
            )
        }
    }

    private func renderHorizontal(
        context: RenderContext,
        handler: RadioButtonGroupHandler,
        groupHasFocus: Bool,
        palette: Palette
    ) -> [String] {
        let itemLines = items.enumerated().map { index, item in
            renderRadioButton(
                index: index,
                item: item,
                isFocused: handler.focusedIndex == index && groupHasFocus,
                groupHasFocus: groupHasFocus,
                isSelected: selection.wrappedValue == item.value,
                context: context,
                palette: palette
            )
        }

        // Join horizontally with spacing
        let spacing = "  "
        return [itemLines.joined(separator: spacing)]
    }

    private func renderRadioButton(
        index: Int,
        item: RadioButtonItem<Value>,
        isFocused: Bool,
        groupHasFocus: Bool,
        isSelected: Bool,
        context: RenderContext,
        palette: Palette
    ) -> String {
        // Radio indicator: ● if selected OR focused, ◯ if neither
        let indicator = (isSelected || isFocused) ? "●" : "◯"

        // Determine indicator color based on state
        let indicatorColor: Color
        if isDisabled {
            indicatorColor = palette.foregroundTertiary
        } else if isSelected {
            // Selected: accent color, pulses if group has focus
            if groupHasFocus {
                let dimAccent = palette.accent.opacity(0.35)
                indicatorColor = Color.lerp(dimAccent, palette.accent, phase: context.pulsePhase)
            } else {
                indicatorColor = palette.accent
            }
        } else if isFocused {
            // Focused but not selected: dimmed accent (static, no pulse)
            indicatorColor = palette.accent.opacity(0.5)
        } else {
            // Unselected and unfocused: tertiary (dimmed)
            indicatorColor = palette.foregroundTertiary
        }

        let styledIndicator = ANSIRenderer.colorize(indicator, foreground: indicatorColor)

        // Render label with theme color
        let labelView = item.labelBuilder()
        let labelBuffer = labelView.renderToBuffer(context: context)
        let labelText = labelBuffer.lines.first ?? ""

        // Combine: indicator + label
        return styledIndicator + " " + labelText
    }
}

// MARK: - Radio Button Group Convenience Modifiers

extension RadioButtonGroup {
    /// Creates a disabled version of this radio button group.
    ///
    /// - Parameter disabled: Whether the group is disabled.
    /// - Returns: A new group with the disabled state.
    public func disabled(_ disabled: Bool = true) -> RadioButtonGroup<Value> {
        var newGroup = self
        newGroup.isDisabled = disabled
        return newGroup
    }
}

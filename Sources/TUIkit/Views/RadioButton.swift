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

/// A result builder that constructs arrays of radio button items for use in ``RadioButtonGroup``.
///
/// `RadioButtonGroupBuilder` enables the declarative syntax for defining multiple
/// options within a ``RadioButtonGroup``. You don't use this type directly; instead,
/// the `@RadioButtonGroupBuilder` attribute is applied to the trailing closure of
/// ``RadioButtonGroup/init(selection:orientation:isDisabled:builder:)``.
///
/// ## Overview
///
/// When you write:
///
/// ```swift
/// RadioButtonGroup(selection: $choice) {
///     RadioButtonItem(.option1, "First Option")
///     RadioButtonItem(.option2, "Second Option")
///     RadioButtonItem(.option3, "Third Option")
/// }
/// ```
///
/// The `@RadioButtonGroupBuilder` attribute transforms this closure into an array
/// of ``RadioButtonItem`` instances that the group can render and manage.
///
/// ## Supported Control Flow
///
/// The builder supports:
/// - Multiple item expressions
/// - `if`/`else` conditionals
/// - `if let` optional binding
/// - `for`...`in` loops
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
    var focusID: String?

    /// Whether the group is disabled.
    var isDisabled: Bool

    /// Creates a radio button group with items and a selection binding.
    ///
    /// - Parameters:
    ///   - selection: A binding to the selected value.
    ///   - orientation: The layout orientation (default: `.vertical`).
    ///   - isDisabled: Whether the group is disabled (default: false).
    ///   - builder: A builder closure that returns radio button items.
    public init(
        selection: Binding<Value>,
        orientation: RadioButtonOrientation = .vertical,
        isDisabled: Bool = false,
        @RadioButtonGroupBuilder<Value> builder: () -> [RadioButtonItem<Value>]
    ) {
        self.selection = selection
        self.items = builder()
        self.orientation = orientation
        self.focusID = nil
        self.isDisabled = isDisabled
    }

    public var body: some View {
        _RadioButtonGroupCore(
            selection: selection,
            items: items,
            orientation: orientation,
            focusID: focusID,
            isDisabled: isDisabled
        )
    }
}

// MARK: - Internal Core View

/// Internal view that handles the actual rendering of RadioButtonGroup.
private struct _RadioButtonGroupCore<Value: Hashable>: View, Renderable {
    let selection: Binding<Value>
    let items: [RadioButtonItem<Value>]
    let orientation: RadioButtonOrientation
    let focusID: String?
    let isDisabled: Bool

    var body: Never {
        fatalError("_RadioButtonGroupCore renders via Renderable")
    }

    func renderToBuffer(context: RenderContext) -> FrameBuffer {
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

        let persistedFocusID = FocusRegistration.persistFocusID(
            context: context,
            explicitFocusID: focusID,
            defaultPrefix: "radio-group",
            propertyIndex: 1  // focusID
        )

        // Get or create persistent handler from state storage.
        // The handler maintains focusedIndex across renders, enabling Tab navigation.
        let handlerKey = StateStorage.StateKey(identity: context.identity, propertyIndex: 0)  // handler
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

        FocusRegistration.register(context: context, handler: handler)
        let groupHasFocus = FocusRegistration.isFocused(context: context, focusID: persistedFocusID)

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
        let indicator = (isSelected || isFocused) ? TerminalSymbols.radioSelected : TerminalSymbols.radioUnselected

        // Determine indicator color based on state
        let indicatorColor: Color
        if isDisabled {
            indicatorColor = palette.foregroundTertiary.opacity(ViewConstants.disabledForeground)
        } else if isFocused {
            // Focused: pulsing accent (whether selected or not)
            let dimAccent = palette.accent.opacity(ViewConstants.focusPulseMin)
            indicatorColor = Color.lerp(dimAccent, palette.accent, phase: context.pulsePhase)
        } else if isSelected {
            // Selected but not focused: solid accent
            indicatorColor = palette.accent
        } else {
            // Unselected and unfocused: dimmed
            indicatorColor = palette.foregroundTertiary.opacity(ViewConstants.disabledForeground)
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

    /// Sets a custom focus identifier for this radio button group.
    ///
    /// - Parameter id: The unique focus identifier.
    /// - Returns: A group with the specified focus identifier.
    public func focusID(_ id: String) -> RadioButtonGroup<Value> {
        var copy = self
        copy.focusID = id
        return copy
    }
}

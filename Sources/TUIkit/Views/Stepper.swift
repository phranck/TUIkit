//  TUIKit - Terminal UI Kit for Swift
//  Stepper.swift
//
//  Created by LAYERED.work
//  License: MIT

// MARK: - Stepper

/// A control that performs increment and decrement actions.
///
/// A stepper displays a value with left and right arrows that the user
/// can use to increment or decrement the value using keyboard controls.
///
/// ## Rendering
///
/// ```
/// Unfocused:    ◀  5  ▶
/// Focused:    ❙ ◀  5  ▶ ❙    (bars + arrows pulsing in accent)
/// ```
///
/// ## Keyboard Controls
///
/// | Key | Action |
/// |-----|--------|
/// | `->` or `+` | Increment by step |
/// | `<-` or `-` | Decrement by step |
/// | `Home` | Jump to minimum (if range defined) |
/// | `End` | Jump to maximum (if range defined) |
///
/// ## Basic Example
///
/// ```swift
/// @State var quantity: Int = 1
///
/// Stepper("Quantity", value: $quantity)
/// ```
///
/// ## With Range and Step
///
/// ```swift
/// @State var rating: Int = 3
///
/// Stepper("Rating", value: $rating, in: 1...5, step: 1)
/// ```
///
/// ## With Custom Callbacks
///
/// ```swift
/// Stepper("Color") {
///     nextColor()
/// } onDecrement: {
///     previousColor()
/// }
/// ```
public struct Stepper<Label: View>: View {
    /// The binding to the current value.
    let value: Binding<Int>

    /// The optional range of valid values.
    let bounds: ClosedRange<Int>?

    /// The step size for increment/decrement.
    let step: Int

    /// The label view describing the stepper's purpose.
    let label: Label?

    /// Custom increment callback.
    let onIncrement: (() -> Void)?

    /// Custom decrement callback.
    let onDecrement: (() -> Void)?

    /// The unique focus identifier.
    var focusID: String?

    /// Whether the stepper is disabled.
    var isDisabled: Bool

    /// Callback when editing begins or ends.
    let onEditingChanged: ((Bool) -> Void)?

    public var body: some View {
        _StepperCore(
            value: value,
            bounds: bounds,
            step: step,
            label: label,
            onIncrement: onIncrement,
            onDecrement: onDecrement,
            focusID: focusID,
            isDisabled: isDisabled,
            onEditingChanged: onEditingChanged
        )
    }
}

// MARK: - Stepper Initializers (Value Binding)

extension Stepper where Label == Text {
    /// Creates a stepper with a title and value binding.
    ///
    /// - Parameters:
    ///   - title: The title of the stepper.
    ///   - value: The binding to the current value.
    ///   - step: The step size. Defaults to `1`.
    ///   - onEditingChanged: A callback for when editing begins and ends.
    public init<S: StringProtocol>(
        _ title: S,
        value: Binding<Int>,
        step: Int = 1,
        onEditingChanged: @escaping (Bool) -> Void = { _ in }
    ) {
        self.value = value
        self.bounds = nil
        self.step = step
        self.label = Text(String(title))
        self.onIncrement = nil
        self.onDecrement = nil
        // Auto-generated focusID from view identity (collision-free)
        self.focusID = nil
        self.isDisabled = false
        self.onEditingChanged = onEditingChanged
    }

    /// Creates a stepper with a title, value binding, and range.
    ///
    /// - Parameters:
    ///   - title: The title of the stepper.
    ///   - value: The binding to the current value.
    ///   - bounds: The range of valid values.
    ///   - step: The step size. Defaults to `1`.
    ///   - onEditingChanged: A callback for when editing begins and ends.
    public init<S: StringProtocol>(
        _ title: S,
        value: Binding<Int>,
        in bounds: ClosedRange<Int>,
        step: Int = 1,
        onEditingChanged: @escaping (Bool) -> Void = { _ in }
    ) {
        self.value = value
        self.bounds = bounds
        self.step = step
        self.label = Text(String(title))
        self.onIncrement = nil
        self.onDecrement = nil
        // Auto-generated focusID from view identity (collision-free)
        self.focusID = nil
        self.isDisabled = false
        self.onEditingChanged = onEditingChanged
    }
}

// MARK: - Stepper Initializers (Custom Callbacks)

extension Stepper where Label == Text {
    /// Creates a stepper with a title and custom increment/decrement callbacks.
    ///
    /// - Parameters:
    ///   - title: The title of the stepper.
    ///   - onIncrement: Callback when increment is requested.
    ///   - onDecrement: Callback when decrement is requested.
    ///   - onEditingChanged: A callback for when editing begins and ends.
    public init<S: StringProtocol>(
        _ title: S,
        onIncrement: (() -> Void)?,
        onDecrement: (() -> Void)?,
        onEditingChanged: @escaping (Bool) -> Void = { _ in }
    ) {
        var dummy = 0
        self.value = Binding(get: { dummy }, set: { dummy = $0 })
        self.bounds = nil
        self.step = 1
        self.label = Text(String(title))
        self.onIncrement = onIncrement
        self.onDecrement = onDecrement
        // Auto-generated focusID from view identity (collision-free)
        self.focusID = nil
        self.isDisabled = false
        self.onEditingChanged = onEditingChanged
    }
}

// MARK: - Stepper Initializers (ViewBuilder Label)

extension Stepper {
    /// Creates a stepper with a custom label and value binding.
    ///
    /// - Parameters:
    ///   - value: The binding to the current value.
    ///   - step: The step size. Defaults to `1`.
    ///   - label: A view describing the purpose of the stepper.
    ///   - onEditingChanged: A callback for when editing begins and ends.
    public init(
        value: Binding<Int>,
        step: Int = 1,
        @ViewBuilder label: () -> Label,
        onEditingChanged: @escaping (Bool) -> Void = { _ in }
    ) {
        self.value = value
        self.bounds = nil
        self.step = step
        self.label = label()
        self.onIncrement = nil
        self.onDecrement = nil
        self.focusID = nil
        self.isDisabled = false
        self.onEditingChanged = onEditingChanged
    }

    /// Creates a stepper with a custom label, value binding, and range.
    ///
    /// - Parameters:
    ///   - value: The binding to the current value.
    ///   - bounds: The range of valid values.
    ///   - step: The step size. Defaults to `1`.
    ///   - label: A view describing the purpose of the stepper.
    ///   - onEditingChanged: A callback for when editing begins and ends.
    public init(
        value: Binding<Int>,
        in bounds: ClosedRange<Int>,
        step: Int = 1,
        @ViewBuilder label: () -> Label,
        onEditingChanged: @escaping (Bool) -> Void = { _ in }
    ) {
        self.value = value
        self.bounds = bounds
        self.step = step
        self.label = label()
        self.onIncrement = nil
        self.onDecrement = nil
        self.focusID = nil
        self.isDisabled = false
        self.onEditingChanged = onEditingChanged
    }

    /// Creates a stepper with a custom label and increment/decrement callbacks.
    ///
    /// - Parameters:
    ///   - label: A view describing the purpose of the stepper.
    ///   - onIncrement: Callback when increment is requested.
    ///   - onDecrement: Callback when decrement is requested.
    ///   - onEditingChanged: A callback for when editing begins and ends.
    public init(
        @ViewBuilder label: () -> Label,
        onIncrement: (() -> Void)?,
        onDecrement: (() -> Void)?,
        onEditingChanged: @escaping (Bool) -> Void = { _ in }
    ) {
        var dummy = 0
        self.value = Binding(get: { dummy }, set: { dummy = $0 })
        self.bounds = nil
        self.step = 1
        self.label = label()
        self.onIncrement = onIncrement
        self.onDecrement = onDecrement
        self.focusID = nil
        self.isDisabled = false
        self.onEditingChanged = onEditingChanged
    }
}

// MARK: - Stepper Modifiers

extension Stepper {
    /// Creates a disabled version of this stepper.
    ///
    /// - Parameter disabled: Whether the stepper is disabled.
    /// - Returns: A new stepper with the disabled state.
    public func disabled(_ disabled: Bool = true) -> Stepper {
        var copy = self
        copy.isDisabled = disabled
        return copy
    }

    /// Sets a custom focus identifier for this stepper.
    ///
    /// - Parameter id: The unique focus identifier.
    /// - Returns: A stepper with the specified focus identifier.
    public func focusID(_ id: String) -> Stepper {
        var copy = self
        copy.focusID = id
        return copy
    }
}

// MARK: - Internal Core View

/// Internal view that handles the actual rendering of Stepper.
private struct _StepperCore<Label: View>: View, Renderable {
    let value: Binding<Int>
    let bounds: ClosedRange<Int>?
    let step: Int
    let label: Label?
    let onIncrement: (() -> Void)?
    let onDecrement: (() -> Void)?
    let focusID: String?
    let isDisabled: Bool
    let onEditingChanged: ((Bool) -> Void)?

    var body: Never {
        fatalError("_StepperCore renders via Renderable")
    }

    func renderToBuffer(context: RenderContext) -> FrameBuffer {
        let stateStorage = context.environment.stateStorage!
        let palette = context.environment.palette

        let persistedFocusID = FocusRegistration.persistFocusID(
            context: context,
            explicitFocusID: focusID,
            defaultPrefix: "stepper",
            propertyIndex: 1  // focusID
        )

        // Get or create persistent handler from state storage
        let handlerKey = StateStorage.StateKey(identity: context.identity, propertyIndex: 0)  // handler
        let handlerBox: StateBox<StepperHandler<Int>> = stateStorage.storage(
            for: handlerKey,
            default: StepperHandler(
                focusID: persistedFocusID,
                value: value,
                bounds: bounds,
                step: step,
                canBeFocused: !isDisabled
            )
        )
        let handler = handlerBox.value

        // Keep handler in sync with current values
        handler.value = value
        handler.canBeFocused = !isDisabled
        handler.onIncrement = onIncrement
        handler.onDecrement = onDecrement
        handler.onEditingChanged = onEditingChanged
        handler.clampValue()

        FocusRegistration.register(context: context, handler: handler)
        let isFocused = FocusRegistration.isFocused(context: context, focusID: persistedFocusID)

        // Build the stepper content
        let content = buildContent(
            isFocused: isFocused,
            palette: palette,
            pulsePhase: context.environment.pulsePhase
        )

        return FrameBuffer(text: content)
    }

    /// Builds the rendered stepper content.
    private func buildContent(
        isFocused: Bool,
        palette: any Palette,
        pulsePhase: Double
    ) -> String {
        // Arrow and value colors: pulsing accent when focused, dimmed when unfocused
        let arrowColor: Color
        let valueColor: Color
        if isDisabled {
            arrowColor = palette.foregroundTertiary.opacity(ViewConstants.disabledForeground)
            valueColor = palette.foregroundTertiary
        } else if isFocused {
            // Pulse between 35% and 100% accent
            let dimAccent = palette.accent.opacity(ViewConstants.focusPulseMin)
            arrowColor = Color.lerp(dimAccent, palette.accent, phase: pulsePhase)
            valueColor = palette.foreground
        } else {
            // Dimmed arrows when unfocused
            arrowColor = palette.foregroundTertiary.opacity(ViewConstants.disabledForeground)
            valueColor = palette.foregroundSecondary
        }

        // Build arrows
        let leftArrow = ANSIRenderer.colorize(TerminalSymbols.leftArrow, foreground: arrowColor)
        let rightArrow = ANSIRenderer.colorize(TerminalSymbols.rightArrow, foreground: arrowColor)

        // Build value display
        let valueText = ANSIRenderer.colorize(" \(value.wrappedValue) ", foreground: valueColor)

        // Pulsing arrows indicate focus - no extra markers needed
        return "\(leftArrow)\(valueText)\(rightArrow)"
    }
}

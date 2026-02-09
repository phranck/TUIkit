//  TUIKit - Terminal UI Kit for Swift
//  SliderHandler.swift
//
//  Created by LAYERED.work
//  License: MIT

/// A focus handler for slider components.
///
/// `SliderHandler` manages value changes and keyboard input for `Slider`.
/// It handles:
/// - Increment/decrement via arrow keys or +/-
/// - Jump to min/max via Home/End
/// - Clamping values to the defined range
///
/// ## Keyboard Controls
///
/// | Key | Action |
/// |-----|--------|
/// | `→` or `+` | Increment by step |
/// | `←` or `-` | Decrement by step |
/// | `Home` | Jump to minimum |
/// | `End` | Jump to maximum |
final class SliderHandler<V: BinaryFloatingPoint>: Focusable where V.Stride: BinaryFloatingPoint {
    /// The unique identifier for this focusable element.
    let focusID: String

    /// The binding to the current value.
    var value: Binding<V>

    /// The range of valid values.
    let bounds: ClosedRange<V>

    /// The step size for increment/decrement.
    let step: V.Stride

    /// Whether this element can currently receive focus.
    var canBeFocused: Bool

    /// Callback triggered when editing begins or ends.
    var onEditingChanged: ((Bool) -> Void)?

    /// Whether the slider is currently being edited.
    private var isEditing = false

    /// Creates a slider handler.
    ///
    /// - Parameters:
    ///   - focusID: The unique focus identifier.
    ///   - value: The binding to the current value.
    ///   - bounds: The range of valid values.
    ///   - step: The step size for changes.
    ///   - canBeFocused: Whether this element can receive focus. Defaults to `true`.
    init(
        focusID: String,
        value: Binding<V>,
        bounds: ClosedRange<V>,
        step: V.Stride,
        canBeFocused: Bool = true
    ) {
        self.focusID = focusID
        self.value = value
        self.bounds = bounds
        self.step = step
        self.canBeFocused = canBeFocused
    }
}

// MARK: - Key Event Handling

extension SliderHandler {
    func handleKeyEvent(_ event: KeyEvent) -> Bool {
        switch event.key {
        case .right, .character("+"), .character("="):
            beginEditingIfNeeded()
            increment()
            return true

        case .left, .character("-"), .character("_"):
            beginEditingIfNeeded()
            decrement()
            return true

        case .home:
            beginEditingIfNeeded()
            jumpToMinimum()
            return true

        case .end:
            beginEditingIfNeeded()
            jumpToMaximum()
            return true

        default:
            return false
        }
    }
}

// MARK: - Value Manipulation

extension SliderHandler {
    /// Increments the value by the step size.
    func increment() {
        let newValue = value.wrappedValue + V(step)
        value.wrappedValue = min(bounds.upperBound, newValue)
    }

    /// Decrements the value by the step size.
    func decrement() {
        let newValue = value.wrappedValue - V(step)
        value.wrappedValue = max(bounds.lowerBound, newValue)
    }

    /// Jumps to the minimum value.
    func jumpToMinimum() {
        value.wrappedValue = bounds.lowerBound
    }

    /// Jumps to the maximum value.
    func jumpToMaximum() {
        value.wrappedValue = bounds.upperBound
    }

    /// Clamps the current value to the bounds.
    func clampValue() {
        let clamped = max(bounds.lowerBound, min(bounds.upperBound, value.wrappedValue))
        if clamped != value.wrappedValue {
            value.wrappedValue = clamped
        }
    }
}

// MARK: - Editing State

extension SliderHandler {
    /// Begins editing if not already editing.
    private func beginEditingIfNeeded() {
        guard !isEditing else { return }
        isEditing = true
        onEditingChanged?(true)
    }

    /// Ends editing if currently editing.
    private func endEditingIfNeeded() {
        guard isEditing else { return }
        isEditing = false
        onEditingChanged?(false)
    }
}

// MARK: - Focus Lifecycle

extension SliderHandler {
    func onFocusReceived() {
        clampValue()
    }

    func onFocusLost() {
        endEditingIfNeeded()
    }
}

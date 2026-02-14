//  🖥️ TUIKit — Terminal UI Kit for Swift
//  StepperHandler.swift
//
//  Created by LAYERED.work
//  License: MIT

/// A focus handler for stepper components.
///
/// `StepperHandler` manages value changes and keyboard input for `Stepper`.
/// It handles:
/// - Increment/decrement via arrow keys or +/-
/// - Jump to min/max via Home/End (when bounds are defined)
/// - Clamping values to the defined range
///
/// ## Keyboard Controls
///
/// | Key | Action |
/// |-----|--------|
/// | `->` or `+` | Increment by step |
/// | `<-` or `-` | Decrement by step |
/// | `Home` | Jump to minimum (if bounds defined) |
/// | `End` | Jump to maximum (if bounds defined) |
final class StepperHandler<V: Strideable>: Focusable where V.Stride: SignedNumeric {
    /// The unique identifier for this focusable element.
    let focusID: String

    /// The binding to the current value.
    var value: Binding<V>

    /// The optional range of valid values.
    let bounds: ClosedRange<V>?

    /// The step size for increment/decrement.
    let step: V.Stride

    /// Whether this element can currently receive focus.
    var canBeFocused: Bool

    /// Callback triggered when increment is requested.
    var onIncrement: (() -> Void)?

    /// Callback triggered when decrement is requested.
    var onDecrement: (() -> Void)?

    /// Callback triggered when editing begins or ends.
    var onEditingChanged: ((Bool) -> Void)?

    /// Whether the stepper is currently being edited.
    private var isEditing = false

    /// Creates a stepper handler with a value binding.
    ///
    /// - Parameters:
    ///   - focusID: The unique focus identifier.
    ///   - value: The binding to the current value.
    ///   - bounds: The optional range of valid values.
    ///   - step: The step size for changes.
    ///   - canBeFocused: Whether this element can receive focus. Defaults to `true`.
    init(
        focusID: String,
        value: Binding<V>,
        bounds: ClosedRange<V>? = nil,
        step: V.Stride,
        canBeFocused: Bool = true
    ) {
        self.focusID = focusID
        self.value = value
        self.bounds = bounds
        self.step = step
        self.canBeFocused = canBeFocused
    }

    /// Creates a stepper handler with custom increment/decrement callbacks.
    ///
    /// - Parameters:
    ///   - focusID: The unique focus identifier.
    ///   - onIncrement: Callback when increment is requested.
    ///   - onDecrement: Callback when decrement is requested.
    ///   - canBeFocused: Whether this element can receive focus. Defaults to `true`.
    init(
        focusID: String,
        onIncrement: (() -> Void)?,
        onDecrement: (() -> Void)?,
        canBeFocused: Bool = true
    ) where V: ExpressibleByIntegerLiteral, V.Stride: ExpressibleByIntegerLiteral {
        self.focusID = focusID
        // Create a dummy binding that does nothing
        var dummy: V? = nil
        self.value = Binding(
            get: { dummy ?? 0 },
            set: { dummy = $0 }
        )
        self.bounds = nil
        self.step = 1
        self.canBeFocused = canBeFocused
        self.onIncrement = onIncrement
        self.onDecrement = onDecrement
    }
}

// MARK: - Key Event Handling

extension StepperHandler {
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
            if bounds != nil {
                beginEditingIfNeeded()
                jumpToMinimum()
                return true
            }
            return false

        case .end:
            if bounds != nil {
                beginEditingIfNeeded()
                jumpToMaximum()
                return true
            }
            return false

        default:
            return false
        }
    }
}

// MARK: - Value Manipulation

extension StepperHandler {
    /// Increments the value by the step size.
    func increment() {
        if let onIncrement {
            onIncrement()
        } else {
            let newValue = value.wrappedValue.advanced(by: step)
            if let bounds {
                value.wrappedValue = min(bounds.upperBound, newValue)
            } else {
                value.wrappedValue = newValue
            }
        }
    }

    /// Decrements the value by the step size.
    func decrement() {
        if let onDecrement {
            onDecrement()
        } else {
            // For Strideable, we need to negate the step
            let negativeStep = V.Stride.zero - step
            let newValue = value.wrappedValue.advanced(by: negativeStep)
            if let bounds {
                value.wrappedValue = max(bounds.lowerBound, newValue)
            } else {
                value.wrappedValue = newValue
            }
        }
    }

    /// Jumps to the minimum value.
    func jumpToMinimum() {
        guard let bounds else { return }
        value.wrappedValue = bounds.lowerBound
    }

    /// Jumps to the maximum value.
    func jumpToMaximum() {
        guard let bounds else { return }
        value.wrappedValue = bounds.upperBound
    }

    /// Clamps the current value to the bounds.
    func clampValue() {
        guard let bounds else { return }
        if value.wrappedValue < bounds.lowerBound {
            value.wrappedValue = bounds.lowerBound
        } else if value.wrappedValue > bounds.upperBound {
            value.wrappedValue = bounds.upperBound
        }
    }
}

// MARK: - Editing State

extension StepperHandler {
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

extension StepperHandler {
    func onFocusReceived() {
        clampValue()
    }

    func onFocusLost() {
        endEditingIfNeeded()
    }
}

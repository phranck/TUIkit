//  TUIKit - Terminal UI Kit for Swift
//  Slider.swift
//
//  Created by LAYERED.work
//  License: MIT

import Foundation

// MARK: - Slider

/// A control for selecting a value from a bounded linear range of values.
///
/// A slider displays a visual track that the user can adjust using keyboard
/// controls. The track shows the current position within the range.
///
/// ## Rendering
///
/// ```
/// Unfocused:    ◀ ████████████░░░░░░░░ ▶  50%
/// Focused:    ❙ ◀ ████████████░░░░░░░░ ▶ ❙ 50%
/// ```
///
/// ## Keyboard Controls
///
/// | Key | Action |
/// |-----|--------|
/// | `→` or `+` | Increment by step |
/// | `←` or `-` | Decrement by step |
/// | `Home` | Jump to minimum |
/// | `End` | Jump to maximum |
///
/// ## Basic Example
///
/// ```swift
/// @State var volume: Double = 0.5
///
/// Slider(value: $volume)
/// ```
///
/// ## With Range and Step
///
/// ```swift
/// @State var brightness: Double = 50
///
/// Slider(value: $brightness, in: 0...100, step: 5)
/// ```
///
/// ## With Title
///
/// ```swift
/// Slider("Volume", value: $volume, in: 0...1)
/// ```
///
/// ## With Editing Callback
///
/// ```swift
/// Slider(value: $volume, in: 0...1) { isEditing in
///     print("Editing: \(isEditing)")
/// }
/// ```
public struct Slider<Label: View, ValueLabel: View>: View {
    /// The binding to the current value.
    let value: Binding<Double>

    /// The range of valid values.
    let bounds: ClosedRange<Double>

    /// The step size for increment/decrement.
    let step: Double

    /// The label view describing the slider's purpose.
    let label: Label?

    /// The value label showing the current value.
    let valueLabel: ValueLabel?

    /// The visual style of the track.
    var trackStyle: TrackStyle

    /// The unique focus identifier.
    let focusID: String

    /// Whether the slider is disabled.
    let isDisabled: Bool

    /// Callback when editing begins or ends.
    let onEditingChanged: ((Bool) -> Void)?

    /// Default track width when no explicit frame is set.
    private static var defaultTrackWidth: Int { 20 }

    public var body: some View {
        _SliderCore(
            value: value,
            bounds: bounds,
            step: step,
            label: label,
            valueLabel: valueLabel,
            trackStyle: trackStyle,
            focusID: focusID,
            isDisabled: isDisabled,
            onEditingChanged: onEditingChanged
        )
    }
}

// MARK: - Slider Initializers (No Label)

extension Slider where Label == EmptyView, ValueLabel == EmptyView {
    /// Creates a slider to select a value from a given range.
    ///
    /// - Parameters:
    ///   - value: The selected value within `bounds`.
    ///   - bounds: The range of valid values. Defaults to `0...1`.
    ///   - step: The distance between each valid value. Defaults to `0.01`.
    ///   - onEditingChanged: A callback for when editing begins and ends.
    public init<V: BinaryFloatingPoint>(
        value: Binding<V>,
        in bounds: ClosedRange<V> = 0...1,
        step: V.Stride = 0.01,
        onEditingChanged: @escaping (Bool) -> Void = { _ in }
    ) where V.Stride: BinaryFloatingPoint {
        self.value = Binding(
            get: { Double(value.wrappedValue) },
            set: { value.wrappedValue = V($0) }
        )
        self.bounds = Double(bounds.lowerBound)...Double(bounds.upperBound)
        self.step = Double(step)
        self.label = nil
        self.valueLabel = nil
        self.trackStyle = .block
        self.focusID = "slider-\(UUID().uuidString)"
        self.isDisabled = false
        self.onEditingChanged = onEditingChanged
    }
}

// MARK: - Slider Initializers (String Title)

extension Slider where Label == Text, ValueLabel == EmptyView {
    /// Creates a slider with a title string.
    ///
    /// - Parameters:
    ///   - title: The title of the slider.
    ///   - value: The selected value within `bounds`.
    ///   - bounds: The range of valid values. Defaults to `0...1`.
    ///   - step: The distance between each valid value. Defaults to `0.01`.
    ///   - onEditingChanged: A callback for when editing begins and ends.
    public init<S: StringProtocol, V: BinaryFloatingPoint>(
        _ title: S,
        value: Binding<V>,
        in bounds: ClosedRange<V> = 0...1,
        step: V.Stride = 0.01,
        onEditingChanged: @escaping (Bool) -> Void = { _ in }
    ) where V.Stride: BinaryFloatingPoint {
        self.value = Binding(
            get: { Double(value.wrappedValue) },
            set: { value.wrappedValue = V($0) }
        )
        self.bounds = Double(bounds.lowerBound)...Double(bounds.upperBound)
        self.step = Double(step)
        self.label = Text(String(title))
        self.valueLabel = nil
        self.trackStyle = .block
        self.focusID = "slider-\(title)"
        self.isDisabled = false
        self.onEditingChanged = onEditingChanged
    }
}

// MARK: - Slider Initializers (ViewBuilder Label)

extension Slider where ValueLabel == EmptyView {
    /// Creates a slider with a custom label.
    ///
    /// - Parameters:
    ///   - value: The selected value within `bounds`.
    ///   - bounds: The range of valid values. Defaults to `0...1`.
    ///   - step: The distance between each valid value. Defaults to `0.01`.
    ///   - label: A view describing the purpose of the slider.
    ///   - onEditingChanged: A callback for when editing begins and ends.
    public init<V: BinaryFloatingPoint>(
        value: Binding<V>,
        in bounds: ClosedRange<V> = 0...1,
        step: V.Stride = 0.01,
        @ViewBuilder label: () -> Label,
        onEditingChanged: @escaping (Bool) -> Void = { _ in }
    ) where V.Stride: BinaryFloatingPoint {
        self.value = Binding(
            get: { Double(value.wrappedValue) },
            set: { value.wrappedValue = V($0) }
        )
        self.bounds = Double(bounds.lowerBound)...Double(bounds.upperBound)
        self.step = Double(step)
        self.label = label()
        self.valueLabel = nil
        self.trackStyle = .block
        self.focusID = "slider-\(UUID().uuidString)"
        self.isDisabled = false
        self.onEditingChanged = onEditingChanged
    }
}

// MARK: - Slider Modifiers

extension Slider {
    /// Sets the visual style of the slider track.
    ///
    /// ```swift
    /// Slider(value: $volume)
    ///     .trackStyle(.dot)
    /// ```
    ///
    /// - Parameter style: The track style.
    /// - Returns: A slider with the specified track style.
    public func trackStyle(_ style: TrackStyle) -> Slider {
        var copy = self
        copy.trackStyle = style
        return copy
    }

    /// Creates a disabled version of this slider.
    ///
    /// - Parameter disabled: Whether the slider is disabled.
    /// - Returns: A new slider with the disabled state.
    public func disabled(_ disabled: Bool = true) -> Slider {
        Slider(
            value: value,
            bounds: bounds,
            step: step,
            label: label,
            valueLabel: valueLabel,
            trackStyle: trackStyle,
            focusID: focusID,
            isDisabled: disabled,
            onEditingChanged: onEditingChanged
        )
    }
}

// MARK: - Internal Core View

/// Internal view that handles the actual rendering of Slider.
private struct _SliderCore<Label: View, ValueLabel: View>: View, Renderable {
    let value: Binding<Double>
    let bounds: ClosedRange<Double>
    let step: Double
    let label: Label?
    let valueLabel: ValueLabel?
    let trackStyle: TrackStyle
    let focusID: String
    let isDisabled: Bool
    let onEditingChanged: ((Bool) -> Void)?

    /// Default track width when no explicit frame is set.
    private let defaultTrackWidth = 20

    var body: Never {
        fatalError("_SliderCore renders via Renderable")
    }

    func renderToBuffer(context: RenderContext) -> FrameBuffer {
        let focusManager = context.environment.focusManager
        let stateStorage = context.tuiContext.stateStorage
        let palette = context.environment.palette

        // Determine track width: use available width minus arrows and value label space
        // Layout: [label] ❙ ◀ [track] ▶ ❙ [value]
        // Focus indicators: 2 chars each side (❙ + space)
        // Arrows: 2 chars each (◀ + space, space + ▶)
        // Value label: ~5 chars (e.g., "100%")
        let arrowsWidth = 4  // "◀ " + " ▶"
        let focusWidth = 4   // "❙ " on each side when focused (or "  " when not)
        let valueLabelWidth = 6  // " 100%"

        let trackWidth: Int
        if context.hasExplicitWidth {
            let availableForTrack = context.availableWidth - arrowsWidth - focusWidth - valueLabelWidth
            trackWidth = max(5, availableForTrack)
        } else {
            trackWidth = defaultTrackWidth
        }

        // Get or create persistent handler from state storage
        let handlerKey = StateStorage.StateKey(identity: context.identity, propertyIndex: 0)
        let handlerBox: StateBox<SliderHandler<Double>> = stateStorage.storage(
            for: handlerKey,
            default: SliderHandler(
                focusID: focusID,
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
        handler.onEditingChanged = onEditingChanged
        handler.clampValue()

        // Register with focus manager
        focusManager.register(handler, inSection: context.activeFocusSectionID)
        stateStorage.markActive(context.identity)

        // Determine focus state
        let isFocused = focusManager.isFocused(id: focusID)

        // Calculate fraction
        let range = bounds.upperBound - bounds.lowerBound
        let fraction = range > 0 ? (value.wrappedValue - bounds.lowerBound) / range : 0

        // Build the slider content
        let content = buildContent(
            fraction: fraction,
            isFocused: isFocused,
            palette: palette,
            pulsePhase: context.pulsePhase,
            trackWidth: trackWidth
        )

        return FrameBuffer(text: content)
    }

    /// Builds the rendered slider content.
    private func buildContent(
        fraction: Double,
        isFocused: Bool,
        palette: any Palette,
        pulsePhase: Double,
        trackWidth: Int
    ) -> String {
        // Arrow colors
        let arrowColor: Color
        if isDisabled {
            arrowColor = palette.foregroundTertiary
        } else if isFocused {
            // Pulse between 35% and 100% accent
            let dimAccent = palette.accent.opacity(0.35)
            arrowColor = Color.lerp(dimAccent, palette.accent, phase: pulsePhase)
        } else {
            arrowColor = palette.foregroundTertiary
        }

        // Build track
        let track = TrackRenderer.render(
            fraction: fraction,
            width: trackWidth,
            style: trackStyle,
            filledColor: isDisabled ? palette.foregroundTertiary : palette.foregroundSecondary,
            emptyColor: palette.foregroundTertiary,
            accentColor: palette.accent
        )

        // Build arrows
        let leftArrow = ANSIRenderer.colorize("◀", foreground: arrowColor)
        let rightArrow = ANSIRenderer.colorize("▶", foreground: arrowColor)

        // Build value label (percentage)
        let percentage = Int((fraction * 100).rounded())
        let valueText = "\(percentage)%"
        let valueLabelColor = isDisabled ? palette.foregroundTertiary : palette.foregroundSecondary
        let valueLabel = ANSIRenderer.colorize(valueText, foreground: valueLabelColor)

        // Build with focus indicators
        if isFocused && !isDisabled {
            let dimAccent = palette.accent.opacity(0.35)
            let barColor = Color.lerp(dimAccent, palette.accent, phase: pulsePhase)
            let bar = ANSIRenderer.colorize("❙", foreground: barColor)
            return "\(bar) \(leftArrow) \(track) \(rightArrow) \(bar) \(valueLabel)"
        }

        // Unfocused: spaces instead of bars for alignment
        return "  \(leftArrow) \(track) \(rightArrow)   \(valueLabel)"
    }
}

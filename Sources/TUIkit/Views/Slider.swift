//  TUIKit - Terminal UI Kit for Swift
//  Slider.swift
//
//  Created by LAYERED.work
//  License: MIT


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
    var focusID: String?

    /// Whether the slider is disabled.
    var isDisabled: Bool

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
        self.focusID = nil
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
        // Auto-generated focusID from view identity (collision-free)
        self.focusID = nil
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
        self.focusID = nil
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
        var copy = self
        copy.isDisabled = disabled
        return copy
    }

    /// Sets a custom focus identifier for this slider.
    ///
    /// - Parameter id: The unique focus identifier.
    /// - Returns: A slider with the specified focus identifier.
    public func focusID(_ id: String) -> Slider {
        var copy = self
        copy.focusID = id
        return copy
    }
}

// MARK: - Internal Core View

/// Internal view that handles the actual rendering of Slider.
private struct _SliderCore<Label: View, ValueLabel: View>: View, Renderable, Layoutable {
    let value: Binding<Double>
    let bounds: ClosedRange<Double>
    let step: Double
    let label: Label?
    let valueLabel: ValueLabel?
    let trackStyle: TrackStyle
    let focusID: String?
    let isDisabled: Bool
    let onEditingChanged: ((Bool) -> Void)?

    /// Minimum track width.
    private let minTrackWidth = 10

    /// Default track width when no explicit frame is set.
    private let defaultTrackWidth = 20

    /// Fixed width for arrows and value label.
    /// Layout: ◀ [track] ▶ [value]
    /// Arrows: 4 chars ("◀ " + " ▶"), Value: 5 chars (" 100%")
    private let fixedWidth = 9  // arrowsWidth(4) + valueLabelWidth(5)

    var body: Never {
        fatalError("_SliderCore renders via Renderable")
    }

    /// Returns the size this slider needs.
    ///
    /// Slider is width-flexible: it has a minimum width but expands
    /// to fill available horizontal space in HStack.
    func sizeThatFits(proposal: ProposedSize, context: RenderContext) -> ViewSize {
        let proposedWidth = proposal.width ?? (defaultTrackWidth + fixedWidth)
        let trackWidth = max(minTrackWidth, proposedWidth - fixedWidth)
        return ViewSize(
            width: trackWidth + fixedWidth,
            height: 1,
            isWidthFlexible: true,
            isHeightFlexible: false
        )
    }

    func renderToBuffer(context: RenderContext) -> FrameBuffer {
        let stateStorage = context.tuiContext.stateStorage
        let palette = context.environment.palette

        // Slider expands to fill available width (with minimum)
        let trackWidth = max(minTrackWidth, context.availableWidth - fixedWidth)

        let persistedFocusID = FocusRegistration.persistFocusID(
            context: context,
            explicitFocusID: focusID,
            defaultPrefix: "slider",
            propertyIndex: 1  // focusID
        )

        // Get or create persistent handler from state storage
        let handlerKey = StateStorage.StateKey(identity: context.identity, propertyIndex: 0)  // handler
        let handlerBox: StateBox<SliderHandler<Double>> = stateStorage.storage(
            for: handlerKey,
            default: SliderHandler(
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
        handler.onEditingChanged = onEditingChanged
        handler.clampValue()

        FocusRegistration.register(context: context, handler: handler)
        let isFocused = FocusRegistration.isFocused(context: context, focusID: persistedFocusID)

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
        // Arrow colors: pulsing accent when focused, dimmed when unfocused
        let arrowColor: Color
        if isDisabled {
            arrowColor = palette.foregroundTertiary.opacity(ViewConstants.disabledForeground)
        } else if isFocused {
            // Pulse between 35% and 100% accent
            let dimAccent = palette.accent.opacity(ViewConstants.focusPulseMin)
            arrowColor = Color.lerp(dimAccent, palette.accent, phase: pulsePhase)
        } else {
            // Dimmed arrows when unfocused
            arrowColor = palette.foregroundTertiary.opacity(ViewConstants.disabledForeground)
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
        let leftArrow = ANSIRenderer.colorize(TerminalSymbols.leftArrow, foreground: arrowColor)
        let rightArrow = ANSIRenderer.colorize(TerminalSymbols.rightArrow, foreground: arrowColor)

        // Build value label (percentage)
        let percentage = Int((fraction * 100).rounded())
        let valueText = "\(percentage)%"
        let valueLabelColor = isDisabled ? palette.foregroundTertiary : palette.foregroundSecondary
        let valueLabel = ANSIRenderer.colorize(valueText, foreground: valueLabelColor)

        // Pulsing arrows indicate focus - no extra markers needed
        return "\(leftArrow) \(track) \(rightArrow) \(valueLabel)"
    }
}

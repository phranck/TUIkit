//  🖥️ TUIKit — Terminal UI Kit for Swift
//  ProgressView.swift
//
//  Created by LAYERED.work
//  License: MIT

// MARK: - ProgressBar Style

/// The visual style of a progress bar.
///
/// TUIKit provides five built-in styles using different Unicode characters:
///
/// ```
/// block:     ████████████████░░░░░░░░░░░░░░░░
/// blockFine: ████████████████▍░░░░░░░░░░░░░░░   (sub-character precision)
/// shade:     ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓░░░░░░░░░░░░░░░░
/// bar:       ▌▌▌▌▌▌▌▌▌▌▌▌▌▌▌▌────────────────
/// dot:       ▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬●────────────────
/// ```
public enum ProgressBarStyle: Sendable, Equatable {
    /// Full block characters (default).
    ///
    /// Uses `█` for filled cells and `░` for empty cells.
    case block

    /// Full block characters with sub-character fractional precision.
    ///
    /// Uses `█` for filled cells, fractional blocks (`▉▊▋▌▍▎▏`) for the
    /// partial cell at the boundary, and `░` for empty cells. This gives
    /// 8× finer visual resolution than ``block``.
    case blockFine

    /// Shade characters for a softer, textured look.
    ///
    /// Uses `▓` (dark shade) for filled and `░` (light shade) for empty.
    case shade

    /// Vertical bar characters with a horizontal line track.
    ///
    /// Uses `▌` for filled and `─` for empty.
    case bar

    /// Rectangle track with a dot indicator at the progress position.
    ///
    /// Uses `▬` for filled, `●` as the progress head, and `─` for empty.
    /// The dot head renders in the accent color.
    case dot
}

// MARK: - ProgressView

/// A view that shows the progress toward completion of a task.
///
/// `ProgressView` renders a horizontal bar using Unicode block characters.
/// It matches SwiftUI's determinate progress API with `value` and `total`
/// parameters.
///
/// ## Visual Output
///
/// ```
/// Downloading                  50%
/// ████████████████▌░░░░░░░░░░░░░░░
/// ```
///
/// - **Line 1** (optional): Label (left-aligned) + CurrentValueLabel (right-aligned)
/// - **Line 2**: Progress bar
///
/// ## Styles
///
/// Set the style via the `progressBarStyle(_:)` modifier or pass it directly:
///
/// ```swift
/// ProgressView(value: 0.5)
///     .progressBarStyle(.shade)
/// ```
///
/// See ``ProgressBarStyle`` for all available styles.
///
/// ## Examples
///
/// ```swift
/// // Simple progress bar (50%)
/// ProgressView(value: 0.5)
///
/// // With total
/// ProgressView(value: 3, total: 10)
///
/// // With string title
/// ProgressView("Loading...", value: 0.75)
///
/// // With label and current value label
/// ProgressView(value: 0.5) {
///     Text("Downloading")
/// } currentValueLabel: {
///     Text("50%")
/// }
/// ```
///
/// ## Colors
///
/// | Part | Color |
/// |------|-------|
/// | Filled bar | `palette.foregroundSecondary` |
/// | Empty bar | `palette.foregroundTertiary` |
/// | Dot head (`.dot` style only) | `palette.accent` |
/// | Label | inherited from environment |
/// | CurrentValueLabel | inherited from environment |
///
/// ## Size Behavior
///
/// The bar fills the full `availableWidth`. When a label or currentValueLabel
/// is provided, the view is 2 lines tall; otherwise 1 line.
public struct ProgressView<Label: View, CurrentValueLabel: View>: View {
    /// The normalized fraction completed (0.0–1.0), or nil for indeterminate.
    let fractionCompleted: Double?

    /// The visual style of the progress bar.
    var style: ProgressBarStyle

    /// The label view displayed above the bar (left-aligned).
    let label: Label?

    /// The current value label displayed above the bar (right-aligned).
    let currentValueLabel: CurrentValueLabel?

    public var body: some View {
        _ProgressViewCore(
            fractionCompleted: fractionCompleted,
            style: style,
            label: label,
            currentValueLabel: currentValueLabel
        )
    }
}

// MARK: - Initializers (value/total)

extension ProgressView where Label == EmptyView, CurrentValueLabel == EmptyView {
    /// Creates a progress view with a fractional completion value.
    ///
    /// - Parameters:
    ///   - value: The completed amount (nil for indeterminate).
    ///   - total: The total amount (default: 1.0).
    public init<V: BinaryFloatingPoint>(value: V?, total: V = 1.0) {
        self.fractionCompleted = ProgressView.normalizedFraction(value: value, total: total)
        self.style = .block
        self.label = nil
        self.currentValueLabel = nil
    }
}

extension ProgressView where CurrentValueLabel == EmptyView {
    /// Creates a progress view with a label.
    ///
    /// - Parameters:
    ///   - value: The completed amount (nil for indeterminate).
    ///   - total: The total amount (default: 1.0).
    ///   - label: A view that describes the task in progress.
    public init<V: BinaryFloatingPoint>(
        value: V?, total: V = 1.0,
        @ViewBuilder label: () -> Label
    ) {
        self.fractionCompleted = ProgressView.normalizedFraction(value: value, total: total)
        self.style = .block
        self.label = label()
        self.currentValueLabel = nil
    }
}

extension ProgressView {
    /// Creates a progress view with a label and current value label.
    ///
    /// - Parameters:
    ///   - value: The completed amount (nil for indeterminate).
    ///   - total: The total amount (default: 1.0).
    ///   - label: A view that describes the task in progress.
    ///   - currentValueLabel: A view showing the current progress value.
    public init<V: BinaryFloatingPoint>(
        value: V?, total: V = 1.0,
        @ViewBuilder label: () -> Label,
        @ViewBuilder currentValueLabel: () -> CurrentValueLabel
    ) {
        self.fractionCompleted = ProgressView.normalizedFraction(value: value, total: total)
        self.style = .block
        self.label = label()
        self.currentValueLabel = currentValueLabel()
    }
}

// MARK: - String Title Initializer

extension ProgressView where Label == Text, CurrentValueLabel == EmptyView {
    /// Creates a progress view with a string title.
    ///
    /// - Parameters:
    ///   - title: A string that describes the task in progress.
    ///   - value: The completed amount (nil for indeterminate).
    ///   - total: The total amount (default: 1.0).
    public init<S: StringProtocol, V: BinaryFloatingPoint>(
        _ title: S, value: V?, total: V = 1.0
    ) {
        self.fractionCompleted = ProgressView.normalizedFraction(value: value, total: total)
        self.style = .block
        self.label = Text(String(title))
        self.currentValueLabel = nil
    }
}

// MARK: - Style Modifier

extension ProgressView {
    /// Sets the visual style of the progress bar.
    ///
    /// ```swift
    /// ProgressView(value: 0.5)
    ///     .progressBarStyle(.shade)
    /// ```
    ///
    /// - Parameter style: The progress bar style.
    /// - Returns: A progress view with the specified style.
    public func progressBarStyle(_ style: ProgressBarStyle) -> ProgressView {
        var copy = self
        copy.style = style
        return copy
    }
}

// MARK: - Equatable Conformance

extension ProgressView: Equatable where Label: Equatable, CurrentValueLabel: Equatable {
    nonisolated public static func == (lhs: ProgressView<Label, CurrentValueLabel>, rhs: ProgressView<Label, CurrentValueLabel>) -> Bool {
        MainActor.assumeIsolated {
            lhs.fractionCompleted == rhs.fractionCompleted &&
            lhs.style == rhs.style &&
            lhs.label == rhs.label &&
            lhs.currentValueLabel == rhs.currentValueLabel
        }
    }
}

// MARK: - Normalization Helper

extension ProgressView {
    /// Normalizes value/total to a 0.0–1.0 fraction, clamping out-of-range values.
    static func normalizedFraction<V: BinaryFloatingPoint>(value: V?, total: V) -> Double? {
        guard let value else { return nil }
        guard total > 0 else { return 0.0 }
        return min(1.0, max(0.0, Double(value) / Double(total)))
    }
}

// MARK: - Internal Core View

/// Internal view that handles the actual rendering of ProgressView.
private struct _ProgressViewCore<Label: View, CurrentValueLabel: View>: View, Renderable {
    let fractionCompleted: Double?
    let style: ProgressBarStyle
    let label: Label?
    let currentValueLabel: CurrentValueLabel?

    var body: Never {
        fatalError("_ProgressViewCore renders via Renderable")
    }

    func renderToBuffer(context: RenderContext) -> FrameBuffer {
        let palette = context.environment.palette
        let width = context.availableWidth
        var lines: [String] = []

        // Label line (optional): label left, currentValueLabel right
        let hasLabel = label != nil && !(label is EmptyView)
        let hasValueLabel = currentValueLabel != nil && !(currentValueLabel is EmptyView)

        if hasLabel || hasValueLabel {
            lines.append(
                renderLabelLine(
                    width: width,
                    palette: palette,
                    context: context
                )
            )
        }

        // Progress bar line
        lines.append(renderBarLine(width: width, palette: palette))

        return FrameBuffer(lines: lines)
    }

    // MARK: - Label Line Rendering

    /// Renders the label line with label left-aligned and currentValueLabel right-aligned.
    private func renderLabelLine(width: Int, palette: any Palette, context: RenderContext) -> String {
        let labelBuffer: FrameBuffer
        if let labelView = label, !(labelView is EmptyView) {
            labelBuffer = TUIkit.renderToBuffer(labelView, context: context)
        } else {
            labelBuffer = FrameBuffer()
        }

        let valueBuffer: FrameBuffer
        if let valueView = currentValueLabel, !(valueView is EmptyView) {
            valueBuffer = TUIkit.renderToBuffer(valueView, context: context)
        } else {
            valueBuffer = FrameBuffer()
        }

        let labelText = labelBuffer.lines.first ?? ""
        let valueText = valueBuffer.lines.first ?? ""

        let labelWidth = labelText.strippedLength
        let valueWidth = valueText.strippedLength
        let gap = max(1, width - labelWidth - valueWidth)

        return labelText + String(repeating: " ", count: gap) + valueText
    }

    // MARK: - Bar Line Rendering

    /// Renders the progress bar line using the current style.
    private func renderBarLine(width: Int, palette: any Palette) -> String {
        let barWidth = max(0, width)
        let fraction = fractionCompleted ?? 0.0

        let filledColor = palette.foregroundSecondary
        let emptyColor = palette.foregroundTertiary

        switch style {
        case .block:
            return renderSimpleStyle(
                fraction: fraction, barWidth: barWidth,
                filledChar: "█", emptyChar: "░",
                filledColor: filledColor, emptyColor: emptyColor
            )
        case .blockFine:
            return renderBlockFineStyle(fraction: fraction, barWidth: barWidth, filledColor: filledColor, emptyColor: emptyColor)
        case .shade:
            return renderSimpleStyle(
                fraction: fraction, barWidth: barWidth,
                filledChar: "▓", emptyChar: "░",
                filledColor: filledColor, emptyColor: emptyColor
            )
        case .bar:
            return renderSimpleStyle(
                fraction: fraction, barWidth: barWidth,
                filledChar: "▌", emptyChar: "─",
                filledColor: filledColor, emptyColor: emptyColor
            )
        case .dot:
            return renderHeadStyle(
                fraction: fraction, barWidth: barWidth,
                filledChar: "▬", headChar: "●", emptyChar: "─",
                filledColor: filledColor, headColor: palette.accent, emptyColor: emptyColor
            )
        }
    }

    /// Renders the `.blockFine` style with sub-character fractional precision.
    private func renderBlockFineStyle(fraction: Double, barWidth: Int, filledColor: Color, emptyColor: Color) -> String {
        guard barWidth > 0 else { return "" }

        let totalEighths = fraction * Double(barWidth) * 8.0
        let fullCells = Int(totalEighths) / 8
        let remainderEighths = Int(totalEighths) % 8

        let fractionalBlocks: [Character] = ["▏", "▎", "▍", "▌", "▋", "▊", "▉"]

        var result = ""

        if fullCells > 0 {
            let filledBar = String(repeating: "█", count: fullCells)
            result += ANSIRenderer.colorize(filledBar, foreground: filledColor)
        }

        let cellsUsed: Int
        if remainderEighths > 0 && fullCells < barWidth {
            let partialChar = fractionalBlocks[remainderEighths - 1]
            result += ANSIRenderer.colorize(String(partialChar), foreground: filledColor)
            cellsUsed = fullCells + 1
        } else {
            cellsUsed = fullCells
        }

        let emptyCount = barWidth - cellsUsed
        if emptyCount > 0 {
            let emptyBar = String(repeating: "░", count: emptyCount)
            result += ANSIRenderer.colorize(emptyBar, foreground: emptyColor)
        }

        return result
    }

    /// Renders a simple two-character style (filled + empty, no head indicator).
    private func renderSimpleStyle(
        fraction: Double,
        barWidth: Int,
        filledChar: Character,
        emptyChar: Character,
        filledColor: Color,
        emptyColor: Color
    ) -> String {
        let filledCount = Int((fraction * Double(barWidth)).rounded())
        let emptyCount = barWidth - filledCount

        var result = ""
        if filledCount > 0 {
            result += ANSIRenderer.colorize(
                String(repeating: filledChar, count: filledCount),
                foreground: filledColor
            )
        }
        if emptyCount > 0 {
            result += ANSIRenderer.colorize(
                String(repeating: emptyChar, count: emptyCount),
                foreground: emptyColor
            )
        }
        return result
    }

    /// Renders a head-indicator style (filled track + head + empty track).
    private func renderHeadStyle(
        fraction: Double,
        barWidth: Int,
        filledChar: Character,
        headChar: Character,
        emptyChar: Character,
        filledColor: Color,
        headColor: Color,
        emptyColor: Color
    ) -> String {
        guard barWidth > 0 else { return "" }

        let filledCount = Int((fraction * Double(barWidth)).rounded())

        var result = ""

        let trackCount = max(0, filledCount - 1)
        if trackCount > 0 {
            result += ANSIRenderer.colorize(
                String(repeating: filledChar, count: trackCount),
                foreground: filledColor
            )
        }

        if filledCount > 0 && filledCount <= barWidth {
            result += ANSIRenderer.colorize(String(headChar), foreground: headColor)
        }

        let emptyCount = barWidth - max(filledCount, 0)
        if emptyCount > 0 {
            result += ANSIRenderer.colorize(
                String(repeating: emptyChar, count: emptyCount),
                foreground: emptyColor
            )
        }

        return result
    }
}

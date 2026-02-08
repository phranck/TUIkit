//  🖥️ TUIKit — Terminal UI Kit for Swift
//  Spinner.swift
//
//  Created by LAYERED.work
//  License: MIT

import Foundation

// MARK: - Spinner Style

/// The visual style of a spinner animation.
///
/// TUIKit provides three built-in styles:
///
/// - ``dots``: Braille character rotation (`⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏`)
/// - ``line``: ASCII line rotation (`|/-\`)
/// - ``bouncing``: A highlight block (`▇`) bouncing across a track with a fading trail (Knight Rider / Larson scanner)
public enum SpinnerStyle: Sendable {
    /// Braille character rotation.
    ///
    /// Cycles through: `⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏`
    case dots

    /// ASCII line rotation.
    ///
    /// Cycles through: `| / - \`
    case line

    /// A highlight block bouncing across a track of small squares with a
    /// fading trail behind it (Larson scanner / Knight Rider effect).
    ///
    /// The highlight moves back and forth across a fixed 9-position track.
    /// Three trailing positions fade out progressively, creating a smooth
    /// motion trail.
    case bouncing

    /// The animation frames for frame-based styles (dots, line).
    var frames: [String] {
        switch self {
        case .dots:
            return ["⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"]
        case .line:
            return ["|", "/", "-", "\\"]
        case .bouncing:
            return Self.bouncingPositions(trackLength: Self.trackWidth)
                .map { String($0) }
        }
    }

    /// The fixed animation interval for this style.
    var interval: TimeInterval {
        switch self {
        case .dots: return 0.110
        case .line: return 0.140
        case .bouncing: return 0.100
        }
    }

    /// The fixed track width for the bouncing style (9 positions).
    static let trackWidth = 9

    /// The fixed trail opacities for the bouncing style.
    ///
    /// Index 0 is the highlight itself, followed by 5 fading positions.
    static let trailOpacities: [Double] = [1.0, 0.75, 0.5, 0.35, 0.22, 0.15]

    /// How many positions the highlight overshoots beyond each edge of
    /// the visible track. This lets the trail fade out smoothly at the
    /// edges instead of being cut off abruptly.
    static let edgeOvershoot = 2
}

// MARK: - Internal API

extension SpinnerStyle {
    /// Generates the bounce position sequence for the given track length.
    ///
    /// The highlight travels from `-edgeOvershoot` to
    /// `trackLength - 1 + edgeOvershoot`, then bounces back. Positions
    /// outside the visible range `0..<trackLength` are still valid — the
    /// highlight is off-screen there but its trail remains partially visible.
    ///
    /// - Parameter trackLength: The number of visible positions in the track.
    /// - Returns: An array of highlight positions for each frame.
    static func bouncingPositions(trackLength: Int) -> [Int] {
        let lower = -edgeOvershoot
        let upper = trackLength - 1 + edgeOvershoot
        var positions: [Int] = []

        // Forward: lower → upper
        for position in lower...upper {
            positions.append(position)
        }

        // Backward: upper-1 → lower+1 (skip endpoints to avoid double-pause)
        for position in stride(from: upper - 1, through: lower + 1, by: -1) {
            positions.append(position)
        }

        return positions
    }

    /// Renders a single bouncing frame with colored trail.
    ///
    /// The highlight position may be outside the visible track (overshoot).
    /// Only positions within `0..<trackWidth` are rendered. Trail positions
    /// that fall within the visible range still get their faded color, even
    /// when the highlight itself is off-screen.
    ///
    /// - Parameters:
    ///   - frameIndex: The current frame index in the bounce sequence.
    ///   - color: The resolved highlight color.
    /// - Returns: An ANSI-colored string representing the track.
    static func renderBouncingFrame(
        frameIndex: Int,
        color: Color
    ) -> String {
        let positions = bouncingPositions(trackLength: trackWidth)
        let currentPos = positions[frameIndex % positions.count]

        // Determine direction: compare with previous position.
        let prevIndex = (frameIndex - 1 + positions.count) % positions.count
        let prevPos = positions[prevIndex]
        let movingForward = currentPos > prevPos || (currentPos == -edgeOvershoot && prevPos == -edgeOvershoot + 1)

        var result = ""
        for trackIndex in 0..<trackWidth {
            let distance = trailDistance(
                from: currentPos,
                to: trackIndex,
                movingForward: movingForward
            )

            if let distance, distance < trailOpacities.count {
                let fadedColor = color.opacity(trailOpacities[distance])
                result += ANSIRenderer.colorize("●", foreground: fadedColor)
            } else {
                result += ANSIRenderer.colorize("●", foreground: color.opacity(0.15))
            }
        }

        return result
    }
}

// MARK: - Private Helpers

private extension SpinnerStyle {
    /// Calculates the trail distance from the highlight to a track position.
    ///
    /// Returns `nil` if the position is not in the trail (ahead of the highlight
    /// or too far behind). Distance 0 = highlight itself, 1 = first trail, etc.
    ///
    /// - Parameters:
    ///   - highlight: The current highlight position.
    ///   - target: The track position to check.
    ///   - movingForward: Whether the highlight is moving left→right.
    /// - Returns: The trail distance, or `nil` if not in the trail.
    static func trailDistance(
        from highlight: Int,
        to target: Int,
        movingForward: Bool
    ) -> Int? {
        if target == highlight { return 0 }

        // Trail is behind the highlight (opposite to movement direction).
        let offset: Int
        if movingForward {
            offset = highlight - target  // Trail extends to the left
        } else {
            offset = target - highlight  // Trail extends to the right
        }

        return offset > 0 ? offset : nil
    }
}

// MARK: - Spinner

/// An animated loading indicator.
///
/// `Spinner` displays a continuously animating indicator to communicate
/// that a task is in progress. It supports multiple visual styles and
/// an optional label.
///
/// The animation runs automatically via a background task that triggers
/// re-renders at a fixed interval. The task is started when the spinner
/// first appears and cancelled when it disappears.
///
/// # Example
///
/// ```swift
/// // Simple dots spinner
/// Spinner()
///
/// // With label
/// Spinner("Loading...")
///
/// // Bouncing style with custom color
/// Spinner("Processing...", style: .bouncing, color: .cyan)
/// ```
///
/// # Styles
///
/// | Style | Visual | Interval |
/// |-------|--------|----------|
/// | `.dots` | `⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏` | 110ms |
/// | `.line` | `\| / - \\` | 140ms |
/// | `.bouncing` | `■■▇▇▇▇■■■` (with fade trail) | 100ms |
public struct Spinner: View {
    /// The optional label displayed after the spinner.
    let label: String?

    /// The animation style.
    let style: SpinnerStyle

    /// The spinner color (uses theme accent if nil).
    let color: Color?

    /// Unique lifecycle token for this spinner instance.
    let token: String

    /// Creates a spinner with an optional label.
    ///
    /// - Parameters:
    ///   - label: Text displayed after the spinner indicator.
    ///   - style: The animation style (default: `.dots`).
    ///   - color: The spinner color (default: theme accent).
    public init(
        _ label: String? = nil,
        style: SpinnerStyle = .dots,
        color: Color? = nil
    ) {
        self.label = label
        self.style = style
        self.color = color
        self.token = "spinner-\(UUID().uuidString)"
    }

    public var body: some View {
        _SpinnerCore(
            label: label,
            style: style,
            color: color,
            token: token
        )
    }
}

// MARK: - Internal Core View

/// Internal view that handles the actual rendering and animation of Spinner.
private struct _SpinnerCore: View, Renderable {
    let label: String?
    let style: SpinnerStyle
    let color: Color?
    let token: String

    var body: Never {
        fatalError("_SpinnerCore renders via Renderable")
    }

    func renderToBuffer(context: RenderContext) -> FrameBuffer {
        let lifecycle = context.tuiContext.lifecycle
        let stateStorage = context.tuiContext.stateStorage

        // Retrieve or create persistent start time for this spinner.
        let timeKey = StateStorage.StateKey(identity: context.identity, propertyIndex: 0)
        let startTimeBox: StateBox<Double> = stateStorage.storage(for: timeKey, default: Date().timeIntervalSinceReferenceDate)
        stateStorage.markActive(context.identity)

        // Start render-trigger task on first appearance.
        if !lifecycle.hasAppeared(token: token) {
            _ = lifecycle.recordAppear(token: token) {}

            let triggerNanos: UInt64 = 40_000_000  // 40ms — matches run loop poll rate (~25 FPS)
            lifecycle.startTask(token: token, priority: .medium) {
                while !Task.isCancelled {
                    try? await Task.sleep(nanoseconds: triggerNanos)
                    guard !Task.isCancelled else { break }
                    RenderNotifier.current.setNeedsRender()
                }
            }
        } else {
            _ = lifecycle.recordAppear(token: token) {}
        }

        // Register disappear callback to cancel the animation task.
        lifecycle.registerDisappear(token: token) { [lifecycle] in
            lifecycle.cancelTask(token: token)
        }

        // Calculate frame index from elapsed time.
        let elapsed = Date().timeIntervalSinceReferenceDate - startTimeBox.value
        let frameCount: Int
        switch style {
        case .bouncing:
            frameCount = SpinnerStyle.bouncingPositions(trackLength: SpinnerStyle.trackWidth).count
        case .dots, .line:
            frameCount = style.frames.count
        }
        let frameIndex = Int(elapsed / style.interval) % frameCount

        // Resolve color - use environment foregroundColor if no explicit color set
        let effectiveColor = color ?? context.environment.foregroundStyle ?? .palette.accent
        let resolvedColor = effectiveColor.resolve(with: context.environment.palette)

        // Build spinner text — bouncing renders with colored trail, others are plain.
        let coloredSpinner: String
        switch style {
        case .bouncing:
            coloredSpinner = SpinnerStyle.renderBouncingFrame(
                frameIndex: frameIndex,
                color: resolvedColor
            )
        case .dots, .line:
            coloredSpinner = ANSIRenderer.colorize(
                style.frames[frameIndex],
                foreground: resolvedColor
            )
        }

        let output: String
        if let label {
            output = coloredSpinner + " " + label
        } else {
            output = coloredSpinner
        }

        return FrameBuffer(text: output)
    }
}

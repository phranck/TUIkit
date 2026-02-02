//
//  Spinner.swift
//  TUIkit
//
//  An animated loading indicator with multiple visual styles.
//

import Foundation

// MARK: - Spinner Speed

/// The animation speed of a spinner.
///
/// Each speed maps to a style-specific interval. Faster styles like ``dots``
/// use shorter base intervals than ``bouncing``.
public enum SpinnerSpeed: Sendable {
    /// Slow animation.
    case slow

    /// Normal animation (default).
    case regular

    /// Fast animation.
    case fast

    /// Returns the interval multiplier relative to the style's base interval.
    var multiplier: Double {
        switch self {
        case .slow: return 2.2
        case .regular: return 1.4
        case .fast: return 0.8
        }
    }
}

// MARK: - Bouncing Trail Length

/// The length of the fading trail behind the bouncing spinner's highlight.
///
/// Controls how many blocks (highlight + fading positions) are visible
/// as the highlight moves across the track.
public enum BouncingTrailLength: Sendable {
    /// Short trail: highlight + 1 fade step (2 blocks total).
    case short

    /// Regular trail: highlight + 3 fade steps (4 blocks total, default).
    case regular

    /// Long trail: highlight + 5 fade steps (6 blocks total).
    case long

    /// The opacity values for the trail positions (highlight first, then fading).
    var opacities: [Double] {
        switch self {
        case .short: return [1.0, 0.4]
        case .regular: return [1.0, 0.7, 0.4, 0.15]
        case .long: return [1.0, 0.85, 0.65, 0.45, 0.25, 0.10]
        }
    }
}

// MARK: - Bouncing Track Width

/// The track width for the bouncing spinner style.
///
/// The track is the row of positions the highlight bounces across.
/// Use ``max`` to fill the available terminal width (responds to resizing).
public enum BouncingTrackWidth: Sendable, Equatable {
    /// Minimum width (7 positions).
    case minimum

    /// Default width (9 positions).
    case `default`

    /// Fill the available terminal width (minus label and spacing).
    ///
    /// The actual width is resolved at render time using the available
    /// width from ``RenderContext``. Responds to terminal resizing.
    case maximum

    /// Explicit width in characters (clamped to minimum of 7).
    case fixed(Int)

    /// Resolves the track width to a concrete character count.
    ///
    /// - Parameters:
    ///   - availableWidth: The available width from the render context.
    ///   - labelWidth: The visible character count of the label (including spacing).
    /// - Returns: The resolved track width, clamped to the minimum.
    func resolve(availableWidth: Int, labelWidth: Int) -> Int {
        let raw: Int
        switch self {
        case .minimum:
            raw = SpinnerStyle.minimumTrackWidth
        case .default:
            raw = 9
        case .maximum:
            raw = availableWidth - labelWidth
        case .fixed(let width):
            raw = width
        }
        return Swift.max(raw, SpinnerStyle.minimumTrackWidth)
    }
}

// MARK: - Spinner Style

/// The visual style of a spinner animation.
///
/// TUIKit provides three built-in styles:
///
/// - ``dots``: Braille character rotation (`⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏`)
/// - ``line``: ASCII line rotation (`|/-\`)
/// - ``bouncing``: A highlight block (`▇`) bouncing across a track of dots with a fading trail (Knight Rider / Larson scanner)
///
/// Each style has a default animation interval that can be overridden
/// when creating a ``Spinner``.
public enum SpinnerStyle: Sendable {
    /// Braille character rotation.
    ///
    /// Cycles through: `⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏`
    ///
    /// Default interval: 80ms.
    case dots

    /// ASCII line rotation.
    ///
    /// Cycles through: `| / - \`
    ///
    /// Default interval: 100ms.
    case line

    /// A highlight block bouncing across a track of small squares with a
    /// fading trail behind it (Larson scanner / Knight Rider effect).
    ///
    /// The highlight moves back and forth. Three trailing positions fade
    /// out progressively behind it, creating a smooth motion trail.
    ///
    /// Default interval: 120ms. Default track length: 7.
    case bouncing

    /// The animation frames for this style.
    ///
    /// For ``dots`` and ``line``, these are plain character strings.
    /// For ``bouncing``, the frames are position indices encoded as strings
    /// (the actual colored rendering happens in ``Spinner``'s `renderToBuffer`).
    var frames: [String] {
        switch self {
        case .dots:
            return ["⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"]
        case .line:
            return ["|", "/", "-", "\\"]
        case .bouncing:
            return Self.bouncingPositions(trackLength: BouncingTrackWidth.default.resolve(availableWidth: 0, labelWidth: 0))
                .map { String($0) }
        }
    }

    /// The base animation interval for this style at ``SpinnerSpeed/regular``.
    var baseInterval: TimeInterval {
        switch self {
        case .dots: return 0.08
        case .line: return 0.10
        case .bouncing: return 0.07
        }
    }

    /// The minimum track width for the bouncing style.
    public static let minimumTrackWidth = 7

    /// Generates the bounce position sequence for the given track length.
    ///
    /// Positions move forward (0 → trackLength-1) then backward
    /// (trackLength-2 → 1), skipping endpoints to avoid stutter.
    ///
    /// - Parameter trackLength: The number of positions in the track.
    /// - Returns: An array of highlight positions for each frame.
    static func bouncingPositions(trackLength: Int) -> [Int] {
        var positions: [Int] = []

        // Forward: 0 → trackLength-1
        for position in 0..<trackLength {
            positions.append(position)
        }

        // Backward: trackLength-2 → 1 (skip endpoints to avoid double-pause)
        for position in stride(from: trackLength - 2, through: 1, by: -1) {
            positions.append(position)
        }

        return positions
    }

    /// Renders a single bouncing frame with colored trail.
    ///
    /// The highlight position gets the full color. Up to 3 positions behind
    /// it (in the direction of movement) get progressively faded colors.
    /// All other positions render as dimmed small squares.
    ///
    /// - Parameters:
    ///   - frameIndex: The current frame index in the bounce sequence.
    ///   - color: The resolved highlight color.
    ///   - trackLength: The number of positions in the track.
    /// - Returns: An ANSI-colored string representing the track.
    static func renderBouncingFrame(
        frameIndex: Int,
        color: Color,
        trackWidth: Int,
        trailLength: BouncingTrailLength
    ) -> String {
        let positions = bouncingPositions(trackLength: trackWidth)
        let currentPos = positions[frameIndex % positions.count]

        // Determine direction: compare with previous position.
        let prevIndex = (frameIndex - 1 + positions.count) % positions.count
        let prevPos = positions[prevIndex]
        let movingForward = currentPos > prevPos || (currentPos == 0 && prevPos == 1)

        let opacities = trailLength.opacities
        var result = ""
        for trackIndex in 0..<trackWidth {
            let distance = trailDistance(
                from: currentPos,
                to: trackIndex,
                movingForward: movingForward,
                trackLength: trackWidth
            )

            if let distance, distance < opacities.count {
                let fadedColor = color.opacity(opacities[distance])
                result += ANSIRenderer.colorize("▇", foreground: fadedColor)
            } else {
                result += ANSIRenderer.colorize("■", foreground: color.opacity(0.15))
            }
        }

        return result
    }

    /// Calculates the trail distance from the highlight to a track position.
    ///
    /// Returns `nil` if the position is not in the trail (ahead of the highlight
    /// or too far behind). Distance 0 = highlight itself, 1 = first trail, etc.
    ///
    /// - Parameters:
    ///   - highlight: The current highlight position.
    ///   - target: The track position to check.
    ///   - movingForward: Whether the highlight is moving left→right.
    ///   - trackLength: The track length (unused but kept for future extension).
    /// - Returns: The trail distance, or `nil` if not in the trail.
    private static func trailDistance(
        from highlight: Int,
        to target: Int,
        movingForward: Bool,
        trackLength: Int
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
/// re-renders at the configured interval. The task is started when the
/// spinner first appears and cancelled when it disappears.
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
/// | Style | Visual | Default Interval |
/// |-------|--------|-----------------|
/// | `.dots` | `⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏` | 80ms |
/// | `.line` | `\| / - \\` | 100ms |
/// | `.bouncing` | `▪▪▇▇▇▇▪` (with fade trail) | 180ms |
public struct Spinner: View {
    /// The optional label displayed after the spinner.
    let label: String?

    /// The animation style.
    let style: SpinnerStyle

    /// The animation speed.
    let speed: SpinnerSpeed

    /// The spinner color (uses theme accent if nil).
    let color: Color?

    /// The track width for the bouncing style.
    ///
    /// Ignored for ``SpinnerStyle/dots`` and ``SpinnerStyle/line``.
    let trackWidth: BouncingTrackWidth

    /// The trail length for the bouncing style.
    ///
    /// Ignored for ``SpinnerStyle/dots`` and ``SpinnerStyle/line``.
    let trailLength: BouncingTrailLength

    /// Unique lifecycle token for this spinner instance.
    let token: String

    /// Creates a spinner with an optional label.
    ///
    /// - Parameters:
    ///   - label: Text displayed after the spinner indicator.
    ///   - style: The animation style (default: `.dots`).
    ///   - speed: The animation speed (default: `.regular`).
    ///   - color: The spinner color (default: theme accent).
    ///   - trackWidth: The track width for bouncing style
    ///     (default: `.default`). Use `.max` to fill available width.
    ///     Ignored for other styles.
    ///   - trailLength: The length of the fading trail for bouncing style
    ///     (default: `.regular`). Ignored for other styles.
    public init(
        _ label: String? = nil,
        style: SpinnerStyle = .dots,
        speed: SpinnerSpeed = .regular,
        color: Color? = nil,
        trackWidth: BouncingTrackWidth = .default,
        trailLength: BouncingTrailLength = .regular
    ) {
        self.label = label
        self.style = style
        self.speed = speed
        self.color = color
        self.trackWidth = trackWidth
        self.trailLength = trailLength
        self.token = "spinner-\(UUID().uuidString)"
    }

    /// Creates a spinner with an explicit track width in characters.
    ///
    /// - Parameters:
    ///   - label: Text displayed after the spinner indicator.
    ///   - style: The animation style (default: `.dots`).
    ///   - speed: The animation speed (default: `.regular`).
    ///   - color: The spinner color (default: theme accent).
    ///   - trackWidth: The track width in characters (minimum: 7).
    ///     Ignored for non-bouncing styles.
    ///   - trailLength: The length of the fading trail for bouncing style
    ///     (default: `.regular`). Ignored for other styles.
    public init(
        _ label: String? = nil,
        style: SpinnerStyle = .dots,
        speed: SpinnerSpeed = .regular,
        color: Color? = nil,
        trackWidth: Int,
        trailLength: BouncingTrailLength = .regular
    ) {
        self.label = label
        self.style = style
        self.speed = speed
        self.color = color
        self.trackWidth = .fixed(trackWidth)
        self.trailLength = trailLength
        self.token = "spinner-\(UUID().uuidString)"
    }

    public var body: Never {
        fatalError("Spinner is a primitive view and renders directly")
    }
}

// MARK: - Spinner Rendering

extension Spinner: Renderable {
    func renderToBuffer(context: RenderContext) -> FrameBuffer {
        let lifecycle = context.tuiContext.lifecycle
        let stateStorage = context.tuiContext.stateStorage
        let effectiveInterval = style.baseInterval * speed.multiplier

        // Retrieve or create persistent start time for this spinner.
        let timeKey = StateStorage.StateKey(identity: context.identity, propertyIndex: 0)
        let startTimeBox: StateBox<Double> = stateStorage.storage(for: timeKey, default: CFAbsoluteTimeGetCurrent())
        stateStorage.markActive(context.identity)

        // Start render-trigger task on first appearance.
        // The task fires at a fixed rate (~50ms) to request redraws.
        // The actual animation speed is determined by time-based frame
        // index calculation, not by the trigger interval.
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

        // Resolve track width for bouncing (needs label width for .max).
        let labelWidth = label.map { $0.count + 1 } ?? 0  // +1 for spacing
        let resolvedTrackWidth = trackWidth.resolve(
            availableWidth: context.availableWidth,
            labelWidth: labelWidth
        )

        // Calculate frame index from elapsed time (each spinner respects its own interval).
        let elapsed = CFAbsoluteTimeGetCurrent() - startTimeBox.value
        let frameCount: Int
        switch style {
        case .bouncing:
            frameCount = SpinnerStyle.bouncingPositions(trackLength: resolvedTrackWidth).count
        case .dots, .line:
            frameCount = style.frames.count
        }
        let frameIndex = Int(elapsed / effectiveInterval) % frameCount

        // Resolve color.
        let resolvedColor = (color ?? .palette.accent).resolve(with: context.environment.palette)

        // Build spinner text — bouncing renders with colored trail, others are plain.
        let coloredSpinner: String
        switch style {
        case .bouncing:
            coloredSpinner = SpinnerStyle.renderBouncingFrame(
                frameIndex: frameIndex,
                color: resolvedColor,
                trackWidth: resolvedTrackWidth,
                trailLength: trailLength
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

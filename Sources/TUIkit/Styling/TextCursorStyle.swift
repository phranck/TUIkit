//  TUIKit - Terminal UI Kit for Swift
//  TextCursorStyle.swift
//
//  Created by LAYERED.work
//  License: MIT

// MARK: - TextCursorStyle

/// Defines the visual appearance and animation of the text cursor in text fields.
///
/// Use this type with the `.textCursor(_:)` modifier to customize how the cursor
/// appears in ``TextField`` and ``SecureField`` components.
///
/// ## Cursor Shapes
///
/// TUIkit provides three cursor shapes optimized for terminal display:
///
/// | Shape | Character | Description |
/// |-------|-----------|-------------|
/// | `block` | `█` | Full block cursor (default) |
/// | `bar` | `│` | Centered vertical line |
/// | `underscore` | `▁` | Lower one eighth block |
///
/// ## Animation Styles
///
/// | Animation | Description |
/// |-----------|-------------|
/// | `none` | Static cursor, no animation |
/// | `blink` | Classic on/off blinking |
/// | `pulse` | Smooth color pulsing between dim and bright |
///
/// ## Animation Speed
///
/// | Speed | Multiplier | Cycle Duration |
/// |-------|------------|----------------|
/// | `slow` | 1.5x | ~1.3 seconds |
/// | `regular` | 3x | ~0.67 seconds |
/// | `fast` | 6x | ~0.33 seconds |
///
/// ## Usage
///
/// ```swift
/// // Block cursor with pulse animation (default)
/// TextField("Name", text: $name)
///
/// // Bar cursor with blink animation
/// TextField("Email", text: $email)
///     .textCursor(.bar, animation: .blink)
///
/// // Fast blinking underscore cursor
/// TextField("Code", text: $code)
///     .textCursor(.underscore, animation: .blink, speed: .fast)
///
/// // Apply to all text fields in a container
/// VStack {
///     TextField("First", text: $first)
///     TextField("Last", text: $last)
/// }
/// .textCursor(.bar)
/// ```
public struct TextCursorStyle: Equatable, Sendable {
    /// The visual shape of the cursor.
    public let shape: Shape

    /// The animation style of the cursor.
    public let animation: Animation

    /// The speed of the cursor animation.
    public let speed: Speed

    /// Creates a text cursor style with the specified shape, animation, and speed.
    ///
    /// - Parameters:
    ///   - shape: The cursor shape. Defaults to `.block`.
    ///   - animation: The cursor animation. Defaults to `.blink`.
    ///   - speed: The animation speed. Defaults to `.regular`.
    public init(shape: Shape = .block, animation: Animation = .blink, speed: Speed = .regular) {
        self.shape = shape
        self.animation = animation
        self.speed = speed
    }
}

// MARK: - Shape

extension TextCursorStyle {
    /// The visual shape of the text cursor.
    public enum Shape: String, CaseIterable, Sendable {
        /// Full block cursor (`█`, U+2588).
        ///
        /// The default cursor shape, providing maximum visibility.
        case block

        /// Centered vertical bar cursor (`│`, U+2502).
        ///
        /// A thin vertical line similar to modern GUI text editors.
        case bar

        /// Lower underscore cursor (`▁`, U+2581).
        ///
        /// A horizontal line at the bottom of the character cell.
        case underscore

        /// The Unicode character representing this cursor shape.
        public var character: Character {
            switch self {
            case .block: "█"
            case .bar: "│"
            case .underscore: "▁"
            }
        }
    }
}

// MARK: - Animation

extension TextCursorStyle {
    /// The animation style for the text cursor.
    public enum Animation: String, CaseIterable, Sendable {
        /// No animation. The cursor remains static.
        case none

        /// Classic blinking animation.
        ///
        /// The cursor alternates between visible and invisible at a fixed interval.
        case blink

        /// Smooth pulsing animation.
        ///
        /// The cursor color smoothly transitions between dim and bright,
        /// creating a gentle breathing effect. This is the default animation.
        case pulse
    }
}

// MARK: - Speed

extension TextCursorStyle {
    /// The speed of the cursor animation.
    ///
    /// Each speed defines specific cycle durations for blink and pulse animations,
    /// controlled by the ``CursorTimer``.
    public enum Speed: String, CaseIterable, Sendable {
        /// Slow animation.
        ///
        /// - Blink: 1000ms cycle (500ms on, 500ms off)
        /// - Pulse: 1200ms cycle (1.2 second breathing)
        case slow

        /// Regular animation (default).
        ///
        /// - Blink: 660ms cycle (330ms on, 330ms off)
        /// - Pulse: 800ms cycle (0.8 second breathing)
        case regular

        /// Fast animation.
        ///
        /// - Blink: 400ms cycle (200ms on, 200ms off)
        /// - Pulse: 500ms cycle (0.5 second breathing)
        case fast
    }
}

// MARK: - Convenience Initializers

extension TextCursorStyle {
    /// A block cursor with blink animation at regular speed (the default style).
    public static let block = TextCursorStyle(shape: .block, animation: .blink, speed: .regular)

    /// A bar cursor with blink animation at regular speed.
    public static let bar = TextCursorStyle(shape: .bar, animation: .blink, speed: .regular)

    /// An underscore cursor with blink animation at regular speed.
    public static let underscore = TextCursorStyle(shape: .underscore, animation: .blink, speed: .regular)
}

// MARK: - Environment Key

/// Environment key for the text cursor style.
private struct TextCursorStyleKey: EnvironmentKey {
    static let defaultValue = TextCursorStyle()
}

extension EnvironmentValues {
    /// The text cursor style for text fields.
    ///
    /// Set this value using the `.textCursor(_:)` modifier:
    ///
    /// ```swift
    /// TextField("Name", text: $name)
    ///     .textCursor(.bar, animation: .blink)
    /// ```
    public var textCursorStyle: TextCursorStyle {
        get { self[TextCursorStyleKey.self] }
        set { self[TextCursorStyleKey.self] = newValue }
    }
}

// MARK: - View Extension

extension View {
    /// Sets the text cursor style for text fields within this view.
    ///
    /// Use this modifier to customize the cursor appearance in ``TextField``
    /// and ``SecureField`` components.
    ///
    /// ```swift
    /// TextField("Name", text: $name)
    ///     .textCursor(.bar)
    /// ```
    ///
    /// - Parameter style: The cursor style to use.
    /// - Returns: A view with the cursor style applied.
    public func textCursor(_ style: TextCursorStyle) -> some View {
        environment(\.textCursorStyle, style)
    }

    /// Sets the text cursor style with separate shape, animation, and speed parameters.
    ///
    /// Use this modifier when you want to specify shape, animation, and speed:
    ///
    /// ```swift
    /// TextField("Code", text: $code)
    ///     .textCursor(.underscore, animation: .blink, speed: .fast)
    /// ```
    ///
    /// - Parameters:
    ///   - shape: The cursor shape.
    ///   - animation: The cursor animation. Defaults to `.pulse`.
    ///   - speed: The animation speed. Defaults to `.regular`.
    /// - Returns: A view with the cursor style applied.
    public func textCursor(
        _ shape: TextCursorStyle.Shape,
        animation: TextCursorStyle.Animation = .pulse,
        speed: TextCursorStyle.Speed = .regular
    ) -> some View {
        environment(\.textCursorStyle, TextCursorStyle(shape: shape, animation: animation, speed: speed))
    }
}

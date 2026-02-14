//  🖥️ TUIKit — Terminal UI Kit for Swift
//  Appearance.swift
//
//  Created by LAYERED.work
//  License: MIT
//  Appearance defines the visual style of controls (border style, etc.),
//  while Theme defines the colors. Together they create a complete look.
//


// MARK: - Appearance

/// Defines the visual appearance of UI controls.
///
/// `Appearance` controls the structural styling of UI elements like border styles,
/// while `Theme` controls the colors. Together they create a complete visual design.
///
/// # Usage
///
/// Set appearance at the app level:
///
/// ```swift
/// @main
/// struct MyApp: App {
///     var body: some Scene {
///         WindowGroup {
///             ContentView()
///         }
///         .appearance(.rounded)
///         .theme(.amber)
///     }
/// }
/// ```
///
/// Or override locally:
///
/// ```swift
/// Panel("Bold Section") {
///     content()
/// }
/// .appearance(.heavy)
/// ```
///
/// Access in `renderToBuffer(context:)`:
///
/// ```swift
/// let appearance = context.environment.appearance
/// let style = appearance.borderStyle
/// ```
public struct Appearance: Cyclable, Equatable {
    /// Unique identifier for the appearance (conforms to ``Cyclable``).
    public var id: String { rawId.rawValue }

    /// The type-safe identifier.
    public let rawId: ID

    /// The border style used for all controls.
    public let borderStyle: BorderStyle

    /// Creates a custom appearance.
    ///
    /// - Parameters:
    ///   - id: The unique identifier.
    ///   - borderStyle: The border style to use for controls.
    public init(id: ID, borderStyle: BorderStyle) {
        self.rawId = id
        self.borderStyle = borderStyle
    }

    /// Human-readable name derived from ID (conforms to ``Cyclable``).
    public var name: String {
        rawId.rawValue.capitalized
    }

    /// Equatable conformance based on the type-safe ID.
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.rawId == rhs.rawId && lhs.borderStyle == rhs.borderStyle
    }
}

// MARK: - Appearance ID

extension Appearance {
    /// Type-safe identifier for appearances.
    ///
    /// IDs match `BorderStyle` names for consistency.
    ///
    /// ```swift
    /// // Predefined (matching BorderStyle names)
    /// Appearance.ID.line
    /// Appearance.ID.rounded
    /// Appearance.ID.doubleLine
    ///
    /// // Custom
    /// extension Appearance.ID {
    ///     static let myCustom = ID(rawValue: "my-custom")
    /// }
    /// ```
    public struct ID: RawRepresentable, Hashable, Sendable {
        /// The string identifier for this appearance.
        public let rawValue: String

        /// Creates an appearance ID from a raw string value.
        ///
        /// - Parameter rawValue: The string identifier.
        public init(rawValue: String) {
            self.rawValue = rawValue
        }

        /// Single line borders (┌─┐).
        public static let line = Self(rawValue: "line")

        /// Rounded corners (╭─╮).
        public static let rounded = Self(rawValue: "rounded")

        /// Double-line borders (╔═╗).
        public static let doubleLine = Self(rawValue: "doubleLine")

        /// Heavy/bold borders (┏━┓).
        public static let heavy = Self(rawValue: "heavy")
    }
}

// MARK: - Predefined Appearances

extension Appearance {
    /// Single line borders.
    ///
    /// Uses `BorderStyle.line` with standard box-drawing characters.
    public static let line = Appearance(id: .line, borderStyle: .line)

    /// Rounded corners (default).
    ///
    /// Uses `BorderStyle.rounded` with curved corner characters.
    public static let rounded = Appearance(id: .rounded, borderStyle: .rounded)

    /// Double-line borders.
    ///
    /// Uses `BorderStyle.doubleLine` for a more prominent look.
    public static let doubleLine = Appearance(id: .doubleLine, borderStyle: .doubleLine)

    /// Heavy/bold borders.
    ///
    /// Uses `BorderStyle.heavy` for bold, prominent borders.
    public static let heavy = Appearance(id: .heavy, borderStyle: .heavy)

    /// The default appearance (rounded).
    public static let `default`: Appearance = .rounded
}

// MARK: - Appearance Registry

/// Registry of available appearances for cycling.
public struct AppearanceRegistry {
    /// All available appearances in cycling order.
    ///
    /// Order: rounded (default) → line → doubleLine → heavy
    public static let all: [Appearance] = [
        .rounded,
        .line,
        .doubleLine,
        .heavy,
    ]

    /// Finds an appearance by ID.
    ///
    /// - Parameter id: The appearance ID to find.
    /// - Returns: The appearance, or nil if not found.
    public static func appearance(withId id: Appearance.ID) -> Appearance? {
        all.first { $0.rawId == id }
    }
}

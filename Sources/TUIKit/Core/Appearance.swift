//
//  Appearance.swift
//  TUIKit
//
//  Appearance system for consistent UI control styling.
//
//  Appearance defines the visual style of controls (border style, etc.),
//  while Theme defines the colors. Together they create a complete look.
//

import Foundation

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
/// Panel("Retro Section") {
///     content()
/// }
/// .appearance(.ascii)
/// ```
///
/// Access in views:
///
/// ```swift
/// @Environment(\.appearance) var appearance
/// let style = appearance.borderStyle
/// ```
public struct Appearance: Sendable, Equatable {
    /// Unique identifier for the appearance.
    public let id: ID
    
    /// The border style used for all controls.
    public let borderStyle: BorderStyle
    
    /// Creates a custom appearance.
    ///
    /// - Parameters:
    ///   - id: The unique identifier.
    ///   - borderStyle: The border style to use for controls.
    public init(id: ID, borderStyle: BorderStyle) {
        self.id = id
        self.borderStyle = borderStyle
    }
    
    /// Human-readable name derived from ID.
    public var name: String {
        id.rawValue.capitalized
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
        public let rawValue: String
        
        public init(rawValue: String) {
            self.rawValue = rawValue
        }
        
        /// Single line borders (┌─┐).
        public static let line = ID(rawValue: "line")
        
        /// Rounded corners (╭─╮).
        public static let rounded = ID(rawValue: "rounded")
        
        /// Double-line borders (╔═╗).
        public static let doubleLine = ID(rawValue: "doubleLine")
        
        /// Heavy/bold borders (┏━┓).
        public static let heavy = ID(rawValue: "heavy")
        
        /// Block/solid borders (███).
        public static let block = ID(rawValue: "block")
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
    
    /// Block/solid borders.
    ///
    /// Uses `BorderStyle.block` with solid block characters.
    public static let block = Appearance(id: .block, borderStyle: .block)
    
    /// The default appearance (rounded).
    public static let `default`: Appearance = .rounded
}

// MARK: - Appearance Registry

/// Registry of available appearances for cycling.
public struct AppearanceRegistry {
    /// All available appearances in cycling order.
    ///
    /// Order: line → rounded → doubleLine → heavy → block
    public static let all: [Appearance] = [
        .line,
        .rounded,
        .doubleLine,
        .heavy,
        .block
    ]
    
    /// Finds an appearance by ID.
    ///
    /// - Parameter id: The appearance ID to find.
    /// - Returns: The appearance, or nil if not found.
    public static func appearance(withId id: Appearance.ID) -> Appearance? {
        all.first { $0.id == id }
    }
}

// MARK: - Appearance Environment Key

/// Environment key for the current appearance.
private struct AppearanceKey: EnvironmentKey {
    static let defaultValue: Appearance = .default
}

extension EnvironmentValues {
    /// The current appearance.
    ///
    /// Set an appearance at the app level and it propagates to all child views:
    ///
    /// ```swift
    /// WindowGroup {
    ///     ContentView()
    /// }
    /// .appearance(.rounded)
    /// ```
    ///
    /// Access the appearance in views:
    ///
    /// ```swift
    /// @Environment(\.appearance) var appearance
    /// let borderStyle = appearance.borderStyle
    /// ```
    public var appearance: Appearance {
        get { self[AppearanceKey.self] }
        set { self[AppearanceKey.self] = newValue }
    }
}

// MARK: - Appearance Manager

/// Manages appearance cycling for the application.
///
/// `AppearanceManager` provides methods to cycle through available appearances
/// and set specific ones. It works with the environment system to update
/// the current appearance and trigger re-renders.
///
/// # Usage
///
/// Access via environment:
///
/// ```swift
/// @Environment(\.appearanceManager) var appearanceManager
///
/// // Cycle to the next appearance
/// appearanceManager.cycleAppearance()
///
/// // Set a specific appearance
/// appearanceManager.setAppearance(.ascii)
///
/// // Get the current appearance
/// let appearance = appearanceManager.currentAppearance
/// ```
public final class AppearanceManager: @unchecked Sendable {
    /// The current appearance index.
    private var currentIndex: Int = 0
    
    /// All available appearances.
    public let availableAppearances: [Appearance]
    
    /// Creates a new appearance manager with the default appearances.
    public init() {
        self.availableAppearances = AppearanceRegistry.all
    }
    
    /// Creates a new appearance manager with custom appearances.
    ///
    /// - Parameter appearances: The appearances to cycle through.
    public init(appearances: [Appearance]) {
        self.availableAppearances = appearances.isEmpty ? AppearanceRegistry.all : appearances
    }
    
    /// The current appearance.
    public var currentAppearance: Appearance {
        availableAppearances[currentIndex]
    }
    
    /// The name of the current appearance.
    public var currentAppearanceName: String {
        currentAppearance.name
    }
    
    /// Cycles to the next appearance.
    ///
    /// Updates the environment and triggers a re-render.
    public func cycleAppearance() {
        currentIndex = (currentIndex + 1) % availableAppearances.count
        applyCurrentAppearance()
    }
    
    /// Cycles to the previous appearance.
    ///
    /// Updates the environment and triggers a re-render.
    public func cyclePreviousAppearance() {
        currentIndex = (currentIndex - 1 + availableAppearances.count) % availableAppearances.count
        applyCurrentAppearance()
    }
    
    /// Sets a specific appearance.
    ///
    /// - Parameter appearance: The appearance to set.
    ///
    /// # Example
    ///
    /// ```swift
    /// appearanceManager.setAppearance(.ascii)
    /// appearanceManager.setAppearance(.rounded)
    /// ```
    public func setAppearance(_ appearance: Appearance) {
        if let index = availableAppearances.firstIndex(where: { $0.id == appearance.id }) {
            currentIndex = index
        }
        // If appearance is not in availableAppearances, currentIndex stays unchanged.
        // Only apply appearances that are in the available list to keep
        // currentAppearance and environment in sync.
        applyCurrentAppearance()
    }
    
    /// Applies the current appearance to the environment and triggers a re-render.
    private func applyCurrentAppearance() {
        var environment = EnvironmentStorage.shared.environment
        environment.appearance = currentAppearance
        EnvironmentStorage.shared.environment = environment
        AppState.shared.setNeedsRender()
    }
}

// MARK: - AppearanceManager Environment Key

/// Environment key for the appearance manager.
private struct AppearanceManagerKey: EnvironmentKey {
    static let defaultValue: AppearanceManager = AppearanceManager()
}

extension EnvironmentValues {
    /// The appearance manager for cycling and setting appearances.
    ///
    /// ```swift
    /// @Environment(\.appearanceManager) var appearanceManager
    ///
    /// appearanceManager.cycleAppearance()
    /// appearanceManager.setAppearance(.ascii)
    /// ```
    public var appearanceManager: AppearanceManager {
        get { self[AppearanceManagerKey.self] }
        set { self[AppearanceManagerKey.self] = newValue }
    }
}

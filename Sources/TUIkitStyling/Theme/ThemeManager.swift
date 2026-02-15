//  🖥️ TUIKit — Terminal UI Kit for Swift
//  ThemeManager.swift
//
//  Created by LAYERED.work
//  License: MIT  Replaces the previously duplicated palette manager and appearance manager
//  with a single, reusable implementation.
//

// MARK: - Cyclable Protocol

/// A type that can be managed and cycled through by a `ThemeManager`.
///
/// Conforming types provide a unique identifier and a display name,
/// enabling the `ThemeManager` to cycle, look up, and display items.
///
/// Both ``Palette`` (color palettes) and ``Appearance`` (border styles)
/// conform to this protocol.
///
/// # Example
///
/// ```swift
/// struct MyStyle: Cyclable {
///     let id: String
///     var name: String { id.capitalized }
/// }
/// ```
public protocol Cyclable: Sendable {
    /// The unique identifier for this item.
    var id: String { get }

    /// A human-readable display name.
    var name: String { get }
}

// MARK: - Theme Manager

/// A manager for cycling through a collection of ``Cyclable`` items.
///
/// `ThemeManager` provides methods to cycle forward/backward through items,
/// set a specific item by reference, and apply the current selection.
///
/// TUIkit uses two instances:
/// - A `PaletteManager` for color palettes
/// - An `AppearanceManager` for border-style appearances
///
/// # Usage
///
/// ```swift
/// // Access the palette manager via context.environment
/// let paletteManager = context.environment.paletteManager
/// paletteManager.cycleNext()
/// paletteManager.setCurrent(SystemPalette(.amber))
/// let name = paletteManager.currentName
/// ```
///
/// # Render Integration
///
/// On every change the manager triggers a re-render through the
/// injected render trigger closure. The `RenderLoop` picks up the
/// current item via ``currentPalette`` / ``currentAppearance`` when
/// building the environment for the next frame.
public final class ThemeManager: @unchecked Sendable {
    /// The current item index.
    private var currentIndex: Int = 0

    /// All available items in cycling order.
    public let items: [any Cyclable]

    /// Closure that triggers a re-render when the theme changes.
    private let renderTrigger: @Sendable () -> Void

    /// Creates a theme manager with the given items.
    ///
    /// - Parameters:
    ///   - items: The items to cycle through. Must not be empty.
    ///   - renderTrigger: A closure that triggers a re-render when the selection changes.
    public init(items: [any Cyclable], renderTrigger: @escaping @Sendable () -> Void) {
        precondition(!items.isEmpty, "ThemeManager requires at least one item")
        self.items = items
        self.renderTrigger = renderTrigger
    }

    /// Creates a theme manager with a no-op render trigger.
    ///
    /// Used for environment key defaults only.
    public convenience init(items: [any Cyclable]) {
        self.init(items: items, renderTrigger: {})
    }

    // MARK: - Current Item

    /// The currently selected item.
    public var current: any Cyclable {
        items[currentIndex]
    }

    /// The display name of the currently selected item.
    public var currentName: String {
        current.name
    }
}

// MARK: - Public API

public extension ThemeManager {
    /// Cycles to the next item.
    ///
    /// Wraps around to the first item after the last.
    /// Updates the environment and triggers a re-render.
    func cycleNext() {
        currentIndex = (currentIndex + 1) % items.count
        applyCurrentItem()
    }

    /// Cycles to the previous item.
    ///
    /// Wraps around to the last item before the first.
    /// Updates the environment and triggers a re-render.
    func cyclePrevious() {
        currentIndex = (currentIndex - 1 + items.count) % items.count
        applyCurrentItem()
    }

    /// Sets a specific item as the current selection.
    ///
    /// If the item is not found in the available items (matched by `id`),
    /// the current selection remains unchanged.
    /// Updates the environment and triggers a re-render.
    ///
    /// - Parameter item: The item to select.
    func setCurrent(_ item: any Cyclable) {
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            currentIndex = index
        }
        applyCurrentItem()
    }
}

// MARK: - Private Helpers

private extension ThemeManager {
    /// Triggers a re-render so the `RenderLoop` picks up the new current item.
    func applyCurrentItem() {
        renderTrigger()
    }
}

// MARK: - Typed Accessors

extension ThemeManager {
    /// The current item cast to a specific ``Palette``.
    ///
    /// Use this on the palette manager to get a strongly-typed palette.
    /// Returns `nil` if the manager does not hold ``Palette`` items.
    public var currentPalette: (any Palette)? {
        current as? any Palette
    }

    /// The current item cast to ``Appearance``.
    ///
    /// Use this on the appearance manager to get a strongly-typed appearance.
    /// Returns `nil` if the manager does not hold ``Appearance`` items.
    public var currentAppearance: Appearance? {
        current as? Appearance
    }
}

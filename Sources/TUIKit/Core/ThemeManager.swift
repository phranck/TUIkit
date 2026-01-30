//
//  ThemeManager.swift
//  TUIKit
//
//  Generic manager for cycling through items that conform to `Cyclable`.
//  Replaces the previously duplicated palette manager and appearance manager
//  with a single, reusable implementation.
//

import Foundation

// MARK: - Cyclable Protocol

/// A type that can be managed and cycled through by a ``ThemeManager``.
///
/// Conforming types provide a unique identifier and a display name,
/// enabling the ``ThemeManager`` to cycle, look up, and display items.
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
/// set a specific item by reference, and apply the current selection to the
/// environment so all views pick up the change.
///
/// TUIKit uses two instances:
/// - A ``PaletteManager`` for color palettes
/// - An ``AppearanceManager`` for border-style appearances
///
/// # Usage
///
/// ```swift
/// // Access the palette manager via the environment
/// @Environment(\.paletteManager) var paletteManager
///
/// paletteManager.cycleNext()
/// paletteManager.setCurrent(AmberPhosphorPalette())
/// let name = paletteManager.currentName
/// ```
///
/// # Environment Integration
///
/// On every change the manager writes the current item into
/// `EnvironmentStorage.shared` via the closure provided at init,
/// then triggers a re-render through `AppState.shared.setNeedsRender()`.
public final class ThemeManager: @unchecked Sendable {
    /// The current item index.
    private var currentIndex: Int = 0

    /// All available items in cycling order.
    public let items: [any Cyclable]

    /// Closure that writes the current item into the environment.
    private let applyToEnvironment: @Sendable (any Cyclable) -> Void

    /// Creates a theme manager with the given items and environment binding.
    ///
    /// - Parameters:
    ///   - items: The items to cycle through. Must not be empty.
    ///   - applyToEnvironment: A closure that writes the current item
    ///     into `EnvironmentStorage.shared.environment`.
    public init(items: [any Cyclable], applyToEnvironment: @escaping @Sendable (any Cyclable) -> Void) {
        precondition(!items.isEmpty, "ThemeManager requires at least one item")
        self.items = items
        self.applyToEnvironment = applyToEnvironment
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

    // MARK: - Cycling

    /// Cycles to the next item.
    ///
    /// Wraps around to the first item after the last.
    /// Updates the environment and triggers a re-render.
    public func cycleNext() {
        currentIndex = (currentIndex + 1) % items.count
        applyCurrentItem()
    }

    /// Cycles to the previous item.
    ///
    /// Wraps around to the last item before the first.
    /// Updates the environment and triggers a re-render.
    public func cyclePrevious() {
        currentIndex = (currentIndex - 1 + items.count) % items.count
        applyCurrentItem()
    }

    // MARK: - Direct Selection

    /// Sets a specific item as the current selection.
    ///
    /// If the item is not found in the available items (matched by `id`),
    /// the current selection remains unchanged.
    /// Updates the environment and triggers a re-render.
    ///
    /// - Parameter item: The item to select.
    public func setCurrent(_ item: any Cyclable) {
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            currentIndex = index
        }
        applyCurrentItem()
    }

    // MARK: - Apply

    /// Applies the current item to the environment and triggers a re-render.
    private func applyCurrentItem() {
        applyToEnvironment(current)
        AppState.shared.setNeedsRender()
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

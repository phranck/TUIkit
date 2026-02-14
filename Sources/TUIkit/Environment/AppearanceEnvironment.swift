//  🖥️ TUIKit — Terminal UI Kit for Swift
//  AppearanceEnvironment.swift
//
//  Created by LAYERED.work
//  License: MIT

import TUIkitStyling

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
    /// Access the appearance in `renderToBuffer(context:)`:
    ///
    /// ```swift
    /// let appearance = context.environment.appearance
    /// let borderStyle = appearance.borderStyle
    /// ```
    public var appearance: Appearance {
        get { self[AppearanceKey.self] }
        set { self[AppearanceKey.self] = newValue }
    }
}

// MARK: - AppearanceManager Environment Key

/// Environment key for the appearance manager.
private struct AppearanceManagerKey: EnvironmentKey {
    static let defaultValue = ThemeManager(items: AppearanceRegistry.all)
}

extension EnvironmentValues {
    /// The appearance manager for cycling and setting appearances.
    ///
    /// ```swift
    /// let appearanceManager = context.environment.appearanceManager
    /// appearanceManager.cycleNext()
    /// appearanceManager.setCurrent(Appearance.rounded)
    /// ```
    public var appearanceManager: ThemeManager {
        get { self[AppearanceManagerKey.self] }
        set { self[AppearanceManagerKey.self] = newValue }
    }
}

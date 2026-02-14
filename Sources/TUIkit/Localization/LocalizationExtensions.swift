//  🖥️ TUIKit — Terminal UI Kit for Swift
//  LocalizationExtensions.swift
//
//  Created by LAYERED.work
//  License: MIT

// MARK: - Text Localization Convenience

extension Text {
    /// Creates a text view with a localized string using a dot-notation key.
    ///
    /// # Example
    ///
    /// ```swift
    /// Text(localized: "button.ok")
    /// ```
    ///
    /// This is an alternative to `LocalizedString("button.ok")` for cases where
    /// you need a `Text` view directly (e.g., as a return value from a computed property).
    ///
    /// - Parameter key: The dot-notation key for the localized string.
    public init(localized key: String) {
        let localizedValue = LocalizationService.shared.string(for: key)
        self.init(localizedValue)
    }
}

// MARK: - AppState Language Convenience

extension AppState {
    /// Gets the currently active language.
    public var currentLanguage: LocalizationService.Language {
        LocalizationService.shared.currentLanguage
    }

    /// Changes the active language and triggers a re-render.
    ///
    /// The language preference is persisted to disk and will survive app restarts.
    /// The UI automatically re-renders with the new language strings.
    ///
    /// # Example
    ///
    /// ```swift
    /// AppState.shared.setLanguage(.german)
    /// ```
    ///
    /// - Parameter language: The language to activate.
    public func setLanguage(_ language: LocalizationService.Language) {
        LocalizationService.shared.setLanguage(language)
    }
}

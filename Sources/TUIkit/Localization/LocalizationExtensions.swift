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
        let localizationService = StateRegistration.currentEnvironment?.localizationService
            ?? LocalizationService.transient()
        let localizedValue = localizationService.string(for: key)
        self.init(localizedValue)
    }
}

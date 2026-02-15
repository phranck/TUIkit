//  🖥️ TUIKit — Terminal UI Kit for Swift
//  LocalizedString.swift
//
//  Created by LAYERED.work
//  License: MIT

// MARK: - Localized String View

/// A view that displays a localized string using a dot-notation key.
///
/// The string is looked up in the current language from the localization service.
/// If the key is missing, falls back to English, then to the key itself.
///
/// # Example
///
/// ```swift
/// VStack {
///     LocalizedString("button.ok")
///     LocalizedString("error.invalid_input")
/// }
/// ```
///
/// Use this for all UI strings that need localization.
public struct LocalizedString: View {
    /// The dot-notation key for the string to display.
    private let key: String

    /// Creates a localized string view.
    ///
    /// - Parameter key: The dot-notation key (e.g., "button.ok", "error.invalid_input")
    public init(_ key: String) {
        self.key = key
    }

    public var body: some View {
        Text(LocalizationService.shared.string(for: key))
    }
}

//  🖥️ TUIKit — Terminal UI Kit for Swift
//  TextContentType.swift
//
//  Created by LAYERED.work
//  License: MIT

import Foundation

// MARK: - TextContentType

/// Declares the semantic content type of a text field and filters input accordingly.
///
/// In SwiftUI, `UITextContentType` provides autofill hints to the system.
/// In a TUI there is no autofill, so `TextContentType` instead defines an
/// **allowed character set** for input filtering. Both typed characters and
/// pasted text are filtered against the allowed set; invalid characters are
/// silently dropped.
///
/// ## Usage
///
/// ```swift
/// // Only allow URL-valid characters
/// TextField("URL", text: $url)
///     .textContentType(.url)
///
/// // Only allow digits
/// TextField("Code", text: $code)
///     .textContentType(.oneTimeCode)
///
/// // Apply to all fields in a container
/// VStack {
///     TextField("User", text: $user)
///     SecureField("Password", text: $pass)
/// }
/// .textContentType(.username)
/// ```
///
/// ## Character Filtering
///
/// | Type              | Allowed Characters                            |
/// |-------------------|-----------------------------------------------|
/// | `url`             | Alphanumeric, `:/.?#[]@!$&'()*+,;=-_~%`       |
/// | `emailAddress`    | Alphanumeric, `@._+-`                         |
/// | `telephoneNumber` | `0-9`, `+()-. #*`, space                      |
/// | `username`        | Alphanumeric, `._-@`                          |
/// | `password`        | All characters (no filtering)                 |
/// | `oneTimeCode`     | `0-9`                                         |
/// | `integer`         | `0-9`, `-`                                    |
/// | `decimal`         | `0-9`, `-.`                                   |
public enum TextContentType: Sendable, Equatable {
    /// URL input. Allows alphanumeric characters and URL-safe punctuation.
    case url

    /// Email address input. Allows alphanumeric characters, `@`, `.`, `_`, `+`, `-`.
    case emailAddress

    /// Telephone number input. Allows digits, `+`, `(`, `)`, `-`, `.`, `#`, `*`, space.
    case telephoneNumber

    /// Username input. Allows alphanumeric characters, `.`, `_`, `-`, `@`.
    case username

    /// Password input. Allows all characters (no filtering).
    case password

    /// One-time code input. Allows digits only.
    case oneTimeCode

    /// Integer input. Allows digits and `-` for negative numbers.
    case integer

    /// Decimal number input. Allows digits, `-`, and `.` for fractional numbers.
    case decimal
}

// MARK: - Character Filtering

extension TextContentType {
    /// The set of Unicode scalars allowed for this content type.
    ///
    /// `.password` returns `nil` to indicate no filtering.
    var allowedCharacters: CharacterSet? {
        switch self {
        case .url:
            return Self.urlCharacters
        case .emailAddress:
            return Self.emailCharacters
        case .telephoneNumber:
            return Self.phoneCharacters
        case .username:
            return Self.usernameCharacters
        case .password:
            return nil
        case .oneTimeCode:
            return Self.digitCharacters
        case .integer:
            return Self.integerCharacters
        case .decimal:
            return Self.decimalCharacters
        }
    }

    /// Whether the given character is allowed by this content type.
    ///
    /// - Parameter character: The character to check.
    /// - Returns: `true` if the character passes the filter, or if this type
    ///   has no filter (`.password`).
    func isAllowed(_ character: Character) -> Bool {
        guard let allowed = allowedCharacters else { return true }
        return character.unicodeScalars.allSatisfy { allowed.contains($0) }
    }

    /// Filters a string, keeping only characters allowed by this content type.
    ///
    /// - Parameter string: The input string to filter.
    /// - Returns: A new string containing only the allowed characters.
    func filterString(_ string: String) -> String {
        guard allowedCharacters != nil else { return string }
        return String(string.filter { isAllowed($0) })
    }
}

// MARK: - Character Set Definitions

private extension TextContentType {
    /// URL-safe characters per RFC 3986.
    static let urlCharacters: CharacterSet = {
        var set = CharacterSet.alphanumerics
        set.insert(charactersIn: ":/.?#[]@!$&'()*+,;=-_~%")
        return set
    }()

    /// Email address characters.
    static let emailCharacters: CharacterSet = {
        var set = CharacterSet.alphanumerics
        set.insert(charactersIn: "@._+-")
        return set
    }()

    /// Telephone number characters.
    static let phoneCharacters: CharacterSet = {
        var set = CharacterSet(charactersIn: "0123456789")
        set.insert(charactersIn: "+()-. #*")
        set.insert(charactersIn: " ")
        return set
    }()

    /// Username characters.
    static let usernameCharacters: CharacterSet = {
        var set = CharacterSet.alphanumerics
        set.insert(charactersIn: "._-@")
        return set
    }()

    /// Digits only.
    static let digitCharacters = CharacterSet(charactersIn: "0123456789")

    /// Integer characters (digits and minus sign).
    static let integerCharacters = CharacterSet(charactersIn: "0123456789-")

    /// Decimal characters (digits, minus sign, and decimal point).
    static let decimalCharacters = CharacterSet(charactersIn: "0123456789-.")
}

// MARK: - Environment Key

/// Environment key for the text content type.
private struct TextContentTypeKey: EnvironmentKey {
    static let defaultValue: TextContentType? = nil
}

extension EnvironmentValues {
    /// The text content type for text fields.
    ///
    /// When set, text fields filter both typed characters and pasted text
    /// against the allowed character set of the content type.
    ///
    /// Set this value using the `.textContentType(_:)` modifier:
    ///
    /// ```swift
    /// TextField("URL", text: $url)
    ///     .textContentType(.url)
    /// ```
    public var textContentType: TextContentType? {
        get { self[TextContentTypeKey.self] }
        set { self[TextContentTypeKey.self] = newValue }
    }
}

// MARK: - View Extension

extension View {
    /// Sets the text content type for text fields within this view.
    ///
    /// When a content type is set, both typed characters and pasted text
    /// are filtered against the allowed character set. Invalid characters
    /// are silently dropped.
    ///
    /// ```swift
    /// TextField("URL", text: $url)
    ///     .textContentType(.url)
    /// ```
    ///
    /// - Parameter type: The content type, or `nil` to disable filtering.
    /// - Returns: A view with the content type applied.
    public func textContentType(_ type: TextContentType?) -> some View {
        environment(\.textContentType, type)
    }
}

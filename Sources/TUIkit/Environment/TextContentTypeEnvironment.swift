//  🖥️ TUIKit — Terminal UI Kit for Swift
//  TextContentTypeEnvironment.swift
//
//  Created by LAYERED.work
//  License: MIT

import TUIkitStyling

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

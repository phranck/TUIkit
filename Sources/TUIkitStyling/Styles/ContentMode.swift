//  🖥️ TUIKit — Terminal UI Kit for Swift
//  ContentMode.swift
//
//  Created by LAYERED.work
//  License: MIT


// MARK: - ContentMode

/// Constants that define how a view's content fills the available space.
///
/// Use `ContentMode` with the ``View/aspectRatio(_:contentMode:)`` modifier
/// to control how an image or other content is scaled within its bounds.
///
/// - ``fit``: Scales content to fit within the bounds while preserving
///   the aspect ratio. The content may not fill the entire available space.
/// - ``fill``: Scales content to fill the bounds while preserving
///   the aspect ratio. The content may extend beyond the available space.
///
/// ## Usage
///
/// ```swift
/// Image(.file("photo.png"))
///     .aspectRatio(contentMode: .fit)
///
/// Image(.url("https://example.com/photo.png"))
///     .aspectRatio(16.0/9.0, contentMode: .fill)
/// ```
public enum ContentMode: Sendable, Equatable {
    /// Scales content to fit within the parent by maintaining the
    /// aspect ratio. The resulting dimensions are always within bounds.
    case fit

    /// Scales content to fill the parent by maintaining the aspect ratio.
    /// The content may extend beyond the bounds along one dimension.
    case fill
}

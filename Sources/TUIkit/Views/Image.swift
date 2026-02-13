//  🖥️ TUIKit — Terminal UI Kit for Swift
//  Image.swift
//
//  Created by LAYERED.work
//  License: MIT

import Foundation

// MARK: - Image Source

/// Describes where to load an image from.
public enum ImageSource: Sendable, Equatable {
    /// Load from a local file path.
    case file(String)

    /// Load from a URL (cached per session).
    case url(String)
}

// MARK: - Image Loading Phase

/// Represents the current state of an async image loading operation.
enum ImageLoadingPhase: Sendable {
    /// Loading has not started yet or is in progress.
    case loading

    /// The raw image was successfully loaded and is ready for conversion.
    case success(RGBAImage)

    /// Loading failed with an error.
    case failure(String)
}

// MARK: - Image

/// Displays an image as colored ASCII art in the terminal.
///
/// `Image` loads a raster image from a file path or URL, converts it to
/// colored ASCII characters, and displays it at the specified size.
/// Loading happens asynchronously; a placeholder is shown while loading.
///
/// ## Usage
///
/// ```swift
/// // From a local file
/// Image(.file("/path/to/logo.png"))
///     .frame(width: 60, height: 30)
///
/// // From a URL (cached per session)
/// Image(.url("https://example.com/photo.png"))
///     .frame(width: 40, height: 20)
///
/// // With rendering options
/// Image(.file("photo.png"))
///     .imageCharacterSet(.braille)
///     .imageColorMode(.trueColor)
///     .imageDithering(.floydSteinberg)
///     .frame(width: 80, height: 40)
/// ```
///
/// ## Placeholder
///
/// While loading, a centered placeholder is displayed. By default this is
/// a ``Spinner``. Use ``View/imagePlaceholder(_:)`` to customize.
public struct Image: View {
    /// The image source (file path or URL).
    let source: ImageSource

    /// Creates an image from the given source.
    ///
    /// - Parameter source: The image source (file or URL).
    public init(_ source: ImageSource) {
        self.source = source
    }

    public var body: some View {
        _ImageCore(source: source)
    }
}

// MARK: - Equatable

extension Image: Equatable {
    nonisolated public static func == (lhs: Image, rhs: Image) -> Bool {
        lhs.source == rhs.source
    }
}

// MARK: - Environment Keys

/// Environment key for the ASCII character set used by Image.
private struct ImageCharacterSetKey: EnvironmentKey {
    static let defaultValue: ASCIICharacterSet = .blocks
}

/// Environment key for the color mode used by Image.
private struct ImageColorModeKey: EnvironmentKey {
    static let defaultValue: ASCIIColorMode = .trueColor
}

/// Environment key for the dithering mode used by Image.
private struct ImageDitheringKey: EnvironmentKey {
    static let defaultValue: DitheringMode = .none
}

/// Environment key for the placeholder text shown while loading.
private struct ImagePlaceholderTextKey: EnvironmentKey {
    static let defaultValue: String? = nil
}

/// Environment key controlling whether a spinner is shown while loading.
private struct ImagePlaceholderSpinnerKey: EnvironmentKey {
    static let defaultValue: Bool = true
}

/// Environment key for the image content mode.
private struct ImageContentModeKey: EnvironmentKey {
    static let defaultValue: ContentMode = .fit
}

/// Environment key for an explicit aspect ratio override.
private struct ImageAspectRatioKey: EnvironmentKey {
    static let defaultValue: Double? = nil
}

// MARK: - EnvironmentValues

extension EnvironmentValues {
    /// The character set for ASCII art rendering.
    var imageCharacterSet: ASCIICharacterSet {
        get { self[ImageCharacterSetKey.self] }
        set { self[ImageCharacterSetKey.self] = newValue }
    }

    /// The color mode for ASCII art rendering.
    var imageColorMode: ASCIIColorMode {
        get { self[ImageColorModeKey.self] }
        set { self[ImageColorModeKey.self] = newValue }
    }

    /// The dithering mode for ASCII art rendering.
    var imageDithering: DitheringMode {
        get { self[ImageDitheringKey.self] }
        set { self[ImageDitheringKey.self] = newValue }
    }

    /// Custom placeholder text shown while loading (nil = no text).
    var imagePlaceholderText: String? {
        get { self[ImagePlaceholderTextKey.self] }
        set { self[ImagePlaceholderTextKey.self] = newValue }
    }

    /// Whether to show a spinner in the placeholder.
    var imagePlaceholderSpinner: Bool {
        get { self[ImagePlaceholderSpinnerKey.self] }
        set { self[ImagePlaceholderSpinnerKey.self] = newValue }
    }

    /// The content mode for image scaling.
    var imageContentMode: ContentMode {
        get { self[ImageContentModeKey.self] }
        set { self[ImageContentModeKey.self] = newValue }
    }

    /// An explicit aspect ratio override for images (width/height).
    ///
    /// When `nil`, the source image's natural aspect ratio is used.
    var imageAspectRatio: Double? {
        get { self[ImageAspectRatioKey.self] }
        set { self[ImageAspectRatioKey.self] = newValue }
    }
}

// MARK: - View Modifiers

extension View {

    /// Sets the character set for ASCII art image rendering.
    ///
    /// - Parameter characterSet: The character set to use.
    /// - Returns: A modified view.
    public func imageCharacterSet(_ characterSet: ASCIICharacterSet) -> some View {
        environment(\.imageCharacterSet, characterSet)
    }

    /// Sets the color mode for ASCII art image rendering.
    ///
    /// - Parameter colorMode: The color mode to use.
    /// - Returns: A modified view.
    public func imageColorMode(_ colorMode: ASCIIColorMode) -> some View {
        environment(\.imageColorMode, colorMode)
    }

    /// Sets the dithering mode for ASCII art image rendering.
    ///
    /// - Parameter dithering: The dithering algorithm.
    /// - Returns: A modified view.
    public func imageDithering(_ dithering: DitheringMode) -> some View {
        environment(\.imageDithering, dithering)
    }

    /// Sets the placeholder text shown while an image is loading.
    ///
    /// - Parameter text: The placeholder text, or nil for no text.
    /// - Returns: A modified view.
    public func imagePlaceholder(_ text: String?) -> some View {
        environment(\.imagePlaceholderText, text)
    }

    /// Controls whether a spinner is shown while an image is loading.
    ///
    /// - Parameter showSpinner: Whether to show a spinner.
    /// - Returns: A modified view.
    public func imagePlaceholderSpinner(_ showSpinner: Bool) -> some View {
        environment(\.imagePlaceholderSpinner, showSpinner)
    }

    /// Sets the aspect ratio and content mode for image rendering.
    ///
    /// Use this modifier to control how images are scaled within their
    /// available space.
    ///
    /// ```swift
    /// // Use natural aspect ratio, fit within bounds
    /// Image(.file("photo.png"))
    ///     .aspectRatio(contentMode: .fit)
    ///
    /// // Force 16:9 ratio, fill bounds
    /// Image(.url("https://example.com/banner.png"))
    ///     .aspectRatio(16.0/9.0, contentMode: .fill)
    /// ```
    ///
    /// - Parameters:
    ///   - aspectRatio: The ratio of width to height to use for the
    ///     resulting view. Use `nil` to maintain the source image's
    ///     natural aspect ratio.
    ///   - contentMode: A flag that indicates whether this view fits or
    ///     fills the parent context.
    /// - Returns: A view that constrains this view's dimensions to the
    ///   given aspect ratio and content mode.
    public func aspectRatio(_ aspectRatio: Double? = nil, contentMode: ContentMode) -> some View {
        environment(\.imageContentMode, contentMode)
            .environment(\.imageAspectRatio, aspectRatio)
    }

    /// Scales this view to fit within the parent while maintaining the
    /// aspect ratio.
    ///
    /// Equivalent to `.aspectRatio(contentMode: .fit)`.
    ///
    /// - Returns: A view that scales to fit.
    public func scaledToFit() -> some View {
        aspectRatio(contentMode: .fit)
    }

    /// Scales this view to fill the parent while maintaining the
    /// aspect ratio.
    ///
    /// Equivalent to `.aspectRatio(contentMode: .fill)`.
    ///
    /// - Returns: A view that scales to fill.
    public func scaledToFill() -> some View {
        aspectRatio(contentMode: .fill)
    }
}

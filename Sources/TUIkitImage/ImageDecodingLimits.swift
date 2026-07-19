//  🖥️ TUIKit — Terminal UI Kit for Swift
//  ImageDecodingLimits.swift
//
//  Created by LAYERED.work
//  License: MIT

/// Resource limits applied before image decoding begins.
public struct ImageDecodingLimits: Sendable {
    /// The default maximum encoded image size: 64 MiB.
    public static let defaultMaxInputBytes = 64 * 1_024 * 1_024

    /// The default maximum width or height in pixels.
    public static let defaultMaxDimension = 16_384

    /// The default maximum pixel count: 40 megapixels.
    public static let defaultMaxPixelCount = 40_000_000

    /// The default maximum frame count. TUIkit currently supports static images only.
    public static let defaultMaxFrameCount = 1

    /// The default maximum final RGBA allocation: 160 MiB.
    public static let defaultMaxDecodedBytes = 160 * 1_024 * 1_024

    /// The default maximum decompressed source data: 160 MiB.
    public static let defaultMaxDecompressedBytes = 160 * 1_024 * 1_024

    /// The default limits used by ``PlatformImageLoader``.
    public static let `default` = Self()

    /// Maximum encoded image size in bytes.
    public let maxInputBytes: Int

    /// Maximum width or height in pixels.
    public let maxDimension: Int

    /// Maximum total pixel count.
    public let maxPixelCount: Int

    /// Maximum image frame count.
    public let maxFrameCount: Int

    /// Maximum byte count for the final RGBA pixel buffer.
    public let maxDecodedBytes: Int

    /// Maximum byte count for decompressed source samples.
    public let maxDecompressedBytes: Int

    /// Creates image decoding limits.
    ///
    /// - Parameters:
    ///   - maxInputBytes: Maximum encoded image size in bytes.
    ///   - maxDimension: Maximum width or height in pixels.
    ///   - maxPixelCount: Maximum total pixel count.
    ///   - maxFrameCount: Maximum image frame count.
    ///   - maxDecodedBytes: Maximum byte count for the final RGBA pixel buffer.
    ///   - maxDecompressedBytes: Maximum byte count for decompressed source samples.
    public init(
        maxInputBytes: Int = defaultMaxInputBytes,
        maxDimension: Int = defaultMaxDimension,
        maxPixelCount: Int = defaultMaxPixelCount,
        maxFrameCount: Int = defaultMaxFrameCount,
        maxDecodedBytes: Int = defaultMaxDecodedBytes,
        maxDecompressedBytes: Int = defaultMaxDecompressedBytes
    ) {
        self.maxInputBytes = maxInputBytes
        self.maxDimension = maxDimension
        self.maxPixelCount = maxPixelCount
        self.maxFrameCount = maxFrameCount
        self.maxDecodedBytes = maxDecodedBytes
        self.maxDecompressedBytes = maxDecompressedBytes
    }
}

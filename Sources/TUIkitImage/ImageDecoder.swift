//  🖥️ TUIKit — Terminal UI Kit for Swift
//  ImageDecoder.swift
//
//  Created by LAYERED.work
//  License: MIT

import Foundation

enum EncodedImageFormat {
    case png
    case jpeg
}

struct DecodedImageMetadata {
    let width: Int
    let height: Int
    let frameCount: Int
    let decompressedByteCount: Int
}

struct ImageByteStream {
    let bytes: [UInt8]
    private(set) var position = 0

    mutating func read(count: Int) -> [UInt8]? {
        guard count >= 0 else { return nil }
        let (endPosition, overflow) = position.addingReportingOverflow(count)
        guard !overflow, endPosition <= bytes.endIndex else { return nil }

        defer { position = endPosition }
        return Array(bytes[position..<endPosition])
    }
}

struct PureSwiftImageDecoder {
    let limits: ImageDecodingLimits

    var maxInputBytes: Int { limits.maxInputBytes }

    func decode(_ data: Data, maxPixelCount: Int?) throws -> RGBAImage {
        guard data.count <= limits.maxInputBytes else {
            throw ImageLoadError.inputTooLarge(byteCount: data.count, limit: limits.maxInputBytes)
        }

        let bytes = [UInt8](data)
        let format = try detectFormat(in: bytes)
        let metadata = try inspect(bytes, format: format)
        let expectedPixelCount = try validate(metadata, maxPixelCount: maxPixelCount)

        let image: RGBAImage
        switch format {
        case .png:
            image = try PNGImageDecoder.decode(bytes)
        case .jpeg:
            image = try JPEGImageDecoder.decode(bytes)
        }

        guard image.width == metadata.width,
              image.height == metadata.height,
              image.pixels.count == expectedPixelCount
        else {
            throw ImageLoadError.decodingFailed("decoded image dimensions do not match its header")
        }
        return image
    }

    func validateCachedImage(_ image: RGBAImage, maxPixelCount: Int?) throws {
        let metadata = DecodedImageMetadata(
            width: image.width,
            height: image.height,
            frameCount: 1,
            decompressedByteCount: 0
        )
        let expectedPixelCount = try validate(metadata, maxPixelCount: maxPixelCount)

        guard image.pixels.count == expectedPixelCount else {
            throw ImageLoadError.decodingFailed("cached image dimensions do not match its pixel buffer")
        }
    }
}

private extension PureSwiftImageDecoder {

    func detectFormat(in bytes: [UInt8]) throws -> EncodedImageFormat {
        if bytes.starts(with: [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]) {
            return .png
        }
        if bytes.starts(with: [0xFF, 0xD8, 0xFF]) {
            return .jpeg
        }

        throw ImageLoadError.unsupportedFormat("unknown")
    }

    func inspect(_ bytes: [UInt8], format: EncodedImageFormat) throws -> DecodedImageMetadata {
        switch format {
        case .png:
            return try PNGImageDecoder.inspect(bytes)
        case .jpeg:
            return try JPEGImageDecoder.inspect(bytes)
        }
    }

    func validate(_ metadata: DecodedImageMetadata, maxPixelCount: Int?) throws -> Int {
        guard metadata.width > 0, metadata.height > 0 else {
            throw ImageLoadError.decodingFailed("image dimensions must be greater than zero")
        }
        guard metadata.width <= limits.maxDimension, metadata.height <= limits.maxDimension else {
            throw ImageLoadError.dimensionTooLarge(
                width: metadata.width,
                height: metadata.height,
                limit: limits.maxDimension
            )
        }

        let (pixelCount, pixelCountOverflow) = metadata.width.multipliedReportingOverflow(by: metadata.height)
        guard !pixelCountOverflow else {
            throw ImageLoadError.sizeOverflow(width: metadata.width, height: metadata.height)
        }

        let requestedPixelLimit = maxPixelCount ?? limits.maxPixelCount
        let effectivePixelLimit = min(requestedPixelLimit, limits.maxPixelCount)
        guard pixelCount <= effectivePixelLimit else {
            throw ImageLoadError.imageTooLarge(pixelCount: pixelCount, limit: effectivePixelLimit)
        }

        let effectiveFrameLimit = min(limits.maxFrameCount, ImageDecodingLimits.defaultMaxFrameCount)
        guard metadata.frameCount <= effectiveFrameLimit else {
            throw ImageLoadError.frameLimitExceeded(
                frameCount: metadata.frameCount,
                limit: effectiveFrameLimit
            )
        }

        let (decodedByteCount, decodedByteCountOverflow) = pixelCount.multipliedReportingOverflow(
            by: MemoryLayout<RGBA>.stride
        )
        guard !decodedByteCountOverflow else {
            throw ImageLoadError.sizeOverflow(width: metadata.width, height: metadata.height)
        }
        guard decodedByteCount <= limits.maxDecodedBytes else {
            throw ImageLoadError.allocationLimitExceeded(
                byteCount: decodedByteCount,
                limit: limits.maxDecodedBytes
            )
        }
        guard metadata.decompressedByteCount <= limits.maxDecompressedBytes else {
            throw ImageLoadError.decompressionLimitExceeded(
                byteCount: metadata.decompressedByteCount,
                limit: limits.maxDecompressedBytes
            )
        }

        return pixelCount
    }
}

//  🖥️ TUIKit — Terminal UI Kit for Swift
//  ImageDecoderTests.swift
//
//  Created by LAYERED.work
//  License: MIT

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import Testing
@testable import TUIkitImage

@Suite("Image Decoder Tests")
struct ImageDecoderTests {

    @Test("Existing interlaced PNG fixture decodes to expected RGBA pixels")
    func validPNGFixture() throws {
        let loader = PlatformImageLoader()

        let image = try loader.loadImage(from: fixtureData(at: pngFixturePath))

        #expect(image.width == 1_024)
        #expect(image.height == 1_024)
        #expect(image.pixel(at: 0, 0) == RGBA(r: 0, g: 0, b: 0, a: 0))
        #expect(image.pixel(at: 512, 128) == RGBA(r: 48, g: 37, b: 0, a: 255))
    }

    @Test("Existing JPEG fixture decodes to expected RGBA pixels")
    func validJPEGFixture() throws {
        let loader = PlatformImageLoader()

        let image = try loader.loadImage(from: fixtureData(at: jpegFixturePath))
        let centerPixel = image.pixel(at: 550, 540)

        #expect(image.width == 1_101)
        #expect(image.height == 1_080)
        #expect(centerPixel.a == 255)
        #expect(abs(Int(centerPixel.r) - 88) <= 3)
        #expect(abs(Int(centerPixel.g) - 121) <= 3)
        #expect(abs(Int(centerPixel.b) - 164) <= 3)
    }

    @Test("Repeated decoding produces identical pixels")
    func deterministicDecoding() throws {
        let loader = PlatformImageLoader()
        let data = tinyPNGFixture()

        let firstImage = try loader.loadImage(from: data)
        let secondImage = try loader.loadImage(from: data)

        #expect(firstImage.width == secondImage.width)
        #expect(firstImage.height == secondImage.height)
        #expect(firstImage.pixels == secondImage.pixels)
    }

    @Test("File loading enforces the encoded input byte limit")
    func pathInputByteLimit() {
        let loader = PlatformImageLoader(
            limits: ImageDecodingLimits(maxInputBytes: 4)
        )

        do {
            _ = try loader.loadImage(from: pngFixturePath)
            Issue.record("Expected the input byte limit to reject the file")
        } catch let error as ImageLoadError {
            guard case .inputTooLarge(let byteCount, limit: 4) = error else {
                Issue.record("Unexpected error: \(error)")
                return
            }
            #expect(byteCount == 5)
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }

    @Test("JPEG dimensions are rejected before decompression")
    func jpegDimensionLimit() {
        let loader = PlatformImageLoader(
            limits: ImageDecodingLimits(maxDimension: 4)
        )

        do {
            _ = try loader.loadImage(from: jpegHeader(width: 5, height: 1))
            Issue.record("Expected the JPEG dimension limit to reject the image")
        } catch let error as ImageLoadError {
            guard case .dimensionTooLarge(width: 5, height: 1, limit: 4) = error else {
                Issue.record("Unexpected error: \(error)")
                return
            }
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }

    @Test("Per-call pixel limits cannot loosen the loader limit")
    func loaderPixelLimitCannotBeLoosened() {
        let loader = PlatformImageLoader(
            limits: ImageDecodingLimits(maxPixelCount: 3)
        )

        do {
            _ = try loader.loadImage(from: pngHeader(width: 2, height: 2), maxPixelCount: 100)
            Issue.record("Expected the loader pixel limit to reject the image")
        } catch let error as ImageLoadError {
            guard case .imageTooLarge(pixelCount: 4, limit: 3) = error else {
                Issue.record("Unexpected error: \(error)")
                return
            }
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }

    @Test("Static image frame limits are enforced before decoding")
    func frameLimit() {
        let loader = PlatformImageLoader(
            limits: ImageDecodingLimits(maxFrameCount: 0)
        )

        do {
            _ = try loader.loadImage(from: pngHeader(width: 1, height: 1))
            Issue.record("Expected the frame limit to reject the image")
        } catch let error as ImageLoadError {
            guard case .frameLimitExceeded(frameCount: 1, limit: 0) = error else {
                Issue.record("Unexpected error: \(error)")
                return
            }
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }

    @Test("Animated PNG frame counts cannot loosen the static image limit")
    func animatedPNGFrameLimit() {
        let loader = PlatformImageLoader(
            limits: ImageDecodingLimits(maxFrameCount: 100)
        )

        do {
            _ = try loader.loadImage(from: animatedPNGHeader(frameCount: 2))
            Issue.record("Expected the static image frame limit to reject animated PNG data")
        } catch let error as ImageLoadError {
            guard case .frameLimitExceeded(frameCount: 2, limit: 1) = error else {
                Issue.record("Unexpected error: \(error)")
                return
            }
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }

    @Test("Truncated PNG data fails with a stable error")
    func truncatedPNG() {
        let loader = PlatformImageLoader()
        let data = tinyPNGFixture().prefix(20)

        expectDecodingFailure(
            from: Data(data),
            using: loader,
            description: "Image decoding failed: invalid PNG header"
        )
    }

    @Test("Malformed PNG data fails with a stable error")
    func malformedPNG() {
        let loader = PlatformImageLoader()
        var data = tinyPNGFixture()
        data[29] ^= 0xFF

        expectDecodingFailure(
            from: data,
            using: loader,
            description: "Image decoding failed: invalid PNG data"
        )
    }

    @Test("Truncated JPEG data fails with a stable error")
    func truncatedJPEG() {
        let loader = PlatformImageLoader()
        let data = tinyJPEGFixture().dropLast(2)

        expectDecodingFailure(
            from: Data(data),
            using: loader,
            description: "Image decoding failed: invalid JPEG data"
        )
    }

    @Test("JPEG decompression limits account for padded component blocks")
    func jpegDecompressionLimit() {
        let loader = PlatformImageLoader(
            limits: ImageDecodingLimits(maxDecompressedBytes: 383)
        )

        do {
            _ = try loader.loadImage(from: tinyJPEGFixture())
            Issue.record("Expected the JPEG decompression limit to reject the image")
        } catch let error as ImageLoadError {
            guard case .decompressionLimitExceeded(byteCount: 384, limit: 383) = error else {
                Issue.record("Unexpected error: \(error)")
                return
            }
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }

    @Test("Four-component JPEG input is rejected as unsupported")
    func unsupportedJPEGComponentCount() {
        let loader = PlatformImageLoader()

        do {
            _ = try loader.loadImage(from: jpegHeader(width: 1, height: 1, componentCount: 4))
            Issue.record("Expected four-component JPEG input to be rejected")
        } catch let error as ImageLoadError {
            guard case .unsupportedFormat("JPEG component count 4") = error else {
                Issue.record("Unexpected error: \(error)")
                return
            }
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }

    @Test("JPEG DNL cannot redefine a positive frame height")
    func jpegDNLWithPositiveFrameHeight() {
        let loader = PlatformImageLoader()
        let data = jpegAddingDNL(to: tinyJPEGFixture(), height: 2)

        expectDecodingFailure(
            from: data,
            using: loader,
            description: "Image decoding failed: invalid JPEG data"
        )
    }

    @Test("JPEG input with an extraneous MCU row fails with a stable error")
    func jpegWithExtraneousMCURow() {
        let loader = PlatformImageLoader()

        expectDecodingFailure(
            from: jpegWithExtraneousMCURowFixture(),
            using: loader,
            description: "Image decoding failed: invalid JPEG data"
        )
    }

    @Test("Input byte limit is enforced before format detection")
    func inputByteLimit() {
        let loader = PlatformImageLoader(
            limits: ImageDecodingLimits(maxInputBytes: 4)
        )

        do {
            _ = try loader.loadImage(from: Data(repeating: 0, count: 5))
            Issue.record("Expected the input byte limit to reject the image")
        } catch let error as ImageLoadError {
            guard case .inputTooLarge(byteCount: 5, limit: 4) = error else {
                Issue.record("Unexpected error: \(error)")
                return
            }
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }

    @Test("Unknown image signatures report a stable unsupported format error")
    func unsupportedFormat() {
        let loader = PlatformImageLoader()

        do {
            _ = try loader.loadImage(from: Data("not an image".utf8))
            Issue.record("Expected unknown image data to be rejected")
        } catch let error as ImageLoadError {
            guard case .unsupportedFormat("unknown") = error else {
                Issue.record("Unexpected error: \(error)")
                return
            }
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }

    @Test("PNG dimensions are rejected before decompression")
    func dimensionLimit() {
        let loader = PlatformImageLoader(
            limits: ImageDecodingLimits(maxDimension: 4)
        )

        do {
            _ = try loader.loadImage(from: pngHeader(width: 5, height: 1))
            Issue.record("Expected the image dimension limit to reject the image")
        } catch let error as ImageLoadError {
            guard case .dimensionTooLarge(width: 5, height: 1, limit: 4) = error else {
                Issue.record("Unexpected error: \(error)")
                return
            }
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }

    @Test("Pixel count is rejected before decompression")
    func pixelCountLimit() {
        let loader = PlatformImageLoader(
            limits: ImageDecodingLimits(maxPixelCount: 20)
        )

        do {
            _ = try loader.loadImage(from: pngHeader(width: 5, height: 5))
            Issue.record("Expected the pixel count limit to reject the image")
        } catch let error as ImageLoadError {
            guard case .imageTooLarge(pixelCount: 25, limit: 20) = error else {
                Issue.record("Unexpected error: \(error)")
                return
            }
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }

    @Test("Overflowing image dimensions fail with a stable error")
    func pixelCountOverflow() {
        let loader = PlatformImageLoader(
            limits: ImageDecodingLimits(
                maxDimension: .max,
                maxPixelCount: .max
            )
        )
        let dimension = UInt32.max

        do {
            _ = try loader.loadImage(from: pngHeader(width: dimension, height: dimension))
            Issue.record("Expected overflowing image dimensions to be rejected")
        } catch let error as ImageLoadError {
            #expect(
                error.description ==
                    "Image dimensions overflow: \(dimension)x\(dimension)"
            )
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }

    @Test("RGBA allocation limit is enforced before decompression")
    func allocationLimit() {
        let loader = PlatformImageLoader(
            limits: ImageDecodingLimits(maxDecodedBytes: 15)
        )

        do {
            _ = try loader.loadImage(from: pngHeader(width: 2, height: 2))
            Issue.record("Expected the decoded allocation limit to reject the image")
        } catch let error as ImageLoadError {
            guard case .allocationLimitExceeded(byteCount: 16, limit: 15) = error else {
                Issue.record("Unexpected error: \(error)")
                return
            }
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }

    @Test("PNG decompression limit is enforced before decoding")
    func decompressionLimit() {
        let loader = PlatformImageLoader(
            limits: ImageDecodingLimits(maxDecompressedBytes: 17)
        )

        do {
            _ = try loader.loadImage(from: pngHeader(width: 2, height: 2))
            Issue.record("Expected the decompression limit to reject the image")
        } catch let error as ImageLoadError {
            guard case .decompressionLimitExceeded(byteCount: 18, limit: 17) = error else {
                Issue.record("Unexpected error: \(error)")
                return
            }
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }

    @Test("Compressed PNG metadata is discarded before format decompression")
    func compressedPNGMetadataIsNotDecompressed() throws {
        let loader = PlatformImageLoader(
            limits: ImageDecodingLimits(maxDecompressedBytes: 18)
        )
        let data = pngAddingChunk(
            to: tinyPNGFixture(),
            type: Array("zTXt".utf8),
            data: Array("Comment".utf8) + [0, 0, 0x78]
        )

        let image = try loader.loadImage(from: data)

        #expect(image.width == 2)
        #expect(image.height == 2)
    }

    @Test("Reserved PNG scanline filters fail with a stable error")
    func invalidPNGScanlineFilter() {
        let loader = PlatformImageLoader()

        expectDecodingFailure(
            from: pngWithReservedScanlineFilter(),
            using: loader,
            description: "Image decoding failed: invalid PNG data"
        )
    }

    @Test("Extraneous decompressed PNG image data fails with a stable error")
    func extraneousPNGImageData() {
        let loader = PlatformImageLoader()

        expectDecodingFailure(
            from: pngWithExtraneousImageData(),
            using: loader,
            description: "Image decoding failed: invalid PNG data"
        )
    }

    @Test("Non-contiguous PNG image data chunks fail with a stable error")
    func nonContiguousPNGImageData() {
        let loader = PlatformImageLoader()

        expectDecodingFailure(
            from: pngWithNonContiguousImageData(),
            using: loader,
            description: "Image decoding failed: invalid PNG data"
        )
    }
}

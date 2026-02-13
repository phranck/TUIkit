//  🖥️ TUIKit — Terminal UI Kit for Swift
//  ImageTests.swift
//
//  Created by LAYERED.work
//  License: MIT

import Testing
@testable import TUIkit

// MARK: - RGBA Tests

@Suite("RGBA Pixel Tests")
struct RGBAPixelTests {

    @Test("RGBA initializes with correct values")
    func rgbaInit() {
        let pixel = RGBA(r: 255, g: 128, b: 0, a: 200)
        #expect(pixel.r == 255)
        #expect(pixel.g == 128)
        #expect(pixel.b == 0)
        #expect(pixel.a == 200)
    }

    @Test("RGBA default alpha is 255 (opaque)")
    func rgbaDefaultAlpha() {
        let pixel = RGBA(r: 100, g: 100, b: 100)
        #expect(pixel.a == 255)
    }

    @Test("Luminance calculation follows ITU-R BT.601")
    func luminanceCalculation() {
        // Pure white
        let white = RGBA(r: 255, g: 255, b: 255)
        #expect(white.luminance > 254.0)

        // Pure black
        let black = RGBA(r: 0, g: 0, b: 0)
        #expect(black.luminance == 0.0)

        // Green contributes most to luminance
        let green = RGBA(r: 0, g: 255, b: 0)
        let red = RGBA(r: 255, g: 0, b: 0)
        #expect(green.luminance > red.luminance)
    }

    @Test("RGBA equality works correctly")
    func rgbaEquality() {
        let a = RGBA(r: 10, g: 20, b: 30, a: 40)
        let b = RGBA(r: 10, g: 20, b: 30, a: 40)
        let c = RGBA(r: 10, g: 20, b: 31, a: 40)
        #expect(a == b)
        #expect(a != c)
    }
}

// MARK: - RGBAImage Tests

@Suite("RGBAImage Tests")
struct RGBAImageTests {

    @Test("Image stores correct dimensions")
    func imageDimensions() {
        let pixels = [RGBA](repeating: RGBA(r: 0, g: 0, b: 0), count: 12)
        let image = RGBAImage(width: 4, height: 3, pixels: pixels)
        #expect(image.width == 4)
        #expect(image.height == 3)
    }

    @Test("Pixel access returns correct values")
    func pixelAccess() {
        var pixels = [RGBA](repeating: RGBA(r: 0, g: 0, b: 0), count: 4)
        pixels[3] = RGBA(r: 255, g: 0, b: 0) // (1, 1) in a 2x2 image
        let image = RGBAImage(width: 2, height: 2, pixels: pixels)

        let topLeft = image.pixel(at: 0, 0)
        #expect(topLeft.r == 0)

        let bottomRight = image.pixel(at: 1, 1)
        #expect(bottomRight.r == 255)
    }

    @Test("Set pixel modifies correct position")
    func setPixel() {
        let pixels = [RGBA](repeating: RGBA(r: 0, g: 0, b: 0), count: 4)
        var image = RGBAImage(width: 2, height: 2, pixels: pixels)

        image.setPixel(at: 1, 0, value: RGBA(r: 128, g: 64, b: 32))
        let pixel = image.pixel(at: 1, 0)
        #expect(pixel.r == 128)
        #expect(pixel.g == 64)
        #expect(pixel.b == 32)
    }

    @Test("Add error clamps to valid range")
    func addErrorClamping() {
        let pixels = [RGBA(r: 250, g: 5, b: 128)]
        var image = RGBAImage(width: 1, height: 1, pixels: pixels)

        // Adding positive error should clamp at 255
        image.addError(at: 0, 0, rError: 20.0, gError: -10.0, bError: 0.0)
        let pixel = image.pixel(at: 0, 0)
        #expect(pixel.r == 255)  // 250 + 20 -> clamped to 255
        #expect(pixel.g == 0)    // 5 - 10 -> clamped to 0
        #expect(pixel.b == 128)  // unchanged
    }

    @Test("Nearest-neighbor scaling produces correct dimensions")
    func nearestNeighborScaling() {
        let pixels = [RGBA](repeating: RGBA(r: 128, g: 128, b: 128), count: 100)
        let image = RGBAImage(width: 10, height: 10, pixels: pixels)

        let scaled = image.scaled(to: 5, 5)
        #expect(scaled.width == 5)
        #expect(scaled.height == 5)
    }

    @Test("Bilinear scaling produces correct dimensions")
    func bilinearScaling() {
        let pixels = [RGBA](repeating: RGBA(r: 128, g: 128, b: 128), count: 100)
        let image = RGBAImage(width: 10, height: 10, pixels: pixels)

        let scaled = image.scaledBilinear(to: 20, 20)
        #expect(scaled.width == 20)
        #expect(scaled.height == 20)
    }

    @Test("Scaling to zero returns empty image")
    func scalingToZero() {
        let pixels = [RGBA](repeating: RGBA(r: 0, g: 0, b: 0), count: 4)
        let image = RGBAImage(width: 2, height: 2, pixels: pixels)

        let scaled = image.scaled(to: 0, 0)
        #expect(scaled.width == 0)
        #expect(scaled.height == 0)
    }
}

// MARK: - ASCIIConverter Tests

@Suite("ASCIIConverter Tests")
struct ASCIIConverterTests {

    @Test("Target size calculation preserves aspect ratio")
    func targetSizeAspectRatio() {
        let size = ASCIIConverter.targetSize(
            imageWidth: 100,
            imageHeight: 100,
            maxWidth: 50
        )
        // 100x100 image -> 50 chars wide, ~25 chars tall (2:1 aspect correction)
        #expect(size.width == 50)
        #expect(size.height == 25)
    }

    @Test("Target size respects max height")
    func targetSizeMaxHeight() {
        let size = ASCIIConverter.targetSize(
            imageWidth: 100,
            imageHeight: 200,
            maxWidth: 80,
            maxHeight: 20
        )
        #expect(size.height <= 20)
        #expect(size.width > 0)
    }

    @Test("Target size is at least 1x1")
    func targetSizeMinimum() {
        let size = ASCIIConverter.targetSize(
            imageWidth: 1,
            imageHeight: 1,
            maxWidth: 1
        )
        #expect(size.width >= 1)
        #expect(size.height >= 1)
    }

    @Test("ASCII character set conversion produces output")
    func asciiConversion() {
        let pixels = [RGBA](repeating: RGBA(r: 128, g: 128, b: 128), count: 100)
        let image = RGBAImage(width: 10, height: 10, pixels: pixels)

        let converter = ASCIIConverter(characterSet: .ascii, colorMode: .mono, dithering: .none)
        let lines = converter.convert(image, width: 10, height: 5)

        #expect(lines.count == 5)
        #expect(!lines[0].isEmpty)
    }

    @Test("Block character set conversion produces output")
    func blockConversion() {
        let pixels = [RGBA](repeating: RGBA(r: 200, g: 100, b: 50), count: 100)
        let image = RGBAImage(width: 10, height: 10, pixels: pixels)

        let converter = ASCIIConverter(characterSet: .blocks, colorMode: .trueColor, dithering: .none)
        let lines = converter.convert(image, width: 10, height: 5)

        #expect(lines.count == 5)
    }

    @Test("Braille conversion produces output")
    func brailleConversion() {
        let pixels = [RGBA](repeating: RGBA(r: 255, g: 255, b: 255), count: 400)
        let image = RGBAImage(width: 20, height: 20, pixels: pixels)

        let converter = ASCIIConverter(characterSet: .braille, colorMode: .trueColor, dithering: .none)
        let lines = converter.convert(image, width: 10, height: 5)

        #expect(lines.count == 5)
    }

    @Test("True color output contains ANSI RGB codes")
    func trueColorOutput() {
        let pixels = [RGBA(r: 255, g: 0, b: 0)]
        let image = RGBAImage(width: 1, height: 1, pixels: pixels)

        let converter = ASCIIConverter(characterSet: .ascii, colorMode: .trueColor, dithering: .none)
        let lines = converter.convert(image, width: 1, height: 1)

        #expect(lines.count == 1)
        // Should contain 38;2; (foreground true color escape)
        #expect(lines[0].contains("38;2;"))
    }

    @Test("Mono output contains no ANSI codes")
    func monoOutput() {
        let pixels = [RGBA(r: 128, g: 128, b: 128)]
        let image = RGBAImage(width: 1, height: 1, pixels: pixels)

        let converter = ASCIIConverter(characterSet: .ascii, colorMode: .mono, dithering: .none)
        let lines = converter.convert(image, width: 1, height: 1)

        #expect(lines.count == 1)
        // Mono should not contain color escape sequences
        #expect(!lines[0].contains("38;2;"))
        #expect(!lines[0].contains("38;5;"))
    }

    @Test("Floyd-Steinberg dithering does not crash")
    func ditheringNoCrash() {
        var pixels = [RGBA]()
        for i in 0..<100 {
            let r = UInt8(clamping: i * 2)
            let g = UInt8(clamping: i)
            let b = UInt8(clamping: 255 - i * 2)
            pixels.append(RGBA(r: r, g: g, b: b))
        }
        let image = RGBAImage(width: 10, height: 10, pixels: pixels)

        let converter = ASCIIConverter(characterSet: .blocks, colorMode: .ansi256, dithering: .floydSteinberg)
        let lines = converter.convert(image, width: 10, height: 5)

        #expect(lines.count == 5)
    }

    @Test("Empty image returns empty lines")
    func emptyImageConversion() {
        let image = RGBAImage(width: 0, height: 0, pixels: [])
        let converter = ASCIIConverter()
        let lines = converter.convert(image, width: 10, height: 5)
        #expect(lines.isEmpty)
    }

    @Test("ANSI 256 output contains palette codes")
    func ansi256Output() {
        let pixels = [RGBA(r: 255, g: 0, b: 0)]
        let image = RGBAImage(width: 1, height: 1, pixels: pixels)

        let converter = ASCIIConverter(characterSet: .ascii, colorMode: .ansi256, dithering: .none)
        let lines = converter.convert(image, width: 1, height: 1)

        #expect(lines.count == 1)
        // Should contain 38;5; (256-color escape)
        #expect(lines[0].contains("38;5;"))
    }

    @Test("Grayscale output contains palette codes")
    func grayscaleOutput() {
        let pixels = [RGBA(r: 128, g: 128, b: 128)]
        let image = RGBAImage(width: 1, height: 1, pixels: pixels)

        let converter = ASCIIConverter(characterSet: .ascii, colorMode: .grayscale, dithering: .none)
        let lines = converter.convert(image, width: 1, height: 1)

        #expect(lines.count == 1)
        #expect(lines[0].contains("38;5;"))
    }
}

// MARK: - Image View Tests

@Suite("Image View Tests")
@MainActor
struct ImageViewTests {

    @Test("Image initializes with file source")
    func imageFileInit() {
        let image = Image(.file("/path/to/image.png"))
        #expect(image.source == .file("/path/to/image.png"))
    }

    @Test("Image initializes with URL source")
    func imageURLInit() {
        let image = Image(.url("https://example.com/image.png"))
        #expect(image.source == .url("https://example.com/image.png"))
    }

    @Test("ImageSource equality works")
    func imageSourceEquality() {
        let a = ImageSource.file("/path/a.png")
        let b = ImageSource.file("/path/a.png")
        let c = ImageSource.url("https://example.com")
        #expect(a == b)
        #expect(a != c)
    }
}

// MARK: - ImageLoadError Tests

@Suite("ImageLoadError Tests")
struct ImageLoadErrorTests {

    @Test("Error descriptions are informative")
    func errorDescriptions() {
        let fileError = ImageLoadError.fileNotFound("/missing.png")
        #expect(fileError.description.contains("/missing.png"))

        let formatError = ImageLoadError.unsupportedFormat("bmp")
        #expect(formatError.description.contains("bmp"))

        let decodeError = ImageLoadError.decodingFailed("corrupt data")
        #expect(decodeError.description.contains("corrupt data"))

        let downloadError = ImageLoadError.downloadFailed("timeout")
        #expect(downloadError.description.contains("timeout"))
    }
}

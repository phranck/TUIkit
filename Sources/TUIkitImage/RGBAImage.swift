//  🖥️ TUIKit — Terminal UI Kit for Swift
//  RGBAImage.swift
//
//  Created by LAYERED.work
//  License: MIT

// MARK: - RGBA Pixel

/// A single pixel with red, green, blue, and alpha channels.
///
/// Used as the intermediate representation for image data before
/// ASCII art conversion. Each channel is stored as a `UInt8` (0-255).
public struct RGBA: Sendable, Equatable {
    public var r: UInt8
    public var g: UInt8
    public var b: UInt8
    public var a: UInt8

    /// Creates an opaque pixel with the given RGB values.
    public init(r: UInt8, g: UInt8, b: UInt8, a: UInt8 = 255) {
        self.r = r
        self.g = g
        self.b = b
        self.a = a
    }
}

// MARK: - Luminance

extension RGBA {

    /// The perceived luminance using ITU-R BT.601 coefficients.
    ///
    /// Returns a value in the range 0.0 (black) to 255.0 (white).
    public var luminance: Double {
        Double(r) * 0.299 + Double(g) * 0.587 + Double(b) * 0.114
    }
}

// MARK: - RGBAImage

/// A raw image stored as a flat array of RGBA pixels in row-major order.
///
/// This is the platform-independent representation produced by
/// `ImageLoader` implementations and consumed by `ASCIIConverter`.
public struct RGBAImage: Sendable {
    /// Image width in pixels.
    public let width: Int

    /// Image height in pixels.
    public let height: Int

    /// Row-major pixel data (`width * height` elements).
    public private(set) var pixels: [RGBA]

    /// Creates an image from dimensions and pixel data.
    ///
    /// - Parameters:
    ///   - width: Image width in pixels.
    ///   - height: Image height in pixels.
    ///   - pixels: Pixel data in row-major order. Must contain `width * height` elements.
    public init(width: Int, height: Int, pixels: [RGBA]) {
        precondition(pixels.count == width * height, "Pixel count must match width * height")
        self.width = width
        self.height = height
        self.pixels = pixels
    }
}

// MARK: - Pixel Access

extension RGBAImage {

    /// Returns the pixel at the given coordinates.
    ///
    /// - Parameters:
    ///   - x: Column (0-based, left to right).
    ///   - y: Row (0-based, top to bottom).
    /// - Returns: The RGBA pixel value.
    public func pixel(at x: Int, _ y: Int) -> RGBA {
        pixels[y * width + x]
    }

    /// Sets the pixel at the given coordinates.
    ///
    /// - Parameters:
    ///   - x: Column (0-based).
    ///   - y: Row (0-based).
    ///   - value: The new pixel value.
    public mutating func setPixel(at x: Int, _ y: Int, value: RGBA) {
        pixels[y * width + x] = value
    }

    /// Adds an error value to the pixel at the given coordinates (for dithering).
    ///
    /// Clamps each channel to the valid 0-255 range.
    ///
    /// - Parameters:
    ///   - x: Column.
    ///   - y: Row.
    ///   - rError: Red channel error.
    ///   - gError: Green channel error.
    ///   - bError: Blue channel error.
    public mutating func addError(at x: Int, _ y: Int, rError: Double, gError: Double, bError: Double) {
        let index = y * width + x
        let pixel = pixels[index]
        pixels[index] = RGBA(
            r: UInt8(clamping: Int(Double(pixel.r) + rError)),
            g: UInt8(clamping: Int(Double(pixel.g) + gError)),
            b: UInt8(clamping: Int(Double(pixel.b) + bError))
        )
    }
}

// MARK: - Image Scaling

extension RGBAImage {

    /// Returns a scaled copy using nearest-neighbor interpolation.
    ///
    /// - Parameters:
    ///   - targetWidth: The desired width.
    ///   - targetHeight: The desired height.
    /// - Returns: A new image with the specified dimensions.
    public func scaled(to targetWidth: Int, _ targetHeight: Int) -> RGBAImage {
        guard targetWidth > 0, targetHeight > 0 else {
            return RGBAImage(width: 0, height: 0, pixels: [])
        }

        var result = [RGBA](repeating: RGBA(r: 0, g: 0, b: 0), count: targetWidth * targetHeight)

        for y in 0..<targetHeight {
            let srcY = y * height / targetHeight
            for x in 0..<targetWidth {
                let srcX = x * width / targetWidth
                result[y * targetWidth + x] = pixel(at: srcX, srcY)
            }
        }

        return RGBAImage(width: targetWidth, height: targetHeight, pixels: result)
    }

    /// Returns a scaled copy using bilinear interpolation for smoother results.
    ///
    /// - Parameters:
    ///   - targetWidth: The desired width.
    ///   - targetHeight: The desired height.
    /// - Returns: A new image with the specified dimensions.
    public func scaledBilinear(to targetWidth: Int, _ targetHeight: Int) -> RGBAImage {
        guard targetWidth > 0, targetHeight > 0 else {
            return RGBAImage(width: 0, height: 0, pixels: [])
        }

        var result = [RGBA](repeating: RGBA(r: 0, g: 0, b: 0), count: targetWidth * targetHeight)
        let xRatio = Double(width) / Double(targetWidth)
        let yRatio = Double(height) / Double(targetHeight)

        for y in 0..<targetHeight {
            let srcY = Double(y) * yRatio
            let y0 = min(Int(srcY), height - 1)
            let y1 = min(y0 + 1, height - 1)
            let yFrac = srcY - Double(y0)

            for x in 0..<targetWidth {
                let srcX = Double(x) * xRatio
                let x0 = min(Int(srcX), width - 1)
                let x1 = min(x0 + 1, width - 1)
                let xFrac = srcX - Double(x0)

                let p00 = pixel(at: x0, y0)
                let p10 = pixel(at: x1, y0)
                let p01 = pixel(at: x0, y1)
                let p11 = pixel(at: x1, y1)

                let r = bilinearInterpolate(
                    Double(p00.r), Double(p10.r), Double(p01.r), Double(p11.r), xFrac, yFrac
                )
                let g = bilinearInterpolate(
                    Double(p00.g), Double(p10.g), Double(p01.g), Double(p11.g), xFrac, yFrac
                )
                let b = bilinearInterpolate(
                    Double(p00.b), Double(p10.b), Double(p01.b), Double(p11.b), xFrac, yFrac
                )

                result[y * targetWidth + x] = RGBA(
                    r: UInt8(clamping: Int(r.rounded())),
                    g: UInt8(clamping: Int(g.rounded())),
                    b: UInt8(clamping: Int(b.rounded()))
                )
            }
        }

        return RGBAImage(width: targetWidth, height: targetHeight, pixels: result)
    }
}

// MARK: - Private Helpers

extension RGBAImage {

    private func bilinearInterpolate(
        _ v00: Double, _ v10: Double, _ v01: Double, _ v11: Double,
        _ xFrac: Double, _ yFrac: Double
    ) -> Double {
        let top = v00 * (1.0 - xFrac) + v10 * xFrac
        let bottom = v01 * (1.0 - xFrac) + v11 * xFrac
        return top * (1.0 - yFrac) + bottom * yFrac
    }
}

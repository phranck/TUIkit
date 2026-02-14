//  🖥️ TUIKit — Terminal UI Kit for Swift
//  ASCIIConverter.swift
//
//  Created by LAYERED.work
//  License: MIT

import TUIkitStyling

/// Standard ANSI escape sequences for ASCII art colorization.
private enum ANSIEscape {
    /// The escape character.
    static let escape = "\u{1B}"
    /// The Control Sequence Introducer.
    static let csi = "\(escape)["
    /// Reset all formatting.
    static let reset = "\(csi)0m"
}

// MARK: - Character Set

/// The set of characters used for ASCII art rendering.
///
/// Each set trades off between compatibility and visual quality.
public enum ASCIICharacterSet: Sendable, Equatable {
    /// Standard ASCII characters (10 levels). Works in every terminal.
    case ascii

    /// Unicode block elements (5 levels). Requires Unicode support.
    case blocks

    /// Unicode Braille patterns (2x4 pixel cells, 256 patterns). Highest resolution.
    case braille
}

// MARK: - Color Mode

/// Controls how colors are rendered in ASCII art output.
public enum ASCIIColorMode: Sendable, Equatable {
    /// 24-bit RGB using `\e[38;2;R;G;B` sequences. Best quality.
    case trueColor

    /// 256-color ANSI palette. Good terminal compatibility.
    case ansi256

    /// 24 shades of gray.
    case grayscale

    /// Black and white only. Universal compatibility.
    case mono
}

// MARK: - Dithering Mode

/// The dithering algorithm applied during color quantization.
public enum DitheringMode: Sendable, Equatable {
    /// Floyd-Steinberg error diffusion. Good for smooth gradients.
    case floydSteinberg

    /// No dithering. Fastest.
    case none
}

// MARK: - ASCII Converter

/// Converts an `RGBAImage` to colored ASCII art strings.
///
/// The conversion pipeline:
/// 1. Scale image to target character dimensions
/// 2. Apply aspect ratio correction (terminal chars are ~2:1)
/// 3. Optionally apply dithering
/// 4. Map each pixel to a character based on luminance
/// 5. Colorize each character using the selected color mode
public struct ASCIIConverter: Sendable {

    /// The character set to use for brightness mapping.
    let characterSet: ASCIICharacterSet

    /// The color mode for output.
    let colorMode: ASCIIColorMode

    /// The dithering algorithm (nil or .none means no dithering).
    let dithering: DitheringMode

    /// Creates a converter with the specified options.
    public init(
        characterSet: ASCIICharacterSet = .blocks,
        colorMode: ASCIIColorMode = .trueColor,
        dithering: DitheringMode = .none
    ) {
        self.characterSet = characterSet
        self.colorMode = colorMode
        self.dithering = dithering
    }
}

// MARK: - Conversion

extension ASCIIConverter {

    /// Converts an image to an array of ANSI-colored strings (one per row).
    ///
    /// - Parameters:
    ///   - image: The source image.
    ///   - width: Target width in characters.
    ///   - height: Target height in characters.
    /// - Returns: An array of ANSI-formatted strings representing the ASCII art.
    public func convert(_ image: RGBAImage, width: Int, height: Int) -> [String] {
        guard image.width > 0, image.height > 0, width > 0, height > 0 else {
            return []
        }

        // For braille, each character cell covers 2x4 pixels.
        let pixelWidth: Int
        let pixelHeight: Int
        if characterSet == .braille {
            pixelWidth = width * 2
            pixelHeight = height * 4
        } else {
            pixelWidth = width
            pixelHeight = height
        }

        // Scale image to target pixel dimensions
        var scaled = image.scaledBilinear(to: pixelWidth, pixelHeight)

        // Apply dithering if requested (only meaningful for non-trueColor modes)
        if dithering == .floydSteinberg, colorMode != .trueColor {
            scaled = applyFloydSteinbergDithering(scaled)
        }

        // Convert to ASCII lines
        if characterSet == .braille {
            return convertBraille(scaled, width: width, height: height)
        }

        return convertCharacterBased(scaled, width: width, height: height)
    }
}

// MARK: - Character-Based Conversion

extension ASCIIConverter {

    /// Converts using character brightness mapping (ascii, blocks).
    private func convertCharacterBased(_ image: RGBAImage, width: Int, height: Int) -> [String] {
        let ramp = characterRamp

        var lines = [String]()
        lines.reserveCapacity(height)

        for y in 0..<height {
            var line = ""
            line.reserveCapacity(width * 20) // Reserve for ANSI codes
            var lastColor = ""

            for x in 0..<width {
                let pixel = image.pixel(at: x, y)

                // Map luminance to character
                let charIndex = Int((pixel.luminance / 255.0) * Double(ramp.count - 1))
                let clampedIndex = min(max(charIndex, 0), ramp.count - 1)
                let char = ramp[clampedIndex]

                // Colorize
                let colorCode = foregroundColorCode(for: pixel)
                if colorCode != lastColor {
                    if !lastColor.isEmpty {
                        line += ANSIEscape.reset
                    }
                    line += colorCode
                    lastColor = colorCode
                }
                line.append(char)
            }

            if !lastColor.isEmpty {
                line += ANSIEscape.reset
            }
            lines.append(line)
        }

        return lines
    }

    /// The character ramp for the current character set, from darkest to brightest.
    private var characterRamp: [Character] {
        switch characterSet {
        case .ascii:
            return Array(" .:;+=xX$@")
        case .blocks:
            return Array(" ░▒▓█")
        case .braille:
            // Not used directly; braille has its own rendering path
            return Array(" ⠁⠃⠇⡇⣇⣧⣷⣿")
        }
    }
}

// MARK: - Braille Conversion

extension ASCIIConverter {

    /// Converts using 2x4 Braille character cells for maximum resolution.
    ///
    /// Each Braille character (U+2800-U+28FF) represents a 2x4 pixel grid.
    /// The dot pattern encodes which pixels are "on" based on a luminance threshold.
    /// Color is taken from the average of the cell's pixels.
    private func convertBraille(_ image: RGBAImage, width: Int, height: Int) -> [String] {
        // Braille dot positions (column, row) -> bit index
        // ⠁ = bit 0 (0,0)  ⠈ = bit 3 (1,0)
        // ⠂ = bit 1 (0,1)  ⠐ = bit 4 (1,1)
        // ⠄ = bit 2 (0,2)  ⠠ = bit 5 (1,2)
        // ⡀ = bit 6 (0,3)  ⢀ = bit 7 (1,3)
        let dotBits: [[Int]] = [
            [0, 3],  // row 0: left=bit0, right=bit3
            [1, 4],  // row 1: left=bit1, right=bit4
            [2, 5],  // row 2: left=bit2, right=bit5
            [6, 7],  // row 3: left=bit6, right=bit7
        ]

        let threshold = 128.0
        var lines = [String]()
        lines.reserveCapacity(height)

        for charY in 0..<height {
            var line = ""
            line.reserveCapacity(width * 20)
            var lastColor = ""

            for charX in 0..<width {
                let pixelX = charX * 2
                let pixelY = charY * 4

                var pattern: UInt8 = 0
                var totalR = 0, totalG = 0, totalB = 0
                var count = 0

                for dy in 0..<4 {
                    for dx in 0..<2 {
                        let px = pixelX + dx
                        let py = pixelY + dy
                        guard px < image.width, py < image.height else { continue }

                        let pixel = image.pixel(at: px, py)
                        totalR += Int(pixel.r)
                        totalG += Int(pixel.g)
                        totalB += Int(pixel.b)
                        count += 1

                        if pixel.luminance >= threshold {
                            pattern |= 1 << dotBits[dy][dx]
                        }
                    }
                }

                // Braille character: U+2800 + pattern
                let brailleChar = Character(Unicode.Scalar(0x2800 + UInt32(pattern))!)

                // Average color for this cell
                let avgPixel: RGBA
                if count > 0 { // swiftlint:disable:this empty_count
                    avgPixel = RGBA(
                        r: UInt8(clamping: totalR / count),
                        g: UInt8(clamping: totalG / count),
                        b: UInt8(clamping: totalB / count)
                    )
                } else {
                    avgPixel = RGBA(r: 0, g: 0, b: 0)
                }

                let colorCode = foregroundColorCode(for: avgPixel)
                if colorCode != lastColor {
                    if !lastColor.isEmpty {
                        line += ANSIEscape.reset
                    }
                    line += colorCode
                    lastColor = colorCode
                }
                line.append(brailleChar)
            }

            if !lastColor.isEmpty {
                line += ANSIEscape.reset
            }
            lines.append(line)
        }

        return lines
    }
}

// MARK: - Color Output

extension ASCIIConverter {

    /// Returns the ANSI foreground color escape code for a pixel.
    private func foregroundColorCode(for pixel: RGBA) -> String {
        switch colorMode {
        case .trueColor:
            return "\(ANSIEscape.csi)38;2;\(pixel.r);\(pixel.g);\(pixel.b)m"

        case .ansi256:
            let index = quantizeToANSI256(pixel)
            return "\(ANSIEscape.csi)38;5;\(index)m"

        case .grayscale:
            let gray = Int(pixel.luminance / 255.0 * 23.0)
            let index = 232 + min(max(gray, 0), 23)
            return "\(ANSIEscape.csi)38;5;\(index)m"

        case .mono:
            return ""
        }
    }

    /// Quantizes an RGB pixel to the nearest ANSI 256-color index.
    private func quantizeToANSI256(_ pixel: RGBA) -> UInt8 {
        // Check for near-grayscale
        let rDiff = abs(Int(pixel.r) - Int(pixel.g))
        let gDiff = abs(Int(pixel.g) - Int(pixel.b))
        if rDiff < 10, gDiff < 10 {
            let gray = Int(pixel.r)
            if gray < 8 { return 16 }
            if gray > 248 { return 231 }
            return UInt8(232 + (gray - 8) / 10)
        }

        // 6x6x6 color cube (indices 16-231)
        let r = Int((Double(pixel.r) / 255.0 * 5.0).rounded())
        let g = Int((Double(pixel.g) / 255.0 * 5.0).rounded())
        let b = Int((Double(pixel.b) / 255.0 * 5.0).rounded())
        return UInt8(16 + 36 * r + 6 * g + b)
    }
}

// MARK: - Floyd-Steinberg Dithering

extension ASCIIConverter {

    /// Applies Floyd-Steinberg error diffusion dithering.
    ///
    /// Distributes quantization error to neighboring pixels:
    /// - Right:       7/16
    /// - Bottom-left: 3/16
    /// - Bottom:      5/16
    /// - Bottom-right: 1/16
    private func applyFloydSteinbergDithering(_ image: RGBAImage) -> RGBAImage {
        var result = image

        for y in 0..<image.height {
            for x in 0..<image.width {
                let oldPixel = result.pixel(at: x, y)
                let newPixel = quantizePixel(oldPixel)
                result.setPixel(at: x, y, value: newPixel)

                let rErr = Double(oldPixel.r) - Double(newPixel.r)
                let gErr = Double(oldPixel.g) - Double(newPixel.g)
                let bErr = Double(oldPixel.b) - Double(newPixel.b)

                // Distribute error to neighbors
                if x + 1 < image.width {
                    result.addError(at: x + 1, y,
                                    rError: rErr * 7.0 / 16.0,
                                    gError: gErr * 7.0 / 16.0,
                                    bError: bErr * 7.0 / 16.0)
                }
                if y + 1 < image.height {
                    if x > 0 {
                        result.addError(at: x - 1, y + 1,
                                        rError: rErr * 3.0 / 16.0,
                                        gError: gErr * 3.0 / 16.0,
                                        bError: bErr * 3.0 / 16.0)
                    }
                    result.addError(at: x, y + 1,
                                    rError: rErr * 5.0 / 16.0,
                                    gError: gErr * 5.0 / 16.0,
                                    bError: bErr * 5.0 / 16.0)
                    if x + 1 < image.width {
                        result.addError(at: x + 1, y + 1,
                                        rError: rErr * 1.0 / 16.0,
                                        gError: gErr * 1.0 / 16.0,
                                        bError: bErr * 1.0 / 16.0)
                    }
                }
            }
        }

        return result
    }

    /// Quantizes a pixel to its nearest representative value for the current color mode.
    private func quantizePixel(_ pixel: RGBA) -> RGBA {
        switch colorMode {
        case .trueColor:
            return pixel

        case .ansi256:
            let index = quantizeToANSI256(pixel)
            return ansi256ToRGB(index)

        case .grayscale:
            let gray = UInt8(clamping: Int(pixel.luminance))
            return RGBA(r: gray, g: gray, b: gray)

        case .mono:
            let val: UInt8 = pixel.luminance > 128.0 ? 255 : 0
            return RGBA(r: val, g: val, b: val)
        }
    }

    /// Converts an ANSI 256-color index back to approximate RGB.
    private func ansi256ToRGB(_ index: UInt8) -> RGBA {
        let idx = Int(index)
        if idx < 16 {
            // Standard colors (approximate)
            let table: [(UInt8, UInt8, UInt8)] = [
                (0, 0, 0), (128, 0, 0), (0, 128, 0), (128, 128, 0),
                (0, 0, 128), (128, 0, 128), (0, 128, 128), (192, 192, 192),
                (128, 128, 128), (255, 0, 0), (0, 255, 0), (255, 255, 0),
                (0, 0, 255), (255, 0, 255), (0, 255, 255), (255, 255, 255),
            ]
            let (r, g, b) = table[idx]
            return RGBA(r: r, g: g, b: b)
        } else if idx < 232 {
            // 6x6x6 color cube
            let offset = idx - 16
            let r = offset / 36
            let g = (offset % 36) / 6
            let b = offset % 6
            return RGBA(
                r: r == 0 ? 0 : UInt8(55 + r * 40),
                g: g == 0 ? 0 : UInt8(55 + g * 40),
                b: b == 0 ? 0 : UInt8(55 + b * 40)
            )
        } else {
            // Grayscale ramp
            let gray = UInt8(8 + (idx - 232) * 10)
            return RGBA(r: gray, g: gray, b: gray)
        }
    }
}

// MARK: - Aspect Ratio

extension ASCIIConverter {

    /// Calculates the target character dimensions preserving aspect ratio.
    ///
    /// Terminal characters are approximately 2:1 (height:width), so the
    /// vertical dimension is halved to compensate.
    ///
    /// - Parameters:
    ///   - imageWidth: Source image width in pixels.
    ///   - imageHeight: Source image height in pixels.
    ///   - maxWidth: Maximum width in characters.
    ///   - maxHeight: Maximum height in characters (optional).
    ///   - contentMode: Whether to fit within or fill the available bounds.
    ///   - overrideAspectRatio: An explicit width/height ratio. When `nil`,
    ///     the source image's natural ratio is used.
    /// - Returns: The target width and height in characters.
    public static func targetSize(
        imageWidth: Int,
        imageHeight: Int,
        maxWidth: Int,
        maxHeight: Int? = nil,
        contentMode: ContentMode = .fit,
        overrideAspectRatio: Double? = nil
    ) -> (width: Int, height: Int) {
        let terminalAspect = 2.0 // Terminal chars are ~2x taller than wide

        // Use override ratio or compute from source dimensions.
        let sourceRatio = overrideAspectRatio
            ?? (Double(imageWidth) / Double(imageHeight))

        // correctedRatio accounts for terminal character aspect (tall cells).
        let correctedRatio = sourceRatio * terminalAspect

        let maxH = maxHeight ?? Int((Double(maxWidth) / correctedRatio).rounded())

        let targetWidth: Int
        let targetHeight: Int

        switch contentMode {
        case .fit:
            // Scale to fit within both bounds. Result <= bounds.
            let widthFromHeight = Int((Double(maxH) * correctedRatio).rounded())
            if widthFromHeight <= maxWidth {
                targetWidth = widthFromHeight
                targetHeight = maxH
            } else {
                targetWidth = maxWidth
                targetHeight = Int((Double(maxWidth) / correctedRatio).rounded())
            }

        case .fill:
            // Scale so the shorter dimension fills its bound.
            // Result may exceed one bound.
            let widthFromHeight = Int((Double(maxH) * correctedRatio).rounded())
            if widthFromHeight >= maxWidth {
                targetWidth = widthFromHeight
                targetHeight = maxH
            } else {
                targetWidth = maxWidth
                targetHeight = Int((Double(maxWidth) / correctedRatio).rounded())
            }
        }

        return (width: max(1, targetWidth), height: max(1, targetHeight))
    }
}

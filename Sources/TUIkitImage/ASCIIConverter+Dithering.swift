//  🖥️ TUIKit — Terminal UI Kit for Swift
//  ASCIIConverter+Dithering.swift
//
//  Created by LAYERED.work
//  License: MIT

// MARK: - Color Output

extension ASCIIConverter {

    /// Returns the ANSI foreground color escape code for a pixel.
    func foregroundColorCode(for pixel: RGBA) -> String {
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
    func applyFloydSteinbergDithering(_ image: RGBAImage) -> RGBAImage {
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

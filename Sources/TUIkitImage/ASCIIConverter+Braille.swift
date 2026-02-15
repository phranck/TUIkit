//  🖥️ TUIKit — Terminal UI Kit for Swift
//  ASCIIConverter+Braille.swift
//
//  Created by LAYERED.work
//  License: MIT

// MARK: - Braille Conversion

extension ASCIIConverter {

    /// Converts using 2x4 Braille character cells for maximum resolution.
    ///
    /// Each Braille character (U+2800-U+28FF) represents a 2x4 pixel grid.
    /// The dot pattern encodes which pixels are "on" based on a luminance threshold.
    /// Color is taken from the average of the cell's pixels.
    func convertBraille(_ image: RGBAImage, width: Int, height: Int) -> [String] {
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

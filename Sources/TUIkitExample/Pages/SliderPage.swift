//  TUIKit - Terminal UI Kit for Swift
//  SliderPage.swift
//
//  Created by LAYERED.work
//  License: MIT

import TUIkit

/// Slider demo page.
///
/// Shows interactive slider features including:
/// - Different track styles (block, shade, dot, bar)
/// - Various ranges and step sizes
/// - Keyboard controls
/// - Live value display
struct SliderPage: View {
    @State var volume: Double = 0.5
    @State var brightness: Double = 75
    @State var rating: Double = 3
    @State var precision: Double = 0.5

    var body: some View {
        VStack(alignment: .leading, spacing: 1) {

            DemoSection("Basic Slider (Block Style)") {
                VStack(alignment: .leading, spacing: 1) {
                    HStack(spacing: 1) {
                        Text("Volume:").foregroundStyle(.palette.foregroundSecondary)
                        Slider(value: $volume)
                    }
                }
            }

            DemoSection("Track Styles") {
                VStack(alignment: .leading, spacing: 1) {
                    HStack(spacing: 1) {
                        Text("Block:").foregroundStyle(.palette.foregroundSecondary)
                        Slider(value: $volume).trackStyle(.block)
                    }
                    HStack(spacing: 1) {
                        Text("Shade:").foregroundStyle(.palette.foregroundSecondary)
                        Slider(value: $volume).trackStyle(.shade)
                    }
                    HStack(spacing: 1) {
                        Text("Dot:  ").foregroundStyle(.palette.foregroundSecondary)
                        Slider(value: $volume).trackStyle(.dot)
                    }
                    HStack(spacing: 1) {
                        Text("Bar:  ").foregroundStyle(.palette.foregroundSecondary)
                        Slider(value: $volume).trackStyle(.bar)
                    }
                }
            }

            DemoSection("Custom Ranges") {
                VStack(alignment: .leading, spacing: 1) {
                    HStack(spacing: 1) {
                        Text("Brightness (0-100, step 5):").foregroundStyle(.palette.foregroundSecondary)
                        Slider(value: $brightness, in: 0...100, step: 5)
                    }
                    HStack(spacing: 1) {
                        Text("Rating (1-5, step 1):      ").foregroundStyle(.palette.foregroundSecondary)
                        Slider(value: $rating, in: 1...5, step: 1)
                    }
                    HStack(spacing: 1) {
                        Text("Precision (0-1, step 0.05):").foregroundStyle(.palette.foregroundSecondary)
                        Slider(value: $precision, in: 0...1, step: 0.05)
                    }
                }
            }

            DemoSection("Current Values") {
                VStack(alignment: .leading, spacing: 1) {
                    ValueDisplayRow("Volume:", String(format: "%.0f%%", volume * 100))
                    ValueDisplayRow("Brightness:", String(format: "%.0f", brightness))
                    ValueDisplayRow("Rating:", String(format: "%.0f", rating))
                    ValueDisplayRow("Precision:", String(format: "%.2f", precision))
                }
            }

            KeyboardHelpSection(shortcuts: [
                "[<-] [->] Decrease/Increase by step",
                "[-] [+] Decrease/Increase by step",
                "[Home] Jump to minimum",
                "[End] Jump to maximum",
                "[Tab] Move to next slider",
            ])

            Spacer()
        }
        .appHeader {
            DemoAppHeader("Slider Demo")
        }
    }
}

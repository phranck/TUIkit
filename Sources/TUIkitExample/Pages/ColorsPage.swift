//  🖥️ TUIKit — Terminal UI Kit for Swift
//  ColorsPage.swift
//
//  Created by LAYERED.work
//  License: MIT

import TUIkit

/// Colors demo page.
///
/// Shows various color options including:
/// - Standard ANSI colors (8 colors)
/// - Bright colors (8 colors)
/// - RGB colors (24-bit true color)
/// - Semantic colors (primary, success, warning, error)
struct ColorsPage: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 1) {

            DemoSection("Standard ANSI Colors") {
                HStack(spacing: 2) {
                    Text("Black").foregroundStyle(.black).background(.white)
                    Text("Red").foregroundStyle(.red)
                    Text("Green").foregroundStyle(.green)
                    Text("Yellow").foregroundStyle(.yellow)
                }
                HStack(spacing: 2) {
                    Text("Blue").foregroundStyle(.blue)
                    Text("Magenta").foregroundStyle(.magenta)
                    Text("Cyan").foregroundStyle(.cyan)
                    Text("White").foregroundStyle(.white)
                }
            }

            DemoSection("Bright Colors") {
                HStack(spacing: 2) {
                    Text("Bright Red").foregroundStyle(.brightRed)
                    Text("Bright Green").foregroundStyle(.brightGreen)
                    Text("Bright Yellow").foregroundStyle(.brightYellow)
                    Text("Bright Blue").foregroundStyle(.brightBlue)
                }
            }

            DemoSection("RGB Colors (24-bit)") {
                HStack(spacing: 2) {
                    Text("Orange").foregroundStyle(.rgb(255, 128, 0))
                    Text("Pink").foregroundStyle(.rgb(255, 105, 180))
                    Text("Teal").foregroundStyle(.rgb(0, 128, 128))
                    Text("Purple").foregroundStyle(.rgb(128, 0, 128))
                }
            }

            DemoSection("Semantic Colors") {
                HStack(spacing: 2) {
                    Text("Primary").foregroundStyle(.primary)
                    Text("Success").foregroundStyle(.success)
                    Text("Warning").foregroundStyle(.warning)
                    Text("Error").foregroundStyle(.error)
                }
            }

            Spacer()
        }
        .appHeader {
            HStack {
                Text("Colors Demo").bold().foregroundStyle(.palette.accent)
                Spacer()
                Text("TUIkit v\(tuiKitVersion)").foregroundStyle(.palette.foregroundTertiary)
            }
        }
    }
}

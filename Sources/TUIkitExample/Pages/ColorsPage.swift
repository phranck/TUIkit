//
//  ColorsPage.swift
//  TUIkitExample
//
//  Demonstrates color capabilities.
//

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
        VStack(spacing: 1) {
            HeaderView(title: "Colors Demo")

            DemoSection("Standard ANSI Colors") {
                HStack(spacing: 2) {
                    Text("Black").foregroundColor(.black).background(.white)
                    Text("Red").foregroundColor(.red)
                    Text("Green").foregroundColor(.green)
                    Text("Yellow").foregroundColor(.yellow)
                }
                HStack(spacing: 2) {
                    Text("Blue").foregroundColor(.blue)
                    Text("Magenta").foregroundColor(.magenta)
                    Text("Cyan").foregroundColor(.cyan)
                    Text("White").foregroundColor(.white)
                }
            }

            DemoSection("Bright Colors") {
                HStack(spacing: 2) {
                    Text("Bright Red").foregroundColor(.brightRed)
                    Text("Bright Green").foregroundColor(.brightGreen)
                    Text("Bright Yellow").foregroundColor(.brightYellow)
                    Text("Bright Blue").foregroundColor(.brightBlue)
                }
            }

            DemoSection("RGB Colors (24-bit)") {
                HStack(spacing: 2) {
                    Text("Orange").foregroundColor(.rgb(255, 128, 0))
                    Text("Pink").foregroundColor(.rgb(255, 105, 180))
                    Text("Teal").foregroundColor(.rgb(0, 128, 128))
                    Text("Purple").foregroundColor(.rgb(128, 0, 128))
                }
            }

            DemoSection("Semantic Colors") {
                HStack(spacing: 2) {
                    Text("Primary").foregroundColor(.primary)
                    Text("Success").foregroundColor(.success)
                    Text("Warning").foregroundColor(.warning)
                    Text("Error").foregroundColor(.error)
                }
            }

            Spacer()
        }
    }
}

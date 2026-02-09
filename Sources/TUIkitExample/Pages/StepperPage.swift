//  TUIKit - Terminal UI Kit for Swift
//  StepperPage.swift
//
//  Created by LAYERED.work
//  License: MIT

import TUIkit

/// Stepper demo page.
///
/// Shows interactive stepper features including:
/// - Basic value stepping
/// - Range constraints
/// - Custom step sizes
/// - Custom callbacks
/// - Keyboard controls
struct StepperPage: View {
    @State var quantity: Int = 1
    @State var rating: Int = 3
    @State var volume: Int = 50
    @State var colorIndex: Int = 0

    let colors = ["Red", "Green", "Blue", "Yellow", "Purple"]

    var body: some View {
        VStack(alignment: .leading, spacing: 1) {

            DemoSection("Basic Stepper") {
                VStack(alignment: .leading, spacing: 1) {
                    HStack(spacing: 1) {
                        Text("Quantity:").foregroundStyle(.palette.foregroundSecondary)
                        Stepper("Quantity", value: $quantity)
                    }
                }
            }

            DemoSection("With Range Constraints") {
                VStack(alignment: .leading, spacing: 1) {
                    HStack(spacing: 1) {
                        Text("Rating (1-5):").foregroundStyle(.palette.foregroundSecondary)
                        Stepper("Rating", value: $rating, in: 1...5)
                    }
                    HStack(spacing: 1) {
                        Text("Volume (0-100, step 10):").foregroundStyle(.palette.foregroundSecondary)
                        Stepper("Volume", value: $volume, in: 0...100, step: 10)
                    }
                }
            }

            DemoSection("With Custom Callbacks") {
                VStack(alignment: .leading, spacing: 1) {
                    HStack(spacing: 1) {
                        Text("Color:").foregroundStyle(.palette.foregroundSecondary)
                        Stepper(
                            "Color",
                            onIncrement: {
                                colorIndex = (colorIndex + 1) % colors.count
                            },
                            onDecrement: {
                                colorIndex = (colorIndex - 1 + colors.count) % colors.count
                            }
                        )
                        Text(colors[colorIndex]).foregroundStyle(.palette.accent)
                    }
                }
            }

            DemoSection("Current Values") {
                VStack(alignment: .leading, spacing: 1) {
                    HStack(spacing: 1) {
                        Text("Quantity:").foregroundStyle(.palette.foregroundSecondary)
                        Text("\(quantity)").foregroundStyle(.palette.accent)
                    }
                    HStack(spacing: 1) {
                        Text("Rating:").foregroundStyle(.palette.foregroundSecondary)
                        Text("\(rating)").foregroundStyle(.palette.accent)
                    }
                    HStack(spacing: 1) {
                        Text("Volume:").foregroundStyle(.palette.foregroundSecondary)
                        Text("\(volume)").foregroundStyle(.palette.accent)
                    }
                    HStack(spacing: 1) {
                        Text("Color:").foregroundStyle(.palette.foregroundSecondary)
                        Text(colors[colorIndex]).foregroundStyle(.palette.accent)
                    }
                }
            }

            DemoSection("Keyboard Controls") {
                VStack(alignment: .leading) {
                    Text("[<-] [->] Decrease/Increase by step").dim()
                    Text("[-] [+] Decrease/Increase by step").dim()
                    Text("[Home] Jump to minimum (if range defined)").dim()
                    Text("[End] Jump to maximum (if range defined)").dim()
                    Text("[Tab] Move to next stepper").dim()
                }
            }

            Spacer()
        }
        .appHeader {
            HStack {
                Text("Stepper Demo").bold().foregroundStyle(.palette.accent)
                Spacer()
                Text("TUIkit v\(tuiKitVersion)").foregroundStyle(.palette.foregroundTertiary)
            }
        }
    }
}

//  🖥️ TUIKit — Terminal UI Kit for Swift
//  LayoutPage.swift
//
//  Created by LAYERED.work
//  License: MIT

import TUIkit

/// Layout system demo page.
///
/// Shows various layout options including:
/// - VStack (vertical stacking)
/// - HStack (horizontal stacking)
/// - Spacer (flexible space)
/// - Padding and frame modifiers
struct LayoutPage: View {
    var body: some View {
        VStack(spacing: 1) {

            DemoSection("VStack (Vertical)") {
                // Box uses appearance default borderStyle
                Box(color: .brightBlack) {
                    VStack(spacing: 0) {
                        Text("Item 1")
                        Text("Item 2")
                        Text("Item 3")
                    }
                }
            }

            DemoSection("HStack (Horizontal)") {
                Box(color: .brightBlack) {
                    HStack(spacing: 2) {
                        Text("Left")
                        Text("Center")
                        Text("Right")
                    }
                }
            }

            DemoSection("Spacer") {
                Box(color: .brightBlack) {
                    HStack {
                        Text("Start")
                        Spacer()
                        Text("End")
                    }
                }
            }

            DemoSection("Padding & Frame") {
                HStack(spacing: 2) {
                    VStack {
                        Text(".padding()").dim()
                        Text("Padded")
                            .padding(EdgeInsets(all: 1))
                            .border()  // Uses appearance default
                    }
                    VStack {
                        Text(".frame()").dim()
                        Text("Framed")
                            .frame(width: 15, alignment: .center)
                            .border()  // Uses appearance default
                    }
                }
            }

            Spacer()
        }
        .appHeader {
            HStack {
                Text("Layout System Demo").bold().foregroundColor(.palette.accent)
                Spacer()
                Text("TUIkit v\(tuiKitVersion)").foregroundColor(.palette.foregroundTertiary)
            }
        }
    }
}

//
//  LayoutPage.swift
//  SwiftTUIExample
//
//  Demonstrates layout system capabilities.
//

import SwiftTUI

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
            HeaderView(title: "Layout System Demo")

            DemoSection("VStack (Vertical)") {
                Box(.rounded, color: .brightBlack) {
                    VStack(spacing: 0) {
                        Text("Item 1")
                        Text("Item 2")
                        Text("Item 3")
                    }
                }
            }

            DemoSection("HStack (Horizontal)") {
                Box(.rounded, color: .brightBlack) {
                    HStack(spacing: 2) {
                        Text("Left")
                        Text("Center")
                        Text("Right")
                    }
                }
            }

            DemoSection("Spacer") {
                Box(.rounded, color: .brightBlack) {
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
                            .border(.line)
                    }
                    VStack {
                        Text(".frame()").dim()
                        Text("Framed")
                            .frame(width: 15, alignment: .center)
                            .border(.line)
                    }
                }
            }

            Spacer()
        }
    }
}

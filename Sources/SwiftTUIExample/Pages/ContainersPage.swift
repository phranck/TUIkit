//
//  ContainersPage.swift
//  SwiftTUIExample
//
//  Demonstrates container view capabilities.
//

import SwiftTUI

/// Container views demo page.
///
/// Shows various container views including:
/// - Card (bordered container with padding)
/// - Box (simple bordered container)
/// - Panel (container with title in border)
/// - All available border styles
struct ContainersPage: View {
    var body: some View {
        VStack(spacing: 1) {
            HeaderView(title: "Container Views Demo")

            HStack(spacing: 2) {
                // Card example
                VStack(alignment: .leading) {
                    Text("Card").bold().foregroundColor(.yellow)
                    Card(borderStyle: .rounded, borderColor: .cyan) {
                        Text("A Card view")
                        Text("with padding").dim()
                    }
                }

                // Box example
                VStack(alignment: .leading) {
                    Text("Box").bold().foregroundColor(.yellow)
                    Box(.doubleLine, color: .green) {
                        Text("Simple Box")
                    }
                }

                // Panel example
                VStack(alignment: .leading) {
                    Text("Panel").bold().foregroundColor(.yellow)
                    Panel("Info", borderStyle: .line, titleColor: .magenta) {
                        Text("Title in border")
                    }
                }
            }

            DemoSection("Border Styles") {
                HStack(spacing: 1) {
                    Box(.line) { Text("line") }
                    Box(.rounded) { Text("rounded") }
                    Box(.doubleLine) { Text("double") }
                    Box(.heavy) { Text("heavy") }
                    Box(.block) { Text("block") }
                }
            }

            Spacer()
        }
    }
}

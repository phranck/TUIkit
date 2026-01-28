//
//  ButtonsPage.swift
//  SwiftTUIExample
//
//  Demonstrates button and focus system capabilities.
//

import SwiftTUI

/// Buttons and focus demo page.
///
/// Shows interactive button features including:
/// - Different button styles (default, primary, success, destructive)
/// - Disabled buttons
/// - Plain style (no border)
/// - ButtonRow for horizontal groups
/// - Focus navigation with Tab
struct ButtonsPage: View {
    var body: some View {
        VStack(spacing: 1) {
            HeaderView(title: "Buttons & Focus Demo")

            DemoSection("Button Styles") {
                HStack(spacing: 2) {
                    Button("Default") {
                        // Default style button action
                    }
                    Button("Primary", style: .primary) {
                        // Primary button action
                    }
                    Button("Success", style: .success) {
                        // Success button action
                    }
                    Button("Destructive", style: .destructive) {
                        // Destructive button action
                    }
                }
            }

            DemoSection("Disabled Button") {
                HStack(spacing: 2) {
                    Button("Enabled") { }
                    Button("Disabled") { }.disabled()
                }
            }

            DemoSection("Plain Style (No Border)") {
                HStack(spacing: 2) {
                    Button("Link 1", style: .plain) { }
                    Button("Link 2", style: .plain) { }
                }
            }

            DemoSection("ButtonRow (Horizontal Group)") {
                ButtonRow(spacing: 3) {
                    Button("Cancel") { }
                    Button("Save", style: .primary) { }
                }
            }

            DemoSection("Focus Navigation") {
                VStack {
                    Text("Use [Tab] to move focus between buttons")
                        .dim()
                    Text("Use [Enter] or [Space] to press the focused button")
                        .dim()
                }
            }

            Spacer()
        }
    }
}

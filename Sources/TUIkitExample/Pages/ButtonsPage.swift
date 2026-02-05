//  🖥️ TUIKit — Terminal UI Kit for Swift
//  ButtonsPage.swift
//
//  Created by LAYERED.work
//  License: MIT

import TUIkit

/// Buttons and focus demo page.
///
/// Shows interactive button features including:
/// - Different button styles (default, primary, success, destructive)
/// - Disabled buttons
/// - Plain style (no border)
/// - ButtonRow for horizontal groups
/// - Focus navigation with Tab
/// - Live click counter demonstrating `@State` persistence across re-renders
struct ButtonsPage: View {
    @State var clickCount: Int = 0

    var body: some View {
        VStack(spacing: 1) {

            DemoSection("Interactive Counter (@State)") {
                HStack(spacing: 2) {
                    Button("+1", style: .primary) {
                        clickCount += 1
                    }
                    Button("+10", style: .success) {
                        clickCount += 10
                    }
                    Button("Reset", style: .destructive) {
                        clickCount = 0
                    }
                    Text("Clicks: \(clickCount)")
                        .bold()
                        .foregroundColor(.palette.accent)
                }
            }

            DemoSection("Button Styles") {
                HStack(spacing: 2) {
                    Button("Default") {
                        clickCount += 1
                    }
                    Button("Primary", style: .primary) {
                        clickCount += 1
                    }
                    Button("Success", style: .success) {
                        clickCount += 1
                    }
                    Button("Destructive", style: .destructive) {
                        clickCount += 1
                    }
                }
            }

            DemoSection("Disabled Button") {
                HStack(spacing: 2) {
                    Button("Enabled") { clickCount += 1 }
                    Button("Disabled") {}.disabled()
                }
            }

            DemoSection("Plain Style (No Border)") {
                HStack(spacing: 2) {
                    Button("Link 1", style: .plain) { clickCount += 1 }
                    Button("Link 2", style: .plain) { clickCount += 1 }
                }
            }

            DemoSection("ButtonRow (Horizontal Group)") {
                ButtonRow(spacing: 3) {
                    Button("Cancel") { clickCount += 1 }
                    Button("Save", style: .primary) { clickCount += 1 }
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
        .appHeader {
            HStack {
                Text("Buttons & Focus Demo").bold().foregroundColor(.palette.accent)
                Spacer()
                Text("TUIkit v\(tuiKitVersion)").foregroundColor(.palette.foregroundTertiary)
            }
        }
    }
}

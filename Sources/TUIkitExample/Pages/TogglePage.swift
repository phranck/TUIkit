//  🖥️ TUIKit — Terminal UI Kit for Swift
//  TogglePage.swift
//
//  Created by LAYERED.work
//  License: MIT

import TUIkit

/// Toggle and checkbox demo page.
///
/// Shows interactive toggle features including:
/// - Toggle style (slider with dots)
/// - Checkbox style (classic checkbox)
/// - Disabled toggles
/// - Focus navigation with Tab
/// - Live state changes demonstrating `@State` persistence across re-renders
struct TogglePage: View {
    @State var notificationsEnabled: Bool = false
    @State var darkModeEnabled: Bool = true
    @State var advancedOptionsEnabled: Bool = false
    @State var analitycsEnabled: Bool = true

    var body: some View {
        VStack(spacing: 1) {

            DemoSection("Toggle Style (Slider)") {
                VStack(spacing: 1) {
                    Toggle("Enable Notifications", isOn: $notificationsEnabled, style: .toggle)
                    Toggle("Dark Mode", isOn: $darkModeEnabled, style: .toggle)
                }
            }

            DemoSection("Checkbox Style") {
                VStack(spacing: 1) {
                    Toggle("Show Hidden Files", isOn: $advancedOptionsEnabled, style: .checkbox)
                    Toggle("Send Analytics", isOn: $analitycsEnabled, style: .checkbox)
                }
            }

            DemoSection("Disabled Toggles") {
                VStack(spacing: 1) {
                    Toggle("Enabled Toggle", isOn: $notificationsEnabled, style: .toggle)
                    Toggle("Disabled Toggle", isOn: Binding(get: { false }, set: { _ in }), style: .toggle)
                        .disabled()
                    Toggle("Disabled Checkbox", isOn: Binding(get: { true }, set: { _ in }), style: .checkbox)
                        .disabled()
                }
            }

            DemoSection("State Summary") {
                VStack(spacing: 1) {
                    HStack(spacing: 1) {
                        Text("Notifications:").foregroundColor(.palette.foregroundSecondary)
                        Text(notificationsEnabled ? "[●○]" : "[○●]").foregroundColor(.palette.accent)
                    }
                    HStack(spacing: 1) {
                        Text("Dark Mode:").foregroundColor(.palette.foregroundSecondary)
                        Text(darkModeEnabled ? "[●○]" : "[○●]").foregroundColor(.palette.accent)
                    }
                    HStack(spacing: 1) {
                        Text("Hidden Files:").foregroundColor(.palette.foregroundSecondary)
                        Text(advancedOptionsEnabled ? "[●]" : "[ ]").foregroundColor(.palette.accent)
                    }
                    HStack(spacing: 1) {
                        Text("Analytics:").foregroundColor(.palette.foregroundSecondary)
                        Text(analitycsEnabled ? "[●]" : "[ ]").foregroundColor(.palette.accent)
                    }
                }
            }

            DemoSection("Focus Navigation") {
                VStack {
                    Text("Use [Tab] to move focus between toggles")
                        .dim()
                    Text("Use [Space] or [Enter] to toggle the focused item")
                        .dim()
                }
            }

            Spacer()
        }
        .appHeader {
            HStack {
                Text("Toggles & Checkboxes Demo").bold().foregroundColor(.palette.accent)
                Spacer()
                Text("TUIkit v\(tuiKitVersion)").foregroundColor(.palette.foregroundTertiary)
            }
        }
    }
}

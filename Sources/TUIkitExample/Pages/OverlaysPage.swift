//
//  OverlaysPage.swift
//  TUIkitExample
//
//  Demonstrates overlay and modal capabilities with an interactive menu.
//

import TUIkit

// MARK: - Overlay Demo Variants

/// Available overlay demo variants.
private enum OverlayDemo: Int, CaseIterable {
    case alertStandard
    case alertWarning
    case alertError
    case alertInfo
    case alertSuccess
    case dialog
    case dialogWithFooter
    case modalCustom

    /// Display label for the menu.
    var label: String {
        switch self {
        case .alertStandard: "Alert (Standard)"
        case .alertWarning: "Alert (Warning)"
        case .alertError: "Alert (Error)"
        case .alertInfo: "Alert (Info)"
        case .alertSuccess: "Alert (Success)"
        case .dialog: "Dialog"
        case .dialogWithFooter: "Dialog with Footer"
        case .modalCustom: "Modal (Custom)"
        }
    }

    /// Description text for the detail panel.
    var description: String {
        switch self {
        case .alertStandard:
            "A standard alert with default theme colors. Uses .alert(isPresented:) modifier."
        case .alertWarning:
            "A warning-style alert with yellow border and title. Uses Alert.warning() preset."
        case .alertError:
            "An error-style alert with red border and title. Uses Alert.error() preset."
        case .alertInfo:
            "An info-style alert with cyan border and title. Uses Alert.info() preset."
        case .alertSuccess:
            "A success-style alert with green border and title. Uses Alert.success() preset."
        case .dialog:
            "A Dialog view with custom content. More flexible than Alert — accepts any views."
        case .dialogWithFooter:
            "A Dialog with a footer section for action buttons, separated by a divider line."
        case .modalCustom:
            "A custom modal overlay using .modal(isPresented:). Accepts any view as content."
        }
    }

    /// API usage example for the detail panel.
    var apiUsage: String {
        switch self {
        case .alertStandard:
            ".alert(\"Title\", isPresented: $show) { actions } message: { Text(\"...\") }"
        case .alertWarning:
            ".modal(isPresented: $show) { Alert.warning(message: \"...\") { actions } }"
        case .alertError:
            ".modal(isPresented: $show) { Alert.error(message: \"...\") { actions } }"
        case .alertInfo:
            ".modal(isPresented: $show) { Alert.info(message: \"...\") { actions } }"
        case .alertSuccess:
            ".modal(isPresented: $show) { Alert.success(message: \"...\") { actions } }"
        case .dialog:
            ".modal(isPresented: $show) { Dialog(title: \"...\") { content } }"
        case .dialogWithFooter:
            ".modal(isPresented: $show) { Dialog(title: \"...\") { content } footer: { buttons } }"
        case .modalCustom:
            ".modal(isPresented: $show) { VStack { ... } }"
        }
    }
}

// MARK: - Overlays Page

/// Interactive overlays and modals demo page.
///
/// Displays a menu of overlay variants on the left and a description
/// panel on the right. Pressing Enter shows the selected overlay
/// with dimmed background content.
struct OverlaysPage: View {
    @State var menuSelection: Int = 0
    @State var showOverlay: Bool = false

    /// The currently selected demo variant.
    private var selectedDemo: OverlayDemo {
        OverlayDemo.allCases[menuSelection]
    }

    var body: some View {
        backgroundContent
            .modal(isPresented: $showOverlay) {
                overlayContent(for: selectedDemo)
            }
    }

    // MARK: - Background Content

    /// The main background content with menu and description.
    private var backgroundContent: some View {
        VStack(spacing: 1) {
            HeaderView(title: "Overlays & Modals Demo")

            HStack(spacing: 3) {
                // Left: Demo menu
                Menu(
                    title: "Select a Demo",
                    items: OverlayDemo.allCases.map { demo in
                        MenuItem(label: demo.label, shortcut: nil)
                    },
                    selection: $menuSelection,
                    onSelect: { _ in
                        showOverlay = true
                    },
                    selectedColor: .palette.accent,
                    borderColor: .palette.border
                )

                // Right: Description of selected demo
                descriptionPanel
            }

            DemoSection("How It Works") {
                Text("All overlays use the SwiftUI-style presentation API:")
                    .foregroundColor(.palette.foregroundSecondary)
                Text("  .alert(isPresented:) — for Alert views")
                    .foregroundColor(.palette.foregroundSecondary)
                Text("  .modal(isPresented:) — for Dialog, custom content")
                    .foregroundColor(.palette.foregroundSecondary)
                Text("The background is automatically dimmed. Status bar stays visible.")
                    .bold()
                    .foregroundColor(.palette.accent)
            }

            Spacer()
        }
    }

    // MARK: - Description Panel

    /// Detail panel showing the selected demo's description and API usage.
    private var descriptionPanel: some View {
        Panel(selectedDemo.label, titleColor: .palette.accent) {
            VStack(alignment: .leading, spacing: 1) {
                Text(selectedDemo.description)
                    .foregroundColor(.palette.foreground)

                Text("")

                Text("API:")
                    .bold()
                    .foregroundColor(.palette.accent)
                Text("  \(selectedDemo.apiUsage)")
                    .foregroundColor(.palette.foregroundSecondary)
            }
        }
        .frame(width: 55)
    }

    // MARK: - Overlay Content

    /// Builds the overlay content for the selected demo variant.
    @ViewBuilder
    private func overlayContent(for demo: OverlayDemo) -> some View {
        switch demo {
        case .alertStandard:
            Alert(
                title: "Standard Alert",
                message: "This is a standard alert with default theme colors.",
                borderColor: .palette.border,
                titleColor: .palette.accent
            ) {
                dismissButton
            }
            .frame(width: 50)

        case .alertWarning:
            Alert(
                title: "Warning",
                message: "Something might go wrong. Please check your input.",
                borderColor: .yellow,
                titleColor: .yellow
            ) {
                dismissButton
            }
            .frame(width: 50)

        case .alertError:
            Alert(
                title: "Error",
                message: "An unexpected error occurred. Please try again.",
                borderColor: .red,
                titleColor: .red
            ) {
                dismissButton
            }
            .frame(width: 50)

        case .alertInfo:
            Alert(
                title: "Info",
                message: "This is an informational message for the user.",
                borderColor: .cyan,
                titleColor: .cyan
            ) {
                dismissButton
            }
            .frame(width: 50)

        case .alertSuccess:
            Alert(
                title: "Success",
                message: "Operation completed successfully!",
                borderColor: .green,
                titleColor: .green
            ) {
                dismissButton
            }
            .frame(width: 50)

        case .dialog:
            Dialog(title: "Settings", borderColor: .palette.border, titleColor: .palette.accent) {
                VStack(alignment: .leading) {
                    Text("Theme: Dark")
                        .foregroundColor(.palette.foreground)
                    Text("Language: English")
                        .foregroundColor(.palette.foreground)
                    Text("Notifications: On")
                        .foregroundColor(.palette.foreground)
                    Text("")
                    dismissButton
                }
            }
            .frame(width: 50)

        case .dialogWithFooter:
            Dialog(
                title: "Confirm Action",
                borderColor: .palette.border,
                titleColor: .palette.accent
            ) {
                Text("Are you sure you want to proceed?")
                    .foregroundColor(.palette.foreground)
                Text("This action cannot be undone.")
                    .foregroundColor(.palette.foregroundSecondary)
            } footer: {
                dismissButton
            }
            .frame(width: 50)

        case .modalCustom:
            VStack(spacing: 1) {
                Text("Custom Modal Content")
                    .bold()
                    .foregroundColor(.palette.accent)
                Text("")
                Text("This modal uses .modal(isPresented:)")
                    .foregroundColor(.palette.foreground)
                Text("with completely custom view content.")
                    .foregroundColor(.palette.foregroundSecondary)
                Text("No Alert or Dialog — just any View!")
                    .foregroundColor(.palette.foregroundSecondary)
                Text("")
                dismissButton
            }
            .padding(EdgeInsets(horizontal: 2, vertical: 1))
            .border(color: .palette.border)
        }
    }

    /// Reusable right-aligned dismiss button for all overlay variants.
    private var dismissButton: some View {
        HStack {
            Spacer()
            Button("Dismiss", style: .primary) {
                showOverlay = false
            }
        }
    }
}

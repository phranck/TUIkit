//  🖥️ TUIKit — Terminal UI Kit for Swift
//  OverlaysPage.swift
//
//  Created by LAYERED.work
//  License: MIT

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
    case notification

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
        case .notification: "Notification"
        }
    }

    /// Description text for the detail panel.
    var description: String {
        switch self {
        case .alertStandard:
            "A standard alert with default theme colors. Uses .alert(isPresented:) modifier."
        case .alertWarning:
            "A warning-style alert with palette warning colors. Uses Alert.warning() preset."
        case .alertError:
            "An error-style alert with palette error colors. Uses Alert.error() preset."
        case .alertInfo:
            "An info-style alert with palette info colors. Uses Alert.info() preset."
        case .alertSuccess:
            "A success-style alert with palette success colors. Uses Alert.success() preset."
        case .dialog:
            "A Dialog view with custom content. More flexible than Alert — accepts any views."
        case .dialogWithFooter:
            "A Dialog with a footer section for action buttons, separated by a divider line."
        case .modalCustom:
            "A custom modal overlay using .modal(isPresented:). Accepts any view as content."
        case .notification:
            "A fire-and-forget notification. Fades in, stays 3s, fades out. Posted via NotificationService."
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
        case .notification:
            "NotificationService.current.post(\"Saved!\")"
        }
    }

    /// Whether this demo variant is a notification (not a modal).
    var isNotification: Bool {
        self == .notification
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

    /// Callback to navigate back to the main menu.
    let onBack: () -> Void

    /// The currently selected demo variant.
    private var selectedDemo: OverlayDemo {
        OverlayDemo.allCases[menuSelection]
    }

    var body: some View {
        backgroundContent
            .modal(isPresented: $showOverlay) {
                overlayContent(for: selectedDemo)
            }
            .notificationHost()
            .statusBarItems(statusBarItems)
    }

    /// Status bar items change depending on whether a modal is open.
    /// When a modal is presented, ESC closes the modal instead of navigating back.
    private var statusBarItems: [any StatusBarItemProtocol] {
        if showOverlay {
            return [
                StatusBarItem(shortcut: Shortcut.escape, label: "close") {
                    showOverlay = false
                },
                StatusBarItem(shortcut: Shortcut.enter, label: "dismiss"),
            ]
        } else {
            return [
                StatusBarItem(shortcut: Shortcut.escape, label: "back") {
                    onBack()
                },
                StatusBarItem(shortcut: Shortcut.arrowsUpDown, label: "nav"),
                StatusBarItem(shortcut: Shortcut.enter, label: "show"),
            ]
        }
    }

    // MARK: - Background Content

    /// The main background content with menu and description.
    private var backgroundContent: some View {
        VStack(spacing: 1) {
            HStack(spacing: 3) {
                // Left: Demo menu
                Menu(
                    title: "Select a Demo",
                    items: OverlayDemo.allCases.map { demo in
                        MenuItem(label: demo.label, shortcut: nil)
                    },
                    selection: $menuSelection,
                    onSelect: { _ in
                        if selectedDemo.isNotification {
                            NotificationService.current.post(
                                "Operation completed successfully!"
                            )
                        } else {
                            showOverlay = true
                        }
                    },
                    selectedColor: .palette.accent,
                    borderColor: .palette.border
                )

                // Right: Description of selected demo
                descriptionPanel
            }

            DemoSection("How It Works") {
                Text("All overlays use the SwiftUI-style presentation API:")
                    .foregroundStyle(.palette.foregroundSecondary)
                Text("  .alert(isPresented:)        — for Alert views")
                    .foregroundStyle(.palette.foregroundSecondary)
                Text("  .modal(isPresented:)        — for Dialog, custom content")
                    .foregroundStyle(.palette.foregroundSecondary)
                Text("  NotificationService.current.post() — fire-and-forget with fade")
                    .foregroundStyle(.palette.foregroundSecondary)
                Text("Modals dim the background. Notifications stay non-blocking.")
                    .bold()
                    .foregroundStyle(.palette.accent)
            }

            Spacer()
        }
        .appHeader {
            HStack {
                Text("Overlays, Modals & Notifications Demo").bold().foregroundStyle(.palette.accent)
                Spacer()
                Text("TUIkit v\(tuiKitVersion)").foregroundStyle(.palette.foregroundTertiary)
            }
        }
    }

    // MARK: - Description Panel

    /// Detail panel showing the selected demo's description and API usage.
    private var descriptionPanel: some View {
        Panel(selectedDemo.label, titleColor: .palette.accent) {
            VStack(alignment: .leading, spacing: 1) {
                Text(selectedDemo.description)
                    .foregroundStyle(.palette.foreground)

                Text("")

                Text("API:")
                    .bold()
                    .foregroundStyle(.palette.accent)
                Text("  \(selectedDemo.apiUsage)")
                    .foregroundStyle(.palette.foregroundSecondary)
            }
        }
        .frame(width: 55)
    }

    // MARK: - Overlay Content

    /// Builds the overlay content for the selected demo variant.
    @ViewBuilder
    private func overlayContent(for demo: OverlayDemo) -> some View {
        switch demo {
        case .alertStandard, .alertWarning, .alertError,
             .alertInfo, .alertSuccess:
            alertContent(for: demo)

        case .dialog:
            Dialog(title: "Settings", borderColor: .palette.border, titleColor: .palette.accent) {
                VStack(alignment: .leading) {
                    Text("Theme: Dark").foregroundStyle(.palette.foreground)
                    Text("Language: English").foregroundStyle(.palette.foreground)
                    Text("Notifications: On").foregroundStyle(.palette.foreground)
                    Text("")
                    dismissButton
                }
            }
            .frame(width: 50)

        case .dialogWithFooter:
            Dialog(title: "Confirm Action", borderColor: .palette.border, titleColor: .palette.accent) {
                Text("Are you sure you want to proceed?").foregroundStyle(.palette.foreground)
                Text("This action cannot be undone.").foregroundStyle(.palette.foregroundSecondary)
            } footer: {
                dismissButton
            }
            .frame(width: 50)

        case .modalCustom:
            VStack(spacing: 1) {
                Text("Custom Modal Content").bold().foregroundStyle(.palette.accent)
                Text("")
                Text("This modal uses .modal(isPresented:)").foregroundStyle(.palette.foreground)
                Text("with completely custom view content.").foregroundStyle(.palette.foregroundSecondary)
                Text("No Alert or Dialog — just any View!").foregroundStyle(.palette.foregroundSecondary)
                Text("")
                dismissButton
            }
            .padding(EdgeInsets(horizontal: 2, vertical: 1))
            .border(color: .palette.border)

        case .notification:
            // Notifications are posted via NotificationService, not shown as modal content.
            EmptyView()
        }
    }

    /// Builds an alert for the given demo variant.
    @ViewBuilder
    private func alertContent(for demo: OverlayDemo) -> some View {
        switch demo {
        case .alertStandard:
            Alert(
                title: "Standard Alert",
                message: "This is a standard alert with default theme colors.",
                borderColor: .palette.border, titleColor: .palette.accent
            ) { dismissButton }.frame(width: 50)
        case .alertWarning:
            Alert(
                title: "Warning",
                message: "Something might go wrong. Please check your input.",
                titleColor: .palette.warning
            ) { dismissButton }.frame(width: 50)
        case .alertError:
            Alert(
                title: "Error",
                message: "An unexpected error occurred. Please try again.",
                titleColor: .palette.error
            ) { dismissButton }.frame(width: 50)
        case .alertInfo:
            Alert(
                title: "Info",
                message: "This is an informational message for the user.",
                titleColor: .palette.info
            ) { dismissButton }.frame(width: 50)
        case .alertSuccess:
            Alert(
                title: "Success",
                message: "Operation completed successfully!",
                titleColor: .palette.success
            ) { dismissButton }.frame(width: 50)
        default:
            EmptyView()
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

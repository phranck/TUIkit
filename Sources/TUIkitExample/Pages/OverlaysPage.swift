//
//  OverlaysPage.swift
//  TUIkitExample
//
//  Demonstrates overlay and modal capabilities.
//

import TUIkit

/// Overlays and modals demo page.
///
/// Shows the overlay system including:
/// - `.overlay()` modifier with `@State`-controlled visibility
/// - `.dimmed()` modifier
/// - `.modal()` helper
/// - Note: The status bar is NOT dimmed by modals!
struct OverlaysPage: View {
    @State var showModal: Bool = true

    var body: some View {
        if showModal {
            backgroundContent
                .dimmed()
                .overlay {
                    HStack {
                        Spacer()
                        Alert(
                            title: "Alert",
                            message: "This alert overlays dimmed content!",
                            borderColor: .palette.border,
                            titleColor: .palette.accent
                        ) {
                            VStack(spacing: 1) {
                                Button("Dismiss", style: .primary) {
                                    showModal = false
                                }
                            }
                        }
                        .frame(width: 55)
                        Spacer()
                    }
                }
        } else {
            backgroundContent
        }
    }

    var backgroundContent: some View {
        VStack(spacing: 1) {
            HeaderView(title: "Overlays & Modals Demo")

            DemoSection("Overlay System Features") {
                Text("  .overlay() modifier - layer content on top")
                Text("  .dimmed() modifier - reduce visual emphasis")
                Text("  .modal() helper - combines dimmed + centered overlay")
            }

            DemoSection("Modal Toggle (@State)") {
                HStack(spacing: 2) {
                    if showModal {
                        Text("Modal is visible")
                            .foregroundColor(.palette.accent)
                    } else {
                        Text("Modal dismissed")
                            .foregroundColor(.palette.foregroundSecondary)
                        Button("Show Again", style: .primary) {
                            showModal = true
                        }
                    }
                }
            }

            DemoSection("How It Works") {
                Text("The modal visibility is controlled by @State var showModal")
                Text("Pressing 'Dismiss' sets showModal = false")
                    .foregroundColor(.palette.foregroundSecondary)
                Text("Note: The status bar is NOT dimmed!")
                    .bold()
                    .foregroundColor(.palette.accent)
            }

            Spacer()
        }
    }
}

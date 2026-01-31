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
/// - `.overlay()` modifier
/// - `.dimmed()` modifier
/// - `.modal()` helper
/// - Note: The status bar is NOT dimmed by modals!
struct OverlaysPage: View {
    var body: some View {
        // Background content with modal overlay
        backgroundContent
            .dimmed()
            .overlay {
                HStack {
                    Spacer()
                    Alert(
                        title: "Alert",
                        message: "This alert overlays dimmed content!",
                        // borderStyle uses appearance default
                        borderColor: .palette.border,
                        titleColor: .palette.accent
                    ) {
                        VStack(spacing: 1) {
                            Button("OK", style: .primary) {}
                            Button("Cancel") {}
                        }
                    }
                    .frame(width: 55)
                    Spacer()
                }
            }
    }

    var backgroundContent: some View {
        VStack(spacing: 1) {
            HeaderView(title: "Overlays & Modals Demo")

            DemoSection("Overlay System Features") {
                Text("• .overlay() modifier - layer content on top")
                Text("• .dimmed() modifier - reduce visual emphasis")
                Text("• .modal() helper - combines dimmed + centered overlay")
            }

            DemoSection("This page demonstrates a modal overlay") {
                Text("The content behind is dimmed automatically")
                Text("Note: The status bar is NOT dimmed!")
                    .bold()
                    .foregroundColor(.palette.accent)
            }

            Spacer()
        }
    }
}

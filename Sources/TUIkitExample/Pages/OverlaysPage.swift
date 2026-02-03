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
/// - `.alert(isPresented:)` modifier - SwiftUI-style alert presentation
/// - `.modal(isPresented:)` modifier - SwiftUI-style modal presentation
/// - `.dimmed()` modifier - visual de-emphasis
/// - Note: The status bar is NOT dimmed by modals!
struct OverlaysPage: View {
    @State var showModal: Bool = true

    var body: some View {
        backgroundContent
            .alert(
                "Alert Demo",
                isPresented: $showModal,
                actions: {
                    Button("Dismiss", style: .primary) {
                        showModal = false
                    }
                },
                message: "This alert uses the new .alert(isPresented:) API!",
                borderColor: .palette.border,
                titleColor: .palette.accent
            )
    }

    var backgroundContent: some View {
        VStack(spacing: 1) {
            HeaderView(title: "Overlays & Modals Demo")

            DemoSection("Presentation APIs (SwiftUI-style)") {
                Text("  .alert(isPresented:) - declarative alert presentation")
                Text("  .modal(isPresented:) - declarative modal presentation")
                Text("  .overlay() - layer content on top")
                Text("  .dimmed() - reduce visual emphasis")
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
                Text("Uses .alert(isPresented: $showModal) { ... }")
                    .foregroundColor(.palette.foregroundSecondary)
                Text("No manual if/else needed - SwiftUI-style API!")
                    .bold()
                    .foregroundColor(.palette.accent)
                Text("Pressing 'Dismiss' sets showModal = false")
                    .foregroundColor(.palette.foregroundSecondary)
                Text("Status bar is NOT dimmed (separate render layer)")
                    .foregroundColor(.palette.foregroundSecondary)
            }

            Spacer()
        }
    }
}

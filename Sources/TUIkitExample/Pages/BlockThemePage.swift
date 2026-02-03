//
//  BlockThemePage.swift
//  TUIkitExample
//
//  Visual test page for Block appearance background colors.
//  Shows all background roles side by side for color tuning.
//

import TUIkit

/// Block theme color tuning page.
///
/// Displays all background color roles used in block appearance
/// as labeled color swatches. This page is designed to be viewed
/// exclusively in block appearance mode for visual comparison.
struct BlockThemePage: View {
    var body: some View {
        VStack(spacing: 1) {
            HeaderView(title: "Block Theme Colors")

            Text("Switch to block appearance (press 'a') and violet theme (press 't').")
                .foregroundColor(.palette.foregroundSecondary)

            // Panel with Header, Body, and Footer — shows all 3 block background roles
            DemoSection("Panel with Header + Body + Footer") {
                Panel("Header — surfaceHeaderBackground", titleColor: .palette.accent) {
                    Text("Body area — surfaceBackground").foregroundColor(.palette.foreground)
                    Text("Secondary on body").foregroundColor(.palette.foregroundSecondary)
                    Text("Tertiary on body").foregroundColor(.palette.foregroundTertiary)
                } footer: {
                    Text("Footer — surfaceHeaderBackground").foregroundColor(.palette.foreground)
                }
            }

            // Side-by-side containers to compare
            DemoSection("Panel vs Card vs Box") {
                HStack(spacing: 2) {
                    Panel("Panel", titleColor: .palette.accent) {
                        Text("Foreground").foregroundColor(.palette.foreground)
                        Text("Secondary").foregroundColor(.palette.foregroundSecondary)
                        Text("Tertiary").foregroundColor(.palette.foregroundTertiary)
                    }

                    Card {
                        Text("Foreground").foregroundColor(.palette.foreground)
                        Text("Secondary").foregroundColor(.palette.foregroundSecondary)
                        Text("Tertiary").foregroundColor(.palette.foregroundTertiary)
                    }

                    Box {
                        Text("Foreground").foregroundColor(.palette.foreground)
                        Text("Secondary").foregroundColor(.palette.foregroundSecondary)
                        Text("Tertiary").foregroundColor(.palette.foregroundTertiary)
                    }
                }
            }

            // Buttons on app background
            DemoSection("Buttons — elevatedBackground") {
                HStack(spacing: 2) {
                    Button("Default") {}
                    Button("Primary", style: .primary) {}
                    Button("Destructive", style: .destructive) {}
                }
            }

            // Buttons inside a Panel (on surfaceBackground)
            DemoSection("Buttons inside Panel") {
                Panel("Panel with Buttons", titleColor: .palette.accent) {
                    Text("Buttons on surfaceBackground:").foregroundColor(.palette.foregroundSecondary)
                    HStack(spacing: 2) {
                        Button("Default") {}
                        Button("Primary", style: .primary) {}
                    }
                }
            }

            Spacer()
        }
    }
}

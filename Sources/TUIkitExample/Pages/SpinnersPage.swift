//
//  SpinnersPage.swift
//  TUIkitExample
//
//  Demo page showcasing the Spinner view with all three styles.
//

import TUIkit

/// A demo page showing all Spinner styles.
struct SpinnersPage: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            HeaderView(title: "Spinners")

            DemoSection("Dots (Braille Rotation)") {
                Spinner("Loading data...")
            }

            DemoSection("Line (ASCII Rotation)") {
                Spinner("Compiling...", style: .line)
            }

            DemoSection("Bouncing (Knight Rider)") {
                Spinner("Processing...", style: .bouncing)
            }

            DemoSection("Custom Color") {
                Spinner("Installing...", style: .bouncing, color: .palette.success)
            }

            Spacer()
        }
    }
}

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
                Spinner("Loading data...", style: .dots)
            }

            DemoSection("Line (ASCII Rotation)") {
                Spinner("slow", style: .line, speed: .slow)
                Spinner("regular", style: .line, speed: .regular)
                Spinner("fast", style: .line, speed: .fast)
            }

            DemoSection("Bouncing (Knight Rider)") {
                Spinner("Short trail (.regular)", style: .bouncing, trailLength: .short)
                Spinner("Regular trail (.regular)", style: .bouncing, trailLength: .regular)
                Spinner("Long trail (.regular)", style: .bouncing, trailLength: .long)
            }

            DemoSection("Bouncing Speed") {
                Spinner("slow", style: .bouncing, speed: .slow)
                Spinner("regular", style: .bouncing, speed: .regular)
                Spinner("fast", style: .bouncing, speed: .fast)
            }

            DemoSection("Bouncing Track Width") {
                Spinner("Minimum (.regular)", style: .bouncing, trackWidth: .minimum)
                Spinner("Default (.regular)", style: .bouncing)
                Spinner("Fixed 15 (.regular)", style: .bouncing, trackWidth: 15)
                Spinner("Full width (.fast)", style: .bouncing, speed: .fast, trackWidth: .maximum, trailLength: .long)
            }

            DemoSection("Speed Variants") {
                Spinner("Slow", style: .dots, speed: .slow)
                Spinner("Regular", style: .dots, speed: .regular)
                Spinner("Fast", style: .dots, speed: .fast)
            }

            DemoSection("Custom Color") {
                Spinner("Installing...", style: .bouncing, color: .green)
            }

            Spacer()
        }
    }
}

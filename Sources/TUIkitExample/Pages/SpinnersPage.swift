//  🖥️ TUIKit — Terminal UI Kit for Swift
//  SpinnersPage.swift
//
//  Created by LAYERED.work
//  License: MIT

import TUIkit

/// A demo page showing all Spinner styles.
struct SpinnersPage: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 1) {

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
        .appHeader {
            HStack {
                Text("Spinners").bold().foregroundStyle(.palette.accent)
                Spacer()
                Text("TUIkit v\(tuiKitVersion)").foregroundStyle(.palette.foregroundTertiary)
            }
        }
    }
}

//  🖥️ TUIKit — Terminal UI Kit for Swift
//  TextStylesPage.swift
//
//  Created by LAYERED.work
//  License: MIT

import TUIkit

/// Text styles demo page.
///
/// Shows various text styling options including:
/// - Basic styles (bold, italic, underline, etc.)
/// - Combined styles
/// - Special effects (blink, inverted)
struct TextStylesPage: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            DemoSection("Basic Styles") {
                Text("Normal text - no styling applied")
                Text("Bold text").bold()
                Text("Italic text").italic()
                Text("Underlined text").underline()
                Text("Strikethrough text").strikethrough()
                Text("Dimmed text").dim()
            }

            DemoSection("Combined Styles") {
                Text("Bold + Italic").bold().italic()
                Text("Bold + Underline").bold().underline()
                Text("Bold + Color").bold().foregroundStyle(.palette.accent)
                Text("Italic + Dim").italic().dim()
                Text("All combined").bold().italic().underline().foregroundStyle(.palette.accent)
            }

            DemoSection("Special Effects") {
                Text("Blinking text (if terminal supports)").blink()
                Text("Inverted colors").inverted()
            }

            Spacer()
        }
        .appHeader {
            HStack {
                Text("Text Styles Demo").bold().foregroundStyle(.palette.accent)
                Spacer()
                Text("TUIkit v\(tuiKitVersion)").foregroundStyle(.palette.foregroundTertiary)
            }
        }
    }
}

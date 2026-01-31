//
//  TextStylesPage.swift
//  TUIkitExample
//
//  Demonstrates text styling capabilities.
//

import TUIkit

/// Text styles demo page.
///
/// Shows various text styling options including:
/// - Basic styles (bold, italic, underline, etc.)
/// - Combined styles
/// - Special effects (blink, inverted)
struct TextStylesPage: View {
    var body: some View {
        VStack(spacing: 1) {
            HeaderView(title: "Text Styles Demo")

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
                Text("Bold + Color").bold().foregroundColor(.palette.accent)
                Text("Italic + Dim").italic().dim()
                Text("All combined").bold().italic().underline().foregroundColor(.palette.accent)
            }

            DemoSection("Special Effects") {
                Text("Blinking text (if terminal supports)").blink()
                Text("Inverted colors").inverted()
            }

            Spacer()
        }
    }
}

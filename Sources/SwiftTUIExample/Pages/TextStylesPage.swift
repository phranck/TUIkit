//
//  TextStylesPage.swift
//  SwiftTUIExample
//
//  Demonstrates text styling capabilities.
//

import SwiftTUI

/// Text styles demo page.
///
/// Shows various text styling options including:
/// - Basic styles (bold, italic, underline, etc.)
/// - Combined styles
/// - Special effects (blink, inverted)
struct TextStylesPage: TView {
    var body: some TView {
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
                Text("Bold + Color").bold().foregroundColor(.cyan)
                Text("Italic + Dim").italic().dim()
                Text("All combined").bold().italic().underline().foregroundColor(.magenta)
            }

            DemoSection("Special Effects") {
                Text("Blinking text (if terminal supports)").blink()
                Text("Inverted colors").inverted()
            }

            Spacer()
        }
    }
}

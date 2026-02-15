//  🖥️ TUIKit — Terminal UI Kit for Swift
//  RadioButtonPage.swift
//
//  Created by LAYERED.work
//  License: MIT

import TUIkit

/// Radio button group demo page.
///
/// Shows interactive radio button features including:
/// - Vertical layout (default)
/// - Horizontal layout
/// - Single-selection with binding
/// - Disabled radio groups
/// - Focus navigation with arrow keys
/// - Live state changes demonstrating `@State` persistence across re-renders
struct RadioButtonPage: View {
    @State var colorChoice: String = "blue"
    @State var sizeChoice: String = "medium"
    @State var layoutChoice: String = "vertical"

    var body: some View {
        VStack(alignment: .leading, spacing: 1) {

            DemoSection("Color Selection (Vertical)") {
                RadioButtonGroup(selection: $colorChoice) {
                    RadioButtonItem("red", "Red")
                    RadioButtonItem("green", "Green")
                    RadioButtonItem("blue", "Blue")
                    RadioButtonItem("yellow", "Yellow")
                }
            }

            DemoSection("Size Selection (Vertical)") {
                RadioButtonGroup(selection: $sizeChoice) {
                    RadioButtonItem("small", "Small")
                    RadioButtonItem("medium", "Medium")
                    RadioButtonItem("large", "Large")
                }
            }

            DemoSection("Layout Style (Horizontal)") {
                RadioButtonGroup(selection: $layoutChoice, orientation: .horizontal) {
                    RadioButtonItem("vertical", "Vertical")
                    RadioButtonItem("horizontal", "Horizontal")
                }
            }

            DemoSection("Disabled Group") {
                RadioButtonGroup(selection: Binding(get: { "disabled" }, set: { _ in })) {
                    RadioButtonItem("disabled", "This group is disabled")
                }
                .disabled()
            }

            DemoSection("Current Selections") {
                VStack(alignment: .leading, spacing: 1) {
                    ValueDisplayRow("Color:", colorChoice)
                    ValueDisplayRow("Size:", sizeChoice)
                    ValueDisplayRow("Layout:", layoutChoice)
                }
            }

            KeyboardHelpSection("Focus Navigation", shortcuts: [
                "Use [↑/↓] to navigate vertically",
                "Use [←/→] to navigate horizontally",
                "Use [Enter] or [Space] to select",
            ])

            Spacer()
        }
        .appHeader {
            DemoAppHeader("Radio Buttons Demo")
        }
    }
}

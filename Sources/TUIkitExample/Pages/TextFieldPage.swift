//  TUIKit - Terminal UI Kit for Swift
//  TextFieldPage.swift
//
//  Created by LAYERED.work
//  License: MIT

import TUIkit

/// TextField demo page.
///
/// Shows interactive text field features including:
/// - Basic text input with cursor
/// - Cursor styles (block, bar, underscore)
/// - Cursor animations (none, blink, pulse)
/// - Cursor speeds (slow, regular, fast)
/// - Cursor navigation (left/right/home/end)
/// - Text editing (insert, backspace, delete)
/// - onSubmit action
/// - Disabled state
struct TextFieldPage: View {
    @State var demoText: String = ""
    @State var searchQuery: String = ""
    @State var disabledText: String = "Cannot edit"
    @State var submittedValue: String = ""

    @State var cursorShapeIndex: Int = 0
    @State var cursorAnimationIndex: Int = 0
    @State var cursorSpeedIndex: Int = 1  // Start at regular

    private let shapes: [TextCursorStyle.Shape] = [.block, .bar, .underscore]
    private let animations: [TextCursorStyle.Animation] = [.none, .blink, .pulse]
    private let speeds: [TextCursorStyle.Speed] = [.slow, .regular, .fast]

    private var currentShape: TextCursorStyle.Shape {
        shapes[cursorShapeIndex]
    }

    private var currentAnimation: TextCursorStyle.Animation {
        animations[cursorAnimationIndex]
    }

    private var currentSpeed: TextCursorStyle.Speed {
        speeds[cursorSpeedIndex]
    }

    private var shapeLabel: String {
        switch currentShape {
        case .block: "█ Block"
        case .bar: "│ Bar"
        case .underscore: "▁ Underscore"
        }
    }

    private var animationLabel: String {
        switch currentAnimation {
        case .none: "Static"
        case .blink: "Blink"
        case .pulse: "Pulse"
        }
    }

    private var speedLabel: String {
        switch currentSpeed {
        case .slow: "Slow"
        case .regular: "Regular"
        case .fast: "Fast"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 1) {

            DemoSection("Cursor Demo") {
                VStack(alignment: .leading, spacing: 1) {
                    HStack(spacing: 1) {
                        Text("Input:").foregroundStyle(.palette.foregroundSecondary)
                        TextField("Input", text: $demoText, prompt: Text("Type here..."))
                    }
                    HStack(spacing: 1) {
                        Text("Search:").foregroundStyle(.palette.foregroundSecondary)
                        TextField("Search", text: $searchQuery, prompt: Text("Enter search term..."))
                            .onSubmit { submittedValue = searchQuery }
                    }
                    if !submittedValue.isEmpty {
                        HStack(spacing: 1) {
                            Text("Submitted:").foregroundStyle(.palette.foregroundSecondary)
                            Text(submittedValue).foregroundStyle(.palette.success)
                        }
                    }
                    Text("Cursor style set on container, inherited by all fields").dim()
                }
            }

            DemoSection("Disabled TextField") {
                VStack(alignment: .leading, spacing: 1) {
                    HStack(spacing: 1) {
                        Text("Disabled:").foregroundStyle(.palette.foregroundSecondary)
                        TextField("Disabled", text: $disabledText, prompt: Text("Cannot edit"))
                            .disabled()
                    }
                }
            }

            HStack(alignment: .top, spacing: 3) {
                KeyboardHelpSection(shortcuts: [
                    "[←] [→] Move cursor left/right",
                    "[Home] [End] Jump to start/end",
                    "[Backspace] Delete before cursor",
                    "[Delete] Delete at cursor",
                    "[Enter] Submit (triggers onSubmit)",
                    "[Tab] Move to next field",
                ])

                KeyboardHelpSection("Cursor Settings", shortcuts: [
                    "[F1] Shape: Block, Bar, Underscore",
                    "[F2] Animation: Static, Blink, Pulse",
                    "[F3] Speed: Slow, Regular, Fast",
                ])
            }

            Spacer()
        }
        .padding(.horizontal, 1)
        .textCursor(currentShape, animation: currentAnimation, speed: currentSpeed)
        .statusBarItems(cursorStatusBarItems)
        .appHeader {
            DemoAppHeader("TextField Demo")
        }
    }

    private var cursorStatusBarItems: [any StatusBarItemProtocol] {
        [
            StatusBarItem(shortcut: Shortcut.f1, label: shapeLabel) {
                cursorShapeIndex = (cursorShapeIndex + 1) % shapes.count
            },
            StatusBarItem(shortcut: Shortcut.f2, label: animationLabel) {
                cursorAnimationIndex = (cursorAnimationIndex + 1) % animations.count
            },
            StatusBarItem(shortcut: Shortcut.f3, label: speedLabel) {
                cursorSpeedIndex = (cursorSpeedIndex + 1) % speeds.count
            },
        ]
    }
}

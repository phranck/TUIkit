//  🖥️ TUIKit — Terminal UI Kit for Swift
//  KeyboardHelpSection.swift
//
//  Created by LAYERED.work
//  License: MIT

import TUIkit

/// A DemoSection showing keyboard shortcut help lines.
///
/// Each string in the array is rendered as a dimmed text line.
///
/// # Example
///
/// ```swift
/// KeyboardHelpSection([
///     "[Tab] Move focus",
///     "[Enter] Confirm",
/// ])
/// ```
struct KeyboardHelpSection: View {
    let title: String
    let shortcuts: [String]

    init(_ title: String = "Keyboard Controls", shortcuts: [String]) {
        self.title = title
        self.shortcuts = shortcuts
    }

    var body: some View {
        DemoSection(title) {
            VStack(alignment: .leading) {
                ForEach(Array(shortcuts.enumerated()), id: \.offset) { _, shortcut in
                    Text(shortcut).dim()
                }
            }
        }
    }
}

//  🖥️ TUIKit — Terminal UI Kit for Swift
//  ValueDisplayRow.swift
//
//  Created by LAYERED.work
//  License: MIT

import TUIkit

/// A label-value row for displaying current state in demo pages.
///
/// Renders the label in secondary color and the value in bold accent color.
///
/// # Example
///
/// ```swift
/// ValueDisplayRow("Volume:", String(format: "%.0f%%", volume * 100))
/// ValueDisplayRow("Selection:", selection ?? "(none)")
/// ```
struct ValueDisplayRow: View {
    let label: String
    let value: String

    init(_ label: String, _ value: String) {
        self.label = label
        self.value = value
    }

    var body: some View {
        HStack(spacing: 1) {
            Text(label).foregroundStyle(.palette.foregroundSecondary)
            Text(value).bold().foregroundStyle(.palette.accent)
        }
    }
}

//  🖥️ TUIKit — Terminal UI Kit for Swift
//  DemoSection.swift
//
//  Created by LAYERED.work
//  License: MIT

import TUIkit

/// A section with a styled title and content.
///
/// Used to group related demo content with a yellow underlined title.
///
/// # Example
///
/// ```swift
/// DemoSection("Basic Features") {
///     Text("Feature 1")
///     Text("Feature 2")
/// }
/// ```
struct DemoSection<Content: View>: View {
    let title: String
    let content: Content

    init(_ title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .bold()
                .underline()
                .foregroundStyle(.palette.accent)
            content
        }
    }
}

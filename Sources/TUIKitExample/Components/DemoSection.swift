//
//  DemoSection.swift
//  TUIKitExample
//
//  A reusable section component for organizing demo content.
//

import TUIKit

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
                .foregroundColor(.theme.accent)
            content
        }
    }
}

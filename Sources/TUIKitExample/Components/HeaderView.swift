//
//  HeaderView.swift
//  TUIKitExample
//
//  A reusable header component for demo pages.
//

import TUIKit

/// A styled header with title on the left and version on the right.
///
/// Used at the top of each demo page to provide consistent branding
/// and optional subtitle.
///
/// # Example
///
/// ```swift
/// HeaderView(
///     title: "My Demo",
///     subtitle: "An optional description"
/// )
/// ```
struct HeaderView: View {
    let title: String
    let subtitle: String?

    init(title: String, subtitle: String? = nil) {
        self.title = title
        self.subtitle = subtitle
    }

    var body: some View {
        VStack {
            HStack {
                Text(title)
                    .bold()
                    .foregroundColor(.theme.accent)
                Spacer()
                Text("TUIKit v\(tuiKitVersion)")
                    .foregroundColor(.theme.foregroundTertiary)
            }
            if let sub = subtitle {
                Text(sub)
                    .foregroundColor(.theme.foregroundSecondary)
                    .italic()
            }
            Divider(character: "═")
        }
    }
}

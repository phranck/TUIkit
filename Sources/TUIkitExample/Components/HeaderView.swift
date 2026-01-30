//
//  HeaderView.swift
//  TUIkitExample
//
//  A reusable header component for demo pages.
//

import TUIkit

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
                Text("TUIkit v\(tuiKitVersion)")
                    .foregroundColor(.theme.foregroundTertiary)
            }
            if let subtitleText = subtitle {
                Text(subtitleText)
                    .foregroundColor(.theme.foregroundSecondary)
                    .italic()
            }
            Divider(character: "═")
        }
    }
}

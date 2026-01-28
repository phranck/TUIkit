//
//  HeaderView.swift
//  SwiftTUIExample
//
//  A reusable header component for demo pages.
//

import SwiftTUI

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
struct HeaderView: TView {
    let title: String
    let subtitle: String?

    init(title: String, subtitle: String? = nil) {
        self.title = title
        self.subtitle = subtitle
    }

    var body: some TView {
        VStack {
            HStack {
                Text(title)
                    .bold()
                    .foregroundColor(.cyan)
                Spacer()
                Text("SwiftTUI v\(swiftTUIVersion)")
                    .dim()
            }
            if let sub = subtitle {
                Text(sub)
                    .dim()
                    .italic()
            }
            Divider(character: "═")
        }
    }
}

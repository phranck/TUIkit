import Foundation
import TUIkit

// Representative SwiftUI-style layout declarations that must compile
// unchanged under Swift 6.0: stacks with CGFloat spacing, spacer,
// alignment guides, edges, frames, padding, and the custom layout family.

@MainActor
func terminalLayout() -> some View {
    HStack(alignment: .center, spacing: 1) {
        Text("Leading")
        Spacer(minLength: 2)
        Text("Trailing")
    }
}

private enum ThirdGuide: AlignmentID {
    static func defaultValue(in context: ViewDimensions) -> CGFloat {
        context.width / 3
    }
}

@MainActor
func alignmentAndFrames() -> some View {
    VStack(alignment: HorizontalAlignment(ThirdGuide.self), spacing: 0.5) {
        Text("wide")
            .frame(minWidth: 4, maxWidth: .infinity, alignment: .center)
        Text("padded")
            .padding(.horizontal, 2)
            .padding(EdgeInsets(top: 1, leading: 0, bottom: 1, trailing: 0))
    }
    .frame(width: 24, height: 8)
}

@MainActor
func lazyPinned() -> some View {
    LazyVStack(alignment: .leading, spacing: nil, pinnedViews: [.sectionHeaders]) {
        Text("row")
    }
}

@MainActor
func adaptive() -> some View {
    ViewThatFits(in: .horizontal) {
        Text("wide variant")
        Text("narrow")
    }
}

@MainActor
func geometry() -> some View {
    GeometryReader { proxy in
        Text("w:\(Int(proxy.size.width))")
    }
}

private struct RowLayout: Layout {
    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout Void
    ) -> CGSize {
        var width: CGFloat = 0
        var height: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            width += size.width
            height = max(height, size.height)
        }
        return CGSize(width: width, height: height)
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout Void
    ) {
        var x: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            subview.place(at: CGPoint(x: x, y: 0), proposal: .unspecified)
            x += size.width
        }
    }
}

@MainActor
func customLayout() -> some View {
    let layout = AnyLayout(RowLayout())
    return layout {
        Text("a")
        Text("b")
    }
}

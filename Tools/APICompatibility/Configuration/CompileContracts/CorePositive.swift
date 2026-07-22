import TUIkit

// Representative SwiftUI-style declarations that must compile unchanged
// under Swift 6.0: custom views, builder forms, custom modifiers, generic
// content, type erasure, and nested modified content.

@MainActor
func erasedView() -> AnyView {
    AnyView(Text("Core"))
}

@MainActor
private struct CustomView: View {
    var body: some View {
        Text("custom")
    }
}

@MainActor
private struct ConditionalBuilders: View {
    let flag: Bool
    let optionalText: String?

    var body: some View {
        VStack {
            if flag {
                Text("true branch")
            } else {
                Text("false branch")
            }
            if let optionalText {
                Text(optionalText)
            }
            if #available(macOS 10.15, *) {
                Text("available")
            }
        }
    }
}

@MainActor
private struct GenericContent<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
    }
}

private struct FramedModifier: ViewModifier {
    func body(content: Content) -> some View {
        VStack {
            content
        }
    }
}

@MainActor
private func nestedModifiedContent() -> ModifiedContent<
    ModifiedContent<Text, FramedModifier>, FramedModifier
> {
    Text("nested")
        .modifier(FramedModifier())
        .modifier(FramedModifier())
}

@MainActor
private func genericComposition() -> some View {
    GenericContent {
        CustomView()
        ConditionalBuilders(flag: true, optionalText: nil)
    }
}

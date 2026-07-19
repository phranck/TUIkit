import TUIkit

@MainActor
@ViewBuilder
func conditionalContent(_ condition: Bool) -> some View {
    if condition {
        Text("Enabled")
    } else {
        EmptyView()
    }
}

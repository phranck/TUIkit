import TUIkit

@MainActor
func invalidButtonOrder() -> some View {
    Button("Cancel", action: {}, role: .cancel)
}

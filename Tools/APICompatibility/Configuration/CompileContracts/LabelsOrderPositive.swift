import TUIkit

@MainActor
func labeledButton() -> some View {
    Button("Cancel", role: .cancel, action: {})
}

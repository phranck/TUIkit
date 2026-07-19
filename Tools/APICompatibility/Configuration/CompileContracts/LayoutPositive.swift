import TUIkit

@MainActor
func terminalLayout() -> some View {
    HStack(alignment: .center, spacing: 1) {
        Text("Leading")
        Spacer()
        Text("Trailing")
    }
}

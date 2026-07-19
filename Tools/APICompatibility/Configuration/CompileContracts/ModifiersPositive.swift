import TUIkit

@MainActor
func sharedModifiers() -> some View {
    Text("Modifiers")
        .foregroundStyle(.red)
        .onAppear {}
        .task {}
}

import TUIkit

@MainActor
struct FocusedView: View {
    @FocusState private var focused = false

    var body: some View {
        Text("Focus")
    }
}

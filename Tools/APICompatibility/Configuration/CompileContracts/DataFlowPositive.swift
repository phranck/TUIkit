import TUIkit

@MainActor
struct DataFlowView: View {
    @State private var count = 0

    var body: some View {
        Text("\(count)")
    }
}

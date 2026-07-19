import TUIkit

@MainActor
func genericRows() -> some View {
    ForEach([1, 2], id: \.self) { value in
        Text("\(value)")
    }
}

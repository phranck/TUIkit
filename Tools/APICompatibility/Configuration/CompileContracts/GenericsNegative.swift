import TUIkit

final class NonHashableToken {}

struct GenericItem {
    let token: NonHashableToken
}

@MainActor
func invalidGenericRows() -> some View {
    ForEach([GenericItem(token: NonHashableToken())], id: \.token) { _ in
        Text("Row")
    }
}

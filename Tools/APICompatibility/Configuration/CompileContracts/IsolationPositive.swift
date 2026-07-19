import TUIkit

struct LayoutRotationUnaryLayout {}

func acceptsTask(
    action: sending @escaping @isolated(any) () async -> Void
) {}

@MainActor
func isolatedContent() -> some View {
    Text("Isolated")
}

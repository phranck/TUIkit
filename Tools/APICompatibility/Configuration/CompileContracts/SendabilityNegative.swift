import TUIkit

private func requireSendable<Value: Sendable>(_: Value.Type) {}

private final class NonSendableModel {
    var value = 0
}

func rejectNonSendableValueBinding() {
    requireSendable(Binding<NonSendableModel>.self)
}

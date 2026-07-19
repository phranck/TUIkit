import TUIkit

private func requireSendable<Value: Sendable>(_: Value.Type) {}

func rejectNonSendableBinding() {
    requireSendable(Binding<Int>.self)
}

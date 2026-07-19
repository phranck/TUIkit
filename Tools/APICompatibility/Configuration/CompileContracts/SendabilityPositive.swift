import TUIkit

private func requireSendable<Value: Sendable>(_: Value.Type) {}

func acceptSendableButtonRole() {
    requireSendable(ButtonRole.self)
}

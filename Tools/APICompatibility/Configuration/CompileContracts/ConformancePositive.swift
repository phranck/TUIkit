import TUIkit

private enum CountEnvironmentKey: EnvironmentKey {
    static let defaultValue = 0
}

private enum CountPreferenceKey: PreferenceKey {
    static let defaultValue = 0

    static func reduce(value: inout Int, nextValue: () -> Int) {
        value += nextValue()
    }
}

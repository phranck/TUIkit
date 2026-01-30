//
//  View+Lifecycle.swift
//  TUIKit
//
//  The .onAppear(), .onDisappear(), and .task() view extensions.
//

extension View {
    /// Executes an action when this view first appears.
    ///
    /// The action is only executed once per view appearance. If the view
    /// is removed and then added again, the action will execute again.
    ///
    /// # Example
    ///
    /// ```swift
    /// struct ContentView: View {
    ///     var body: some View {
    ///         Text("Hello")
    ///             .onAppear {
    ///                 loadData()
    ///             }
    ///     }
    /// }
    /// ```
    ///
    /// - Parameter action: The action to execute.
    /// - Returns: A view that executes the action on appearance.
    public func onAppear(perform action: @escaping () -> Void) -> some View {
        OnAppearModifier(
            content: self,
            token: TokenGenerator.shared.next(),
            action: action
        )
    }

    /// Executes an action when this view disappears.
    ///
    /// The action is executed when the view is no longer rendered.
    ///
    /// # Example
    ///
    /// ```swift
    /// struct ContentView: View {
    ///     var body: some View {
    ///         Text("Hello")
    ///             .onDisappear {
    ///                 cleanup()
    ///             }
    ///     }
    /// }
    /// ```
    ///
    /// - Parameter action: The action to execute.
    /// - Returns: A view that executes the action on disappearance.
    public func onDisappear(perform action: @escaping () -> Void) -> some View {
        OnDisappearModifier(
            content: self,
            token: TokenGenerator.shared.next(),
            action: action
        )
    }

    /// Starts an async task when this view appears.
    ///
    /// The task is automatically cancelled when the view disappears.
    ///
    /// # Example
    ///
    /// ```swift
    /// struct ContentView: View {
    ///     var body: some View {
    ///         Text("Loading...")
    ///             .task {
    ///                 await fetchData()
    ///             }
    ///     }
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - priority: The task priority (default: .userInitiated).
    ///   - action: The async action to execute.
    /// - Returns: A view that starts the task on appearance.
    public func task(
        priority: TaskPriority = .userInitiated,
        _ action: @escaping @Sendable () async -> Void
    ) -> some View {
        TaskModifier(
            content: self,
            token: TokenGenerator.shared.next(),
            task: action,
            priority: priority
        )
    }
}

//
//  View+NavigationTitle.swift
//  TUIKit
//
//  The .navigationTitle() view extension convenience method.
//

extension View {
    /// Sets the navigation title for this view.
    ///
    /// # Example
    ///
    /// ```swift
    /// VStack {
    ///     Text("Content")
    /// }
    /// .navigationTitle("Home")
    /// ```
    ///
    /// - Parameter title: The navigation title.
    /// - Returns: A view with the navigation title preference set.
    public func navigationTitle(_ title: String) -> some View {
        preference(key: NavigationTitleKey.self, value: title)
    }
}

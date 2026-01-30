//
//  View+Preferences.swift
//  TUIkit
//
//  Preference system view modifiers: preference, onPreferenceChange, navigationTitle.
//

// MARK: - Preference

extension View {
    /// Sets a preference value for this view.
    ///
    /// Preferences propagate up the view hierarchy, allowing child views
    /// to communicate values to their ancestors.
    ///
    /// # Example
    ///
    /// ```swift
    /// Text("Page Title")
    ///     .preference(key: NavigationTitleKey.self, value: "Home")
    /// ```
    ///
    /// - Parameters:
    ///   - key: The preference key type.
    ///   - value: The value to set.
    /// - Returns: A view that sets the preference.
    public func preference<K: PreferenceKey>(key: K.Type, value: K.Value) -> some View {
        PreferenceModifier<Self, K>(content: self, value: value)
    }

    /// Adds an action to perform when a preference value changes.
    ///
    /// # Example
    ///
    /// ```swift
    /// NavigationView {
    ///     content
    /// }
    /// .onPreferenceChange(NavigationTitleKey.self) { title in
    ///     self.title = title
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - key: The preference key type.
    ///   - action: The action to perform with the new value.
    /// - Returns: A view that reacts to preference changes.
    public func onPreferenceChange<K: PreferenceKey>(
        _ key: K.Type,
        perform action: @escaping (K.Value) -> Void
    ) -> some View where K.Value: Equatable {
        OnPreferenceChangeModifier<Self, K>(content: self, action: action)
    }
}

// MARK: - Navigation Title

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

//  🖥️ TUIKit — Terminal UI Kit for Swift
//  LocalizationKeys.swift
//
//  Created by LAYERED.work
//  License: MIT

// MARK: - Localization Keys

/// Type-safe localization keys for all framework strings.
///
/// Provides compile-time safety and IDE autocomplete for all localized strings
/// in the framework. Keys are organized by category matching the JSON structure.
///
/// # Example
///
/// ```swift
/// Text(localized: LocalizationKey.Button.ok.rawValue)
/// Text(localized: LocalizationKey.Error.notFound.rawValue)
/// ```
public enum LocalizationKey {
    /// Button labels and actions
    public enum Button: String {
        case ok = "button.ok"
        case cancel = "button.cancel"
        case yes = "button.yes"
        case no = "button.no"
        case save = "button.save"
        case delete = "button.delete"
        case close = "button.close"
        case apply = "button.apply"
        case reset = "button.reset"
        case submit = "button.submit"
        case search = "button.search"
        case clear = "button.clear"
        case add = "button.add"
        case remove = "button.remove"
        case edit = "button.edit"
        case done = "button.done"
        case next = "button.next"
        case previous = "button.previous"
        case back = "button.back"
        case forward = "button.forward"
        case refresh = "button.refresh"
    }

    /// Label and field names
    public enum Label: String {
        case search = "label.search"
        case name = "label.name"
        case description = "label.description"
        case value = "label.value"
        case status = "label.status"
        case error = "label.error"
        case warning = "label.warning"
        case info = "label.info"
        case loading = "label.loading"
        case empty = "label.empty"
        case none = "label.none"
        case page = "label.page"
        case item = "label.item"
        case items = "label.items"
        case total = "label.total"
        case from = "label.from"
        case to = "label.to"
    }

    /// Error messages
    public enum Error: String {
        case invalidInput = "error.invalid_input"
        case requiredField = "error.required_field"
        case notFound = "error.not_found"
        case accessDenied = "error.access_denied"
        case networkError = "error.network_error"
        case unknown = "error.unknown"
        case invalidFormat = "error.invalid_format"
        case operationFailed = "error.operation_failed"
        case timeout = "error.timeout"
        case fileNotFound = "error.file_not_found"
        case permissionDenied = "error.permission_denied"
    }

    /// Placeholder text for input fields
    public enum Placeholder: String {
        case search = "placeholder.search"
        case enterText = "placeholder.enter_text"
        case enterValue = "placeholder.enter_value"
        case selectOption = "placeholder.select_option"
        case enterName = "placeholder.enter_name"
        case chooseFile = "placeholder.choose_file"
    }

    /// Menu items and sections
    public enum Menu: String {
        case file = "menu.file"
        case edit = "menu.edit"
        case view = "menu.view"
        case help = "menu.help"
        case new = "menu.new"
        case open = "menu.open"
        case save = "menu.save"
        case exit = "menu.exit"
    }

    /// Dialog titles and messages
    public enum Dialog: String {
        case confirm = "dialog.confirm"
        case deleteConfirmation = "dialog.delete_confirmation"
        case unsavedChanges = "dialog.unsaved_changes"
        case overwriteConfirmation = "dialog.overwrite_confirmation"
        case exitConfirmation = "dialog.exit_confirmation"
        case success = "dialog.success"
        case error = "dialog.error"
    }

    /// Validation messages
    public enum Validation: String {
        case emailInvalid = "validation.email_invalid"
        case passwordTooShort = "validation.password_too_short"
        case usernameTaken = "validation.username_taken"
        case fieldRequired = "validation.field_required"
    }
}

// MARK: - Convenient Localization Extensions

extension LocalizedString {
    /// Creates a localized string view from a typed localization key.
    ///
    /// # Example
    ///
    /// ```swift
    /// LocalizedString(.button(.ok))
    /// LocalizedString(.error(.notFound))
    /// ```
    public init(_ key: LocalizationKey.Button) {
        self.init(key.rawValue)
    }

    /// Creates a localized string view from a label key.
    public init(_ key: LocalizationKey.Label) {
        self.init(key.rawValue)
    }

    /// Creates a localized string view from an error key.
    public init(_ key: LocalizationKey.Error) {
        self.init(key.rawValue)
    }

    /// Creates a localized string view from a placeholder key.
    public init(_ key: LocalizationKey.Placeholder) {
        self.init(key.rawValue)
    }

    /// Creates a localized string view from a menu key.
    public init(_ key: LocalizationKey.Menu) {
        self.init(key.rawValue)
    }

    /// Creates a localized string view from a dialog key.
    public init(_ key: LocalizationKey.Dialog) {
        self.init(key.rawValue)
    }

    /// Creates a localized string view from a validation key.
    public init(_ key: LocalizationKey.Validation) {
        self.init(key.rawValue)
    }
}

extension Text {
    /// Creates a text view with a localized string using a typed localization key.
    ///
    /// # Example
    ///
    /// ```swift
    /// Text(localized: .button(.ok))
    /// Text(localized: .error(.notFound))
    /// ```
    public init(localized key: LocalizationKey.Button) {
        self.init(localized: key.rawValue)
    }

    /// Creates a text view with a localized string from a label key.
    public init(localized key: LocalizationKey.Label) {
        self.init(localized: key.rawValue)
    }

    /// Creates a text view with a localized string from an error key.
    public init(localized key: LocalizationKey.Error) {
        self.init(localized: key.rawValue)
    }

    /// Creates a text view with a localized string from a placeholder key.
    public init(localized key: LocalizationKey.Placeholder) {
        self.init(localized: key.rawValue)
    }

    /// Creates a text view with a localized string from a menu key.
    public init(localized key: LocalizationKey.Menu) {
        self.init(localized: key.rawValue)
    }

    /// Creates a text view with a localized string from a dialog key.
    public init(localized key: LocalizationKey.Dialog) {
        self.init(localized: key.rawValue)
    }

    /// Creates a text view with a localized string from a validation key.
    public init(localized key: LocalizationKey.Validation) {
        self.init(localized: key.rawValue)
    }
}

extension LocalizationService {
    /// Retrieves a localized string for a typed key.
    ///
    /// # Example
    ///
    /// ```swift
    /// let okText = LocalizationService.shared.string(for: .button(.ok))
    /// let errorText = LocalizationService.shared.string(for: .error(.notFound))
    /// ```
    public func string(for key: LocalizationKey.Button) -> String {
        string(for: key.rawValue)
    }

    /// Retrieves a localized string for a label key.
    public func string(for key: LocalizationKey.Label) -> String {
        string(for: key.rawValue)
    }

    /// Retrieves a localized string for an error key.
    public func string(for key: LocalizationKey.Error) -> String {
        string(for: key.rawValue)
    }

    /// Retrieves a localized string for a placeholder key.
    public func string(for key: LocalizationKey.Placeholder) -> String {
        string(for: key.rawValue)
    }

    /// Retrieves a localized string for a menu key.
    public func string(for key: LocalizationKey.Menu) -> String {
        string(for: key.rawValue)
    }

    /// Retrieves a localized string for a dialog key.
    public func string(for key: LocalizationKey.Dialog) -> String {
        string(for: key.rawValue)
    }

    /// Retrieves a localized string for a validation key.
    public func string(for key: LocalizationKey.Validation) -> String {
        string(for: key.rawValue)
    }
}

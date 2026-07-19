//  🖥️ TUIKit — Terminal UI Kit for Swift
//  AppStorage.swift
//
//  Created by LAYERED.work
//  License: MIT

import Foundation

// MARK: - Storage Backend Protocol

/// Protocol for persistent storage backends.
public protocol StorageBackend: Sendable {
    /// Retrieves a value for the given key.
    func value<T: Codable>(forKey key: String) -> T?

    /// Stores a value for the given key.
    func setValue<T: Codable>(_ value: T, forKey key: String)

    /// Removes the value for the given key.
    func removeValue(forKey key: String)

    /// Synchronizes changes to disk.
    func synchronize()
}

// MARK: - Process Name Sanitization

/// Sanitizes a process name for safe use as a file system path component.
///
/// Removes characters that could cause path traversal or file system issues:
/// - Forward slashes (`/`)
/// - Null bytes (`\0`)
/// - Replaces `..` sequences (path traversal)
///
/// Falls back to `"app"` if the result is empty after sanitization.
///
/// - Parameter name: The raw process name.
/// - Returns: A sanitized string safe for use as a directory name.
func sanitizedProcessName(_ name: String) -> String {
    var sanitized = name
        .replacingOccurrences(of: "/", with: "")
        .replacingOccurrences(of: "\0", with: "")
        .replacingOccurrences(of: "..", with: "")
    sanitized = sanitized.trimmingCharacters(in: .whitespacesAndNewlines)
    return sanitized.isEmpty ? "app" : sanitized
}

// MARK: - Config Directory

/// Returns the app-specific configuration directory.
///
/// Resolves the directory in this order:
/// 1. `$XDG_CONFIG_HOME/<appName>` (Linux convention)
/// 2. `~/.config/<appName>` (fallback)
///
/// This ensures correct behavior on Linux where `$XDG_CONFIG_HOME`
/// may differ from `~/.config`.
private func appConfigDirectory() -> URL {
    let appName = sanitizedProcessName(ProcessInfo.processInfo.processName)

    if let xdgConfig = ProcessInfo.processInfo.environment["XDG_CONFIG_HOME"], !xdgConfig.isEmpty {
        return URL(fileURLWithPath: xdgConfig)
            .appendingPathComponent(appName)
    }

    return FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent(".config")
        .appendingPathComponent(appName)
}

// MARK: - JSON File Storage

/// A storage backend that persists data to a JSON file.
///
/// This is the default storage backend for TUIkit apps.
/// Data is stored in `$XDG_CONFIG_HOME/[appName]/settings.json`
/// or `~/.config/[appName]/settings.json` as fallback.
public final class JSONFileStorage: StorageBackend, @unchecked Sendable {
    /// The file URL for the storage file.
    private let fileURL: URL

    /// In-memory cache of stored values.
    private var cache: [String: Data] = [:]

    /// Lock for thread safety.
    private let lock = NSLock()

    /// Creates a JSON file storage with default location.
    public init() {
        let configDir = appConfigDirectory()

        // Create directory if needed
        try? FileManager.default.createDirectory(at: configDir, withIntermediateDirectories: true)

        self.fileURL = configDir.appendingPathComponent("settings.json")
        loadFromDisk()
    }

    /// Creates a JSON file storage with a custom file URL.
    public init(fileURL: URL) {
        self.fileURL = fileURL
        loadFromDisk()
    }
}

// MARK: - Public API

public extension JSONFileStorage {
    func value<T: Codable>(forKey key: String) -> T? {
        lock.lock()
        defer { lock.unlock() }

        guard let data = cache[key] else { return nil }

        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            return nil
        }
    }

    func setValue<T: Codable>(_ value: T, forKey key: String) {
        lock.lock()
        defer { lock.unlock() }

        do {
            let data = try JSONEncoder().encode(value)
            cache[key] = data
            saveToDiskAsync()
        } catch {
            // Encoding failed - ignore silently
        }
    }

    func removeValue(forKey key: String) {
        lock.lock()
        defer { lock.unlock() }

        cache.removeValue(forKey: key)
        saveToDiskAsync()
    }

    func synchronize() {
        lock.lock()
        defer { lock.unlock() }

        saveToDiskSync()
    }
}

// MARK: - Private Helpers

private extension JSONFileStorage {
    func loadFromDisk() {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return }

        do {
            let data = try Data(contentsOf: fileURL)
            if let decoded = try JSONSerialization.jsonObject(with: data) as? [String: String] {
                // Convert base64 strings back to Data
                for (key, base64String) in decoded {
                    if let valueData = Data(base64Encoded: base64String) {
                        cache[key] = valueData
                    }
                }
            }
        } catch {
            // Failed to load - start fresh
        }
    }

    func saveToDiskAsync() {
        Task.detached(priority: .utility) { [weak self] in
            self?.saveToDiskSync()
        }
    }

    func saveToDiskSync() {
        // Convert Data values to base64 strings for JSON compatibility
        var serializable: [String: String] = [:]
        for (key, data) in cache {
            serializable[key] = data.base64EncodedString()
        }

        do {
            let data = try JSONSerialization.data(withJSONObject: serializable, options: .prettyPrinted)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            // Failed to save - ignore silently
        }
    }
}

// MARK: - Storage Defaults

/// Provides the default storage backend for ``AppStorage``.
///
/// This global compatibility hook is deprecated. `@AppStorage` properties
/// rendered inside an app bind to that app's runtime backend. Pass an explicit
/// backend to the property wrapper when code outside a runtime needs one.
///
/// ```swift
/// @AppStorage("token", storage: MyCustomBackend()) var token = ""
/// ```
public enum StorageDefaults {
    /// Backing storage retained until issue #15 removes the global fallback.
    nonisolated(unsafe) private static var configuredBackend: StorageBackend = JSONFileStorage()

    /// The default storage backend used by ``AppStorage``.
    ///
    /// Defaults to a ``JSONFileStorage`` instance that persists to
    /// `$XDG_CONFIG_HOME/[appName]/settings.json`.
    @available(*, deprecated, message: "Pass a StorageBackend to the AppStorage initializer instead")
    public static var backend: StorageBackend {
        get { configuredBackend }
        set { configuredBackend = newValue }
    }

    /// Legacy fallback used only when AppStorage is accessed outside a runtime.
    static var runtimeBackend: StorageBackend {
        configuredBackend
    }
}

// MARK: - AppStorage Property Wrapper

/// A property wrapper that reads and writes to persistent storage.
///
/// Use `@AppStorage` to persist simple values across app launches.
/// Values must conform to `Codable`.
///
/// # Example
///
/// ```swift
/// struct SettingsView: View {
///     @AppStorage("username") var username = "Guest"
///     @AppStorage("darkMode") var darkMode = false
///     @AppStorage("fontSize") var fontSize = 14
///
///     var body: some View {
///         VStack {
///             Text("User: \(username)")
///             Text("Dark Mode: \(darkMode ? "On" : "Off")")
///         }
///     }
/// }
/// ```
///
/// # Supported Types
///
/// Any type that conforms to `Codable`:
/// - String, Int, Double, Bool
/// - Date, Data, URL
/// - Arrays and Dictionaries of Codable types
/// - Custom Codable structs and enums
@propertyWrapper
public struct AppStorage<Value: Codable>: @unchecked Sendable {
    /// Reference storage that captures the first runtime owning this property.
    private let box: AppStorageBox<Value>

    /// Creates an AppStorage with the default storage backend.
    ///
    /// - Parameters:
    ///   - wrappedValue: The default value.
    ///   - key: The key to use for storage.
    public init(wrappedValue: Value, _ key: String) {
        self.box = AppStorageBox(
            key: key,
            defaultValue: wrappedValue,
            explicitStorage: nil
        )
    }

    /// Creates an AppStorage with a custom storage backend.
    ///
    /// - Parameters:
    ///   - wrappedValue: The default value.
    ///   - key: The key to use for storage.
    ///   - storage: The storage backend to use.
    public init(wrappedValue: Value, _ key: String, storage: StorageBackend) {
        self.box = AppStorageBox(
            key: key,
            defaultValue: wrappedValue,
            explicitStorage: storage
        )
    }

    /// The current value.
    public var wrappedValue: Value {
        get {
            box.value
        }
        nonmutating set {
            box.value = newValue
        }
    }

    /// A binding to the stored value.
    public var projectedValue: Binding<Value> {
        Binding(
            get: { self.wrappedValue },
            set: { self.wrappedValue = $0 }
        )
    }
}

// MARK: - App Storage Box

/// Reference storage that binds AppStorage to its first rendering runtime.
private final class AppStorageBox<Value: Codable>: @unchecked Sendable {
    /// Persistent key.
    private let key: String

    /// Value returned when the backend contains no entry.
    private let defaultValue: Value

    /// Explicit backend supplied by the property-wrapper initializer.
    private let explicitStorage: StorageBackend?

    /// Backend captured from the owning runtime.
    private var runtimeStorage: StorageBackend?

    /// Runtime receiving changes made through this property.
    private var invalidationSink: (any RenderInvalidationSink)?

    /// Structural identity owning this property.
    private var identity: ViewIdentity?

    /// Lock protecting dependency binding.
    private let lock = NSLock()

    /// Creates reference storage for one AppStorage property.
    init(
        key: String,
        defaultValue: Value,
        explicitStorage: StorageBackend?
    ) {
        self.key = key
        self.defaultValue = defaultValue
        self.explicitStorage = explicitStorage
    }

    /// Current persisted value.
    var value: Value {
        get {
            let storage = resolvedDependencies().storage
            return storage.value(forKey: key) ?? defaultValue
        }
        set {
            let dependencies = resolvedDependencies()
            dependencies.storage.setValue(newValue, forKey: key)

            if let identity = dependencies.identity {
                dependencies.invalidationSink?.invalidate(.subtree(identity))
            } else {
                dependencies.invalidationSink?.invalidate(.all)
            }
        }
    }
}

// MARK: - Private Helpers

private extension AppStorageBox {
    typealias Dependencies = (
        storage: StorageBackend,
        invalidationSink: (any RenderInvalidationSink)?,
        identity: ViewIdentity?
    )

    func resolvedDependencies() -> Dependencies {
        bindToActiveRuntimeIfNeeded()

        lock.lock()
        let storage = explicitStorage ?? runtimeStorage ?? StorageDefaults.runtimeBackend
        let invalidationSink = invalidationSink
        let identity = identity
        lock.unlock()
        return (storage, invalidationSink, identity)
    }

    func bindToActiveRuntimeIfNeeded() {
        guard let environment = StateRegistration.activeEnvironment else { return }

        lock.lock()
        if runtimeStorage == nil {
            runtimeStorage = environment.storageBackend
            invalidationSink = environment.renderInvalidationSink
            identity = StateRegistration.activeContext?.identity
        }
        lock.unlock()
    }
}

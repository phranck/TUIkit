//
//  AppStorage.swift
//  SwiftTUI
//
//  Persistent storage for app settings using @AppStorage property wrapper.
//

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

// MARK: - JSON File Storage

/// A storage backend that persists data to a JSON file.
///
/// This is the default storage backend for SwiftTUI apps.
/// Data is stored in `~/.config/[appName]/settings.json`.
public final class JSONFileStorage: StorageBackend, @unchecked Sendable {
    /// The shared instance.
    public static let shared = JSONFileStorage()

    /// The file URL for the storage file.
    private let fileURL: URL

    /// In-memory cache of stored values.
    private var cache: [String: Data] = [:]

    /// Lock for thread safety.
    private let lock = NSLock()

    /// Creates a JSON file storage with default location.
    public init() {
        let appName = ProcessInfo.processInfo.processName
        let configDir = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".config")
            .appendingPathComponent(appName)

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

    public func value<T: Codable>(forKey key: String) -> T? {
        lock.lock()
        defer { lock.unlock() }

        guard let data = cache[key] else { return nil }

        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            return nil
        }
    }

    public func setValue<T: Codable>(_ value: T, forKey key: String) {
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

    public func removeValue(forKey key: String) {
        lock.lock()
        defer { lock.unlock() }

        cache.removeValue(forKey: key)
        saveToDiskAsync()
    }

    public func synchronize() {
        lock.lock()
        defer { lock.unlock() }

        saveToDiskSync()
    }

    // MARK: - Private

    private func loadFromDisk() {
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

    private func saveToDiskAsync() {
        DispatchQueue.global(qos: .utility).async { [weak self] in
            self?.saveToDiskSync()
        }
    }

    private func saveToDiskSync() {
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

// MARK: - Storage Manager

/// Central manager for app storage.
public final class StorageManager: @unchecked Sendable {
    /// The shared storage manager.
    public static let shared = StorageManager()

    /// The current storage backend.
    public var backend: StorageBackend

    private init() {
        self.backend = JSONFileStorage.shared
    }

    /// Sets the storage backend to use.
    public func setBackend(_ backend: StorageBackend) {
        self.backend = backend
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
/// struct SettingsView: TView {
///     @AppStorage("username") var username = "Guest"
///     @AppStorage("darkMode") var darkMode = false
///     @AppStorage("fontSize") var fontSize = 14
///
///     var body: some TView {
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
    /// The key used for storage.
    private let key: String

    /// The default value if no stored value exists.
    private let defaultValue: Value

    /// The storage backend to use.
    private let storage: StorageBackend

    /// Creates an AppStorage with the default storage backend.
    ///
    /// - Parameters:
    ///   - wrappedValue: The default value.
    ///   - key: The key to use for storage.
    public init(wrappedValue: Value, _ key: String) {
        self.key = key
        self.defaultValue = wrappedValue
        self.storage = StorageManager.shared.backend
    }

    /// Creates an AppStorage with a custom storage backend.
    ///
    /// - Parameters:
    ///   - wrappedValue: The default value.
    ///   - key: The key to use for storage.
    ///   - storage: The storage backend to use.
    public init(wrappedValue: Value, _ key: String, storage: StorageBackend) {
        self.key = key
        self.defaultValue = wrappedValue
        self.storage = storage
    }

    /// The current value.
    public var wrappedValue: Value {
        get {
            storage.value(forKey: key) ?? defaultValue
        }
        nonmutating set {
            storage.setValue(newValue, forKey: key)
            AppState.shared.setNeedsRender()
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

// MARK: - Optional AppStorage

extension AppStorage where Value: ExpressibleByNilLiteral {
    /// Creates an AppStorage for an optional value.
    ///
    /// - Parameters:
    ///   - key: The key to use for storage.
    public init(_ key: String) where Value == String? {
        self.key = key
        self.defaultValue = nil
        self.storage = StorageManager.shared.backend
    }

    /// Creates an AppStorage for an optional value.
    ///
    /// - Parameters:
    ///   - key: The key to use for storage.
    public init(_ key: String) where Value == Int? {
        self.key = key
        self.defaultValue = nil
        self.storage = StorageManager.shared.backend
    }

    /// Creates an AppStorage for an optional value.
    ///
    /// - Parameters:
    ///   - key: The key to use for storage.
    public init(_ key: String) where Value == Double? {
        self.key = key
        self.defaultValue = nil
        self.storage = StorageManager.shared.backend
    }

    /// Creates an AppStorage for an optional value.
    ///
    /// - Parameters:
    ///   - key: The key to use for storage.
    public init(_ key: String) where Value == Bool? {
        self.key = key
        self.defaultValue = nil
        self.storage = StorageManager.shared.backend
    }
}

// MARK: - SceneStorage Property Wrapper

/// A property wrapper that persists state for scene restoration.
///
/// Unlike `@AppStorage`, `@SceneStorage` is tied to a specific scene
/// and is primarily used for restoring UI state (scroll position,
/// selected tab, etc.) rather than user preferences.
///
/// # Example
///
/// ```swift
/// struct ContentView: TView {
///     @SceneStorage("selectedTab") var selectedTab = 0
///     @SceneStorage("scrollOffset") var scrollOffset = 0
///
///     var body: some TView {
///         TabView(selection: $selectedTab) {
///             // ...
///         }
///     }
/// }
/// ```
@propertyWrapper
public struct SceneStorage<Value: Codable>: @unchecked Sendable {
    /// The key used for storage.
    private let key: String

    /// The default value if no stored value exists.
    private let defaultValue: Value

    /// Scene-specific storage file.
    private static var sceneStorage: JSONFileStorage {
        let appName = ProcessInfo.processInfo.processName
        let configDir = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".config")
            .appendingPathComponent(appName)

        try? FileManager.default.createDirectory(at: configDir, withIntermediateDirectories: true)

        let fileURL = configDir.appendingPathComponent("scene-state.json")
        return JSONFileStorage(fileURL: fileURL)
    }

    /// Creates a SceneStorage.
    ///
    /// - Parameters:
    ///   - wrappedValue: The default value.
    ///   - key: The key to use for storage.
    public init(wrappedValue: Value, _ key: String) {
        self.key = key
        self.defaultValue = wrappedValue
    }

    /// The current value.
    public var wrappedValue: Value {
        get {
            Self.sceneStorage.value(forKey: key) ?? defaultValue
        }
        nonmutating set {
            Self.sceneStorage.setValue(newValue, forKey: key)
            AppState.shared.setNeedsRender()
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

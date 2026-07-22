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
    /// Persists one serialized snapshot payload to its destination.
    ///
    /// The default handler writes atomically to the file system. Tests inject
    /// recording or failing handlers to assert ordering and error behavior.
    typealias PersistHandler = @Sendable (_ payload: Data, _ destination: URL) throws -> Void

    /// The file URL for the storage file.
    private let fileURL: URL

    /// In-memory cache of stored values.
    private var cache: [String: Data] = [:]

    /// Lock protecting the in-memory cache.
    private let lock = NSLock()

    /// Serial queue establishing a total order over snapshot writes.
    ///
    /// Every mutation enqueues an immutable snapshot of its resulting state.
    /// Because the queue is serial, an earlier (older) snapshot can never be
    /// written after (and thereby overwrite) a later one.
    private let writeQueue = DispatchQueue(label: "work.layered.tuikit.storage-writer")

    /// Writes one serialized payload to disk.
    private let persist: PersistHandler

    /// Receives every persistence failure this storage encounters.
    private let onPersistenceFailure: @Sendable (StoragePersistenceError) -> Void

    /// Creates a JSON file storage with default location.
    ///
    /// - Parameter onPersistenceFailure: Optional handler receiving sanitized
    ///   persistence failures. Defaults to logging one line to standard error.
    public init(
        onPersistenceFailure: (@Sendable (StoragePersistenceError) -> Void)? = nil
    ) {
        let configDir = appConfigDirectory()

        // Create directory if needed
        try? FileManager.default.createDirectory(at: configDir, withIntermediateDirectories: true)

        self.fileURL = configDir.appendingPathComponent("settings.json")
        self.persist = Self.atomicWrite
        self.onPersistenceFailure = onPersistenceFailure ?? Self.logFailureToStandardError
        loadFromDisk()
    }

    /// Creates a JSON file storage with a custom file URL.
    ///
    /// - Parameters:
    ///   - fileURL: The destination file for persisted values.
    ///   - onPersistenceFailure: Optional handler receiving sanitized
    ///     persistence failures. Defaults to logging one line to standard error.
    public init(
        fileURL: URL,
        onPersistenceFailure: (@Sendable (StoragePersistenceError) -> Void)? = nil
    ) {
        self.fileURL = fileURL
        self.persist = Self.atomicWrite
        self.onPersistenceFailure = onPersistenceFailure ?? Self.logFailureToStandardError
        loadFromDisk()
    }

    /// Creates a storage with an injectable persistence step.
    ///
    /// - Parameters:
    ///   - fileURL: The destination passed to every persist invocation.
    ///   - persist: Handler receiving each serialized snapshot payload in
    ///     mutation order on the storage's writer queue.
    ///   - onPersistenceFailure: Optional handler receiving sanitized
    ///     persistence failures. Defaults to logging one line to standard error.
    init(
        fileURL: URL,
        persist: @escaping PersistHandler,
        onPersistenceFailure: (@Sendable (StoragePersistenceError) -> Void)? = nil
    ) {
        self.fileURL = fileURL
        self.persist = persist
        self.onPersistenceFailure = onPersistenceFailure ?? Self.logFailureToStandardError
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
        do {
            let data = try JSONEncoder().encode(value)
            applyAndEnqueueSnapshot { cache in cache[key] = data }
        } catch {
            onPersistenceFailure(StoragePersistenceError(operation: .encode, underlying: error))
        }
    }

    func removeValue(forKey key: String) {
        applyAndEnqueueSnapshot { cache in cache.removeValue(forKey: key) }
    }

    func synchronize() {
        // An empty synchronous block on the serial writer queue is a true
        // barrier: it can only run after every previously enqueued snapshot
        // write has completed.
        writeQueue.sync {}
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

    /// Applies a mutation to the cache and enqueues the resulting snapshot.
    ///
    /// The mutation and the snapshot copy happen under the lock, so every
    /// enqueued snapshot is an immutable, consistent image of the state the
    /// mutation produced. The writer queue then persists snapshots strictly
    /// in mutation order.
    ///
    /// - Parameter mutate: The cache mutation to apply.
    func applyAndEnqueueSnapshot(_ mutate: (inout [String: Data]) -> Void) {
        lock.lock()
        mutate(&cache)
        let snapshot = cache
        lock.unlock()

        writeQueue.async { [persist, fileURL, onPersistenceFailure] in
            Self.persistSnapshot(
                snapshot,
                to: fileURL,
                using: persist,
                reportingTo: onPersistenceFailure
            )
        }
    }

    /// Serializes one snapshot and hands it to the persist handler.
    ///
    /// Runs on the writer queue. Captures only immutable values so pending
    /// writes complete even if the storage instance is released.
    ///
    /// - Parameters:
    ///   - snapshot: The cache state to persist.
    ///   - fileURL: The destination file.
    ///   - persist: The handler performing the actual write.
    ///   - report: Receiver for sanitized serialization and write failures.
    static func persistSnapshot(
        _ snapshot: [String: Data],
        to fileURL: URL,
        using persist: PersistHandler,
        reportingTo report: @Sendable (StoragePersistenceError) -> Void
    ) {
        // Convert Data values to base64 strings for JSON compatibility
        var serializable: [String: String] = [:]
        for (key, data) in snapshot {
            serializable[key] = data.base64EncodedString()
        }

        let payload: Data
        do {
            payload = try JSONSerialization.data(withJSONObject: serializable, options: .prettyPrinted)
        } catch {
            report(StoragePersistenceError(operation: .serialize, underlying: error))
            return
        }

        do {
            try persist(payload, fileURL)
        } catch {
            report(StoragePersistenceError(operation: .write, underlying: error))
        }
    }

    /// Default persistence: atomic replacement of the destination file.
    static let atomicWrite: PersistHandler = { payload, destination in
        try payload.write(to: destination, options: .atomic)
    }

    /// Default failure handling: one sanitized line on standard error.
    static let logFailureToStandardError: @Sendable (StoragePersistenceError) -> Void = { failure in
        FileHandle.standardError.write(Data("TUIkit: \(failure.description)\n".utf8))
    }
}

// MARK: - Unbound Fallback

/// Process-local fallback for ``AppStorage`` properties accessed outside a
/// runtime.
///
/// Persistent storage is always owned by an app runtime (injected through
/// `TUIContext`) or passed explicitly to the property wrapper:
///
/// ```swift
/// @AppStorage("token", store: MyCustomBackend()) var token = ""
/// ```
///
/// Code that touches an `@AppStorage` property before any runtime hydrates it
/// therefore gets deliberately volatile in-memory semantics: nothing reaches
/// the file system, and no global mutable backend exists that two runtimes
/// could accidentally share.
enum UnboundAppStorage {
    /// Shared volatile backend for unbound property access.
    static let fallback: StorageBackend = VolatileStorageBackend()
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
/// SwiftUI's initializer families cover `Bool`, `Int`, `Double`, `String`,
/// `URL`, `Data`, `Date`, `RawRepresentable` values with `String` or `Int`
/// raw values, and their optional variants. As an additive terminal
/// convenience, any `Codable` value is supported as well.
///
/// The `store` parameter accepts a ``StorageBackend`` instead of SwiftUI's
/// `UserDefaults`, which has no terminal equivalent; passing `nil` uses the
/// owning runtime's injected backend.
@propertyWrapper
public struct AppStorage<Value>: @unchecked Sendable {
    /// Reference storage that captures the first runtime owning this property.
    private let box: AppStorageBox<Value>

    /// Creates a wrapper around prepared reference storage.
    fileprivate init(box: AppStorageBox<Value>) {
        self.box = box
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
        box.binding
    }
}

// MARK: - Codable Convenience

extension AppStorage {
    /// Creates a property that can read and write any Codable value.
    ///
    /// Additive terminal convenience beyond SwiftUI's typed families; the
    /// typed overloads below take precedence for their exact value types.
    ///
    /// - Parameters:
    ///   - wrappedValue: The default value.
    ///   - key: The key to read and write the value to.
    ///   - store: The backend to use, or `nil` for the runtime's backend.
    public init(
        wrappedValue: Value,
        _ key: String,
        store: (any StorageBackend)? = nil
    ) where Value: Codable {
        self.init(box: AppStorageBox(
            key: key,
            defaultValue: wrappedValue,
            explicitStorage: store,
            read: { backend, key in backend.value(forKey: key) },
            write: { backend, key, value in backend.setValue(value, forKey: key) }
        ))
    }
}

// MARK: - Standard Value Families

extension AppStorage {
    /// Shared construction for Codable-backed typed families.
    fileprivate static func codableFamily(
        wrappedValue: Value,
        key: String,
        store: (any StorageBackend)?
    ) -> AppStorage<Value> where Value: Codable {
        AppStorage(wrappedValue: wrappedValue, key, store: store)
    }

    /// Creates a property that can read and write a Boolean value.
    public init(wrappedValue: Value, _ key: String, store: (any StorageBackend)? = nil)
    where Value == Bool {
        self = Self.codableFamily(wrappedValue: wrappedValue, key: key, store: store)
    }

    /// Creates a property that can read and write an integer value.
    public init(wrappedValue: Value, _ key: String, store: (any StorageBackend)? = nil)
    where Value == Int {
        self = Self.codableFamily(wrappedValue: wrappedValue, key: key, store: store)
    }

    /// Creates a property that can read and write a double value.
    public init(wrappedValue: Value, _ key: String, store: (any StorageBackend)? = nil)
    where Value == Double {
        self = Self.codableFamily(wrappedValue: wrappedValue, key: key, store: store)
    }

    /// Creates a property that can read and write a string value.
    public init(wrappedValue: Value, _ key: String, store: (any StorageBackend)? = nil)
    where Value == String {
        self = Self.codableFamily(wrappedValue: wrappedValue, key: key, store: store)
    }

    /// Creates a property that can read and write a URL value.
    public init(wrappedValue: Value, _ key: String, store: (any StorageBackend)? = nil)
    where Value == URL {
        self = Self.codableFamily(wrappedValue: wrappedValue, key: key, store: store)
    }

    /// Creates a property that can read and write a data value.
    public init(wrappedValue: Value, _ key: String, store: (any StorageBackend)? = nil)
    where Value == Data {
        self = Self.codableFamily(wrappedValue: wrappedValue, key: key, store: store)
    }

    /// Creates a property that can read and write a date value.
    public init(wrappedValue: Value, _ key: String, store: (any StorageBackend)? = nil)
    where Value == Date {
        self = Self.codableFamily(wrappedValue: wrappedValue, key: key, store: store)
    }
}

// MARK: - RawRepresentable Families

extension AppStorage {
    /// Shared construction for raw-representable typed families.
    fileprivate static func rawFamily<Raw: Codable>(
        wrappedValue: Value,
        key: String,
        store: (any StorageBackend)?,
        rawValue: @escaping @Sendable (Value) -> Raw,
        fromRaw: @escaping @Sendable (Raw) -> Value?
    ) -> AppStorage<Value> {
        AppStorage(box: AppStorageBox(
            key: key,
            defaultValue: wrappedValue,
            explicitStorage: store,
            read: { backend, key in
                let raw: Raw? = backend.value(forKey: key)
                return raw.flatMap(fromRaw)
            },
            write: { backend, key, value in
                backend.setValue(rawValue(value), forKey: key)
            }
        ))
    }

    /// Creates a property that can read and write a string-backed
    /// RawRepresentable value.
    public init(wrappedValue: Value, _ key: String, store: (any StorageBackend)? = nil)
    where Value: RawRepresentable, Value.RawValue == String {
        self = Self.rawFamily(
            wrappedValue: wrappedValue,
            key: key,
            store: store,
            rawValue: { $0.rawValue },
            fromRaw: { Value(rawValue: $0) }
        )
    }

    /// Creates a property that can read and write an integer-backed
    /// RawRepresentable value.
    public init(wrappedValue: Value, _ key: String, store: (any StorageBackend)? = nil)
    where Value: RawRepresentable, Value.RawValue == Int {
        self = Self.rawFamily(
            wrappedValue: wrappedValue,
            key: key,
            store: store,
            rawValue: { $0.rawValue },
            fromRaw: { Value(rawValue: $0) }
        )
    }
}

// MARK: - Optional Families

extension AppStorage {
    /// Shared construction for optional Codable-backed families.
    fileprivate static func optionalFamily<Wrapped: Codable>(
        key: String,
        store: (any StorageBackend)?
    ) -> AppStorage<Value> where Value == Wrapped? {
        AppStorage(box: AppStorageBox(
            key: key,
            defaultValue: nil,
            explicitStorage: store,
            read: { backend, key in
                let stored: Wrapped? = backend.value(forKey: key)
                return stored.map { $0 }
            },
            write: { backend, key, value in
                if let value {
                    backend.setValue(value, forKey: key)
                } else {
                    backend.removeValue(forKey: key)
                }
            }
        ))
    }

    /// Creates a property that can read and write an optional Boolean value.
    public init(_ key: String, store: (any StorageBackend)? = nil) where Value == Bool? {
        self = Self.optionalFamily(key: key, store: store)
    }

    /// Creates a property that can read and write an optional integer value.
    public init(_ key: String, store: (any StorageBackend)? = nil) where Value == Int? {
        self = Self.optionalFamily(key: key, store: store)
    }

    /// Creates a property that can read and write an optional double value.
    public init(_ key: String, store: (any StorageBackend)? = nil) where Value == Double? {
        self = Self.optionalFamily(key: key, store: store)
    }

    /// Creates a property that can read and write an optional string value.
    public init(_ key: String, store: (any StorageBackend)? = nil) where Value == String? {
        self = Self.optionalFamily(key: key, store: store)
    }

    /// Creates a property that can read and write an optional URL value.
    public init(_ key: String, store: (any StorageBackend)? = nil) where Value == URL? {
        self = Self.optionalFamily(key: key, store: store)
    }

    /// Creates a property that can read and write an optional data value.
    public init(_ key: String, store: (any StorageBackend)? = nil) where Value == Data? {
        self = Self.optionalFamily(key: key, store: store)
    }

    /// Creates a property that can read and write an optional date value.
    public init(_ key: String, store: (any StorageBackend)? = nil) where Value == Date? {
        self = Self.optionalFamily(key: key, store: store)
    }

    /// Creates a property that can read and write an optional string-backed
    /// RawRepresentable value.
    public init<R>(_ key: String, store: (any StorageBackend)? = nil)
    where Value == R?, R: RawRepresentable, R.RawValue == String {
        self.init(box: AppStorageBox(
            key: key,
            defaultValue: nil,
            explicitStorage: store,
            read: { backend, key in
                let raw: String? = backend.value(forKey: key)
                return raw.flatMap(R.init(rawValue:)).map { $0 }
            },
            write: { backend, key, value in
                if let value {
                    backend.setValue(value.rawValue, forKey: key)
                } else {
                    backend.removeValue(forKey: key)
                }
            }
        ))
    }

    /// Creates a property that can read and write an optional integer-backed
    /// RawRepresentable value.
    public init<R>(_ key: String, store: (any StorageBackend)? = nil)
    where Value == R?, R: RawRepresentable, R.RawValue == Int {
        self.init(box: AppStorageBox(
            key: key,
            defaultValue: nil,
            explicitStorage: store,
            read: { backend, key in
                let raw: Int? = backend.value(forKey: key)
                return raw.flatMap(R.init(rawValue:)).map { $0 }
            },
            write: { backend, key, value in
                if let value {
                    backend.setValue(value.rawValue, forKey: key)
                } else {
                    backend.removeValue(forKey: key)
                }
            }
        ))
    }
}

// MARK: - Dynamic Property Conformance

extension AppStorage: DynamicProperty {}

// MARK: - App Storage Box

/// Reference storage that binds AppStorage to its first rendering runtime.
private final class AppStorageBox<Value>: @unchecked Sendable {
    /// Reads the stored value from a backend, if present.
    typealias Read = @Sendable (any StorageBackend, String) -> Value?

    /// Writes (or clears) the stored value on a backend.
    typealias Write = @Sendable (any StorageBackend, String, Value) -> Void

    /// Persistent key.
    private let key: String

    /// Value returned when the backend contains no entry.
    private let defaultValue: Value

    /// Explicit backend supplied by the property-wrapper initializer.
    private let explicitStorage: StorageBackend?

    /// Family-specific decoding step.
    private let read: Read

    /// Family-specific encoding step.
    private let write: Write

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
        explicitStorage: StorageBackend?,
        read: @escaping Read,
        write: @escaping Write
    ) {
        self.key = key
        self.defaultValue = defaultValue
        self.explicitStorage = explicitStorage
        self.read = read
        self.write = write
    }

    /// Current persisted value.
    var value: Value {
        get {
            let storage = resolvedDependencies().storage
            return read(storage, key) ?? defaultValue
        }
        set {
            let dependencies = resolvedDependencies()
            write(dependencies.storage, key, newValue)

            if let identity = dependencies.identity {
                dependencies.invalidationSink?.invalidate(.subtree(identity))
            } else {
                dependencies.invalidationSink?.invalidate(.all)
            }
        }
    }

    /// Binding captured while the property wrapper is hydrated by its runtime.
    var binding: Binding<Value> {
        bindToActiveRuntimeIfNeeded()
        return Binding(
            get: { self.value },
            set: { self.value = $0 }
        )
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
        let storage = explicitStorage ?? runtimeStorage ?? UnboundAppStorage.fallback
        let invalidationSink = invalidationSink
        let identity = identity
        lock.unlock()
        return (storage, invalidationSink, identity)
    }

    func bindToActiveRuntimeIfNeeded() {
        guard let environment = StateRegistration.currentEnvironment else { return }

        lock.lock()
        if runtimeStorage == nil {
            runtimeStorage = environment.storageBackend
            invalidationSink = environment.renderInvalidationSink
            identity = StateRegistration.currentContext?.identity
        }
        lock.unlock()
    }
}

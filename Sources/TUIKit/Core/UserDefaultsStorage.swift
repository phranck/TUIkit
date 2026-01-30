//
//  UserDefaultsStorage.swift
//  TUIKit
//
//  UserDefaults-compatible storage backend for all platforms.
//

import Foundation

// MARK: - UserDefaults Storage (Apple Platforms)

#if os(macOS) || os(iOS) || os(tvOS) || os(watchOS)
    /// A storage backend that uses UserDefaults.
    ///
    /// Useful when running on Apple platforms with standard app conventions.
    public final class UserDefaultsStorage: StorageBackend, @unchecked Sendable {
        /// The shared instance using standard UserDefaults.
        public static let shared = UserDefaultsStorage()

        /// The underlying UserDefaults.
        private let defaults: UserDefaults

        /// Creates a UserDefaults storage with standard defaults.
        public init() {
            self.defaults = .standard
        }

        /// Creates a UserDefaults storage with a custom suite.
        public init(suiteName: String?) {
            self.defaults = UserDefaults(suiteName: suiteName) ?? .standard
        }

        public func value<T: Codable>(forKey key: String) -> T? {
            guard let data = defaults.data(forKey: key) else { return nil }

            do {
                return try JSONDecoder().decode(T.self, from: data)
            } catch {
                return nil
            }
        }

        public func setValue<T: Codable>(_ value: T, forKey key: String) {
            do {
                let data = try JSONEncoder().encode(value)
                defaults.set(data, forKey: key)
            } catch {
                // Encoding failed
            }
        }

        public func removeValue(forKey key: String) {
            defaults.removeObject(forKey: key)
        }

        public func synchronize() {
            defaults.synchronize()
        }
    }

// MARK: - UserDefaults Storage (Linux)

#elseif os(Linux)
    /// A storage backend that emulates UserDefaults on Linux.
    ///
    /// Uses a JSON file at `~/.local/share/[appName]/UserDefaults.json` to store data,
    /// following the XDG Base Directory Specification.
    public final class UserDefaultsStorage: StorageBackend, @unchecked Sendable {
        /// The shared instance (standard defaults equivalent).
        public static let shared = UserDefaultsStorage()

        /// The underlying file storage.
        private let storage: JSONFileStorage

        /// The suite name (nil for standard defaults).
        private let suiteName: String?

        /// Creates a UserDefaults-compatible storage with standard defaults.
        public init() {
            self.suiteName = nil
            self.storage = Self.createStorage(suiteName: nil)
        }

        /// Creates a UserDefaults-compatible storage with a custom suite.
        ///
        /// On Linux, each suite gets its own JSON file.
        public init(suiteName: String?) {
            self.suiteName = suiteName
            self.storage = Self.createStorage(suiteName: suiteName)
        }

        private static func createStorage(suiteName: String?) -> JSONFileStorage {
            let appName = ProcessInfo.processInfo.processName

            // Use XDG Base Directory: ~/.local/share/[appName]/
            let dataHome: URL
            if let xdgDataHome = ProcessInfo.processInfo.environment["XDG_DATA_HOME"] {
                dataHome = URL(fileURLWithPath: xdgDataHome)
            } else {
                dataHome = FileManager.default.homeDirectoryForCurrentUser
                    .appendingPathComponent(".local")
                    .appendingPathComponent("share")
            }

            let appDir = dataHome.appendingPathComponent(appName)

            // Create directory if needed
            try? FileManager.default.createDirectory(at: appDir, withIntermediateDirectories: true)

            // Use suite name in filename if provided
            let filename: String
            if let suite = suiteName {
                filename = "UserDefaults-\(suite).json"
            } else {
                filename = "UserDefaults.json"
            }

            let fileURL = appDir.appendingPathComponent(filename)
            return JSONFileStorage(fileURL: fileURL)
        }

        public func value<T: Codable>(forKey key: String) -> T? {
            storage.value(forKey: key)
        }

        public func setValue<T: Codable>(_ value: T, forKey key: String) {
            storage.setValue(value, forKey: key)
        }

        public func removeValue(forKey key: String) {
            storage.removeValue(forKey: key)
        }

        public func synchronize() {
            storage.synchronize()
        }

        // MARK: - UserDefaults-compatible convenience methods

        /// Returns the string value for the given key.
        public func string(forKey key: String) -> String? {
            value(forKey: key)
        }

        /// Returns the integer value for the given key.
        public func integer(forKey key: String) -> Int {
            value(forKey: key) ?? 0
        }

        /// Returns the double value for the given key.
        public func double(forKey key: String) -> Double {
            value(forKey: key) ?? 0.0
        }

        /// Returns the boolean value for the given key.
        public func bool(forKey key: String) -> Bool {
            value(forKey: key) ?? false
        }

        /// Returns the data value for the given key.
        public func data(forKey key: String) -> Data? {
            value(forKey: key)
        }

        /// Returns the array value for the given key.
        public func array<T: Codable>(forKey key: String) -> [T]? {
            value(forKey: key)
        }

        /// Returns the dictionary value for the given key.
        public func dictionary<K: Codable & Hashable, V: Codable>(forKey key: String) -> [K: V]? {
            value(forKey: key)
        }

        /// Sets a string value for the given key.
        public func set(_ value: String?, forKey key: String) {
            if let value {
                setValue(value, forKey: key)
            } else {
                removeValue(forKey: key)
            }
        }

        /// Sets an integer value for the given key.
        public func set(_ value: Int, forKey key: String) {
            setValue(value, forKey: key)
        }

        /// Sets a double value for the given key.
        public func set(_ value: Double, forKey key: String) {
            setValue(value, forKey: key)
        }

        /// Sets a boolean value for the given key.
        public func set(_ value: Bool, forKey key: String) {
            setValue(value, forKey: key)
        }

        /// Sets a data value for the given key.
        public func set(_ value: Data?, forKey key: String) {
            if let value {
                setValue(value, forKey: key)
            } else {
                removeValue(forKey: key)
            }
        }
    }
#endif

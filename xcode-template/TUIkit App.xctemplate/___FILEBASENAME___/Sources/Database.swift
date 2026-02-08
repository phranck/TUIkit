import Foundation
import SQLite

/// Helper class for SQLite database operations
///
/// Example usage:
/// ```swift
/// let db = try Database(path: "./myapp.db")
/// ```
class Database {
    let connection: Connection

    init(path: String) throws {
        connection = try Connection(path)
    }
}

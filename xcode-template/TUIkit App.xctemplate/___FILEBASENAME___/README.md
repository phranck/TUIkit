# ___VARIABLE_productName___

A terminal user interface app built with [TUIkit](https://tuikit.layered.work).

## ⚠️ IMPORTANT: First Time Setup

**Before building, verify the run destination:**

1. Look at the Xcode toolbar (top of the window)
2. Next to "___VARIABLE_productName___", you'll see a destination dropdown
3. **Make sure it says "My Mac"** (not "iPhone Simulator")
4. If it doesn't, click it and select "My Mac"

This is a macOS-only terminal application and will show build errors if an iOS destination is selected.

## Quick Start

### Run in Xcode
Press `Cmd+R` to build and run.

### Run from Terminal

```bash
swift run
```

## Project Structure

```
___VARIABLE_productName___/
├── Sources/
│   ├── App.swift          # Main application entry point
│   ├── ContentView.swift  # Root view___IF_includeSQLite___
│   └── Database.swift     # SQLite database helper___ENDIF______IF_testFramework:Swift Testing___
└── Tests/                 # Swift Testing suite___ENDIF______IF_testFramework:XCTest___
└── Tests/                 # XCTest suite___ENDIF___
```

___IF_includeSQLite___

## Database

This project includes [SQLite.swift](https://github.com/stephencelis/SQLite.swift) for local data persistence.

**Quick Start:**

```swift
import SQLite

// Initialize database
let db = try Database(path: "./myapp.db")

// Define a table
let users = Table("users")
let id = Expression<Int64>("id")
let name = Expression<String>("name")

// Insert data
try db.run(users.insert(name <- "Alice"))

// Query data
for user in try db.prepare(users) {
    print("User: \(user[name])")
}
```

For detailed documentation, see [SQLite.swift Documentation](https://github.com/stephencelis/SQLite.swift/blob/master/Documentation/Index.md).

___ENDIF___

## Learn More

- [TUIkit Documentation](https://tuikit.layered.work/documentation/tuikit/)
- [TUIkit on GitHub](https://github.com/phranck/TUIkit)

---

**Need help?** Check the [TUIkit Issues](https://github.com/phranck/TUIkit/issues)

# TUIkit Project Creator

Modern CLI tool and templates for creating TUIkit terminal applications.

## 🚀 Quick Install (Recommended)

**One-liner installation:**

```bash
curl -fsSL https://raw.githubusercontent.com/phranck/TUIkit/main/xcode-template/install.sh | bash
```

This installs the `tuikit` command globally on your system.

## Usage

Create TUIkit projects with simple commands:

```bash
# Basic TUIkit app
tuikit init MyApp

# With SQLite support
tuikit init sqlite MyApp

# With Swift Testing
tuikit init testing MyApp

# With XCTest
tuikit init xctest MyApp

# Combine features
tuikit init sqlite testing MyApp
```

## Features

- ✅ **Modern CLI** - Simple, intuitive commands
- ✅ **Swift Package** - Creates real SPM projects (not .xcodeproj)
- ✅ **Conditional Features** - SQLite, Swift Testing, XCTest support
- ✅ **Auto-configured** - Pre-configured schemes, settings, dependencies
- ✅ **Cross-platform** - macOS, Linux support with XDG compliance
- ✅ **One-liner install** - Get started in seconds

## What Gets Created

Every project includes:

```
MyApp/
├── Package.swift           # Swift Package manifest with TUIkit
├── Sources/
│   ├── App.swift          # Main application entry point
│   ├── ContentView.swift  # Root view
│   └── Database.swift     # (if sqlite option used)
├── Tests/                 # (if testing/xctest option used)
├── .swiftpm/              # Pre-configured Xcode scheme
├── README.md              # Project documentation
└── .gitignore
```

## Installation Details

The installer:
- Detects your platform (macOS/Linux)
- Respects XDG Base Directory specification
- Installs to `/usr/local/bin` or `~/.local/bin`
- Offers to update your shell PATH automatically
- Creates `tuikit-uninstall` command

See [INSTALLATION.md](INSTALLATION.md) for detailed installation instructions.

## Manual Installation

```bash
git clone https://github.com/phranck/TUIkit.git
cd TUIkit/xcode-template
./install.sh
```

## Uninstall

```bash
tuikit-uninstall
```

---

## Alternative: Xcode Template (Basic)

For users who prefer Xcode's File > New > Project workflow:

**Installation:**

```bash
mkdir -p ~/Library/Developer/Xcode/Templates/Project\ Templates/macOS/Application
cp -r "TUIkit App.xctemplate" ~/Library/Developer/Xcode/Templates/Project\ Templates/macOS/Application/
```

**Usage:**
1. Xcode > File > New > Project
2. Select "TUIkit App" under macOS > Application
3. Enter project name

**Limitations:**
- No conditional features (SQLite, tests must be added manually)
- Less flexible than CLI tool

---

## Examples

### Create a basic app

```bash
tuikit init HelloWorld
cd HelloWorld
swift run
```

### Create an app with database support

```bash
tuikit init sqlite TaskManager
cd TaskManager
# Database.swift is already included
swift run
```

### Create a fully-featured app

```bash
tuikit init sqlite testing MyProject
cd MyProject
# Includes TUIkit, SQLite.swift, and Swift Testing
swift test  # Run tests
swift run   # Run app
```

## Requirements

- macOS 15+ or Linux
- Swift 6.0+
- Bash shell

## Documentation

- [TUIkit Documentation](https://tuikit.layered.work/documentation/tuikit/)
- [TUIkit GitHub](https://github.com/phranck/TUIkit)
- [Installation Guide](INSTALLATION.md)

## Technical Details

The CLI tool creates **native Swift Packages** with:
- Automatic dependency resolution
- Pre-configured build settings
- Xcode scheme with "My Mac" destination
- Proper project structure following Swift Package conventions

Unlike Xcode templates, the CLI approach:
- ✅ Supports conditional features (options at creation time)
- ✅ Creates proper Swift Packages (not .xcodeproj files)
- ✅ Automatically includes all dependencies
- ✅ Works from command line (automation-friendly)

## License

Same as TUIkit - MIT License

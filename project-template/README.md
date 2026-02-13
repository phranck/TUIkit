# TUIkit Project Creator

CLI tool for creating TUIkit terminal applications.

## Quick Install

```bash
curl -fsSL https://raw.githubusercontent.com/phranck/TUIkit/main/project-template/install.sh | bash
```

This installs the `tuikit` command globally on your system.

## Usage

```bash
tuikit init MyApp                   # Basic app
tuikit init sqlite MyApp            # With SQLite database
tuikit init testing MyApp           # With Swift Testing
tuikit init sqlite testing MyApp    # All features
```

## What Gets Created

```
MyApp/
├── Package.swift           # Swift Package with TUIkit dependency
├── Sources/
│   ├── App.swift           # Main entry point
│   ├── ContentView.swift   # Root view
│   └── Database.swift      # (if sqlite option used)
├── Tests/                  # (if testing/xctest option used)
├── .swiftpm/               # Pre-configured Xcode scheme
├── README.md
└── .gitignore
```

## Features

- Creates native Swift Packages (not .xcodeproj)
- Optional SQLite.swift integration
- Optional Swift Testing or XCTest
- Pre-configured Xcode scheme
- Cross-platform (macOS, Linux)
- XDG Base Directory compliant

## Installation Details

The installer:
- Detects your platform (macOS/Linux)
- Installs to `/usr/local/bin` or `~/.local/bin`
- Offers to update your shell PATH automatically
- Creates `tuikit-uninstall` command for easy removal

## Manual Installation

```bash
git clone https://github.com/phranck/TUIkit.git
cd TUIkit/project-template
./install.sh
```

## Uninstall

```bash
tuikit-uninstall
```

## Requirements

- macOS 15+ or Linux
- Swift 6.0+
- Bash shell

## Documentation

- [TUIkit Documentation](https://tuikit.dev/documentation/tuikit/)
- [TUIkit GitHub](https://github.com/phranck/TUIkit)

## License

MIT License

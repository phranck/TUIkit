# TUIkit Project Creator

CLI tool for creating TUIkit terminal applications.

## Quick Install

```bash
curl -fsSL https://raw.githubusercontent.com/phranck/TUIkit/main/project-template/install.sh | bash
```

This installs the `tuikit` command into your user bin directory
(`~/.local/bin` on Linux; `/usr/local/bin` when writable on macOS, else
`~/.local/bin`).

## Usage

```bash
tuikit init MyApp                   # Basic app
tuikit init sqlite MyApp            # With SQLite (GRDB)
tuikit init testing MyApp           # With Swift Testing
tuikit init sqlite testing MyApp    # All features
tuikit init --yes git MyApp         # Non-interactive (CI-friendly)
```

Set `TUIKIT_NON_INTERACTIVE=1` to suppress every prompt (helpful for
CI or unattended installs).

## What Gets Created

```
MyApp/
├── Package.swift           # Swift Package with TUIkit dependency
├── Sources/
│   ├── App.swift           # Main entry point
│   ├── ContentView.swift   # Root view
│   └── Database.swift      # (if sqlite option used)
├── Tests/                  # (if testing/xctest option used)
├── README.md
└── .gitignore
```

Xcode generates its own scheme configuration on first open, so the
generator does not pre-populate `.swiftpm`.

## Name Handling

The project name is split into a display name (the folder), a Swift
identifier used for target, package, and module names, and a
filesystem path. Invalid components (`..`, embedded `/`, control
characters, empty names) are rejected before any file is written.
Non-identifier characters in the display name become underscores in
the Swift identifier (`my-app` → `my_app`).

## Requirements

- macOS 15+ or a supported Linux distribution
- Swift 6.0.3 (the pinned compiler floor matches the TUIkit SDK gates;
  the Linux installer pins this version through `swiftly` or a Swift.org
  tarball on Ubuntu)
- Bash shell

## Platform Behavior

- **macOS**: Xcode preferences are set only on macOS; the "Open in
  Xcode" prompt is macOS-only and skipped in non-interactive runs.
- **Linux**: the installer offers to install Swift through your
  distribution (apt / dnf / AUR) or `swiftly`. Non-Ubuntu tarball
  downloads are refused instead of pretending to be Ubuntu.

## Manual Installation

```bash
git clone https://github.com/phranck/TUIkit.git
cd TUIkit/project-template
./install.sh
```

## Uninstall

```bash
tuikit-uninstall
# or
tuikit uninstall
```

Both spellings remove the script from the same directory the installer
used.

## Documentation

- [TUIkit Documentation](https://tuikit.layered.work/documentation/tuikit/)
- [TUIkit GitHub](https://github.com/phranck/TUIkit)

## License

This repository has been published under the [MIT](https://layered.mit-license.org) license.

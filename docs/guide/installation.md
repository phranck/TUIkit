# Installation

## Using Swift Package Manager

Add TUIKit to your `Package.swift`:

```swift
let package = Package(
    name: "MyTUIApp",
    dependencies: [
        .package(url: "https://github.com/phranck/SwiftTUI.git", branch: "main")
    ],
    targets: [
        .executableTarget(
            name: "MyTUIApp",
            dependencies: ["TUIKit"]
        )
    ]
)
```

Or in Xcode, use `File > Add Packages...` and enter the URL:
```
https://github.com/phranck/SwiftTUI.git
```

## Create a New Project

```bash
swift package init --type executable --name MyTUIApp
cd MyTUIApp
```

Then add TUIKit as a dependency (see above).

## Run the Example

To see TUIKit in action, clone the repository and run:

```bash
git clone https://github.com/phranck/SwiftTUI.git
cd SwiftTUI
swift run TUIKitExample
```

Press `q` or `ESC` to exit.

## Requirements

- Swift 6.0 or later
- macOS 10.15+ or Linux

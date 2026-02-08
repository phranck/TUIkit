# Xcode Project Template Guide

Complete guide for creating production-ready Xcode project templates based on learnings from the TUIkit template implementation.

## Table of Contents

- [Critical Issues and Solutions](#critical-issues-and-solutions)
- [Template Structure](#template-structure)
- [Variable Substitution](#variable-substitution)
- [Conditional Content](#conditional-content)
- [User Options](#user-options)
- [Installation and Distribution](#installation-and-distribution)
- [Best Practices](#best-practices)
- [Testing Your Template](#testing-your-template)

## Critical Issues and Solutions

### Issue 1: @main Attribute Error

**Problem**: Using `@main` attribute in a file named `main.swift` causes Swift Package Manager to fail with:

```
error: 'main' attribute cannot be used in a module that contains top-level code
```

**Root Cause**: SPM treats `main.swift` specially as a file containing top-level code. The `@main` attribute conflicts with this interpretation.

**Solution**: NEVER name your app entry point file `main.swift` when using `@main`. Use `App.swift` instead:

```swift
// ✅ CORRECT: App.swift
import TUIkit

@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

```swift
// ❌ WRONG: main.swift
@main  // This will fail!
struct MyApp: App { ... }
```

### Issue 2: iOS Destination Selected by Default

**Problem**: Xcode defaults to iOS Simulator destination for Swift Packages, causing 100+ availability errors on macOS-only projects:

```
error: 'some' return types are only available in iOS 13.0.0 or newer
```

**Root Cause**: Xcode doesn't automatically respect `platforms: [.macOS(.v14)]` in Package.swift for destination selection.

**Solutions** (implement ALL three):

#### 1. Set Xcode Defaults (Automatic)

Add to your installation script:

```bash
# Configure Xcode to prefer macOS for Swift Packages
defaults write com.apple.dt.Xcode IDEPreferredPlatformForSwiftPackages -string "macosx"
```

#### 2. Include Shared Scheme

Create `.swiftpm/xcode/xcshareddata/xcschemes/___VARIABLE_productName___.xcscheme`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<Scheme version="1.3">
   <BuildAction>
      <BuildActionEntries>
         <BuildActionEntry buildForRunning="YES">
            <BuildableReference
               BuildableName="___VARIABLE_productName___"
               BlueprintName="___VARIABLE_productName___"
               ReferencedContainer="container:">
            </BuildableReference>
         </BuildActionEntry>
      </BuildActionEntries>
   </BuildAction>
   <LaunchAction
      buildConfiguration="Debug"
      selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier="Xcode.DebuggerFoundation.Launcher.LLDB">
   </LaunchAction>
</Scheme>
```

Also create `.swiftpm/xcode/xcshareddata/WorkspaceSettings.xcsettings`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>BuildSystemType</key>
    <string>Original</string>
</dict>
</plist>
```

#### 3. Add Prominent Warning in README

Make the README the initial file opened (`NameOfInitialFileForEditor` = `README.md`) with a clear warning:

```markdown
## ⚠️ IMPORTANT: First Time Setup

**Before building, verify the run destination:**

1. Look at the Xcode toolbar (top of the window)
2. Next to "YourApp", you'll see a destination dropdown
3. **Make sure it says "My Mac"** (not "iPhone Simulator")
4. If it doesn't, click it and select "My Mac"

This is a macOS-only terminal application and will show build errors if an iOS destination is selected.
```

### Issue 3: Conditional Content Not Working

**Problem**: Template conditionals must be on single lines without line breaks.

**Solution**:

```xml
<!-- ✅ CORRECT: All on one line -->
.package(url: "https://github.com/example/lib.git", branch: "main")___IF_includeSQLite___,
.package(url: "https://github.com/stephencelis/SQLite.swift.git", from: "0.15.0")___ENDIF___

<!-- ❌ WRONG: Line break within conditional -->
.package(url: "https://github.com/example/lib.git", branch: "main")
___IF_includeSQLite___
,
.package(url: "https://github.com/stephencelis/SQLite.swift.git", from: "0.15.0")
___ENDIF___
```

## Template Structure

### Directory Layout

```
MyTemplate.xctemplate/
├── TemplateInfo.plist                                # Required: template metadata
└── ___FILEBASENAME___/                               # Template files directory (required name)
    ├── Package.swift                                 # Swift package manifest
    ├── README.md                                     # Project documentation (recommended)
    ├── .gitignore                                    # Git ignore rules
    ├── Sources/
    │   ├── App.swift                                 # NOT main.swift!
    │   └── ContentView.swift
    ├── Sources___IF_includeSQLite___/
    │   └── Database.swift                            # Conditional file
    ├── Tests___IF_testFramework:Swift Testing___/
    │   └── Tests.swift
    ├── Tests___IF_testFramework:XCTest___/
    │   └── Tests.swift
    └── .swiftpm/xcode/
        └── xcshareddata/
            ├── WorkspaceSettings.xcsettings
            └── xcschemes/
                └── ___VARIABLE_productName___.xcscheme
```

### Installation Location

Templates must be installed in:

```
~/Library/Developer/Xcode/Templates/Project Templates/macOS/Application/
```

The path structure determines where the template appears in Xcode:
- `macOS/Application/` → appears under macOS > Application
- `macOS/Executable/` → appears under macOS > Executable
- `MultiPlatform/Application/` → appears under Multiplatform

## Variable Substitution

### Standard Variables

Xcode replaces these placeholders in all template files:

| Variable | Description | Example |
|----------|-------------|---------|
| `___VARIABLE_productName___` | Project name entered by user | `MyApp` |
| `___VARIABLE_productName:identifier___` | Project name as valid Swift identifier | `MyApp` |
| `___FILEBASENAME___` | Base filename without extension | `MyApp` |
| `___FULLUSERNAME___` | User's full name | `John Doe` |
| `___DATE___` | Current date | `2/8/26` |
| `___YEAR___` | Current year | `2026` |
| `___COPYRIGHT___` | Copyright string | `Copyright © 2026` |

### Usage in Package.swift

```swift
// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "___VARIABLE_productName___",
    platforms: [
        .macOS(.v14)
    ],
    dependencies: [
        .package(url: "https://github.com/phranck/TUIkit.git", branch: "main")
    ],
    targets: [
        .executableTarget(
            name: "___VARIABLE_productName___",
            dependencies: [
                .product(name: "TUIkit", package: "TUIkit")
            ],
            path: "Sources"
        )
    ]
)
```

### Usage in Source Files

```swift
//
//  App.swift
//  ___VARIABLE_productName___
//
//  Created by ___FULLUSERNAME___ on ___DATE___.
//

import TUIkit

/// The main ___VARIABLE_productName___ application.
@main
struct ___VARIABLE_productName:identifier___App: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

## Conditional Content

### Basic Conditional Syntax

Use `___IF_condition___...___ENDIF___` for conditional content:

```xml
<!-- In TemplateInfo.plist -->
<dict>
    <key>Identifier</key>
    <string>includeSQLite</string>
    <key>Type</key>
    <string>checkbox</string>
</dict>
```

```swift
// In Package.swift - ALL ON ONE LINE
dependencies: [
    .package(url: "https://github.com/phranck/TUIkit.git", branch: "main")___IF_includeSQLite___,
    .package(url: "https://github.com/stephencelis/SQLite.swift.git", from: "0.15.0")___ENDIF___
]
```

### Conditional with Value Comparison

For dropdown/popup options, check specific values:

```xml
<!-- In TemplateInfo.plist -->
<dict>
    <key>Identifier</key>
    <string>testFramework</string>
    <key>Type</key>
    <string>popup</string>
    <key>Values</key>
    <array>
        <string>None</string>
        <string>Swift Testing</string>
        <string>XCTest</string>
    </array>
</dict>
```

```swift
// In Package.swift
targets: [
    .executableTarget(
        name: "___VARIABLE_productName___",
        dependencies: [...],
        path: "Sources"
    ),___IF_testFramework:Swift Testing___
    .testTarget(
        name: "___VARIABLE_productName___Tests",
        dependencies: ["___VARIABLE_productName___"],
        path: "Tests"
    )___ENDIF______IF_testFramework:XCTest___
    .testTarget(
        name: "___VARIABLE_productName___Tests",
        dependencies: ["___VARIABLE_productName___"],
        path: "Tests"
    )___ENDIF___
]
```

### Conditional Files and Directories

Include condition in the directory/file name:

```
Sources___IF_includeSQLite___/
    Database.swift
```

This creates `Sources/Database.swift` only if `includeSQLite` is true.

### Conditional Sections in README

```markdown
___IF_includeSQLite___

## Database
This project includes [SQLite.swift](https://github.com/stephencelis/SQLite.swift) for local data persistence.

___ENDIF___
```

**CRITICAL**: Ensure blank lines before and after code blocks in markdown, even within conditionals.

## User Options

### TemplateInfo.plist Options Array

```xml
<key>Options</key>
<array>
    <!-- Product Name -->
    <dict>
        <key>Identifier</key>
        <string>productName</string>
        <key>Required</key>
        <true/>
        <key>Name</key>
        <string>Product Name:</string>
        <key>NotPersisted</key>
        <true/>
        <key>Description</key>
        <string>The name of your app</string>
        <key>EmptyReplacement</key>
        <string>MyApp</string>
        <key>Type</key>
        <string>text</string>
        <key>SortOrder</key>
        <integer>-2</integer>
    </dict>

    <!-- Test Framework Dropdown -->
    <dict>
        <key>Identifier</key>
        <string>testFramework</string>
        <key>Required</key>
        <false/>
        <key>Name</key>
        <string>Test Framework:</string>
        <key>Description</key>
        <string>Choose which test framework to include</string>
        <key>Type</key>
        <string>popup</string>
        <key>Default</key>
        <string>None</string>
        <key>Values</key>
        <array>
            <string>None</string>
            <string>Swift Testing</string>
            <string>XCTest</string>
        </array>
        <key>SortOrder</key>
        <integer>-1</integer>
    </dict>

    <!-- SQLite Checkbox -->
    <dict>
        <key>Identifier</key>
        <string>includeSQLite</string>
        <key>Required</key>
        <false/>
        <key>Name</key>
        <string>Include SQLite.swift:</string>
        <key>Description</key>
        <string>Add SQLite.swift for local database storage</string>
        <key>Type</key>
        <string>checkbox</string>
        <key>Default</key>
        <string>false</string>
        <key>SortOrder</key>
        <integer>0</integer>
    </dict>
</array>
```

### Option Types

| Type | Description | Use Case |
|------|-------------|----------|
| `text` | Text field | Product name, bundle identifier |
| `checkbox` | Boolean checkbox | Optional features (SQLite, Analytics, etc.) |
| `popup` | Dropdown menu | Test framework selection, language choice |

### SortOrder

- Negative numbers: appear before product name field
- `-2`: Product name (standard)
- `-1`: First custom option
- `0+`: Following options

## Template Icons

Templates can display custom icons in Xcode's project template chooser using two methods: SF Symbols (recommended) or custom PNG files.

### Method 1: SF Symbols (Recommended)

**Advantages:**
- Always renders correctly in all macOS versions
- Adapts to light/dark mode automatically
- No additional files needed
- Consistent with macOS design language

**Implementation:**

Add to `TemplateInfo.plist`:

```xml
<key>Image</key>
<dict>
    <key>SystemSymbolName</key>
    <string>terminal.fill</string>
</dict>
```

**Popular SF Symbol choices for templates:**

- `terminal.fill` - CLI/terminal applications
- `app.fill` - General applications
- `gear` - Utilities and tools
- `doc.text` - Document-based apps
- `network` - Networking applications
- `cpu` - System/low-level apps
- `hammer.fill` - Build tools
- `wrench.and.screwdriver.fill` - Developer tools

**Finding SF Symbols:**

1. Download the SF Symbols app from [Apple Developer](https://developer.apple.com/sf-symbols/)
2. Browse available symbols
3. Copy the symbol name (e.g., `terminal.fill`)
4. Use in `TemplateInfo.plist`

### Method 2: Custom PNG Files

**Note:** Custom PNG icons in user templates may not display reliably in all Xcode versions. SF Symbols are strongly recommended instead.

**Requirements if using PNG:**

1. **File names (both required):**
   - `TemplateIcon.png` - Standard resolution (48×48 pixels)
   - `TemplateIcon@2x.png` - Retina resolution (96×96 pixels)

2. **File location:**
   - Place directly in the `.xctemplate` directory root (NOT in `___FILEBASENAME___`)

3. **Image specifications:**
   - **Size:** Exactly 48×48 (standard) and 96×96 (retina)
   - **Format:** PNG with transparency
   - **Color depth:** 32-bit RGBA
   - **Background:** Transparent (alpha channel)
   - **Style:** Simple, recognizable icon that works in light and dark modes

4. **Design guidelines:**
   - Use simple shapes and limited colors
   - Ensure visibility on both light and dark backgrounds
   - Avoid fine details that won't be visible at small sizes
   - Test appearance in both light and dark mode

**TemplateInfo.plist configuration:**

When using PNG files, you can OMIT the `<key>Image</key>` section entirely. Xcode will automatically use `TemplateIcon.png` and `TemplateIcon@2x.png` if present.

Alternatively, explicitly reference them (though this is optional):

```xml
<key>Image</key>
<dict>
    <key>TemplateIcon</key>
    <string>TemplateIcon.png</string>
</dict>
```

**Creating PNG icons from SVG:**

If you have an SVG source file:

```bash
# Install ImageMagick if needed
brew install imagemagick

# Convert SVG to PNG icons
magick -background none -resize 48x48 icon.svg TemplateIcon.png
magick -background none -resize 96x96 icon.svg TemplateIcon@2x.png
```

### Comparison: SF Symbols vs PNG

| Aspect | SF Symbols | Custom PNG |
|--------|-----------|------------|
| Reliability | ✅ Always works | ⚠️ May not display in user templates |
| File size | ✅ None (built-in) | ❌ ~5-10KB for both files |
| Dark mode | ✅ Automatic adaptation | ⚠️ Must design for both modes |
| Maintenance | ✅ No updates needed | ❌ Must update for design changes |
| Customization | ⚠️ Limited to available symbols | ✅ Complete control |
| Xcode versions | ✅ Works in all modern versions | ⚠️ Behavior varies by version |

### Template Directory Structure with Icons

**Using SF Symbols (Recommended):**

```
MyTemplate.xctemplate/
├── TemplateInfo.plist          # Contains SystemSymbolName
└── ___FILEBASENAME___/
    └── [template files]
```

**Using PNG Files:**

```
MyTemplate.xctemplate/
├── TemplateInfo.plist          # Image key optional
├── TemplateIcon.png            # 48×48 pixels
├── TemplateIcon@2x.png         # 96×96 pixels
└── ___FILEBASENAME___/
    └── [template files]

```

### Best Practice Recommendation

**Always use SF Symbols** unless you have a compelling reason to use custom PNG icons (e.g., specific branding requirements). SF Symbols provide:

1. Guaranteed compatibility across Xcode versions
2. Automatic light/dark mode adaptation
3. Smaller template package size
4. No maintenance overhead
5. Consistent with Apple's design language

If your template represents a well-known tool or framework, choose an SF Symbol that best represents its purpose rather than trying to recreate a logo.

## Installation and Distribution

### ZIP-Based Distribution (Recommended)

More reliable than downloading individual files.

#### 1. Create Packaging Script

`create-template-zip.sh`:

```bash
#!/bin/bash

set -e

TEMPLATE_NAME="TUIkit App.xctemplate"
OUTPUT_ZIP="TUIkit-App-Template.zip"

if [ ! -d "$TEMPLATE_NAME" ]; then
    echo "Error: Template directory '$TEMPLATE_NAME' not found"
    exit 1
fi

# Remove old ZIP
rm -f "$OUTPUT_ZIP"

# Create new ZIP (exclude build artifacts)
zip -r "$OUTPUT_ZIP" "$TEMPLATE_NAME" \
    -x "*.DS_Store" \
    -x "*/.build/*" \
    -x "*/build/*" \
    -x "*/.swiftpm/xcode/package.xcworkspace/*"

echo "Created $OUTPUT_ZIP"
ls -lh "$OUTPUT_ZIP"
```

#### 2. Create Installation Script

`install.sh`:

```bash
#!/bin/bash
#
# Template Installer
# Usage:
#   curl -fsSL https://example.com/install.sh | bash
#   ./install.sh              # Install template
#   ./install.sh --uninstall  # Uninstall template
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

TEMPLATE_NAME="MyApp.xctemplate"
GITHUB_REPO="user/repo"
GITHUB_BRANCH="main"
TEMPLATE_ZIP_URL="https://github.com/${GITHUB_REPO}/raw/${GITHUB_BRANCH}/template/MyApp-Template.zip"
TEMPLATE_DIR="$HOME/Library/Developer/Xcode/Templates/Project Templates/macOS/Application"
TEMP_DIR=$(mktemp -d)

# Cleanup function
cleanup() {
    if [ -d "$TEMP_DIR" ]; then
        rm -rf "$TEMP_DIR"
    fi
}
trap cleanup EXIT

# Check for uninstall flag
if [[ "$1" == "--uninstall" ]]; then
    echo -e "${BLUE}Uninstalling template...${NC}"

    if [ -d "$TEMPLATE_DIR/$TEMPLATE_NAME" ]; then
        rm -rf "$TEMPLATE_DIR/$TEMPLATE_NAME"
        echo -e "${GREEN}✅ Template uninstalled successfully!${NC}"
    else
        echo -e "${YELLOW}Template is not installed.${NC}"
    fi
    exit 0
fi

# Check if running on macOS
if [[ "$(uname)" != "Darwin" ]]; then
    echo -e "${RED}Error: This installer only works on macOS.${NC}"
    exit 1
fi

# Check if Xcode is installed
if ! command -v xcodebuild &> /dev/null; then
    echo -e "${RED}Error: Xcode is not installed.${NC}"
    exit 1
fi

echo -e "${YELLOW}Installing template...${NC}"

# Create template directory
mkdir -p "$TEMPLATE_DIR"

# Download template ZIP
echo -e "  ${BLUE}Downloading template...${NC}"
if ! curl -fsSL "$TEMPLATE_ZIP_URL" -o "$TEMP_DIR/template.zip"; then
    echo -e "${RED}Error: Failed to download template.${NC}"
    exit 1
fi

# Extract template
echo -e "  ${BLUE}Extracting template...${NC}"
cd "$TEMP_DIR"
if ! unzip -q template.zip; then
    echo -e "${RED}Error: Failed to extract template.${NC}"
    exit 1
fi

# Copy to Xcode templates directory
echo -e "  ${BLUE}Installing template...${NC}"
if [ -d "$TEMP_DIR/$TEMPLATE_NAME" ]; then
    # Remove old template if exists
    [ -d "$TEMPLATE_DIR/$TEMPLATE_NAME" ] && rm -rf "$TEMPLATE_DIR/$TEMPLATE_NAME"
    # Copy new template
    cp -R "$TEMP_DIR/$TEMPLATE_NAME" "$TEMPLATE_DIR/"
else
    echo -e "${RED}Error: Template structure not found in ZIP.${NC}"
    exit 1
fi

# Configure Xcode to prefer macOS for Swift Packages
echo -e "  ${BLUE}Configuring Xcode preferences...${NC}"
defaults write com.apple.dt.Xcode IDEPreferredPlatformForSwiftPackages -string "macosx" 2>/dev/null || true

echo ""
echo -e "${GREEN}✅ Installation complete!${NC}"
echo ""
echo -e "The template is now available in Xcode:"
echo -e "  ${BLUE}File > New > Project > macOS > Application > MyApp${NC}"
echo ""
echo -e "${YELLOW}⚠️  IMPORTANT:${NC}"
echo -e "  When creating a new project, verify that 'My Mac' is selected"
echo -e "  as the run destination in Xcode (not iOS Simulator)."
echo ""
echo -e "To uninstall, run:"
echo -e "  ${YELLOW}curl -fsSL https://example.com/install.sh | bash -s -- --uninstall${NC}"
echo ""
```

#### 3. Local Installation Script

`install-local.sh`:

```bash
#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_NAME="MyApp.xctemplate"
TEMPLATE_DIR="$HOME/Library/Developer/Xcode/Templates/Project Templates/macOS/Application"

# Check for uninstall flag
if [[ "$1" == "--uninstall" ]]; then
    if [ -d "$TEMPLATE_DIR/$TEMPLATE_NAME" ]; then
        rm -rf "$TEMPLATE_DIR/$TEMPLATE_NAME"
        echo "✅ Template uninstalled successfully!"
    else
        echo "Template is not installed."
    fi
    exit 0
fi

# Check if template exists
if [ ! -d "$SCRIPT_DIR/$TEMPLATE_NAME" ]; then
    echo "Error: Template not found at $SCRIPT_DIR/$TEMPLATE_NAME"
    exit 1
fi

echo "Installing template from local files..."

# Create template directory
mkdir -p "$TEMPLATE_DIR"

# Remove old template if exists
[ -d "$TEMPLATE_DIR/$TEMPLATE_NAME" ] && rm -rf "$TEMPLATE_DIR/$TEMPLATE_NAME"

# Copy template
cp -R "$SCRIPT_DIR/$TEMPLATE_NAME" "$TEMPLATE_DIR/"

# Configure Xcode preferences
defaults write com.apple.dt.Xcode IDEPreferredPlatformForSwiftPackages -string "macosx" 2>/dev/null || true

echo "✅ Installation complete!"
echo ""
echo "To uninstall, run:"
echo "  $0 --uninstall"
```

## Best Practices

### 1. File Naming

- ✅ DO: Use `App.swift` for app entry point
- ❌ DON'T: Use `main.swift` with `@main` attribute
- ✅ DO: Separate views into their own files (`ContentView.swift`)
- ✅ DO: Use descriptive names for conditional files (`Database.swift`, `NetworkManager.swift`)

### 2. Documentation

- ✅ DO: Include comprehensive README.md as initial file
- ✅ DO: Add prominent setup instructions at the top
- ✅ DO: Include troubleshooting section for common issues
- ✅ DO: Link to external documentation
- ✅ DO: Use blank lines before and after markdown code blocks

### 3. User Options

- ✅ DO: Provide sensible defaults
- ✅ DO: Use clear, descriptive option names
- ✅ DO: Add helpful descriptions for each option
- ❌ DON'T: Require options that have obvious defaults
- ✅ DO: Use checkboxes for optional features
- ✅ DO: Use popups for mutually exclusive choices

### 4. Dependencies

- ✅ DO: Use `branch: "main"` for dependencies without releases
- ✅ DO: Use `from: "x.x.x"` for stable, released dependencies
- ✅ DO: Include only essential dependencies by default
- ✅ DO: Make optional dependencies conditional
- ❌ DON'T: Include experimental or unstable dependencies

### 5. Installation

- ✅ DO: Use ZIP-based distribution for reliability
- ✅ DO: Configure Xcode defaults automatically
- ✅ DO: Provide uninstall capability
- ✅ DO: Add clear installation instructions
- ✅ DO: Test installation on clean system
- ✅ DO: Provide both remote and local installation options

### 6. Template Metadata

- ✅ DO: Use `SupportsSwiftPackage` = `true`
- ✅ DO: Use `TextSubstitutionPlaygroundsAppTemplateKind` for custom files
- ✅ DO: Set `NameOfInitialFileForEditor` to most important file (usually README.md)
- ✅ DO: Use SF Symbols for icons (more reliable than PNG)
- ✅ DO: Set appropriate `Platforms` array
- ✅ DO: Set `AllowedTypes` to `["com.apple.swiftpm"]`

### 7. Conditional Content

- ✅ DO: Keep conditionals on single lines (no line breaks)
- ✅ DO: Test all combinations of user options
- ✅ DO: Use meaningful conditional identifiers
- ❌ DON'T: Nest conditionals (Xcode doesn't support this well)
- ✅ DO: Document what each conditional does

## Testing Your Template

### 1. Validation Checklist

Before distribution, verify:

- [ ] Template installs without errors
- [ ] All files appear in Xcode project navigator
- [ ] Variables are substituted correctly
- [ ] All option combinations work
- [ ] Conditional files appear/disappear correctly
- [ ] Package dependencies resolve successfully
- [ ] Project builds without errors on first run
- [ ] Correct destination (My Mac) is selected by default
- [ ] README opens automatically
- [ ] Shared scheme is recognized by Xcode

### 2. Test Each Option Combination

For a template with 2 options (each with 2 values), test all 4 combinations:

```
1. Test Framework: None,          SQLite: No
2. Test Framework: None,          SQLite: Yes
3. Test Framework: Swift Testing, SQLite: No
4. Test Framework: Swift Testing, SQLite: Yes
5. Test Framework: XCTest,        SQLite: No
6. Test Framework: XCTest,        SQLite: Yes
```

### 3. Verify Generated Projects

For each test project:

```bash
# Build should succeed
swift build

# Run should succeed
swift run

# Tests should work (if enabled)
swift test
```

### 4. Test Installation Scripts

```bash
# Test local install
./install-local.sh

# Verify template appears in Xcode
open /Applications/Xcode.app

# Test uninstall
./install-local.sh --uninstall

# Test remote install (requires ZIP on GitHub)
curl -fsSL https://example.com/install.sh | bash

# Test remote uninstall
curl -fsSL https://example.com/install.sh | bash -s -- --uninstall
```

### 5. Common Issues to Check

- [ ] No `@main` in `main.swift`
- [ ] All conditionals on single lines
- [ ] No trailing commas in arrays/dependencies
- [ ] Valid plist syntax: `plutil -lint TemplateInfo.plist`
- [ ] All referenced files exist
- [ ] Scheme file has correct target name placeholder
- [ ] Xcode defaults command succeeds
- [ ] ZIP contains correct directory structure

## Reference Files

### Complete TemplateInfo.plist Example

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>SupportsSwiftPackage</key>
    <true/>
    <key>Kind</key>
    <string>Xcode.IDESwiftPackageUI.TextSubstitutionPlaygroundsAppTemplateKind</string>
    <key>Identifier</key>
    <string>com.example.template.myapp</string>
    <key>Name</key>
    <string>My App</string>
    <key>Summary</key>
    <string>A custom Swift package template</string>
    <key>Description</key>
    <string>Creates a new Swift package app with pre-configured dependencies and boilerplate code.</string>
    <key>Options</key>
    <array>
        <dict>
            <key>Identifier</key>
            <string>productName</string>
            <key>Required</key>
            <true/>
            <key>Name</key>
            <string>Product Name:</string>
            <key>NotPersisted</key>
            <true/>
            <key>Description</key>
            <string>The name of your app</string>
            <key>EmptyReplacement</key>
            <string>MyApp</string>
            <key>Type</key>
            <string>text</string>
            <key>SortOrder</key>
            <integer>-2</integer>
        </dict>
        <dict>
            <key>Identifier</key>
            <string>testFramework</string>
            <key>Required</key>
            <false/>
            <key>Name</key>
            <string>Test Framework:</string>
            <key>Description</key>
            <string>Choose which test framework to include</string>
            <key>Type</key>
            <string>popup</string>
            <key>Default</key>
            <string>None</string>
            <key>Values</key>
            <array>
                <string>None</string>
                <string>Swift Testing</string>
                <string>XCTest</string>
            </array>
            <key>SortOrder</key>
            <integer>-1</integer>
        </dict>
        <dict>
            <key>Identifier</key>
            <string>includeSQLite</string>
            <key>Required</key>
            <false/>
            <key>Name</key>
            <string>Include SQLite.swift:</string>
            <key>Description</key>
            <string>Add SQLite.swift for local database storage</string>
            <key>Type</key>
            <string>checkbox</string>
            <key>Default</key>
            <string>false</string>
            <key>SortOrder</key>
            <integer>0</integer>
        </dict>
    </array>
    <key>NameOfInitialFileForEditor</key>
    <string>README.md</string>
    <key>SortOrder</key>
    <integer>50</integer>
    <key>MainTemplateFile</key>
    <string>___FILEBASENAME___</string>
    <key>AllowedTypes</key>
    <array>
        <string>com.apple.swiftpm</string>
    </array>
    <key>DefaultCompletionName</key>
    <string>MyApp</string>
    <key>Platforms</key>
    <array>
        <string>com.apple.platform.macosx</string>
    </array>
    <key>Image</key>
    <dict>
        <key>SystemSymbolName</key>
        <string>terminal.fill</string>
    </dict>
</dict>
</plist>
```

### Complete Package.swift Example

```swift
// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "___VARIABLE_productName___",
    platforms: [
        .macOS(.v14)
    ],
    dependencies: [
        .package(url: "https://github.com/phranck/TUIkit.git", branch: "main")___IF_includeSQLite___,
        .package(url: "https://github.com/stephencelis/SQLite.swift.git", from: "0.15.0")___ENDIF___
    ],
    targets: [
        .executableTarget(
            name: "___VARIABLE_productName___",
            dependencies: [
                .product(name: "TUIkit", package: "TUIkit")___IF_includeSQLite___,
                .product(name: "SQLite", package: "SQLite.swift")___ENDIF___
            ],
            path: "Sources"
        ),___IF_testFramework:Swift Testing___
        .testTarget(
            name: "___VARIABLE_productName___Tests",
            dependencies: ["___VARIABLE_productName___"],
            path: "Tests"
        )___ENDIF______IF_testFramework:XCTest___
        .testTarget(
            name: "___VARIABLE_productName___Tests",
            dependencies: ["___VARIABLE_productName___"],
            path: "Tests"
        )___ENDIF___
    ]
)
```

## Summary

Key learnings from creating the TUIkit template:

1. **Never use `main.swift` with `@main`** - Always use `App.swift` or similar
2. **Configure Xcode defaults** - Set macOS as preferred platform in installation script
3. **Include shared scheme** - Helps Xcode select correct destination
4. **Prominent README warning** - Make it impossible to miss the destination requirement
5. **Conditionals on single lines** - No line breaks within `___IF___...___ENDIF___`
6. **ZIP-based distribution** - More reliable than individual file downloads
7. **Test all option combinations** - Ensure every permutation works
8. **Provide uninstall capability** - Makes testing and maintenance easier
9. **Use SF Symbols for icons** - More reliable than custom PNGs
10. **Set initial file to README** - Ensures users see important information first

Following these practices will result in a production-ready template that provides maximum convenience for users and minimal friction during project setup.

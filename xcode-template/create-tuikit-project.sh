#!/bin/bash

# TUIkit Project Creator
# Creates a new TUIkit Swift Package project with all dependencies

set -e

# Colors
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}"
echo "╔════════════════════════════════════════════════════╗"
echo "║                                                    ║"
echo "║              TUIkit Project Creator                ║"
echo "║                                                    ║"
echo "╚════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Get project name
echo -e "${YELLOW}Enter project name (e.g., MyTUIApp):${NC}"
read -r PROJECT_NAME

if [ -z "$PROJECT_NAME" ]; then
    echo -e "${RED}Error: Project name cannot be empty${NC}"
    exit 1
fi

# Get test framework
echo -e "${YELLOW}Select test framework:${NC}"
echo "  1) None"
echo "  2) Swift Testing"
echo "  3) XCTest"
read -r TEST_CHOICE

case $TEST_CHOICE in
    1) TEST_FRAMEWORK="None" ;;
    2) TEST_FRAMEWORK="Swift Testing" ;;
    3) TEST_FRAMEWORK="XCTest" ;;
    *) TEST_FRAMEWORK="None" ;;
esac

# Get SQLite option
echo -e "${YELLOW}Include SQLite.swift for database storage? (y/n):${NC}"
read -r SQLITE_CHOICE

INCLUDE_SQLITE=false
if [[ "$SQLITE_CHOICE" =~ ^[Yy]$ ]]; then
    INCLUDE_SQLITE=true
fi

# Create project directory
echo -e "${BLUE}Creating project directory...${NC}"
mkdir -p "$PROJECT_NAME"
cd "$PROJECT_NAME"

# Create Package.swift
echo -e "${BLUE}Creating Package.swift...${NC}"
cat > Package.swift << 'EOF'
// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "___PROJECT_NAME___",
    platforms: [.macOS(.v15)],
    dependencies: [
        .package(url: "https://github.com/phranck/TUIkit.git", branch: "main")___SQLITE_DEPENDENCY___
    ],
    targets: [
        .executableTarget(
            name: "___PROJECT_NAME___",
            dependencies: [
                .product(name: "TUIkit", package: "TUIkit")___SQLITE_TARGET_DEPENDENCY___
            ],
            path: "Sources"
        )___TEST_TARGET___
    ]
)
EOF

# Replace placeholders in Package.swift
sed -i '' "s/___PROJECT_NAME___/$PROJECT_NAME/g" Package.swift

if [ "$INCLUDE_SQLITE" = true ]; then
    sed -i '' 's/___SQLITE_DEPENDENCY___/,\'$'\n''        .package(url: "https:\/\/github.com\/stephencelis\/SQLite.swift.git", from: "0.15.0")/g' Package.swift
    sed -i '' 's/___SQLITE_TARGET_DEPENDENCY___/,\'$'\n''                .product(name: "SQLite", package: "SQLite.swift")/g' Package.swift
else
    sed -i '' 's/___SQLITE_DEPENDENCY___//g' Package.swift
    sed -i '' 's/___SQLITE_TARGET_DEPENDENCY___//g' Package.swift
fi

if [ "$TEST_FRAMEWORK" = "Swift Testing" ]; then
    TEST_TARGET=",\n        .testTarget(\n            name: \"${PROJECT_NAME}Tests\",\n            dependencies: [\"$PROJECT_NAME\"],\n            path: \"Tests\"\n        )"
    sed -i '' "s|___TEST_TARGET___|$TEST_TARGET|g" Package.swift
elif [ "$TEST_FRAMEWORK" = "XCTest" ]; then
    TEST_TARGET=",\n        .testTarget(\n            name: \"${PROJECT_NAME}Tests\",\n            dependencies: [\"$PROJECT_NAME\"],\n            path: \"Tests\"\n        )"
    sed -i '' "s|___TEST_TARGET___|$TEST_TARGET|g" Package.swift
else
    sed -i '' 's/___TEST_TARGET___//g' Package.swift
fi

# Create Sources directory and files
echo -e "${BLUE}Creating source files...${NC}"
mkdir -p Sources

cat > Sources/App.swift << EOF
import TUIkit

@main
struct ${PROJECT_NAME}App: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
EOF

cat > Sources/ContentView.swift << 'EOF'
import TUIkit

struct ContentView: View {
    var body: some View {
        VStack {
            Text("Hello, TUIkit!")
                .foregroundStyle(.green)
                .bold()

            Text("Welcome to your new terminal app")
                .foregroundStyle(.gray)
        }
        .padding()
    }
}
EOF

# Create Database.swift if SQLite is enabled
if [ "$INCLUDE_SQLITE" = true ]; then
    cat > Sources/Database.swift << 'EOF'
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
EOF
fi

# Create Tests if needed
if [ "$TEST_FRAMEWORK" != "None" ]; then
    echo -e "${BLUE}Creating test files...${NC}"
    mkdir -p Tests

    if [ "$TEST_FRAMEWORK" = "Swift Testing" ]; then
        cat > Tests/${PROJECT_NAME}Tests.swift << EOF
import Testing
@testable import $PROJECT_NAME

@Test func example() async throws {
    #expect(true)
}
EOF
    else
        cat > Tests/${PROJECT_NAME}Tests.swift << EOF
import XCTest
@testable import $PROJECT_NAME

final class ${PROJECT_NAME}Tests: XCTestCase {
    func testExample() throws {
        XCTAssertTrue(true)
    }
}
EOF
    fi
fi

# Create README.md
echo -e "${BLUE}Creating README.md...${NC}"
cat > README.md << EOF
# $PROJECT_NAME

A custom Swift package application built with TUIkit.

## ⚠️ IMPORTANT: First Time Setup

**Before building, verify the run destination:**

1. Look at the Xcode toolbar (top of the window)
2. Next to "$PROJECT_NAME", you'll see a destination dropdown
3. **Make sure it says "My Mac"** (not "iPhone Simulator")
4. If it doesn't, click it and select "My Mac"

This is a macOS-only application and will show build errors if an iOS destination is selected.

## Quick Start

### Run in Xcode

Press \`Cmd+R\` to build and run.

### Run from Terminal

\`\`\`bash
swift run
\`\`\`

## Project Structure

\`\`\`
$PROJECT_NAME/
├── Sources/
│   ├── App.swift          # Main application entry point
│   └── ContentView.swift  # Root view
EOF

if [ "$INCLUDE_SQLITE" = true ]; then
    cat >> README.md << 'EOF'
│   └── Database.swift     # SQLite database helper
EOF
fi

if [ "$TEST_FRAMEWORK" != "None" ]; then
    cat >> README.md << EOF
└── Tests/                 # $TEST_FRAMEWORK suite
EOF
fi

cat >> README.md << 'EOF'
```

EOF

if [ "$INCLUDE_SQLITE" = true ]; then
    cat >> README.md << 'EOF'

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

EOF
fi

cat >> README.md << 'EOF'

## Learn More

- [TUIkit Documentation](https://tuikit.layered.work/documentation/tuikit/)
- [GitHub](https://github.com/phranck/TUIkit)
EOF

# Create .gitignore
cat > .gitignore << 'EOF'
.DS_Store
/.build
/Packages
xcuserdata/
DerivedData/
.swiftpm/configuration/registries.json
.swiftpm/xcode/package.xcworkspace/contents.xcworkspacedata
.netrc
EOF

# Create .xcode.env
cat > .xcode.env << 'EOF'
# Xcode environment configuration
# This file is used by Xcode to set environment variables

# Prefer macOS platform for Swift packages
export XCODE_PREFERRED_PLATFORM=macosx
EOF

# Create setup.sh
cat > setup.sh << 'EOF'
#!/bin/bash
# Configure Xcode to prefer macOS platform
defaults write com.apple.dt.Xcode IDEPreferredPlatformForSwiftPackages -string "macosx"
echo "✅ Xcode configured for macOS platform"
EOF
chmod +x setup.sh

# Create open-in-xcode.command
cat > open-in-xcode.command << EOF
#!/bin/bash
cd "\$(dirname "\$0")"
open Package.swift
EOF
chmod +x open-in-xcode.command

# Create .swiftpm directory with scheme
mkdir -p .swiftpm/xcode/xcshareddata/xcschemes

cat > .swiftpm/xcode/xcshareddata/xcschemes/${PROJECT_NAME}.xcscheme << EOF
<?xml version="1.0" encoding="UTF-8"?>
<Scheme
   LastUpgradeVersion = "1600"
   version = "1.7">
   <BuildAction
      parallelizeBuildables = "YES"
      buildImplicitDependencies = "YES">
      <BuildActionEntries>
         <BuildActionEntry
            buildForTesting = "YES"
            buildForRunning = "YES"
            buildForProfiling = "YES"
            buildForArchiving = "YES"
            buildForAnalyzing = "YES">
            <BuildableReference
               BuildableIdentifier = "primary"
               BlueprintIdentifier = "$PROJECT_NAME"
               BuildableName = "$PROJECT_NAME"
               BlueprintName = "$PROJECT_NAME"
               ReferencedContainer = "container:">
            </BuildableReference>
         </BuildActionEntry>
      </BuildActionEntries>
   </BuildAction>
   <LaunchAction
      buildConfiguration = "Debug"
      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
      launchStyle = "0"
      useCustomWorkingDirectory = "NO"
      ignoresPersistentStateOnLaunch = "NO"
      debugDocumentVersioning = "YES"
      debugServiceExtension = "internal"
      allowLocationSimulation = "YES"
      viewDebuggingEnabled = "No">
      <BuildableProductRunnable
         runnableDebuggingMode = "0">
         <BuildableReference
            BuildableIdentifier = "primary"
            BlueprintIdentifier = "$PROJECT_NAME"
            BuildableName = "$PROJECT_NAME"
            BlueprintName = "$PROJECT_NAME"
            ReferencedContainer = "container:">
         </BuildableReference>
      </BuildableProductRunnable>
      <EnvironmentVariables>
         <EnvironmentVariable
            key = "TUIKIT_DEBUG"
            value = "1"
            isEnabled = "YES">
         </EnvironmentVariable>
      </EnvironmentVariables>
   </LaunchAction>
   <ProfileAction
      buildConfiguration = "Release"
      shouldUseLaunchSchemeArgsEnv = "YES"
      savedToolIdentifier = ""
      useCustomWorkingDirectory = "NO"
      debugDocumentVersioning = "YES">
      <BuildableProductRunnable
         runnableDebuggingMode = "0">
         <BuildableReference
            BuildableIdentifier = "primary"
            BlueprintIdentifier = "$PROJECT_NAME"
            BuildableName = "$PROJECT_NAME"
            BlueprintName = "$PROJECT_NAME"
            ReferencedContainer = "container:">
         </BuildableReference>
      </BuildableProductRunnable>
   </ProfileAction>
   <AnalyzeAction
      buildConfiguration = "Debug">
   </AnalyzeAction>
   <ArchiveAction
      buildConfiguration = "Release"
      revealArchiveInOrganizer = "YES">
   </ArchiveAction>
</Scheme>
EOF

cat > .swiftpm/xcode/xcshareddata/WorkspaceSettings.xcsettings << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>BuildSystemType</key>
    <string>Original</string>
    <key>DisableBuildSystemDeprecationWarning</key>
    <true/>
</dict>
</plist>
EOF

# Run setup
echo -e "${BLUE}Configuring Xcode preferences...${NC}"
./setup.sh

echo -e "${GREEN}"
echo "╔════════════════════════════════════════════════════╗"
echo "║                                                    ║"
echo "║            ✅ Project created successfully!         ║"
echo "║                                                    ║"
echo "╚════════════════════════════════════════════════════╝"
echo -e "${NC}"

echo -e "${BLUE}Project: ${NC}${GREEN}$PROJECT_NAME${NC}"
echo -e "${BLUE}Location: ${NC}$(pwd)"
echo -e "${BLUE}Test Framework: ${NC}$TEST_FRAMEWORK"
echo -e "${BLUE}SQLite.swift: ${NC}$([ "$INCLUDE_SQLITE" = true ] && echo "Yes" || echo "No")"

echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "  1. cd $PROJECT_NAME"
echo "  2. open Package.swift"
echo "  3. Wait for dependencies to resolve"
echo "  4. Press Cmd+R to build and run"
echo ""
echo -e "${YELLOW}⚠️  Remember: Select 'My Mac' as run destination!${NC}"
echo ""
echo -e "${BLUE}Documentation: ${NC}${YELLOW}https://tuikit.layered.work${NC}"

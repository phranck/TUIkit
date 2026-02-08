#!/bin/bash
#
# TUIkit Xcode Template Installer
# Installs the TUIkit App template into Xcode's user templates directory.
#
# Usage:
#   curl -fsSL https://tuikit.layered.work/install-template.sh | bash
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

TEMPLATE_NAME="TUIkit App.xctemplate"
GITHUB_REPO="phranck/TUIkit"
GITHUB_BRANCH="main"
TEMPLATE_ZIP_URL="https://github.com/${GITHUB_REPO}/raw/${GITHUB_BRANCH}/xcode-template/TUIkit-App-Template.zip"
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
    echo -e "${BLUE}"
    echo "╔════════════════════════════════════════════════════╗"
    echo "║                                                    ║"
    echo "║                     TUIkit                         ║"
    echo "║          Xcode Template Uninstaller                ║"
    echo "║                                                    ║"
    echo "╚════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    
    if [ -d "$TEMPLATE_DIR/$TEMPLATE_NAME" ]; then
        echo -e "${YELLOW}Removing TUIkit Xcode template...${NC}"
        rm -rf "$TEMPLATE_DIR/$TEMPLATE_NAME"
        echo ""
        echo -e "${GREEN}✅ Template uninstalled successfully!${NC}"
        echo ""
    else
        echo -e "${YELLOW}Template is not installed.${NC}"
        echo ""
    fi
    exit 0
fi

echo -e "${BLUE}"
echo "╔════════════════════════════════════════════════════╗"
echo "║                                                    ║"
echo "║                     TUIkit                         ║"
echo "║            Xcode Template Installer                ║"
echo "║                                                    ║"
echo "╚════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Check if running on macOS
if [[ "$(uname)" != "Darwin" ]]; then
    echo -e "${RED}Error: This installer only works on macOS.${NC}"
    exit 1
fi

# Check if Xcode is installed
if ! command -v xcodebuild &> /dev/null; then
    echo -e "${RED}Error: Xcode is not installed. Please install Xcode from the App Store.${NC}"
    exit 1
fi

echo -e "${YELLOW}Installing TUIkit Xcode template...${NC}"
echo ""

# Create template directory
echo -e "  ${BLUE}Creating template directory...${NC}"
mkdir -p "$TEMPLATE_DIR"

# Download template ZIP
echo -e "  ${BLUE}Downloading template...${NC}"
if ! curl -fsSL "$TEMPLATE_ZIP_URL" -o "$TEMP_DIR/template.zip"; then
    echo -e "${RED}Error: Failed to download template from GitHub.${NC}"
    echo -e "${YELLOW}Make sure the template ZIP exists at:${NC}"
    echo -e "  $TEMPLATE_ZIP_URL"
    exit 1
fi

# Extract template
echo -e "  ${BLUE}Extracting template...${NC}"
cd "$TEMP_DIR"
if ! unzip -q template.zip; then
    echo -e "${RED}Error: Failed to extract template ZIP.${NC}"
    exit 1
fi

# Copy to Xcode templates directory
echo -e "  ${BLUE}Installing template...${NC}"
if [ -d "$TEMP_DIR/$TEMPLATE_NAME" ]; then
    # Remove old template if exists
    if [ -d "$TEMPLATE_DIR/$TEMPLATE_NAME" ]; then
        rm -rf "$TEMPLATE_DIR/$TEMPLATE_NAME"
    fi
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
echo -e "The TUIkit App template is now available in Xcode:"
echo -e "  ${BLUE}File > New > Project > macOS > Application > TUIkit App${NC}"
echo ""
echo -e "${YELLOW}⚠️  IMPORTANT:${NC}"
echo -e "  When creating a new TUIkit project, make sure to select"
echo -e "  ${GREEN}'My Mac'${NC} as the run destination in Xcode (not iOS Simulator)."
echo -e "  The installer has configured Xcode to prefer macOS by default."
echo ""
echo -e "To uninstall, run:"
echo -e "  ${YELLOW}curl -fsSL https://tuikit.layered.work/install-template.sh | bash -s -- --uninstall${NC}"
echo -e "  or: ${YELLOW}curl -fsSL https://raw.githubusercontent.com/phranck/TUIkit/main/xcode-template/install.sh | bash -s -- --uninstall${NC}"
echo ""
echo -e "${BLUE}Happy coding with TUIkit!${NC}"
echo -e "Documentation: ${YELLOW}https://tuikit.layered.work${NC}"
echo ""

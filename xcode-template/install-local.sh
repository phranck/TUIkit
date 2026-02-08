#!/bin/bash
#
# TUIkit Xcode Template Installer (Local Version)
# Installs the TUIkit App template from local files into Xcode's user templates directory.
#
# Usage:
#   ./install-local.sh              # Install template
#   ./install-local.sh --uninstall  # Uninstall template
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_NAME="TUIkit App.xctemplate"
TEMPLATE_DIR="$HOME/Library/Developer/Xcode/Templates/Project Templates/macOS/Application"

# Check for uninstall flag
if [[ "$1" == "--uninstall" ]]; then
    echo -e "${BLUE}"
    echo "╔════════════════════════════════════════════════════╗"
    echo "║                                                    ║"
    echo "║                     TUIkit                         ║"
    echo "║         Xcode Template Uninstaller (Local)         ║"
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
echo "║       Xcode Template Installer (Local)             ║"
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

# Check if template exists in local directory
if [ ! -d "$SCRIPT_DIR/$TEMPLATE_NAME" ]; then
    echo -e "${RED}Error: Template not found at $SCRIPT_DIR/$TEMPLATE_NAME${NC}"
    exit 1
fi

echo -e "${YELLOW}Installing TUIkit Xcode template from local files...${NC}"
echo ""

# Create template directory
echo -e "  ${BLUE}Creating template directory...${NC}"
mkdir -p "$TEMPLATE_DIR"

# Remove old template if exists
if [ -d "$TEMPLATE_DIR/$TEMPLATE_NAME" ]; then
    echo -e "  ${BLUE}Removing old template...${NC}"
    rm -rf "$TEMPLATE_DIR/$TEMPLATE_NAME"
fi

# Copy template
echo -e "  ${BLUE}Copying template files...${NC}"
cp -R "$SCRIPT_DIR/$TEMPLATE_NAME" "$TEMPLATE_DIR/"

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
echo -e "  ${YELLOW}$0 --uninstall${NC}"
echo ""
echo -e "${BLUE}Happy coding with TUIkit!${NC}"
echo -e "Documentation: ${YELLOW}https://tuikit.layered.work${NC}"
echo ""

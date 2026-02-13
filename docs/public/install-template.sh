#!/bin/bash
#
# TUIkit Xcode Template Installer
# Installs the TUIkit App template into Xcode's user templates directory.
#
# Usage:
#   curl -fsSL https://tuikit.dev/install-template.sh | bash
#
# Or manually:
#   ./install.sh
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

TEMPLATE_NAME="TUIkit App.xctemplate"
GITHUB_RAW_BASE="https://raw.githubusercontent.com/phranck/TUIkit/main/xcode-template"
TEMPLATE_DIR="$HOME/Library/Developer/Xcode/Templates/Project Templates/macOS/Application"

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
mkdir -p "$TEMPLATE_DIR/$TEMPLATE_NAME/___FILEBASENAME___/Sources/___VARIABLE_productName___"

# Download TemplateInfo.plist
echo -e "  ${BLUE}Downloading TemplateInfo.plist...${NC}"
curl -fsSL "$GITHUB_RAW_BASE/TUIkit%20App.xctemplate/TemplateInfo.plist" \
    -o "$TEMPLATE_DIR/$TEMPLATE_NAME/TemplateInfo.plist"

# Download Package.swift
echo -e "  ${BLUE}Downloading Package.swift...${NC}"
curl -fsSL "$GITHUB_RAW_BASE/TUIkit%20App.xctemplate/___FILEBASENAME___/Package.swift" \
    -o "$TEMPLATE_DIR/$TEMPLATE_NAME/___FILEBASENAME___/Package.swift"

# Download main.swift
echo -e "  ${BLUE}Downloading main.swift...${NC}"
curl -fsSL "$GITHUB_RAW_BASE/TUIkit%20App.xctemplate/___FILEBASENAME___/Sources/___VARIABLE_productName___/main.swift" \
    -o "$TEMPLATE_DIR/$TEMPLATE_NAME/___FILEBASENAME___/Sources/___VARIABLE_productName___/main.swift"

# Download icon if it exists
if curl -fsSL --head "$GITHUB_RAW_BASE/TUIkit%20App.xctemplate/TemplateIcon.png" &> /dev/null; then
    echo -e "  ${BLUE}Downloading template icon...${NC}"
    curl -fsSL "$GITHUB_RAW_BASE/TUIkit%20App.xctemplate/TemplateIcon.png" \
        -o "$TEMPLATE_DIR/$TEMPLATE_NAME/TemplateIcon.png"
    curl -fsSL "$GITHUB_RAW_BASE/TUIkit%20App.xctemplate/TemplateIcon@2x.png" \
        -o "$TEMPLATE_DIR/$TEMPLATE_NAME/TemplateIcon@2x.png" 2>/dev/null || true
fi

echo ""
echo -e "${GREEN}Installation complete!${NC}"
echo ""
echo -e "The TUIkit App template is now available in Xcode:"
echo -e "  ${BLUE}File > New > Project > macOS > TUIkit App${NC}"
echo ""
echo -e "To uninstall, run:"
echo -e "  ${YELLOW}rm -rf \"$TEMPLATE_DIR/$TEMPLATE_NAME\"${NC}"
echo ""
echo -e "${BLUE}Happy coding with TUIkit!${NC}"
echo -e "Documentation: ${YELLOW}https://tuikit.dev${NC}"
echo ""

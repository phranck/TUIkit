#!/bin/bash

# TUIkit CLI Installer
# Installs the tuikit command globally with platform detection

set -e

VERSION="1.0.0"
SCRIPT_NAME="tuikit"

# Colors (friendly pastels)
CYAN='\033[0;96m'
GREEN='\033[0;92m'
YELLOW='\033[0;93m'
RED='\033[0;91m'
DIM='\033[2m'
BOLD='\033[1m'
NC='\033[0m'

# Detect platform
detect_install_path() {
    # Check for XDG_BIN_HOME first (XDG Base Directory specification)
    if [ -n "$XDG_BIN_HOME" ]; then
        echo "$XDG_BIN_HOME"
        return
    fi

    # Check for XDG_DATA_HOME and use bin subdirectory
    if [ -n "$XDG_DATA_HOME" ]; then
        echo "$XDG_DATA_HOME/../bin"
        return
    fi

    # Platform-specific defaults
    case "$(uname -s)" in
        Darwin*)
            # macOS - prefer /usr/local/bin
            if [ -w "/usr/local/bin" ]; then
                echo "/usr/local/bin"
            else
                echo "$HOME/.local/bin"
            fi
            ;;
        Linux*)
            # Linux - follow XDG spec
            echo "${HOME}/.local/bin"
            ;;
        *)
            # Other Unix-like systems
            echo "${HOME}/.local/bin"
            ;;
    esac
}

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Check if tuikit script exists
if [ ! -f "$SCRIPT_DIR/$SCRIPT_NAME" ]; then
    echo -e "${RED}Error:${NC} $SCRIPT_NAME script not found in $SCRIPT_DIR"
    exit 1
fi

# Detect install path
INSTALL_PATH=$(detect_install_path)

# Create directory if it doesn't exist
mkdir -p "$INSTALL_PATH"

# Check if directory is in PATH
if [[ ":$PATH:" != *":$INSTALL_PATH:"* ]]; then
    NEEDS_PATH_UPDATE=true
else
    NEEDS_PATH_UPDATE=false
fi

# Detect shell config file
detect_shell_config() {
    if [ -n "$BASH_VERSION" ]; then
        if [ -f "$HOME/.bashrc" ]; then
            echo "$HOME/.bashrc"
        else
            echo "$HOME/.bash_profile"
        fi
    elif [ -n "$ZSH_VERSION" ]; then
        echo "$HOME/.zshrc"
    elif [ -n "$FISH_VERSION" ]; then
        echo "$HOME/.config/fish/config.fish"
    else
        # Default to .profile
        echo "$HOME/.profile"
    fi
}

# Install function
install() {
    echo -e "${CYAN}"
    echo "  ╭──────────────────────────────────────╮"
    echo "  │                                      │"
    echo "  │         TUIkit CLI Installer         │"
    echo "  │                v${VERSION}                │"
    echo "  │                                      │"
    echo "  ╰──────────────────────────────────────╯"
    echo -e "${NC}"
    echo -e "  ${DIM}Installing to:${NC} $INSTALL_PATH"

    # Copy script
    if [ -w "$INSTALL_PATH" ]; then
        cp "$SCRIPT_DIR/$SCRIPT_NAME" "$INSTALL_PATH/"
        chmod +x "$INSTALL_PATH/$SCRIPT_NAME"
    else
        echo -e "  ${DIM}Requesting sudo access...${NC}"
        sudo cp "$SCRIPT_DIR/$SCRIPT_NAME" "$INSTALL_PATH/"
        sudo chmod +x "$INSTALL_PATH/$SCRIPT_NAME"
    fi

    # Create uninstall script
    cat > "$INSTALL_PATH/${SCRIPT_NAME}-uninstall" << 'UNINSTALL_SCRIPT'
#!/bin/bash
INSTALL_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
echo "Uninstalling tuikit from $INSTALL_PATH..."
rm -f "$INSTALL_PATH/tuikit"
rm -f "$INSTALL_PATH/tuikit-uninstall"
echo "✅ TUIkit CLI uninstalled successfully"
UNINSTALL_SCRIPT

    chmod +x "$INSTALL_PATH/${SCRIPT_NAME}-uninstall"

    echo ""
    echo -e "  ${GREEN}Done!${NC} tuikit is now installed."
    echo ""

    # Handle PATH configuration
    if [ "$NEEDS_PATH_UPDATE" = true ]; then
        SHELL_CONFIG=$(detect_shell_config)

        echo -e "  ${YELLOW}Note:${NC} $INSTALL_PATH is not in your PATH yet."
        echo ""
        echo -e "  Add this to ${DIM}$SHELL_CONFIG${NC}:"
        echo ""
        echo -e "    ${CYAN}export PATH=\"\$PATH:$INSTALL_PATH\"${NC}"
        echo ""
        echo -e "  ${DIM}Add automatically? (y/n)${NC}"
        read -r response

        if [[ "$response" =~ ^[Yy]$ ]]; then
            # Create backup
            if [ -f "$SHELL_CONFIG" ]; then
                cp "$SHELL_CONFIG" "${SHELL_CONFIG}.backup"
            fi

            # Add to PATH
            echo "" >> "$SHELL_CONFIG"
            echo "# Added by TUIkit installer" >> "$SHELL_CONFIG"
            echo "export PATH=\"\$PATH:$INSTALL_PATH\"" >> "$SHELL_CONFIG"

            echo ""
            echo -e "  ${GREEN}Done!${NC} PATH updated."
            echo -e "  ${DIM}Restart your terminal or run:${NC} source $SHELL_CONFIG"
        else
            echo -e "  ${DIM}Skipped. Add PATH manually to use tuikit.${NC}"
        fi
    fi

    echo ""
    echo -e "  ${BOLD}Quick Start${NC}"
    echo -e "    tuikit init MyApp              ${DIM}Basic app${NC}"
    echo -e "    tuikit init sqlite MyApp       ${DIM}With database${NC}"
    echo -e "    tuikit init testing MyApp      ${DIM}With tests${NC}"
    echo ""
    echo -e "  ${DIM}Uninstall: tuikit-uninstall${NC}"
    echo ""
}

# Uninstall function
uninstall() {
    echo ""
    echo -e "  ${DIM}Uninstalling TUIkit CLI...${NC}"

    INSTALL_PATH=$(detect_install_path)

    if [ -f "$INSTALL_PATH/$SCRIPT_NAME" ]; then
        if [ -w "$INSTALL_PATH" ]; then
            rm -f "$INSTALL_PATH/$SCRIPT_NAME"
            rm -f "$INSTALL_PATH/${SCRIPT_NAME}-uninstall"
        else
            sudo rm -f "$INSTALL_PATH/$SCRIPT_NAME"
            sudo rm -f "$INSTALL_PATH/${SCRIPT_NAME}-uninstall"
        fi
        echo -e "  ${GREEN}Done!${NC} TUIkit CLI removed."
        echo ""
    else
        echo -e "  ${DIM}TUIkit CLI not found at $INSTALL_PATH${NC}"
        echo ""
    fi
}

# Main script
case "${1:-install}" in
    install)
        install
        ;;
    uninstall)
        uninstall
        ;;
    *)
        echo "Usage: $0 [install|uninstall]"
        exit 1
        ;;
esac

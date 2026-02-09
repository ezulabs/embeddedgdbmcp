#!/bin/bash
# Embedded GDB MCP Installer
# Usage: curl -sSf https://raw.githubusercontent.com/YOUR_ORG/embedded-gdb-mcp/main/install.sh | sh

set -e

# Configuration
REPO="ezulabs/embeddedgdbmcp"
BINARY_NAME="embedded-gdb-mcp"
INSTALL_DIR="${INSTALL_DIR:-/usr/local/bin}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

info() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# Detect OS and architecture
detect_platform() {
    OS=$(uname -s | tr '[:upper:]' '[:lower:]')
    ARCH=$(uname -m)

    case "$OS" in
        darwin) OS="macos" ;;
        linux) OS="linux" ;;
        mingw*|msys*|cygwin*) OS="windows" ;;
        *) error "Unsupported operating system: $OS" ;;
    esac

    case "$ARCH" in
        x86_64|amd64) ARCH="x64" ;;
        arm64|aarch64) ARCH="arm64" ;;
        *) error "Unsupported architecture: $ARCH" ;;
    esac

    PLATFORM="${OS}-${ARCH}"
    info "Detected platform: $PLATFORM"
}

# Get latest release version
get_latest_version() {
    VERSION=$(curl -sL "https://api.github.com/repos/${REPO}/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
    if [ -z "$VERSION" ]; then
        error "Failed to fetch latest version. Check your internet connection."
    fi
    info "Latest version: $VERSION"
}

# Download and install
install() {
    detect_platform
    get_latest_version

    # Determine archive extension
    if [ "$OS" = "windows" ]; then
        ARCHIVE="${BINARY_NAME}-${PLATFORM}.zip"
    else
        ARCHIVE="${BINARY_NAME}-${PLATFORM}.tar.gz"
    fi

    DOWNLOAD_URL="https://github.com/${REPO}/releases/download/${VERSION}/${ARCHIVE}"
    
    info "Downloading from: $DOWNLOAD_URL"

    # Create temp directory
    TMP_DIR=$(mktemp -d)
    trap "rm -rf $TMP_DIR" EXIT

    # Download
    if command -v curl &> /dev/null; then
        curl -sL "$DOWNLOAD_URL" -o "$TMP_DIR/$ARCHIVE"
    elif command -v wget &> /dev/null; then
        wget -q "$DOWNLOAD_URL" -O "$TMP_DIR/$ARCHIVE"
    else
        error "Neither curl nor wget found. Please install one of them."
    fi

    # Extract
    cd "$TMP_DIR"
    if [ "$OS" = "windows" ]; then
        unzip -q "$ARCHIVE"
    else
        tar -xzf "$ARCHIVE"
    fi

    # Install
    if [ -w "$INSTALL_DIR" ]; then
        mv "$BINARY_NAME" "$INSTALL_DIR/"
    else
        info "Requesting sudo to install to $INSTALL_DIR"
        sudo mv "$BINARY_NAME" "$INSTALL_DIR/"
    fi

    chmod +x "$INSTALL_DIR/$BINARY_NAME"

    info "Installed $BINARY_NAME to $INSTALL_DIR"
    
    # Verify installation
    if command -v "$BINARY_NAME" &> /dev/null; then
        echo ""
        info "Installation successful!"
        echo ""
        echo "Next steps:"
        echo "  1. Get a license key from your administrator"
        echo "  2. Configure your MCP client (Cursor/Claude Desktop):"
        echo ""
        echo "     ~/.cursor/mcp.json (Cursor) or"
        echo "     ~/.config/claude/claude_desktop_config.json (Claude Desktop):"
        echo ""
        echo '     {'
        echo '       "mcpServers": {'
        echo '         "embedded-gdb": {'
        echo "           \"command\": \"$INSTALL_DIR/$BINARY_NAME\","
        echo '           "args": [],'
        echo '           "env": {'
        echo '             "EMBEDDED_GDB_LICENSE": "YOUR-LICENSE-KEY"'
        echo '           }'
        echo '         }'
        echo '       }'
        echo '     }'
        echo ""
    else
        warn "Binary installed but not found in PATH."
        warn "Add $INSTALL_DIR to your PATH or move the binary."
    fi
}

# Run installer
install

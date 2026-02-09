# Embedded GDB MCP Windows Installer
# Usage: irm https://raw.githubusercontent.com/YOUR_ORG/embedded-gdb-mcp/main/install.ps1 | iex

# Configuration
$REPO = "ezulabs/embeddedgdbmcp"
$BINARY_NAME = "embedded-gdb-mcp"
$INSTALL_DIR = "$env:ProgramFiles\embedded-gdb-mcp"

# Error handling
$ErrorActionPreference = "Stop"

function Write-Info {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Green
}

function Write-Warn {
    param([string]$Message)
    Write-Host "[WARN] $Message" -ForegroundColor Yellow
}

function Write-Error {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
    exit 1
}

# Detect architecture
function Get-Architecture {
    $arch = (Get-WmiObject Win32_Processor).Architecture
    switch ($arch) {
        0 { return "x64" }      # x86
        5 { return "arm64" }     # ARM
        9 { return "x64" }       # x64
        default { Write-Error "Unsupported architecture: $arch" }
    }
}

# Get latest release version
function Get-LatestVersion {
    try {
        $response = Invoke-RestMethod -Uri "https://api.github.com/repos/$REPO/releases/latest"
        return $response.tag_name
    }
    catch {
        Write-Error "Failed to fetch latest version. Check your internet connection."
    }
}

# Main installation
function Install-Binary {
    Write-Info "Embedded GDB MCP Windows Installer"
    Write-Info "===================================="
    
    # Detect architecture
    $ARCH = Get-Architecture
    Write-Info "Detected architecture: $ARCH"
    
    # Get version
    $VERSION = Get-LatestVersion
    Write-Info "Latest version: $VERSION"
    
    # Determine download URL
    $PLATFORM = "windows-$ARCH"
    $ARCHIVE = "$BINARY_NAME-$PLATFORM.zip"
    $DOWNLOAD_URL = "https://github.com/$REPO/releases/download/$VERSION/$ARCHIVE"
    
    Write-Info "Downloading from: $DOWNLOAD_URL"
    
    # Create temp directory
    $TMP_DIR = New-TemporaryFile | ForEach-Object { Remove-Item $_; New-Item -ItemType Directory -Path $_ }
    
    try {
        # Download
        $ZIP_PATH = Join-Path $TMP_DIR $ARCHIVE
        Invoke-WebRequest -Uri $DOWNLOAD_URL -OutFile $ZIP_PATH
        
        Write-Info "Extracting archive..."
        Expand-Archive -Path $ZIP_PATH -DestinationPath $TMP_DIR -Force
        
        # Find binary
        $BINARY_PATH = Get-ChildItem -Path $TMP_DIR -Filter "$BINARY_NAME.exe" -Recurse | Select-Object -First 1
        
        if (-not $BINARY_PATH) {
            Write-Error "Binary not found in archive"
        }
        
        # Create install directory
        if (-not (Test-Path $INSTALL_DIR)) {
            New-Item -ItemType Directory -Path $INSTALL_DIR -Force | Out-Null
        }
        
        # Install (requires admin)
        $INSTALL_PATH = Join-Path $INSTALL_DIR "$BINARY_NAME.exe"
        
        if (Test-Path $INSTALL_PATH) {
            Write-Warn "Existing installation found. Removing..."
            Remove-Item $INSTALL_PATH -Force
        }
        
        Copy-Item $BINARY_PATH.FullName $INSTALL_PATH -Force
        Write-Info "Installed to: $INSTALL_PATH"
        
        # Add to PATH (user-level, doesn't require admin)
        $USER_PATH = [Environment]::GetEnvironmentVariable("Path", "User")
        if ($USER_PATH -notlike "*$INSTALL_DIR*") {
            Write-Info "Adding to user PATH..."
            $NEW_PATH = $USER_PATH + ";$INSTALL_DIR"
            [Environment]::SetEnvironmentVariable("Path", $NEW_PATH, "User")
            Write-Info "Added to PATH. Restart your terminal for PATH changes to take effect."
        }
        
        # Verify installation
        Write-Info ""
        Write-Info "Installation successful!"
        Write-Info ""
        Write-Info "Next steps:"
        Write-Info "  1. Restart your terminal (for PATH changes)"
        Write-Info "  2. Get a license key from your administrator"
        Write-Info "  3. Configure your MCP client:"
        Write-Info ""
        Write-Info "     Edit: %APPDATA%\Cursor\mcp.json (Cursor) or"
        Write-Info "           %APPDATA%\Claude\claude_desktop_config.json (Claude Desktop)"
        Write-Info ""
        Write-Info "     Add:"
        Write-Info '     {'
        Write-Info '       "mcpServers": {'
        Write-Info '         "embedded-gdb": {'
        Write-Info "           `"command`": `"$INSTALL_PATH`","
        Write-Info '           "args": [],'
        Write-Info '           "env": {'
        Write-Info '             "EMBEDDED_GDB_LICENSE": "YOUR-LICENSE-KEY"'
        Write-Info '           }'
        Write-Info '         }'
        Write-Info '       }'
        Write-Info '     }'
        Write-Info ""
        
        # Test if in PATH
        $env:Path += ";$INSTALL_DIR"
        if (Get-Command "$BINARY_NAME.exe" -ErrorAction SilentlyContinue) {
            Write-Info "Binary is accessible. Testing version..."
            & "$BINARY_NAME.exe" --version 2>&1 | Out-Null
            if ($LASTEXITCODE -eq 0) {
                Write-Info "✓ Installation verified!"
            }
        }
    }
    finally {
        # Cleanup
        Remove-Item $TMP_DIR -Recurse -Force -ErrorAction SilentlyContinue
    }
}

# Check if running as admin (optional, for system-wide install)
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Warn "Not running as administrator. Installing to user-accessible location."
    Write-Warn "For system-wide install, run PowerShell as Administrator."
}

# Run installer
Install-Binary

# Homelab Media Stack Setup Script for Windows
# PowerShell script to create directory structure and set up the environment

param(
    [string]$BasePath = "C:\homelab-media-stack-data",
    [int]$PUID = 1001,
    [int]$PGID = 1000
)

# Colors for output
$ErrorActionPreference = "Continue"

function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    
    switch ($Color) {
        "Red" { Write-Host $Message -ForegroundColor Red }
        "Green" { Write-Host $Message -ForegroundColor Green }
        "Yellow" { Write-Host $Message -ForegroundColor Yellow }
        "Blue" { Write-Host $Message -ForegroundColor Blue }
        "Cyan" { Write-Host $Message -ForegroundColor Cyan }
        default { Write-Host $Message }
    }
}

function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Test-DockerInstalled {
    try {
        $dockerVersion = docker --version 2>$null
        if ($dockerVersion) {
            return $true
        }
    }
    catch {
        return $false
    }
    return $false
}

# Header
Write-ColorOutput "=================================================================" "Blue"
Write-ColorOutput "    Homelab Media Stack Setup Script for Windows" "Blue"
Write-ColorOutput "=================================================================" "Blue"
Write-Host ""

# Check if running as Administrator
if (-not (Test-Administrator)) {
    Write-ColorOutput "⚠️  WARNING: Not running as Administrator" "Yellow"
    Write-ColorOutput "Some operations may fail. Consider running PowerShell as Administrator." "Yellow"
    Write-Host ""
}

# Check Docker installation
Write-ColorOutput "🐳 Checking Docker installation..." "Cyan"
if (Test-DockerInstalled) {
    $dockerVersion = docker --version
    Write-ColorOutput "✅ Docker found: $dockerVersion" "Green"
} else {
    Write-ColorOutput "❌ Docker not found!" "Red"
    Write-ColorOutput "Please install Docker Desktop from: https://www.docker.com/products/docker-desktop" "Yellow"
    Write-ColorOutput "Press any key to continue anyway, or Ctrl+C to exit..." "Yellow"
    $null = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

Write-Host ""

# Get configuration
Write-ColorOutput "📋 Configuration:" "Cyan"
Write-ColorOutput "  Base Path: $BasePath" "White"
Write-ColorOutput "  PUID: $PUID" "White"
Write-ColorOutput "  PGID: $PGID" "White"
Write-Host ""

$response = Read-Host "Continue with these settings? (y/N)"
if ($response -ne "y" -and $response -ne "Y") {
    Write-ColorOutput "Setup cancelled by user." "Yellow"
    exit 1
}

Write-Host ""

# Create directory structure
Write-ColorOutput "📁 Creating directory structure..." "Green"

$directories = @(
    "$BasePath\docker\servarr\gluetun",
    "$BasePath\docker\servarr\qbittorrent", 
    "$BasePath\docker\servarr\sabnzbd",
    "$BasePath\docker\servarr\prowlarr",
    "$BasePath\docker\servarr\sonarr",
    "$BasePath\docker\servarr\radarr",
    "$BasePath\docker\servarr\lidarr",
    "$BasePath\docker\servarr\bazarr",
    "$BasePath\docker\servarr\homarr\configs",
    "$BasePath\docker\servarr\homarr\icons",
    "$BasePath\docker\servarr\homarr\data",
    "$BasePath\docker\streamarr\plex",
    "$BasePath\docker\streamarr\overseerr",
    "$BasePath\docker\streamarr\tautulli",
    "$BasePath\docker\streamarr\ersatztv",
    "$BasePath\data\downloads\complete",
    "$BasePath\data\downloads\incomplete",
    "$BasePath\data\media\movies",
    "$BasePath\data\media\tv",
    "$BasePath\data\media\music",
    "$BasePath\data\plex_transcode"
)

$createdCount = 0
foreach ($dir in $directories) {
    if (!(Test-Path $dir)) {
        try {
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
            Write-ColorOutput "  ✅ Created: $dir" "Gray"
            $createdCount++
        }
        catch {
            Write-ColorOutput "  ❌ Failed to create: $dir" "Red"
            Write-ColorOutput "     Error: $($_.Exception.Message)" "Red"
        }
    } else {
        Write-ColorOutput "  ℹ️  Already exists: $dir" "Yellow"
    }
}

Write-ColorOutput "📁 Created $createdCount new directories" "Green"
Write-Host ""

# Create Docker networks
Write-ColorOutput "🌐 Creating Docker networks..." "Green"

$networks = @(
    @{Name="servarr-network"; Subnet="172.39.0.0/24"},
    @{Name="streamarr-network"; Subnet="172.40.0.0/24"}
)

foreach ($network in $networks) {
    try {
        $existingNetwork = docker network ls --filter "name=$($network.Name)" --format "{{.Name}}" 2>$null
        if ($existingNetwork -eq $network.Name) {
            Write-ColorOutput "  ℹ️  Network already exists: $($network.Name)" "Yellow"
        } else {
            docker network create --driver bridge --subnet=$($network.Subnet) $($network.Name) 2>$null | Out-Null
            if ($LASTEXITCODE -eq 0) {
                Write-ColorOutput "  ✅ Created network: $($network.Name)" "Gray"
            } else {
                Write-ColorOutput "  ❌ Failed to create network: $($network.Name)" "Red"
            }
        }
    }
    catch {
        Write-ColorOutput "  ❌ Error creating network $($network.Name): $($_.Exception.Message)" "Red"
    }
}

Write-Host ""

# Update environment files with correct paths
Write-ColorOutput "📝 Updating environment file examples..." "Green"

if (Test-Path ".env-servarr.example") {
    try {
        $content = Get-Content ".env-servarr.example" -Raw
        $content = $content -replace "SERVARR_CONFIG_PATH=/volume1/docker/servarr", "SERVARR_CONFIG_PATH=$BasePath/docker/servarr"
        $content = $content -replace "DATA_PATH=/volume1/data", "DATA_PATH=$BasePath/data"
        $content = $content -replace "MEDIA_DATA_PATH=/volume1/data/media", "MEDIA_DATA_PATH=$BasePath/data/media"
        $content = $content -replace "PUID=1001", "PUID=$PUID"
        $content = $content -replace "PGID=1000", "PGID=$PGID"
        $content | Set-Content ".env-servarr.example" -NoNewline
        Write-ColorOutput "  ✅ Updated .env-servarr.example with Windows paths" "Gray"
    }
    catch {
        Write-ColorOutput "  ⚠️  Could not update .env-servarr.example: $($_.Exception.Message)" "Yellow"
    }
}

if (Test-Path ".env-streamarr.example") {
    try {
        $content = Get-Content ".env-streamarr.example" -Raw
        $content = $content -replace "STREAMARR_CONFIG_PATH=/volume1/docker/streamarr", "STREAMARR_CONFIG_PATH=$BasePath/docker/streamarr"
        $content = $content -replace "DATA_PATH=/volume1/data", "DATA_PATH=$BasePath/data"
        $content = $content -replace "PUID=1001", "PUID=$PUID"
        $content = $content -replace "PGID=1000", "PGID=$PGID"
        $content | Set-Content ".env-streamarr.example" -NoNewline
        Write-ColorOutput "  ✅ Updated .env-streamarr.example with Windows paths" "Gray"
    }
    catch {
        Write-ColorOutput "  ⚠️  Could not update .env-streamarr.example: $($_.Exception.Message)" "Yellow"
    }
}

Write-Host ""

# Verify setup
Write-ColorOutput "🔍 Verifying setup..." "Green"

$verificationPassed = $true

# Check critical directories
$criticalDirs = @(
    "$BasePath\docker\servarr",
    "$BasePath\docker\streamarr", 
    "$BasePath\data\downloads",
    "$BasePath\data\media"
)

foreach ($dir in $criticalDirs) {
    if (Test-Path $dir) {
        Write-ColorOutput "  ✅ $dir exists" "Gray"
    } else {
        Write-ColorOutput "  ❌ $dir missing" "Red"
        $verificationPassed = $false
    }
}

# Check Docker networks
foreach ($network in $networks) {
    $networkExists = docker network ls --filter "name=$($network.Name)" --format "{{.Name}}" 2>$null
    if ($networkExists -eq $network.Name) {
        Write-ColorOutput "  ✅ Docker network: $($network.Name)" "Gray"
    } else {
        Write-ColorOutput "  ❌ Docker network missing: $($network.Name)" "Red"
        $verificationPassed = $false
    }
}

Write-Host ""

if ($verificationPassed) {
    Write-ColorOutput "🎉 Setup completed successfully!" "Green"
} else {
    Write-ColorOutput "⚠️  Setup completed with some issues. Check the errors above." "Yellow"
}

Write-Host ""
Write-ColorOutput "📋 Next Steps:" "Blue"
Write-ColorOutput "1. Copy environment files:" "White"
Write-ColorOutput "   Copy-Item .env-servarr.example .env-servarr" "Gray"
Write-ColorOutput "   Copy-Item .env-streamarr.example .env-streamarr" "Gray"
Write-Host ""
Write-ColorOutput "2. Edit environment files with your settings:" "White"
Write-ColorOutput "   notepad .env-servarr" "Gray"
Write-ColorOutput "   notepad .env-streamarr" "Gray"
Write-Host ""
Write-ColorOutput "3. Deploy the stacks:" "White"
Write-ColorOutput "   docker-compose --env-file .env-servarr -f docker-compose-servarr.yml up -d" "Gray"
Write-ColorOutput "   # Wait for VPN connection, then:" "Gray"
Write-ColorOutput "   docker-compose --env-file .env-streamarr -f docker-compose-streamarr.yml up -d" "Gray"
Write-Host ""
Write-ColorOutput "4. Access your services:" "White"
Write-ColorOutput "   • Homarr Dashboard: http://localhost:7575" "Gray"
Write-ColorOutput "   • Plex: http://localhost:32400/web" "Gray"
Write-ColorOutput "   • Overseerr: http://localhost:5055" "Gray"
Write-Host ""
Write-ColorOutput "📚 Documentation:" "Blue"
Write-ColorOutput "• Quick Start: docs\QUICK_START.md" "Gray"
Write-ColorOutput "• Main README: README.md" "Gray"
Write-ColorOutput "• Troubleshooting: docs\TROUBLESHOOTING.md" "Gray"
Write-Host ""
Write-ColorOutput "💡 Tip: Check the Quick Start guide for detailed configuration instructions!" "Cyan"
Write-Host ""

# Final pause
Write-ColorOutput "Press any key to exit..." "Yellow"
$null = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
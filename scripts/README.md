# Scripts Directory

This directory contains utility scripts for maintaining your Homelab Media Stack.

## Available Scripts

### 🚀 `setup.sh` - Universal Setup Script
**Purpose**: Interactive setup and deployment for your homelab media stack across ALL platforms

**Supported Platforms:**
- 🖥️ **Windows** (WSL2, Git Bash, MSYS2)
- 🍎 **macOS** (Intel & Apple Silicon)
- 🐧 **Linux** (Ubuntu, Debian, CentOS, etc.)
- 📦 **Synology NAS** (DSM 7.0+)
- 🟢 **UGREEN NAS** (UGOS)
- 🔵 **QNAP NAS** (QTS/QuTS)
- 🌊 **TrueNAS** (Scale & Core)
- ⭐ **Unraid** (6.8+)
- 🏗️ **Proxmox VE** (7.0+)
- ⚙️ **Custom/Other** platforms

**Features:**
- **Automatic platform detection** with manual override option
- **Interactive setup wizard** with colored output and progress indicators
- **Platform-specific configurations** (paths, permissions, PUID/PGID)
- **Automated directory creation** with proper ownership
- **Environment file configuration** with auto-detected IP and timezone
- **Docker network creation** for multi-stack architecture
- **VPN validation** and security checks
- **Comprehensive service overview** with platform-specific notes

**Usage:**
```bash
# Make executable (Linux/macOS/NAS)
chmod +x scripts/setup.sh

# Run the universal setup script
./scripts/setup.sh
```

**Windows Users:**
```bash
# Option 1: WSL2 (Recommended)
wsl
./scripts/setup.sh

# Option 2: Git Bash
# Open Git Bash and navigate to project folder
./scripts/setup.sh

# Option 3: MSYS2/MinGW
./scripts/setup.sh
```

**What the script does:**
1. **Platform Detection** - Automatically detects your system type
2. **Platform Selection** - Interactive menu to confirm or override detection
3. **Prerequisites Check** - Verifies Docker and Docker Compose installation
4. **Directory Creation** - Creates complete folder structure with proper permissions
5. **Network Setup** - Creates isolated Docker networks for security
6. **Environment Config** - Configures `.env-servarr` and `.env-streamarr` files
7. **Stack Deployment** - Deploys both servarr and streamarr stacks
8. **Service Overview** - Shows access URLs and platform-specific next steps

**Platform-Specific Features:**
| Platform | Auto-Detection | Default Path | PUID:PGID | Special Notes |
|----------|----------------|--------------|-----------|---------------|
| **Synology** | synoinfo | `/volume1` | 1026:100 | Container Manager support |
| **UGREEN** | ugreen-nas | `/volume1` | 1001:1000 | UGOS compatibility |
| **QNAP** | qpkg_cli | `/share` | 1000:1000 | Container Station support |
| **TrueNAS** | midclt | `/mnt` | 1000:1000 | Scale & Core support |
| **Unraid** | os-release | `/mnt/user` | 99:100 | User shares integration |
| **Proxmox** | pveversion | `/opt/homelab` | 1000:1000 | LXC & VM support |
| **Windows** | WSL/Git Bash | `/c/homelab` | 1000:1000 | WSL2 integration |
| **macOS** | Darwin | `~/homelab` | 1000:1000 | Intel & M1/M2 support |
| **Linux** | Generic | `/opt/homelab` | 1000:1000 | All distributions |

### 🛡️ `healthcheck.sh`
**Purpose**: Monitor system health and VPN protection

**Usage:**
```bash
# Basic health check
./scripts/healthcheck.sh

# Detailed diagnostics
./scripts/healthcheck.sh --verbose

# Automated monitoring (for cron)
./scripts/healthcheck.sh --quiet

# Send results to Discord/Slack
./scripts/healthcheck.sh --webhook https://your-webhook-url
```

**Features:**
- VPN leak detection (critical for privacy)
- Container health monitoring
- Resource usage tracking
- Webhook notifications
- Exit codes for automation

**Automation Example:**
```bash
# Add to crontab for automated monitoring
*/15 * * * * /path/to/homelab-media-stack/scripts/healthcheck.sh --quiet
```

### 💾 `backup.sh`
**Purpose**: Create backups of configurations and databases

**Usage:**
```bash
# Quick config backup (recommended for daily)
./scripts/backup.sh

# Full backup with databases (recommended for weekly)
./scripts/backup.sh --full

# Custom destination and retention
./scripts/backup.sh --full --destination /mnt/backup --keep 14
```

**Features:**
- Configuration file backups
- Service database backups (Plex, Sonarr, Radarr, etc.)
- FileBot license and configuration
- Automatic cleanup of old backups
- Backup verification and restoration info

**What Gets Backed Up:**
- **Config Only**: Environment files, Docker configs, scripts (~100MB)
- **Full Backup**: Everything above + databases + metadata (~1-5GB)

### 🗑️ `uninstall.sh`
**Purpose**: Complete removal of all stack components and cleanup

**Usage:**
```bash
# Interactive uninstall with safety prompts
./scripts/uninstall.sh

# Force uninstall without prompts (use with caution)
./scripts/uninstall.sh --force

# Dry run to see what would be removed
./scripts/uninstall.sh --dry-run
```

**Features:**
- **Complete cleanup** - Removes all containers, networks, and volumes
- **Network removal** - Cleans up servarr-network and streamarr-network
- **File cleanup** - Removes generated environment files and backups
- **Data preservation** - Keeps your media files and project files safe
- **Safety prompts** - Confirms actions before destructive operations
- **Beautiful UI** - Colored output and progress indicators
- **Conflict resolution** - Handles leftover networks and containers

**What Gets Removed:**
- **Containers**: All servarr and streamarr stack containers
- **Networks**: servarr-network and streamarr-network (if unused)
- **Volumes**: Docker volumes created by the stacks
- **Files**: Generated .env-servarr and .env-streamarr files
- **Backups**: Backup files created by setup script

**What Gets Preserved:**
- **Media Data**: Your movies, TV shows, music, and downloads
- **Project Files**: Repository files and documentation
- **User Configs**: Any custom configurations you've created

## 🔧 Manual Operations (No Scripts Needed)

### Container Updates
```bash
# Check for updates
docker-compose --env-file .env-servarr -f docker-compose-servarr.yml pull
docker-compose --env-file .env-streamarr -f docker-compose-streamarr.yml pull

# Apply updates
docker-compose --env-file .env-servarr -f docker-compose-servarr.yml up -d
docker-compose --env-file .env-streamarr -f docker-compose-streamarr.yml up -d
```

*Note: Watchtower handles automatic updates by default.*

### Directory Creation (Manual)
```bash
# Linux/macOS/NAS
mkdir -p /volume1/docker/{servarr,streamarr}
mkdir -p /volume1/data/{downloads/{complete,incomplete},media/{movies,tv,music},plex_transcode}
chown -R 1001:1000 /volume1/docker /volume1/data

# Windows (PowerShell)
New-Item -ItemType Directory -Path "C:\homelab\docker\servarr" -Force
New-Item -ItemType Directory -Path "C:\homelab\data\downloads\complete" -Force
# ... (additional directories)
```

### Network Setup (Manual)
```bash
# Docker Compose automatically creates required networks
# No manual network creation needed - networks are defined in docker-compose files
```

## 🎯 Why This Universal Approach?

**Unified Philosophy:**
- **Single script for all platforms** - No more platform-specific confusion
- **Intelligent auto-detection** - Works out of the box on most systems
- **Manual override capability** - Full control when needed
- **Platform-optimized defaults** - Best practices for each system
- **Comprehensive error handling** - Clear guidance when things go wrong
- **Beautiful user interface** - Colored output and progress indicators

**Inspired by TRaSH-Guides syno-script but enhanced for modern homelab setups!**

## 🚀 Quick Start Workflow

### 1. **Clone & Navigate**
```bash
git clone https://github.com/bharry29/homelab-media-stack.git
cd homelab-media-stack
```

### 2. **Run Universal Setup**
```bash
# Linux/macOS/NAS systems
./scripts/setup.sh

# Windows (choose one)
# Option A: WSL2 (Recommended)
wsl ./scripts/setup.sh

# Option B: Git Bash
./scripts/setup.sh

# Option C: PowerShell (via WSL)
wsl --exec ./scripts/setup.sh
```

### 3. **Follow Interactive Prompts**
- Platform detection/selection
- Path configuration
- Automatic setup
- Optional deployment

### 4. **Configure VPN** (Critical!)
```bash
# Edit the generated environment file
nano .env-servarr  # or your preferred editor

# Set your VPN provider credentials
VPN_SERVICE_PROVIDER=privado
OPENVPN_USER=your-username
OPENVPN_PASSWORD=your-password
SERVER_COUNTRIES=United States

# Restart the servarr stack
docker-compose --env-file .env-servarr -f docker-compose-servarr.yml up -d
```

### 5. **Access Your Services**
The script will display all service URLs customized for your platform!

## Script Comparison

| Feature | setup.sh | healthcheck.sh | backup.sh |
|---------|----------|----------------|-----------|
| **Purpose** | Initial deployment | System monitoring | Data protection |
| **Platform Support** | Universal (10+ platforms) | Linux/Unix | Linux/Unix |
| **Frequency** | One-time setup | Every 15 minutes | Daily/Weekly |
| **Automation** | Interactive wizard | Cron-friendly | Cron-friendly |
| **User Level** | Beginner-friendly | Intermediate | Intermediate |
| **Output** | Colored, progress bars | Silent/verbose modes | Detailed logs |

## 🆘 Troubleshooting

### **Universal Setup Script Issues:**

**Platform not detected correctly:**
```bash
# The script will ask you to manually select
# Choose "10) Other/Custom" for unsupported platforms
./scripts/setup.sh
```

**Docker not found:**
```bash
# The script provides platform-specific installation instructions
# Follow the guidance for your detected platform
```

**Permission errors:**
```bash
# Linux/NAS: Run with appropriate permissions
sudo ./scripts/setup.sh

# Windows: Ensure running in elevated Git Bash or WSL2
```

**VPN connection fails:**
```bash
# Edit .env-servarr file and configure your VPN provider
# Supported: NordVPN, Privado, ExpressVPN, Surfshark, and more
nano .env-servarr
```

### **Platform-Specific Notes:**

**Synology:**
- Ensure Container Manager is installed from Package Center
- Use File Station to browse `/volume1/data`
- Configure firewall if services aren't accessible

**QNAP:**
- Install Container Station from App Center
- Access files via File Manager
- Check Container Station for container status

**Unraid:**
- Enable Docker in Settings → Docker
- Access user shares at `/mnt/user/data`
- Monitor in Docker tab

**Windows:**
- Use WSL2 for best compatibility
- Docker Desktop must be running
- Files accessible at `C:\homelab\` (or your chosen path)

**macOS:**
- Ensure Docker Desktop is running
- Files accessible in Finder
- Works on Intel and Apple Silicon

For more information, see the main [README.md](../README.md) and [docs/](../docs/) directory.

## 🌟 Universal Script Advantages

1. **🌍 True Universality**: One script works everywhere
2. **🧠 Smart Detection**: Automatically configures for your platform
3. **🎨 Beautiful Interface**: Modern, colored terminal output
4. **🛡️ Security-First**: VPN validation and network isolation
5. **📚 Self-Documenting**: Clear guidance and error messages
6. **🔧 Maintenance-Friendly**: Easy to update and extend
7. **👥 User-Friendly**: Works for beginners and experts alike

**The universal setup script represents the evolution of homelab automation - one tool, all platforms, zero compromise!**
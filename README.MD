# Homelab Media Stack

A comprehensive, production-ready Docker-based media automation stack for home servers and NAS systems. This project provides a complete solution for automated media acquisition, processing, and streaming with enterprise-grade security through VPN integration.

## 🏗️ Architecture Overview

This stack uses a **dual-stack architecture** with proper network isolation and shared data volumes:

### **SERVARR STACK** (Download & Management)
- **Network**: `172.39.0.0/24` (isolated)
- **Purpose**: Handles all download and media management operations
- **VPN Protection**: All download traffic routed through Gluetun VPN gateway

### **STREAMARR STACK** (Streaming & Requests)
- **Network**: `172.40.0.0/24` (isolated) 
- **Purpose**: Handles media streaming and user request management
- **Data Access**: Read-only access to organized media files

### **Shared Integration**
- **Data Volume**: `/volume1/data` shared between both stacks
- **Communication**: Inter-stack communication via host networking
- **Processing Flow**: Downloads → FileBot Processing → Organized Media → Streaming

## 📋 Stack Components

### SERVARR STACK Services

| Service | Purpose | Port | Network |
|---------|---------|------|---------|
| **Gluetun** | VPN Gateway | - | VPN Router |
| **qBittorrent** | BitTorrent Client | 8080 | Via VPN |
| **SABnzbd** | Usenet Client | 8090 | Via VPN |
| **Prowlarr** | Indexer Management | 9696 | Via VPN |
| **Sonarr** | TV Show Automation | 8989 | Direct |
| **Radarr** | Movie Automation | 7878 | Direct |
| **Lidarr** | Music Automation | 8686 | Direct |
| **Bazarr** | Subtitle Management | 6767 | Direct |
| **FileBot Node** | File Processing UI | 5452 | Direct |
| **FileBot Watcher** | Auto File Processing | - | Internal |
| **Homarr** | Service Dashboard | 7575 | Direct |
| **Watchtower** | Auto Updates | - | Internal |

### STREAMARR STACK Services

| Service | Purpose | Port | Network |
|---------|---------|------|---------|
| **Plex** | Media Server | 32400 | Direct |
| **Overseerr** | Request Management | 5055 | Direct |  
| **Tautulli** | Analytics & Monitoring | 8181 | Direct |
| **ErsatzTV** | Virtual TV Channels | 8409 | Direct |

## 🔧 Prerequisites

- **Docker & Docker Compose** installed
- **NAS/Server** with sufficient storage (500GB+ recommended)
- **VPN Provider** account (NordVPN, Privado, etc.)
- **Plex Account** (Plex Pass recommended for hardware transcoding)
- **FileBot License** (optional, for advanced processing)

### System Requirements

**Minimum:**
- CPU: 2 cores
- RAM: 8GB
- Storage: 500GB
- Network: 100Mbps

**Recommended:**
- CPU: 4+ cores with Intel QuickSync
- RAM: 16GB+
- Storage: 2TB+ (SSD for configs, HDD for media)
- Network: Gigabit connection

## 🚀 Quick Start - Choose Your Path

### 🌟 **Option A: Automated Setup (Recommended for Beginners)**

**Perfect for users who:**
- ✅ Want a hassle-free, guided setup experience
- ✅ Are new to Docker or homelab setups
- ✅ Prefer automated platform detection and configuration
- ✅ Want to get up and running in under 10 minutes

#### **🎯 One-Command Setup**

```bash
# 1. Clone the repository
git clone https://github.com/bharry29/homelab-media-stack.git
cd homelab-media-stack

# 2. Run the universal setup script
./scripts/setup.sh
```

**That's it!** The script will:
- 🔍 **Auto-detect your platform** (Windows, macOS, Linux, Synology, QNAP, Unraid, etc.)
- ✅ **Check prerequisites** (Docker, Docker Compose)
- 📁 **Create all directories** with proper permissions
- ⚙️ **Configure environment files** with your system settings
- 🌐 **Handle Docker networks** automatically (no conflicts!)
- 🚀 **Deploy both stacks** (optional)
- 📊 **Show all service URLs** for easy access
- 🛡️ **Validate VPN protection** and security

#### **💻 Platform-Specific Instructions**

**Linux/macOS/NAS:**
```bash
chmod +x scripts/setup.sh
./scripts/setup.sh
```

**Windows (choose one):**
```bash
# Option 1: WSL2 (Recommended)
wsl
./scripts/setup.sh

# Option 2: Git Bash
./scripts/setup.sh

# Option 3: PowerShell via WSL
wsl --exec ./scripts/setup.sh
```

#### **🎮 What You'll See**
The setup script provides a beautiful, interactive experience with colorful output and progress indicators:

```
╔═══════════════════════════════════════════════════════════════════════════════╗
║                          HOMELAB MEDIA STACK                                  ║
║                       Universal Setup Script v2.0                             ║
║  Supports: Windows • macOS • Linux • Synology • UGREEN • QNAP                 ║
║           TrueNAS • Unraid • Proxmox • And More!                              ║
╚═══════════════════════════════════════════════════════════════════════════════╝

🔍 Detecting your platform...
✓ Detected platform: synology
✓ Default path: /volume1
✓ PUID/PGID: 1026:100

Please confirm or select your platform:
1) Synology NAS
2) UGREEN NAS  
3) QNAP NAS
4) TrueNAS
5) Unraid
6) Proxmox VE
7) Windows (WSL2/Git Bash)
8) macOS
9) Linux (Generic)
0) Custom/Other

[?] Select platform (1-9, 0 for custom): 

📋 Prerequisites Check:
✓ Docker is installed and running
✓ Docker Compose is available
✓ Sufficient disk space available

📁 Creating directory structure...
[████████████████████] 100% Complete

⚙️ Configuring environment files...
✓ .env-servarr configured
✓ .env-streamarr configured

🌐 Checking Docker networks...
⚠️  NETWORK CONFLICTS DETECTED:
   The following networks exist but were not created by Docker Compose:
   • servarr-network
   No containers are attached to servarr-network. Removing automatically...
✓ Removed servarr-network
✓ Docker networks ready!

🚀 Deploying servarr stack...
[████████████████████] 100% Complete
✓ All servarr services started successfully

🛡️ Waiting for VPN connection to establish (30 seconds)...
✓ VPN is working! External IP: 185.xxx.xxx.xxx

🚀 Deploying streamarr stack...
[████████████████████] 100% Complete
✓ All streamarr services started successfully

🎉 Setup Complete! Your services are ready:

🏠 Homarr Dashboard:     http://192.168.1.100:7575
⬇️ qBittorrent:         http://192.168.1.100:8080
🎬 Plex Media Server:   http://192.168.1.100:32400/web
📱 Overseerr:           http://192.168.1.100:5055
📺 Sonarr:              http://192.168.1.100:8989
🎥 Radarr:              http://192.168.1.100:7878
📊 Tautulli:            http://192.168.1.100:8181

Next Steps:
1. Configure your VPN settings in .env-servarr
2. Set up download clients in Sonarr/Radarr
3. Add indexers in Prowlarr
4. Configure Plex libraries
5. Set up Overseerr for requests

For detailed configuration guide: docs/QUICK_START.md
```

---

### 🛠️ **Option B: Manual Setup (For Experienced Users)**

**Perfect for users who:**
- ✅ Want full control over the setup process
- ✅ Have experience with Docker and containerization
- ✅ Prefer to understand each step in detail
- ✅ Need custom configurations beyond the script

#### **1. Clone Repository**
```bash
git clone https://github.com/bharry29/homelab-media-stack.git
cd homelab-media-stack
```

#### **2. Create Directory Structure**

**Linux/Mac/NAS Command Line:**
```bash
# Create base directories
mkdir -p /volume1/docker/{servarr,streamarr}
mkdir -p /volume1/data/{downloads/{complete,incomplete},media/{movies,tv,music},plex_transcode}

# Set permissions (adjust PUID/PGID for your system)
chown -R 1001:1000 /volume1/docker /volume1/data
```

**NAS GUI (Synology, QNAP, Unraid):**
1. **File Manager** → Create shared folder `docker`
2. **File Manager** → Create shared folder `data`
3. **Inside docker**: Create folders `servarr` and `streamarr`
4. **Inside data**: Create folders:
   - `downloads` (with subfolders `complete` and `incomplete`)
   - `media` (with subfolders `movies`, `tv`, `music`)
   - `plex_transcode`

**Windows:**
```powershell
# Create directories
New-Item -ItemType Directory -Path "C:\homelab\docker\servarr" -Force
New-Item -ItemType Directory -Path "C:\homelab\docker\streamarr" -Force
New-Item -ItemType Directory -Path "C:\homelab\data\downloads\complete" -Force
New-Item -ItemType Directory -Path "C:\homelab\data\downloads\incomplete" -Force
New-Item -ItemType Directory -Path "C:\homelab\data\media\movies" -Force
New-Item -ItemType Directory -Path "C:\homelab\data\media\tv" -Force
New-Item -ItemType Directory -Path "C:\homelab\data\media\music" -Force
New-Item -ItemType Directory -Path "C:\homelab\data\plex_transcode" -Force
```

#### **3. Deploy the Stacks**
```bash
# Docker Compose will automatically create the required networks
# Start download & management stack
docker-compose --env-file .env-servarr -f docker-compose-servarr.yml up -d

# Wait for VPN connection (2-3 minutes), then start streaming stack
docker-compose --env-file .env-streamarr -f docker-compose-streamarr.yml up -d
```

#### **4. Configure Environment Files**
```bash
# Copy example files
cp .env-servarr.example .env-servarr
cp .env-streamarr.example .env-streamarr
```

**Edit .env-servarr:**
```bash
# System Configuration (find with: id)
PUID=1001
PGID=1000
TZ=America/Los_Angeles

# VPN Configuration - REQUIRED
VPN_SERVICE_PROVIDER=nordvpn  # or privado, expressvpn, etc.
OPENVPN_USER=your-vpn-username
OPENVPN_PASSWORD=your-vpn-password
SERVER_COUNTRIES=United States

# Paths (adjust for your system)
SERVARR_CONFIG_PATH=/volume1/docker/servarr
DATA_PATH=/volume1/data
MEDIA_DATA_PATH=/volume1/data/media
```

**Edit .env-streamarr:**
```bash
# System Configuration (same as servarr)
PUID=1001
PGID=1000
TZ=America/Los_Angeles

# Plex Configuration
PLEX_CLAIM_TOKEN=claim-xxxxxxxxxx  # Get from https://plex.tv/claim
PLEX_ADVERTISE_URL=http://192.168.1.100:32400  # Your server IP
PLEX_NO_AUTH_NETWORKS=192.168.1.0/24,172.40.0.0/24

# Paths
STREAMARR_CONFIG_PATH=/volume1/docker/streamarr
DATA_PATH=/volume1/data
```

#### **5. Deploy Stacks**
```bash
# Start download & management stack
docker-compose --env-file .env-servarr -f docker-compose-servarr.yml up -d

# Wait for VPN connection (2-3 minutes), then start streaming stack
docker-compose --env-file .env-streamarr -f docker-compose-streamarr.yml up -d
```

#### **6. Verify Deployment**
```bash
# Check all containers are running
docker ps

# Verify VPN protection
docker exec qbittorrent curl -s ifconfig.me
# Should show VPN IP, not your real IP
```

---

## 🎯 Initial Configuration

### Access Your Services
- **Homarr Dashboard**: http://your-server-ip:7575
- **Plex Media Server**: http://your-server-ip:32400/web
- **Overseerr**: http://your-server-ip:5055
- **qBittorrent**: http://your-server-ip:8080

### Quick Setup Checklist
1. **qBittorrent**: Change default password, set download paths
2. **Sonarr/Radarr**: Add root folders, configure download client
3. **Plex**: Add libraries, enable hardware transcoding
4. **Overseerr**: Connect to Plex and *arr services
5. **Prowlarr**: Add indexers and sync to *arr apps

*See [Quick Start Guide](docs/QUICK_START.md) for detailed configuration steps.*

## 🔄 Data Flow & Processing

### Automated Workflow
```
1. User Request (Overseerr) → Sonarr/Radarr
2. Content Search → Prowlarr → Indexers  
3. Download → qBittorrent/SABnzbd (via VPN)
4. Complete Download → /data/downloads/complete/
5. FileBot Watcher → Process & Organize → /data/media/
6. Plex → Scan & Serve → Users
7. Tautulli → Monitor Usage → Analytics
```

## 🛡️ Security Features

### VPN Protection
- **All downloads** routed through VPN (Gluetun)
- **Kill switch** prevents leaks if VPN fails
- **DNS leak protection** via containerized DNS
- **Port forwarding** support (provider dependent)

### Network Isolation
- **Separate networks** for servarr and streamarr stacks
- **No direct internet access** for download clients
- **Controlled communication** between service stacks

## 🔄 Maintenance

### Updates
**Automatic (Recommended):**
- Watchtower updates containers automatically

**Manual:**
```bash
# Pull latest images
docker-compose --env-file .env-servarr -f docker-compose-servarr.yml pull
docker-compose --env-file .env-streamarr -f docker-compose-streamarr.yml pull

# Restart with new images
docker-compose --env-file .env-servarr -f docker-compose-servarr.yml up -d
docker-compose --env-file .env-streamarr -f docker-compose-streamarr.yml up -d
```

### Monitoring & Backups
```bash
# Health monitoring (if setup script was used)
./scripts/healthcheck.sh

# Check VPN protection
docker exec qbittorrent curl -s ifconfig.me

# Create backups (if setup script was used)
./scripts/backup.sh --full

# Manual backup of critical configs
tar -czf backup-$(date +%Y%m%d).tar.gz /volume1/docker/
```

### Uninstalling
```bash
# Complete removal of all stack components
./scripts/uninstall.sh

# This will remove:
# - All containers and services
# - Docker networks (servarr-network, streamarr-network)
# - Generated environment files (.env-servarr, .env-streamarr)
# - Backup files created by the setup script
# - Preserves your media data and project files
```

**What the uninstall script shows:**
```
╔═══════════════════════════════════════════════════════════════════════════════╗
║                          HOMELAB MEDIA STACK                                  ║
║                        Uninstall Script v2.0                                  ║
║                    Complete Cleanup & Removal                                 ║
╚═══════════════════════════════════════════════════════════════════════════════╝

⚠️  WARNING: This will completely remove your homelab media stack!
   This action cannot be undone.

   What will be removed:
   • All Docker containers and services
   • Docker networks (servarr-network, streamarr-network)
   • Generated environment files (.env-servarr, .env-streamarr)
   • Backup files created during setup

   What will be preserved:
   • Your media files (movies, TV shows, music)
   • Project files and documentation
   • Any custom configurations you've created

[?] Are you sure you want to continue? (y/N): y

🔄 Stopping all services...
[████████████████████] 100% Complete
✓ All containers stopped

🗑️ Removing containers...
[████████████████████] 100% Complete
✓ All containers removed

🌐 Removing Docker networks...
✓ servarr-network removed
✓ streamarr-network removed

📁 Cleaning up files...
✓ .env-servarr removed
✓ .env-streamarr removed
✓ Backup files cleaned up

🎉 DOCKER UNINSTALL COMPLETE!
   Your media data and project files have been preserved.
   To reinstall, simply run: ./scripts/setup.sh
```

## 🛠️ Platform-Specific Notes

### **Synology NAS**
- Use Container Manager (new Docker package)
- Create shared folders via File Station
- Enable SSH for command-line access
- Set PUID/PGID to match DSM user (usually 1026:100)

### **QNAP NAS**
- Install Container Station
- Use File Manager for directory creation
- Enable SSH via QTS settings
- Adjust PUID/PGID for QTS user

### **Unraid**
- Use Community Applications for Docker
- Create user shares for directories
- Enable SSH via Unraid settings
- Set PUID/PGID to match Unraid user (usually 99:100)

### **Windows**
- Install Docker Desktop
- Use PowerShell for directory creation
- Adjust paths in environment files (C:\homelab\...)
- Set PUID/PGID to 1000:1000

## 📚 Documentation

- [Community Impact & Project Value](docs/COMMUNITY_IMPACT.md) - Why this project matters
- [Scripts Documentation](scripts/README.md) - Universal setup script and utilities
- [Quick Start Guide](docs/QUICK_START.md) - 30-minute detailed setup
- [Troubleshooting Guide](docs/TROUBLESHOOTING.md) - Common issues and solutions
- [Directory Structure](docs/DIRECTORY_STRUCTURE.md) - Complete data flow explanation
- [Contributing Guidelines](CONTRIBUTING.md) - How to contribute

## 🎯 Key Features

- **🚀 Universal Setup Script**: One script works on all platforms (Windows, macOS, Linux, NAS)
- **🧠 Smart Platform Detection**: Automatically configures for your system
- **🛡️ VPN-First Security**: All downloads protected with kill switch
- **🌐 Network Isolation**: Separate networks for security and performance
- **🗂️ FileBot Integration**: Automated file organization and renaming
- **💻 Hardware Transcoding**: Intel QuickSync support for efficient streaming
- **📱 Request Management**: User-friendly interface via Overseerr
- **📊 Analytics**: Comprehensive monitoring via Tautulli
- **📺 Virtual TV**: Create custom TV channels with ErsatzTV
- **🔄 Auto Updates**: Watchtower keeps containers current
- **🩺 Health Monitoring**: Built-in health checks and restart policies
- **🗑️ Complete Uninstall**: Safe and thorough cleanup with data preservation
- **🎨 Beautiful UI**: Colored output and progress animations in all scripts
- **🔧 Conflict Resolution**: Automatic handling of Docker network conflicts
- **📋 Comprehensive Documentation**: Complete guides for all skill levels

## 🌟 Why Choose This Stack?

### **For Beginners:**
- **🎯 One-command setup** gets you running in minutes
- **🔍 Auto-detection** handles platform-specific configurations
- **📚 Comprehensive documentation** guides you through everything
- **🛡️ Security by default** with VPN protection built-in

### **For Advanced Users:**
- **🔧 Full manual control** over every aspect of the setup
- **📋 Modular architecture** allows customization and extension
- **🌐 Network isolation** for enterprise-grade security
- **🔄 GitOps ready** with version-controlled configurations

### **For Everyone:**
- **🌍 Universal compatibility** across all major platforms
- **🚀 Production-ready** with enterprise-grade features
- **💰 Cost-effective** using open-source components
- **👥 Active community** support and contributions

> **💡 Want to understand the full impact?** Read our [Community Impact & Project Value](docs/COMMUNITY_IMPACT.md) analysis to see why this project is transforming the self-hosted media landscape.

## 🤝 Contributing

Contributions are welcome! Please read our [Contributing Guidelines](CONTRIBUTING.md) before submitting pull requests.

### Areas for Contribution
- **Platform-specific guides** (additional NAS systems, virtualization platforms)
- **Additional VPN providers** configuration examples
- **Enhanced monitoring** and alerting integrations
- **Documentation improvements** and translations
- **Security enhancements** and best practices

## 🆘 Support

- **🔧 Setup Issues**: Use the automated setup script or check [Troubleshooting Guide](docs/TROUBLESHOOTING.md)
- **📖 Documentation**: Check the [docs/](docs/) directory
- **🐛 Bug Reports**: Open a [GitHub issue](https://github.com/bharry29/homelab-media-stack/issues)
- **💬 Discussions**: Join [GitHub Discussions](https://github.com/bharry29/homelab-media-stack/discussions)
- **👥 Community**: Reddit r/selfhosted, r/homelab, r/PleX

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## ⚠️ Disclaimer

This software is for educational and personal use only. Users are responsible for:
- **Complying with local laws** regarding content acquisition
- **Respecting copyright** and intellectual property rights  
- **Using legal content sources** and indexers
- **VPN provider terms of service** compliance

The authors assume no responsibility for misuse of this software.

## 🌟 Acknowledgments

- **Created by**: [The Garage Labs](https://thegaragelabs.cc)
- **Inspired by**: [TechHutTV Homelab](https://github.com/TechHutTV/homelab/blob/main/media/) and [TRaSH-Guides](https://trash-guides.info)
- **Built with**: Docker, Docker Compose, and the excellent work of the *arr developers
- **Special thanks**: To the selfhosted community for continuous innovation

---

*Happy Streaming! 🎬🎵📺*
# Homelab Media Stack

A comprehensive, production-ready Docker-based media automation stack for home servers and NAS systems. This project provides a complete solution for automated media acquisition, processing, and streaming with enterprise-grade security through VPN integration.

## Architecture Overview

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

## Stack Components

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

## Prerequisites

- **Docker & Docker Compose** installed
- **NAS/Server** with sufficient storage (500GB+ recommended)
- **VPN Provider** account (NordVPN, Privado, etc.)
- **Plex Account** (Plex Pass recommended for hardware transcoding)
- **FileBot License** (optional, for advanced processing)
- **Root/Sudo Access** (required for setup script)

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

## Quick Start - Choose Your Path

### **Option A: Automated Setup (Recommended for Beginners)**

**Perfect for users who:**
- Want a hassle-free, guided setup experience
- Are new to Docker or homelab setups
- Prefer automated platform detection and configuration
- Want to get up and running in under 10 minutes

#### **One-Command Setup**

```bash
# 1. Clone the repository
git clone https://github.com/bharry29/homelab-media-stack.git
cd homelab-media-stack

# 2. Run the universal setup script (requires sudo)
sudo ./scripts/setup.sh
```

**That's it!** The script will:
- Auto-detect your platform (Windows, macOS, Linux, Synology, QNAP, Unraid, etc.)
- Check prerequisites (Docker, Docker Compose, sudo access)
- Create all directories with proper permissions
- Configure environment files with your system settings
- Handle Docker networks automatically (no conflicts!)
- Set up VPN protection with interactive provider selection
- Deploy both stacks (SERVARR and STREAMARR) separately
- Show all service URLs for easy access
- Validate VPN protection and security
- Automatic cleanup on any failure (removes all created files)

#### **Platform-Specific Instructions**

**Linux/macOS/NAS:**
```bash
chmod +x scripts/setup.sh
sudo ./scripts/setup.sh
```

**Windows (choose one):**
```bash
# Option 1: WSL2 (Recommended)
wsl
sudo ./scripts/setup.sh

# Option 2: Git Bash
sudo ./scripts/setup.sh

# Option 3: PowerShell via WSL
wsl --exec sudo ./scripts/setup.sh
```

#### **What You'll See**
The setup script provides a beautiful, interactive experience with colorful output and progress indicators:

```
╔═══════════════════════════════════════════════════════════════════════════════╗
║                          HOMELAB MEDIA STACK                                  ║
║                       Universal Setup Script v2.2                             ║
║  Supports: Windows • macOS • Linux • Synology • UGREEN • QNAP                 ║
║           TrueNAS • Unraid • Proxmox • And More!                              ║
╚═══════════════════════════════════════════════════════════════════════════════╝

Detecting your platform...
Detected platform: synology
Default path: /volume1
PUID/PGID: 1026:100

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

Prerequisites Check:
Docker is installed and running
Docker Compose is available
Sufficient disk space available

Creating directory structure...
[████████████████████] 100% Complete

Configuring environment files...
.env-servarr configured
.env-streamarr configured

Configuring VPN settings for Gluetun...

Select your VPN provider:
1) NordVPN (Most Popular)
2) PrivadoVPN
3) Private Internet Access (PIA)
4) ExpressVPN
5) Surfshark
6) ProtonVPN
7) Mullvad
8) CyberGhost
9) Windscribe
10) AirVPN
11) IVPN
12) Other (manual configuration)
13) Skip VPN setup (configure later)

[?] Select VPN provider [1-13] (default: 13): 2
PrivadoVPN selected
Info: Uses username/password. Supports OpenVPN.

Enter your VPN credentials for privado:
Standard username/password authentication
VPN Username: your_privado_username
VPN Password: [hidden input]
Preferred country (e.g., United States, Canada, Germany) [default: United States]: United States

VPN settings configured in .env-servarr
```

Ready to deploy the homelab media stack!
[?] Deploy now? [Y/n]: 

╔═══════════════════════════════════════════════════════════════════════════════╗
║                        DEPLOYING SERVARR STACK                              ║
║                    (Download & Management Services)                          ║
╚═══════════════════════════════════════════════════════════════════════════════╝

[████████████████████] 100% Complete
SERVARR stack deployed successfully!
Services: Gluetun (VPN), qBittorrent, SABnzbd, Prowlarr, Sonarr, Radarr, Lidarr, Bazarr, FileBot, Homarr

Waiting for VPN connection to establish (30 seconds)...
VPN is working! External IP: 185.xxx.xxx.xxx

╔═══════════════════════════════════════════════════════════════════════════════╗
║                       DEPLOYING STREAMARR STACK                             ║
║                    (Streaming & Request Services)                            ║
╚═══════════════════════════════════════════════════════════════════════════════╝

[████████████████████] 100% Complete
STREAMARR stack deployed successfully!
Services: Plex Media Server, Overseerr, Tautulli, ErsatzTV

╔═══════════════════════════════════════════════════════════════════════════════╗
║                             SETUP COMPLETE!                                   ║
║                        Access your services below:                            ║
╚═══════════════════════════════════════════════════════════════════════════════╝

╔═══════════════════════════════════════════════════════════════════════════════╗
║                        SERVARR STACK (Download & Management)                 ║
╚═══════════════════════════════════════════════════════════════════════════════╝

Homarr Dashboard:     http://192.168.1.100:7575
qBittorrent:         http://192.168.1.100:8080
SABnzbd:             http://192.168.1.100:8090
Prowlarr:            http://192.168.1.100:9696
Sonarr:              http://192.168.1.100:8989
Radarr:              http://192.168.1.100:7878
Lidarr:              http://192.168.1.100:8686
Bazarr:              http://192.168.1.100:6767
FileBot:             http://192.168.1.100:5452

╔═══════════════════════════════════════════════════════════════════════════════╗
║                       STREAMARR STACK (Streaming & Requests)                 ║
╚═══════════════════════════════════════════════════════════════════════════════╝

Plex Media Server:   http://192.168.1.100:32400/web
Overseerr:           http://192.168.1.100:5055
Tautulli:            http://192.168.1.100:8181
ErsatzTV:            http://192.168.1.100:8409

Next Steps:
1. Set up download clients in Sonarr/Radarr
2. Add indexers in Prowlarr
3. Configure Plex libraries
4. Set up Overseerr for requests
5. Configure FileBot for media organization

For detailed configuration guide: docs/QUICK_START.md

---

### **Option B: Manual Setup (For Experienced Users)**

**Perfect for users who:**
- Want full control over the setup process
- Have experience with Docker and containerization
- Prefer to understand each step in detail
- Need custom configurations beyond the script

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

#### **3. Configure Environment Files**
```bash
# Copy example files
cp .env-servarr.example .env-servarr
cp .env-streamarr.example .env-streamarr

# Edit with your settings
nano .env-servarr
nano .env-streamarr
```

#### **4. Deploy Stacks**
```bash
# Deploy SERVARR stack (downloads & management)
docker-compose --env-file .env-servarr -f docker-compose-servarr.yml up -d

# Deploy STREAMARR stack (streaming & requests)
docker-compose --env-file .env-streamarr -f docker-compose-streamarr.yml up -d
```

## Features

### **Core Capabilities**
- **VPN Integration**: All download traffic protected through secure VPN
- **Dual-Stack Architecture**: Separate networks for downloads and streaming
- **Cross-Platform Support**: Works on Windows, macOS, Linux, and NAS systems
- **Automated Setup**: One-command deployment with intelligent platform detection
- **Professional UI**: Clean, modern web interfaces for all services

### **Advanced Features**
- **FileBot Integration**: Automated file organization and renaming
- **Request Management**: User-friendly interface via Overseerr
- **Analytics**: Comprehensive monitoring via Tautulli
- **Virtual TV**: Create custom TV channels with ErsatzTV
- **Auto-Updates**: Automatic container updates via Watchtower
- **Health Monitoring**: System health checks and notifications

### **Security & Reliability**
- **Network Isolation**: Separate networks prevent cross-contamination
- **Permission Management**: Proper file ownership and permissions
- **Error Handling**: Comprehensive error recovery and cleanup
- **Backup Support**: Automated backup scripts for configurations
- **Comprehensive Documentation**: Complete guides for all skill levels

### **User Experience**
- **Platform Detection**: Auto-detection handles platform-specific configurations
- **Guided Setup**: Interactive setup process with helpful prompts
- **Progress Indicators**: Visual feedback during deployment
- **Modular architecture**: Allows customization and extension
- **Professional Logging**: Clear, informative log messages

## Management

### **Service Management**

**Start all services:**
```bash
# SERVARR stack
docker-compose --env-file .env-servarr -f docker-compose-servarr.yml up -d

# STREAMARR stack  
docker-compose --env-file .env-streamarr -f docker-compose-streamarr.yml up -d
```

**Stop all services:**
```bash
# SERVARR stack
docker-compose --env-file .env-servarr -f docker-compose-servarr.yml down

# STREAMARR stack
docker-compose --env-file .env-streamarr -f docker-compose-streamarr.yml down
```

**View logs:**
```bash
# All services
docker-compose --env-file .env-servarr -f docker-compose-servarr.yml logs -f

# Specific service
docker logs sonarr
```

### **Backup & Restore**

**Create backup:**
```bash
./scripts/backup.sh
```

**Restore from backup:**
```bash
./scripts/backup.sh --restore /path/to/backup.tar.gz
```

### **Health Monitoring**

**Check system health:**
```bash
./scripts/healthcheck.sh
```

**Setup monitoring with notifications:**
```bash
# Edit healthcheck.sh to configure webhook URLs
nano scripts/healthcheck.sh

# Run health check
./scripts/healthcheck.sh
```

### **Uninstall**

**Complete removal:**
```bash
./scripts/uninstall.sh
```

**What gets removed:**
- All Docker containers and networks
- Generated environment files
- Empty directories created during setup
- Docker volumes (application data)

**What gets preserved:**
- All media files and downloads
- Original project files
- Data directories with content

## Troubleshooting

### **Common Issues**

#### **Setup Script Issues**
- **Permission denied**: Run with `sudo` or fix file permissions
- **Platform detection fails**: Check if your system is supported
- **Docker not found**: Install Docker and Docker Compose first
- **Directory creation fails**: Check disk space and permissions

#### **Service Access Issues**
- **Port already in use**: Check what's using the port: `netstat -tulpn | grep :8080`
- **Firewall blocking**: Configure firewall to allow Docker ports
- **Wrong IP address**: Use `ip addr show` to find correct server IP

#### **VPN Connection Issues**
```bash
# Check VPN container status
docker logs gluetun

# Test VPN connection
docker exec qbittorrent curl -s ifconfig.me

# Restart VPN container
docker restart gluetun
```

### **Detailed Troubleshooting**

#### **Setup Script Issues**
- **Platform Detection Fails**: Check if your system is in the supported list
- **Permission Errors**: Ensure you're running with `sudo` and have proper file permissions
- **Docker Not Found**: Install Docker and Docker Compose first
- **Directory Creation Fails**: Check disk space and parent directory permissions

#### **Uninstall Script Issues**
- **Containers Won't Stop**: Force stop with `docker stop $(docker ps -q)`
- **Networks Won't Remove**: Check if containers are still attached
- **Files Won't Delete**: Check file permissions and ownership

#### **Service Access Issues**
- **Port Already in Use**: Check what's using the port: `netstat -tulpn | grep :8080`
- **Firewall Blocking**: Configure firewall to allow Docker ports
- **Wrong IP Address**: Use `ip addr show` to find correct server IP

### **Error Messages & Solutions**

| Error | Solution |
|-------|----------|
| `Permission denied` | Run with `sudo` or fix file permissions |
| `No such file or directory` | Check if script exists and has correct line endings |
| `Network already exists` | Remove conflicting network or let Docker Compose handle it |
| `Port already in use` | Stop conflicting service or change port in .env file |
| `VPN connection failed` | Check credentials and provider settings |
| `Container won't start` | Check logs: `docker logs container_name` |

### **Manual Recovery**

If scripts fail completely, you can manually clean up:

```bash
# Stop all containers
docker stop $(docker ps -aq)

# Remove all containers
docker rm $(docker ps -aq)

# Remove networks
docker network rm servarr-network streamarr-network

# Remove generated files
rm -f .env-servarr .env-streamarr

# Remove empty directories (be careful!)
find /volume1/docker -type d -empty -delete
find /volume1/data -type d -empty -delete
```

### **Getting Help**

- **Setup Issues**: Use the automated setup script or check [Troubleshooting Guide](docs/TROUBLESHOOTING.md)
- **Documentation**: Check the [docs/](docs/) directory
- **Bug Reports**: Open a [GitHub issue](https://github.com/bharry29/homelab-media-stack/issues)
- **Discussions**: Join [GitHub Discussions](https://github.com/bharry29/homelab-media-stack/discussions)
- **Community**: Reddit r/selfhosted, r/homelab, r/PleX

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Disclaimer

This software is for educational and personal use only. Users are responsible for:
- **Complying with local laws** regarding content acquisition
- **Respecting copyright** and intellectual property rights  
- **Using legal content sources** and indexers
- **VPN provider terms of service** compliance

The authors assume no responsibility for misuse of this software.

## Acknowledgments

- **Created by**: [The Garage Labs](https://thegaragelabs.cc)
- **Inspired by**: [TechHutTV Homelab](https://github.com/TechHutTV/homelab/blob/main/media/) and [TRaSH-Guides](https://trash-guides.info)
- **Built with**: Docker, Docker Compose, and the excellent work of the *arr developers
- **Special thanks**: To the selfhosted community for continuous innovation

---

*Happy Streaming!*
# Homelab Media Stack

A comprehensive, production-ready Docker-based media automation stack for home servers and NAS systems. This project provides a complete solution for automated media acquisition, processing, streaming, and creative content management with enterprise-grade security through VPN integration.

> **🚀 This project is actively growing!** We're continuously adding new services, stacks, and features. The current version includes 6 main stacks with 28+ services, each with dedicated Watchtower instances for automatic updates.

> **🌐 Distributed Deployment Supported!** Each stack is completely independent and can be installed on separate machines. Deploy one stack per machine, or group them as needed - the choice is yours! See [Distributed Deployment](#distributed-deployment-) section below.

## Architecture Overview

This stack uses a **multi-stack architecture** with proper network isolation and shared data volumes:

### **SERVARR STACK** (Media Management & Downloads)
- **Network**: `172.39.0.0/24` (Gateway: `172.39.0.1`) (isolated)
- **Purpose**: Handles all download and media management operations
- **VPN Protection**: All download traffic routed through Gluetun VPN gateway
- **Services**: 10 containers including VPN, downloaders, *arr apps, and FileBot (updates handled by infrastructure watchtower)

### **STREAMARR STACK** (Streaming & Requests)
- **Network**: `172.40.0.0/24` (Gateway: `172.40.0.1`) (isolated) 
- **Purpose**: Handles media streaming and user request management
- **Data Access**: Read-only access to organized media files
- **Services**: 5 containers including Plex, request management, and analytics (updates handled by infrastructure watchtower)

### **CREATARR STACK** (Creative & Entertainment)
- **Network**: `172.41.0.0/24` (Gateway: `172.41.0.1`) (isolated)
- **Purpose**: Creative content and entertainment services
- **Services**: 6 containers including gaming, comics, audiobooks, e-books, and music tools (updates handled by infrastructure watchtower)

### **BUSINESS STACK** (Business & Productivity) 🆕
- **Network**: `172.42.0.0/24` (Gateway: `172.42.0.1`) (isolated)
- **Purpose**: Business and productivity tools
- **Services**: 4 containers including n8n workflows and Mealie recipes (updates handled by infrastructure watchtower)

### **INFRASTRUCTURE STACK** (System Management) 🆕
- **Network**: `172.43.0.0/24` (Gateway: `172.43.0.1`) (isolated)
- **Purpose**: System monitoring and dashboard
- **Services**: 3 containers including Homarr dashboard, Uptime Kuma monitoring, and Watchtower (monitors all labeled containers)

### **WEBSITES STACK** (Custom Web Applications) 🆕
- **Network**: `172.44.0.0/24` (Gateway: `172.44.0.1`) (isolated)
- **Purpose**: Host custom websites, web applications, and personal web services
- **Services**: User-defined websites (updates handled by infrastructure watchtower)
- **Note**: This stack is a template for users to add their own custom websites and web applications

### **Shared Integration**
- **Data Volume**: `/volume1/data` shared between all stacks (or independent per machine)
- **Communication**: Inter-stack communication via host networking
- **Processing Flow**: Downloads → FileBot Processing → Organized Media → Streaming + Creative Tools
- **Auto-Updates**: Centralized Watchtower in infrastructure stack monitors all labeled containers

### **Distributed Deployment** 🌐
**✅ Each stack can be installed on a separate machine!**

- **Complete Independence**: Each stack has its own docker-compose file, network, and environment
- **No Cross-Stack Dependencies**: Deploy any stack without requiring others
- **Flexible Distribution**: Install one stack per machine, or group them as needed
- **Data Options**: Use independent data paths per machine, or share via NFS/NAS

**Example:**
```bash
# Machine 1 - SERVARR only
docker-compose --env-file .env-servarr -f docker-compose-servarr.yml up -d

# Machine 2 - STREAMARR only  
docker-compose --env-file .env-streamarr -f docker-compose-streamarr.yml up -d

# Machine 3 - CREATARR only
docker-compose --env-file .env-creatarr -f docker-compose-creatarr.yml up -d
```

**Note**: When deploying on separate machines, configure services with IP addresses for inter-stack communication (e.g., Overseerr → Sonarr/Radarr on different machines).

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

### STREAMARR STACK Services

| Service | Purpose | Port | Network |
|---------|---------|------|---------|
| **Plex** | Media Server | 32400 | Direct |
| **Overseerr** | Request Management | 5055 | Direct |  
| **Tautulli** | Analytics & Monitoring | 8181 | Direct |
| **ErsatzTV** | Virtual TV Channels | 8409 | Direct |
| **Navidrome** | Music Streaming Server | 4533 | Direct |

### CREATARR STACK Services

| Service | Purpose | Port | Network |
|---------|---------|------|---------|
| **RetroArch** | Gaming Emulator | 8081 | Direct |
| **Komga** | Comic Book Server | 25600 | Direct |
| **Audiobookshelf** | Audiobook Server | 13378 | Direct |
| **Calibre-Web** | E-book Management | 8083 | Direct |
| **Noisedash** | Ambient Sound Generator | 3002 | Direct |
| **Swing Music** | Music Player | 1970 | Direct |

### BUSINESS STACK Services 🆕

| Service | Purpose | Port | Network |
|---------|---------|------|---------|
| **n8n** | Workflow Automation | 5678 | Direct |
| **n8n-postgres** | n8n Database | 5432 | Internal |
| **Mealie** | Recipe Management | 9001 | Direct |
| **mealie-db** | Mealie Database | 5432 | Internal |

### INFRASTRUCTURE STACK Services 🆕

| Service | Purpose | Port | Network |
|---------|---------|------|---------|
| **Homarr** | Service Dashboard | 7575 | Direct |
| **Uptime Kuma** | System Monitoring | 3001 | Direct |
| **Watchtower** | Auto Updates (All Stacks) | - | Internal |

### WEBSITES STACK Services 🆕

| Service | Purpose | Port | Network |
|---------|---------|------|---------|
| **Custom Websites** | User-defined web applications | User-defined | Direct |

> **Note**: The WEBSITES stack is a template for hosting your own custom websites and web applications. See [Websites Stack Guide](docs/WEBSITES_STACK_GUIDE.md) for detailed instructions on adding your websites.

## 🚀 Quick Start

### New Installation

**Option A: Single Machine (All Stacks)**
If you're setting up for the first time, use the automated setup script:

```bash
chmod +x scripts/setup.sh
sudo ./scripts/setup.sh
```

The script will guide you through:
- Platform detection
- Stack selection (choose which stacks to install)
- Service selection (choose specific services from each stack)
- Directory creation
- Environment configuration
- Container deployment

**Option B: Distributed Deployment (One Stack Per Machine)** 🌐
Each stack can be installed independently on separate machines:

```bash
# On Machine 1 - Deploy SERVARR stack only
docker-compose --env-file .env-servarr -f docker-compose-servarr.yml up -d

# On Machine 2 - Deploy STREAMARR stack only
docker-compose --env-file .env-streamarr -f docker-compose-streamarr.yml up -d

# On Machine 3 - Deploy CREATARR stack only
docker-compose --env-file .env-creatarr -f docker-compose-creatarr.yml up -d

# On Machine 4 - Deploy BUSINESS stack only
docker-compose --env-file .env-business -f docker-compose-business.yml up -d

# On Machine 5 - Deploy INFRASTRUCTURE stack only
docker-compose --env-file .env-infrastructure -f docker-compose-infrastructure.yml up -d

# On Machine 6 - Deploy WEBSITES stack only
docker-compose --env-file .env-websites -f docker-compose-websites.yml up -d
```

**Benefits of Distributed Deployment:**
- ✅ Complete isolation between stacks
- ✅ Resource optimization per machine
- ✅ Independent scaling and updates
- ✅ No cross-stack dependencies
- ✅ Mix and match based on hardware capabilities

**Data Sharing Options:**
- **Independent**: Each machine has its own data directory
- **Shared Storage**: Mount NFS/NAS for shared data access
- **Hybrid**: Some data local, some shared (e.g., media library shared, configs local)

### Updating Existing Setup
To update existing stacks, simply redeploy them using the same commands as new installations. Docker Compose will automatically update containers while preserving all data volumes.

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
- Deploy all three stacks (SERVARR, STREAMARR, and CREATARR) separately
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
.env-creatarr configured

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
Services: Gluetun (VPN), qBittorrent, SABnzbd, Prowlarr, Sonarr, Radarr, Lidarr, Bazarr, FileBot

Waiting for VPN connection to establish (30 seconds)...
VPN is working! External IP: 185.xxx.xxx.xxx

╔═══════════════════════════════════════════════════════════════════════════════╗
║                       DEPLOYING STREAMARR STACK                             ║
║                    (Streaming & Request Services)                            ║
╚═══════════════════════════════════════════════════════════════════════════════╝

[████████████████████] 100% Complete
STREAMARR stack deployed successfully!
Services: Plex Media Server, Overseerr, Tautulli, ErsatzTV, Navidrome

╔═══════════════════════════════════════════════════════════════════════════════╗
║                       DEPLOYING CREATARR STACK                               ║
║                    (Creative & Productivity Services)                         ║
╚═══════════════════════════════════════════════════════════════════════════════╝

[████████████████████] 100% Complete
CREATARR stack deployed successfully!
Services: n8n, Mealie, Noisedash, Swing Music, RetroArch

╔═══════════════════════════════════════════════════════════════════════════════╗
║                             SETUP COMPLETE!                                   ║
║                        Access your services below:                            ║
╚═══════════════════════════════════════════════════════════════════════════════╝

╔═══════════════════════════════════════════════════════════════════════════════╗
║                        SERVARR STACK (Download & Management)                 ║
╚═══════════════════════════════════════════════════════════════════════════════╝

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
Navidrome:           http://192.168.1.100:4533

╔═══════════════════════════════════════════════════════════════════════════════╗
║                        CREATARR STACK (Creative & Productivity) 🆕           ║
╚═══════════════════════════════════════════════════════════════════════════════╝

n8n Workflows:      http://192.168.1.100:5678
Mealie Recipes:     http://192.168.1.100:9001
Noisedash:          http://192.168.1.100:3002
Swing Music:        http://192.168.1.100:1970
RetroArch Gaming:   http://192.168.1.100:8081
Komga Comics:       http://192.168.1.100:25600
Audiobookshelf:     http://192.168.1.100:13378
Calibre-Web:        http://192.168.1.100:8083

Next Steps:
1. Set up download clients in Sonarr/Radarr
2. Add indexers in Prowlarr
3. Configure Plex libraries
4. Set up Overseerr for requests
5. Configure FileBot for media organization
6. Create n8n workflows for automation
7. Add recipes to Mealie
8. Set up music libraries in Swing Music
9. Upload comics to Komga
10. Add audiobooks to Audiobookshelf
11. Import e-books to Calibre-Web

For detailed setup instructions, use the interactive setup script: `./scripts/setup.sh`

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
mkdir -p /volume1/docker/{servarr,streamarr,creatarr}
mkdir -p /volume1/data/{downloads/{complete,incomplete},media/{movies,tv,music},plex_transcode}

# Set permissions (adjust PUID/PGID for your system)
chown -R 1001:1000 /volume1/docker /volume1/data
```

**NAS GUI (Synology, QNAP, Unraid):**
1. **File Manager** → Create shared folder `docker`
2. **File Manager** → Create shared folder `data`
3. **Inside docker**: Create folders `servarr`, `streamarr`, and `creatarr`
4. **Inside data**: Create folders:
   - `downloads` (with subfolders `complete` and `incomplete`)
   - `media` (with subfolders `movies`, `tv`, `music`)
   - `plex_transcode`

#### **3. Configure Environment Files**
```bash
# Copy example files
cp .env-servarr.example .env-servarr
cp .env-streamarr.example .env-streamarr
cp .env-creatarr.example .env-creatarr

# Edit with your settings
nano .env-servarr
nano .env-streamarr
nano .env-creatarr
```

#### **4. Deploy Stacks**
```bash
# Deploy SERVARR stack (downloads & management)
docker-compose --env-file .env-servarr -f docker-compose-servarr.yml up -d

# Deploy STREAMARR stack (streaming & requests)
docker-compose --env-file .env-streamarr -f docker-compose-streamarr.yml up -d

# Deploy CREATARR stack (creative & productivity)
docker-compose --env-file .env-creatarr -f docker-compose-creatarr.yml up -d
```

## Features

### **Core Capabilities**
- **VPN Integration**: All download traffic protected through secure VPN
- **Multi-Stack Architecture**: Separate networks for downloads, streaming, and creative tools
- **Cross-Platform Support**: Works on Windows, macOS, Linux, and NAS systems
- **Automated Setup**: One-command deployment with intelligent platform detection
- **Professional UI**: Clean, modern web interfaces for all services
- **Growing Ecosystem**: Continuously expanding with new services and features

### **Advanced Features**
- **FileBot Integration**: Automated file organization and renaming with intelligent quality-based sorting
- **Smart Media Organization**: Automatic UHD/HD/SD categorization based on video resolution
- **Request Management**: User-friendly interface via Overseerr
- **Analytics**: Comprehensive monitoring via Tautulli and Uptime Kuma
- **Virtual TV**: Create custom TV channels with ErsatzTV
- **Workflow Automation**: n8n for complex automation workflows
- **Recipe Management**: Mealie for family meal planning and recipes
- **Creative Tools**: Noisedash for ambient sounds, Swing Music for local music
- **Gaming**: RetroArch for retro gaming emulation
- **Digital Libraries**: Komga for comics, Audiobookshelf for audiobooks, Calibre-Web for e-books
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

# CREATARR stack
docker-compose --env-file .env-creatarr -f docker-compose-creatarr.yml up -d
```

**Stop all services:**
```bash
# SERVARR stack
docker-compose --env-file .env-servarr -f docker-compose-servarr.yml down

# STREAMARR stack
docker-compose --env-file .env-streamarr -f docker-compose-streamarr.yml down

# CREATARR stack
docker-compose --env-file .env-creatarr -f docker-compose-creatarr.yml down
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

### **CREATARR Stack Troubleshooting** 🆕

#### **n8n Issues**

**Bad Gateway Error:**
```bash
# Check n8n container status
docker ps | grep n8n
docker logs n8n --tail 50

# Check port mapping
docker port n8n

# Test direct access
curl -I http://your-nas-ip:5678
```

**Database Connection Issues:**
```bash
# Check PostgreSQL container
docker logs n8n-postgres

# Test database connection
docker exec n8n-postgres pg_isready -U n8n

# Restart n8n if database is ready
docker restart n8n
```

**n8n Deprecation Warnings:**
The stack includes optimized settings to prevent these warnings:
- `DB_SQLITE_POOL_SIZE=10` - Enables connection pooling
- `N8N_RUNNERS_ENABLED=true` - Enables task runners
- `N8N_BLOCK_ENV_ACCESS_IN_NODE=false` - Allows environment variable access

#### **Mealie Issues**

**Database "mealie" does not exist:**
```bash
# Check mealie-db container
docker logs mealie-db

# Restart mealie with database dependency
docker restart mealie-db
docker restart mealie
```

**Permission Issues:**
```bash
# Fix database directory permissions
sudo chown -R 999:999 /volume1/docker/business/mealie-db
sudo chmod -R 700 /volume1/docker/business/mealie-db
```

#### **Port Conflicts**

**Common Port Conflicts:**
- **Port 8080**: qBittorrent (SERVARR) vs RetroArch (CREATARR) → RetroArch moved to 8081
- **Port 9000**: Portainer vs Mealie → Mealie moved to 9001
- **Port 3000**: Uptime Kuma vs Noisedash → Noisedash moved to 3002

**Check Port Usage:**
```bash
# Check what's using a specific port
netstat -tlnp | grep :5678
lsof -i :5678

# Check all Docker port mappings
docker ps --format "table {{.Names}}\t{{.Ports}}"
```

#### **Database Permission Issues**

**PostgreSQL Permission Fix:**
```bash
# Set correct ownership for database directories
sudo chown -R 999:999 /volume1/docker/business/n8n-postgres
sudo chown -R 999:999 /volume1/docker/business/mealie-db

# Set correct permissions
sudo chmod -R 700 /volume1/docker/business/n8n-postgres
sudo chmod -R 700 /volume1/docker/business/mealie-db
```

#### **n8n HTTPS/Domain Configuration**

**For Custom Domain with HTTPS:**
1. **Update .env-creatarr file:**
```bash
# n8n HTTPS/Domain Configuration
N8N_SECURE_COOKIE=true
N8N_EDITOR_BASE_URL=https://your-domain.com
N8N_WEBHOOK_URL=https://your-domain.com
N8N_PROTOCOL=https
N8N_HOST=your-domain.com
N8N_ENCRYPTION_KEY=your_encryption_key_here
```

2. **Generate Encryption Key:**
```bash
# Generate a random encryption key
openssl rand -base64 32

# Or use existing key from n8n config
# Extract from: {"encryptionKey": "XLis7p0o1zKwDbgFU3uXNymkY13aY+8Z"}
```

3. **Key Management:**
- **New Setup**: Use generated key from setup script
- **Existing n8n**: Extract key from your n8n config file
- **Key Location**: `~/.n8n/config` or `${BUSINESS_CONFIG_PATH}/n8n/config`
- **Key Format**: Base64 encoded string (32+ characters)

4. **Configure Nginx Proxy Manager:**
- **Domain Names**: `n8n.yourdomain.com`
- **Forward Hostname/IP**: `172.41.0.11` (n8n container IP)
- **Forward Port**: `5678`
- **Block Common Exploits**: ✅ Enabled
- **Websockets Support**: ✅ Enabled

5. **n8n Encryption Key Helper:**
```bash
# Use the helper script for key management
./scripts/n8n-key-helper.sh

# Options available:
# 1. Generate new encryption key
# 2. Extract key from existing n8n config
# 3. Use existing key file
# 4. Manual key entry
# 5. Show current key from .env-creatarr
```

#### **Service Health Checks**

**Check All CREATARR Services:**
```bash
# Check all containers
docker ps | grep creatarr

# Check specific service logs
docker logs n8n --tail 20
docker logs mealie --tail 20
docker logs noisedash --tail 20
docker logs swing-music --tail 20
docker logs retroarch --tail 20
```

**Test Service Access:**
```bash
# Test each service
curl -I http://your-nas-ip:5678    # n8n
curl -I http://your-nas-ip:9001    # Mealie
curl -I http://your-nas-ip:3002    # Noisedash
curl -I http://your-nas-ip:1970    # Swing Music
curl -I http://your-nas-ip:8081    # RetroArch
```

### **Manual Recovery**

If scripts fail completely, you can manually clean up:

```bash
# Stop all containers
docker stop $(docker ps -aq)

# Remove all containers
docker rm $(docker ps -aq)

# Remove networks
docker network rm servarr-network streamarr-network creatarr-network business-network infrastructure-network

# Remove generated files
rm -f .env-servarr .env-streamarr .env-creatarr .env-business .env-infrastructure

# Remove empty directories (be careful!)
find /volume1/docker -type d -empty -delete
find /volume1/data -type d -empty -delete
```

### **Getting Help**

- **Setup Issues**: Use the automated setup script or check the documentation in the [docs/](docs/) directory
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

## Project Growth & Future Plans 🚀

This project is **actively growing** and evolving! Here's what we're working on:

### **Current Status (v2.0)**
- ✅ **5 Main Stacks**: SERVARR, STREAMARR, CREATARR, BUSINESS, INFRASTRUCTURE
- ✅ **28+ Services**: Complete media automation ecosystem
- ✅ **Cross-Platform Support**: Works on all major platforms
- ✅ **Automated Setup**: One-command deployment
- ✅ **Comprehensive Documentation**: Complete guides and troubleshooting

### **Coming Soon (v2.1)**
- 🔄 **Additional Creative Tools**: More productivity and creative applications
- 🔄 **Enhanced Automation**: Advanced n8n workflow templates
- 🔄 **Mobile Apps**: Companion mobile applications
- 🔄 **Advanced Monitoring**: Enhanced health checks and alerting
- 🔄 **Backup Solutions**: Automated backup and restore systems

### **Future Plans (v3.0+)**
- 🔮 **AI Integration**: AI-powered content recommendations and automation
- 🔮 **IoT Integration**: Smart home device integration
- 🔮 **Advanced Security**: Enhanced security features and monitoring
- 🔮 **Cloud Integration**: Hybrid cloud/on-premises solutions
- 🔮 **Community Templates**: User-contributed service configurations

### **Contributing to Growth**
We welcome contributions! The project grows through:
- **Community Feedback**: Your suggestions and feature requests
- **Service Requests**: New services you'd like to see added
- **Documentation**: Help improve guides and troubleshooting
- **Testing**: Help test on different platforms and configurations

**Join the conversation**: [GitHub Discussions](https://github.com/bharry29/homelab-media-stack/discussions)

## Acknowledgments

- **Created by**: [The Garage Labs](https://thegaragelabs.cc)
- **Inspired by**: [TechHutTV Homelab](https://github.com/TechHutTV/homelab/blob/main/media/) and [TRaSH-Guides](https://trash-guides.info)
- **Built with**: Docker, Docker Compose, and the excellent work of the *arr developers
- **Special thanks**: To the selfhosted community for continuous innovation
- **Growing with**: Community contributions and feedback

---

*Happy Streaming & Creating!* 🎬🎵🎮
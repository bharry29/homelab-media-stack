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
- **NAS/Server** with sufficient storage
- **VPN Provider** account (Privado, NordVPN, etc.)
- **Plex Pass** (optional, for hardware transcoding)
- **FileBot License** (optional, for advanced processing)

## 🚀 Quick Start

### 1. Clone Repository
```bash
git clone https://github.com/yourusername/homelab-media-stack.git
cd homelab-media-stack
```

### 2. Run Setup Script
```bash
# Linux/Mac
./scripts/setup.sh

# Windows
PowerShell -ExecutionPolicy Bypass -File scripts\setup.ps1
```

### 3. Configure Environment Files
```bash
# Copy and edit environment files
cp .env-servarr.example .env-servarr
cp .env-streamarr.example .env-streamarr

# Edit with your VPN credentials and settings
nano .env-servarr      # Linux/Mac
notepad .env-servarr   # Windows
```

**Required Changes:**
- `VPN_SERVICE_PROVIDER`: Your VPN provider
- `OPENVPN_USER`: Your VPN username  
- `OPENVPN_PASSWORD`: Your VPN password
- `PLEX_CLAIM_TOKEN`: Get from https://plex.tv/claim
- `PLEX_ADVERTISE_URL`: Your server's IP address

### 4. Deploy Stacks
```bash
# Start download & management stack
docker-compose --env-file .env-servarr -f docker-compose-servarr.yml up -d

# Wait for VPN connection, then start streaming stack
docker-compose --env-file .env-streamarr -f docker-compose-streamarr.yml up -d
```

### 5. Access Services
- **Homarr Dashboard**: http://your-server-ip:7575
- **Plex Media Server**: http://your-server-ip:32400/web
- **Overseerr**: http://your-server-ip:5055
- **qBittorrent**: http://your-server-ip:8080

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

## 📚 Documentation

- [Quick Start Guide](docs/QUICK_START.md) - Get running in 30 minutes
- [Troubleshooting Guide](docs/TROUBLESHOOTING.md) - Common issues and solutions
- [Directory Structure](docs/DIRECTORY_STRUCTURE.md) - Complete data flow explanation
- [Advanced Configuration](docs/ADVANCED_CONFIG.md) - Customization options

## 🎯 Key Features

- **Complete Automation**: From request to streaming with minimal intervention
- **VPN Security**: All downloads protected with kill switch
- **Network Isolation**: Separate networks for security and performance
- **FileBot Integration**: Automated file organization and renaming
- **Hardware Transcoding**: Intel QuickSync support for efficient streaming
- **Request Management**: User-friendly interface via Overseerr
- **Analytics**: Comprehensive monitoring via Tautulli
- **Virtual TV**: Create custom TV channels with ErsatzTV
- **Auto Updates**: Watchtower keeps containers current
- **Health Monitoring**: Built-in health checks and restart policies

## ⚙️ System Requirements

### Minimum Setup
- **CPU**: 2 cores (Intel preferred for QuickSync)
- **RAM**: 8GB
- **Storage**: 500GB (SSD recommended for configs)
- **Network**: 100Mbps internet connection

### Recommended Setup
- **CPU**: 4+ cores with Intel QuickSync
- **RAM**: 16GB+
- **Storage**: 2TB+ (separate SSD for configs, HDD for media)
- **Network**: Gigabit internet connection

## 🚀 Advanced Features

### Hardware Transcoding
- **Intel QuickSync**: Pre-configured for supported CPUs
- **NVIDIA GPU**: Modify compose file for NVENC support
- **Software Fallback**: Works without hardware acceleration

### Custom FileBot Processing
- **Automated organization**: Movies, TV shows, music
- **Quality detection**: 4K, HDR, Dolby Vision support
- **Webhook notifications**: Discord/Slack integration
- **Custom naming**: Fully customizable file organization

### Monitoring & Analytics
- **Tautulli**: Comprehensive Plex usage statistics
- **Health checks**: Container and service monitoring
- **Notifications**: Discord, Slack, email alerts
- **Performance**: Resource usage tracking

## 🤝 Contributing

Contributions are welcome! Please read our [Contributing Guidelines](CONTRIBUTING.md) before submitting pull requests.

### Areas for Contribution
- **Additional VPN providers** configuration examples
- **Platform-specific guides** (Synology, Unraid, etc.)
- **Enhanced monitoring** and alerting integrations
- **Documentation improvements** and translations
- **Security enhancements** and best practices

## 🆘 Support

- **Documentation**: Check the [docs/](docs/) directory
- **Issues**: Open a [GitHub issue](https://github.com/yourusername/homelab-media-stack/issues)
- **Discussions**: Join [GitHub Discussions](https://github.com/yourusername/homelab-media-stack/discussions)
- **Community**: Reddit r/selfhosted, r/homelab, r/PleX

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
- **Inspired by**: [TechHutTV Homelab](https://github.com/TechHutTV/homelab/blob/main/media/)
- **Built with**: Docker, Docker Compose, and the excellent work of the *arr developers
- **Special thanks**: To the selfhosted community for continuous innovation

## 📈 Star History

If this project helped you, please consider giving it a ⭐ on GitHub!

---

*Happy Streaming! 🎬🎵📺*
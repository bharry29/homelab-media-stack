# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- **Universal Setup Script** (`scripts/setup.sh`) - Cross-platform automated setup with platform detection
- **Uninstall Script** (`scripts/uninstall.sh`) - Complete cleanup and removal of all stack components
- **Enhanced Network Management** - Docker Compose handles network creation automatically
- **Beautiful UI Enhancements** - Colored output, progress bars, and loading animations in scripts
- **Platform-Specific Optimizations** - Auto-detection for Windows, macOS, Linux, Synology, QNAP, Unraid, and more

### Changed
- **Network Creation** - Removed manual network creation steps, now handled by Docker Compose
- **Setup Process** - Simplified manual setup by removing network creation requirements
- **Documentation** - Updated all guides to reflect new network management approach
- **Docker Compose Files** - Removed obsolete version fields and improved network definitions

### Fixed
- **Network Conflicts** - Resolved issues with leftover networks causing deployment failures
- **Setup Script** - Enhanced conflict detection and resolution for existing networks
- **Uninstall Process** - Comprehensive cleanup including Docker networks and generated files
- **Platform Compatibility** - Improved detection and configuration for various NAS systems

### Planned
- Platform-specific installation guides (Synology, Unraid, Proxmox)
- Additional VPN provider configurations
- Advanced monitoring and alerting integrations
- Multi-language documentation support
- Automated backup and restore functionality

---

## [1.0.0] - 2025-01-XX

### 🎉 Initial Release

The first stable release of the Homelab Media Stack - a comprehensive, production-ready Docker-based media automation solution with enterprise-grade security through VPN integration.

### ✨ Features Added

#### **Core Architecture**
- **Dual-stack architecture** with proper network isolation (servarr + streamarr)
- **VPN-protected downloads** via Gluetun with kill switch protection
- **Shared data volumes** for seamless integration between stacks
- **Inter-stack communication** via host networking

#### **SERVARR STACK (Download & Management)**
- **Gluetun VPN Gateway** - Routes all download traffic through VPN
- **qBittorrent** - BitTorrent client with web interface (8080)
- **SABnzbd** - Usenet client with web interface (8090)
- **Prowlarr** - Unified indexer management (9696)
- **Sonarr** - TV show automation and management (8989)
- **Radarr** - Movie automation and management (7878)
- **Lidarr** - Music automation and management (8686)
- **Bazarr** - Subtitle management and automation (6767)
- **FileBot Node** - File processing web interface (5452)
- **FileBot Watcher** - Automated file processing and organization
- **Homarr** - Unified service dashboard (7575)
- **Watchtower** - Automatic container updates

#### **STREAMARR STACK (Streaming & Requests)**
- **Plex Media Server** - Media streaming with hardware transcoding support (32400)
- **Overseerr** - User-friendly request management interface (5055)
- **Tautulli** - Comprehensive Plex analytics and monitoring (8181)
- **ErsatzTV** - Virtual TV channel creation and management (8409)

#### **Security Features**
- **VPN Kill Switch** - Prevents IP leaks if VPN connection fails
- **Network Isolation** - Separate Docker networks for download and streaming services
- **DNS Leak Protection** - Containerized DNS resolution
- **No Direct Internet Access** - Download clients only access internet via VPN

#### **Automation Features**
- **Complete Workflow Automation** - Request → Search → Download → Process → Stream
- **FileBot Integration** - Automated file renaming and organization
- **Quality Management** - Configurable quality profiles for all media types
- **Subtitle Automation** - Automatic subtitle downloading in multiple languages
- **Health Monitoring** - Built-in health checks and restart policies

#### **Hardware Support**
- **Intel QuickSync** - Hardware transcoding for efficient streaming
- **NVIDIA GPU** - Support for NVENC hardware acceleration (configurable)
- **Software Transcoding** - Fallback for systems without hardware acceleration

### 📚 Documentation Added

#### **Core Documentation**
- **README.md** - Comprehensive project overview and setup guide
- **COMMUNITY_IMPACT.md** - Project value and community impact analysis
- **QUICK_START.md** - 30-minute setup guide for immediate deployment
- **TROUBLESHOOTING.md** - Extensive troubleshooting guide with solutions
- **CONTRIBUTING.md** - Community contribution guidelines and standards
- **DIRECTORY_STRUCTURE.md** - Complete data flow and organization guide

#### **Setup Automation**
- **Linux/Mac Setup Script** (`scripts/setup.sh`) - Automated environment preparation
- **Windows Setup Script** (`scripts/setup.ps1`) - PowerShell automation for Windows
- **Environment Templates** - Pre-configured examples with comprehensive documentation

#### **GitHub Integration**
- **Issue Templates** - Bug reports, feature requests, and support questions
- **Pull Request Template** - Standardized contribution process
- **Security Policy** - Responsible disclosure guidelines

### 🔧 Configuration Features

#### **VPN Provider Support**
- **Multiple VPN Providers** - Privado, NordVPN, ExpressVPN, Surfshark, AirVPN, PIA, ProtonVPN
- **Protocol Support** - OpenVPN and WireGuard (provider dependent)
- **Server Selection** - Country and city-level server selection
- **Port Forwarding** - Support for VPN providers that offer port forwarding

#### **Platform Compatibility**
- **Linux** - Ubuntu, Debian, CentOS, RHEL, Arch Linux
- **macOS** - Intel and Apple Silicon support via Docker Desktop
- **Windows** - Windows 10/11 with Docker Desktop or WSL2
- **NAS Systems** - Synology, QNAP, and other Docker-capable NAS devices

#### **Storage Flexibility**
- **Configurable Paths** - Customizable base directories for configs and data
- **Permission Management** - Automated PUID/PGID configuration
- **Multi-Drive Support** - Separate SSD/HDD allocation for performance optimization

### 🛠️ Technical Improvements

#### **Docker Optimization**
- **Health Checks** - Comprehensive container health monitoring
- **Restart Policies** - Smart restart behavior for failed containers
- **Resource Limits** - Configurable resource constraints
- **Volume Management** - Persistent data with proper backup considerations

#### **Network Configuration**
- **Custom Networks** - Isolated subnets (172.39.0.0/24 and 172.40.0.0/24)
- **Static IP Assignment** - Predictable container networking
- **Inter-Service Communication** - Optimized service discovery and communication

#### **Monitoring & Maintenance**
- **Automated Updates** - Watchtower-based container updating
- **Log Management** - Configurable log rotation and retention
- **Performance Monitoring** - Resource usage tracking and optimization
- **Backup Integration** - Configuration backup and restore procedures

### 🎯 User Experience

#### **Setup Experience**
- **Automated Setup** - One-command environment preparation
- **Interactive Configuration** - Guided setup with validation
- **Error Handling** - Comprehensive error messages and recovery suggestions
- **Platform Detection** - Automatic platform-specific optimizations

#### **Management Experience**
- **Unified Dashboard** - Homarr provides single-pane-of-glass management
- **Request Management** - Overseerr enables user-friendly content requests
- **Quality Control** - Configurable quality profiles and preferences
- **Analytics** - Tautulli provides detailed usage analytics and reporting

### 🔄 Data Flow Implementation

#### **Automated Processing Pipeline**
```
User Request (Overseerr) → 
Content Search (Prowlarr + Indexers) → 
Download (qBittorrent/SABnzbd via VPN) → 
File Processing (FileBot) → 
Media Organization (/data/media/) → 
Library Update (Plex) → 
Content Available (All Devices)
```

#### **File Organization**
- **Automated Naming** - Consistent file and folder naming schemes
- **Quality Detection** - 4K, HDR, Dolby Vision, and audio format detection
- **Metadata Integration** - Comprehensive metadata from TheMovieDB and TheTVDB
- **Custom Formats** - Configurable naming patterns and organization rules

### 📦 Dependencies

#### **Runtime Requirements**
- **Docker** - Version 20.10+ (Docker Desktop for Windows/Mac)
- **Docker Compose** - Version 2.0+ (or docker-compose 1.29+)
- **System Requirements** - 2+ CPU cores, 8GB+ RAM, 500GB+ storage

#### **External Services**
- **VPN Provider** - Account with supported VPN service
- **Indexers** - Access to torrent sites and/or Usenet providers
- **Plex Account** - Free account (Plex Pass recommended for hardware transcoding)
- **FileBot License** - Optional for advanced file processing features

### 🌟 Community Features

#### **Open Source**
- **MIT License** - Permissive licensing for broad adoption
- **Community Contributions** - Welcoming contribution guidelines
- **Issue Templates** - Streamlined bug reporting and feature requests
- **Documentation Focus** - Comprehensive guides for all skill levels

#### **Inspiration & Acknowledgments**
- **Based on TechHutTV's homelab project** with significant enhancements
- **Community-driven improvements** and customizations
- **Enterprise-grade features** for production homelab environments

### 📈 Performance Optimizations

#### **Resource Efficiency**
- **Shared Volumes** - Efficient storage utilization across services
- **Network Isolation** - Reduced network overhead and improved security
- **Container Optimization** - Minimal resource footprint per service
- **Caching Strategies** - Optimized transcoding and metadata caching

#### **Scalability Features**
- **Modular Architecture** - Services can be disabled/enabled as needed
- **Hardware Transcoding** - Reduced CPU usage for media streaming
- **Quality Profiles** - Bandwidth-optimized streaming options
- **Storage Tiering** - SSD/HDD optimization for performance vs capacity

---

## [0.9.0] - Development Preview (Internal)

### Added
- Initial Docker Compose stack development
- Basic VPN integration testing
- Core service configurations
- Development documentation

### Changed
- Refined network architecture
- Improved security model
- Enhanced automation workflows

### Fixed
- Container communication issues
- Permission handling improvements
- Network isolation problems

---

## Release Notes

### Upgrade Instructions

**From Development/Beta versions:**
1. Stop all services: `docker-compose down`
2. Backup configurations: `tar -czf backup-$(date +%Y%m%d).tar.gz /volume1/docker/`
3. Update repository: `git pull origin main`
4. Review configuration changes: `diff .env-servarr.example .env-servarr`
5. Deploy updated stack: `docker-compose up -d`

### Breaking Changes

**Version 1.0.0:**
- Initial stable release - no breaking changes from development versions
- Environment file structure finalized
- Network configuration standardized

### Migration Guide

**New Installations:**
- Follow the [Quick Start Guide](docs/QUICK_START.md) for fresh installations
- Use automated setup scripts for best results

**Existing Docker Media Stacks:**
- Review [Migration Guide](docs/MIGRATION.md) for transitioning from other setups
- Backup existing configurations before migration
- Test migration in isolated environment first

---

## Maintenance Schedule

### Security Updates
- **Monthly** - Container base image updates
- **Weekly** - Security patch reviews
- **As-needed** - Critical security fixes

### Feature Releases
- **Minor versions** - Monthly or bi-monthly
- **Major versions** - Annual or as-needed for significant changes
- **Patch versions** - As-needed for bug fixes

### Support Timeline
- **Current version (1.0.x)** - Full support and updates
- **Previous major version** - Security updates only
- **Older versions** - Community support only

---

*For detailed technical changes, see individual commit messages and pull requests.*
# Quick Start Guide

This guide will get your Automated Media Streamer Stack running in under 30 minutes.

## ⚡ Prerequisites Check

Before starting, ensure you have:

- [ ] **Docker & Docker Compose** installed and running
- [ ] **VPN provider account** (Privado, NordVPN, etc.) with OpenVPN credentials
- [ ] **Sufficient storage space** (minimum 500GB recommended)
- [ ] **Network access** to your server from devices you'll use
- [ ] **Basic terminal/command line access** to your server

## 🚀 Installation Steps

### Step 1: Download & Setup
```bash
# Clone the repository
git clone https://github.com/yourusername/homelab-media-stack.git
cd homelab-media-stack

# Run the setup script
# Linux/Mac:
./scripts/setup.sh

# Windows:
PowerShell -ExecutionPolicy Bypass -File scripts\setup.ps1
```

### Step 2: Configure Environment Files

#### Configure SERVARR Stack (Downloads)
```bash
# Copy the example file
cp .env-servarr.example .env-servarr

# Edit with your preferred editor
nano .env-servarr      # Linux/Mac
notepad .env-servarr   # Windows
```

**Essential Settings:**
```bash
# Your system user ID (run 'id' command on Linux/Mac)
PUID=1001
PGID=1000

# VPN Configuration - CHANGE THESE
VPN_SERVICE_PROVIDER=privado
OPENVPN_USER=your-vpn-username  
OPENVPN_PASSWORD=your-vpn-password
SERVER_COUNTRIES=Netherlands

# Your timezone
TZ=America/Los_Angeles
```

#### Configure STREAMARR Stack (Streaming)
```bash
# Copy the example file
cp .env-streamarr.example .env-streamarr

# Edit with your preferred editor
nano .env-streamarr      # Linux/Mac
notepad .env-streamarr   # Windows
```

**Essential Settings:**
```bash
# Same user ID as above
PUID=1001
PGID=1000

# Get claim token from: https://plex.tv/claim
PLEX_CLAIM_TOKEN=claim-xxxxxxxxxx

# Replace with your server IP (find with: hostname -I)
PLEX_ADVERTISE_URL=http://192.168.1.100:32400

# Your local network (find with: ip route | grep default)
PLEX_NO_AUTH_NETWORKS=192.168.1.0/24

# Your timezone (same as servarr)
TZ=America/Los_Angeles
```

### Step 3: Deploy the Stacks

#### Start Download & Management Stack
```bash
docker-compose --env-file .env-servarr -f docker-compose-servarr.yml up -d
```

#### Wait for VPN to Connect (2-3 minutes)
```bash
# Check VPN status - wait until you see "You are running"
docker logs gluetun | grep "You are running"

# Should show something like: "You are running on the internet with IP xxx.xxx.xxx.xxx"
```

#### Start Streaming & Request Stack  
```bash
docker-compose --env-file .env-streamarr -f docker-compose-streamarr.yml up -d
```

### Step 4: Verify Everything is Running
```bash
# Check all services are up
docker ps

# You should see all containers with status "Up" and some showing "healthy"
```

## 🎯 Essential Configuration (First Time)

### 1. Setup Download Client (5 minutes)

**qBittorrent** - http://your-server-ip:8080
- **Default login**: Username: `admin`, Password: `adminadmin`
- **⚠️ IMPORTANT**: Change the default password immediately!
- **Settings → Downloads**:
  - **Save files to location**: `/data/downloads/incomplete`
  - **Copy .torrent files to**: (leave empty)
  - **Keep incomplete torrents in**: (leave empty)
- **Settings → Downloads → Saving Management**:
  - **Copy completed downloads to**: `/data/downloads/complete`
  - **Category changed**: `/data/downloads/complete`
- **Save settings**

### 2. Setup Media Management (10 minutes)

#### **Sonarr (TV Shows)** - http://your-server-ip:8989
1. **Media Management → Root Folders**: 
   - Click "Add Root Folder"
   - Enter: `/data/media/tv`
   - Save
2. **Download Clients**: 
   - Add → qBittorrent
   - **Host**: `172.39.0.2` (Gluetun container IP)
   - **Port**: `8080`
   - **Username**: `admin`
   - **Password**: (your qBittorrent password)
   - Test and Save
3. **General → Security**: Note the API Key (you'll need this for Overseerr)

#### **Radarr (Movies)** - http://your-server-ip:7878  
1. **Media Management → Root Folders**: 
   - Add: `/data/media/movies`
2. **Download Clients**: 
   - Same settings as Sonarr above
3. **General → Security**: Note the API Key

### 3. Setup Plex Media Server (5 minutes)

**Plex** - http://your-server-ip:32400/web
1. **Complete initial setup wizard**
2. **Add Libraries**:
   - **Movies**: `/data/media/movies`
   - **TV Shows**: `/data/media/tv`
   - **Music**: `/data/media/music`
3. **Settings → Transcoder** (if you have Intel CPU):
   - **Use hardware acceleration when available**: ✅ Enabled
   - **Hardware transcoding device**: Intel QuickSync

### 4. Setup Request Management (5 minutes)

**Overseerr** - http://your-server-ip:5055
1. **Connect to Plex**: 
   - Use: `http://172.40.0.1:32400` (container IP)
   - Select your Plex server
2. **Add Sonarr Service**:
   - **Server Name**: Sonarr
   - **Hostname or IP**: `http://your-server-ip:8989`
   - **API Key**: (from Sonarr General → Security)
   - **Base URL**: (leave empty)
   - Test and Save
3. **Add Radarr Service**:
   - **Server Name**: Radarr  
   - **Hostname or IP**: `http://your-server-ip:7878`
   - **API Key**: (from Radarr General → Security)
   - Test and Save

## ✅ Test Your Setup

### 1. Test VPN Connection
```bash
# This should show your VPN IP, NOT your real IP
docker exec qbittorrent curl -s ifconfig.me

# Compare with your real IP:
curl -s ifconfig.me

# They should be different!
```

### 2. Test Media Request Workflow
1. **Go to Overseerr**: http://your-server-ip:5055
2. **Search for a popular movie** (e.g., "The Matrix")
3. **Click "Request"**
4. **Check Radarr**: http://your-server-ip:7878 - movie should appear in "Activity"
5. **Check qBittorrent**: http://your-server-ip:8080 - download should start
6. **Wait for completion** - file should move to `/data/media/movies/`
7. **Check Plex** - movie should appear in library after scan

### 3. Test Indexers (Optional but Recommended)
**Prowlarr** - http://your-server-ip:9696
1. **Add indexers** (torrent sites you have access to)
2. **Settings → Apps**: Add Sonarr and Radarr
3. **Sync App Indexers** to automatically configure all *arr apps

## 🚨 Quick Troubleshooting

### VPN Issues
```bash
# VPN not connecting?
docker logs gluetun

# Common fixes:
docker restart gluetun
# Check VPN credentials in .env-servarr
# Try different SERVER_COUNTRIES
```

### Can't Access Web Interfaces
```bash
# Check if containers are running
docker ps

# Check specific container logs
docker logs plex
docker logs sonarr

# Restart if needed
docker restart plex
```

### Permission Issues
```bash
# Linux/Mac - fix ownership
sudo chown -R 1001:1000 /volume1/docker /volume1/data

# Windows - run PowerShell as Administrator
# Right-click PowerShell → "Run as Administrator"
```

### Download Issues
```bash
# Test download client connectivity
docker exec qbittorrent curl -s ifconfig.me

# Should show VPN IP, not your real IP
# If showing real IP, VPN is not working
```

## 🎉 You're Ready!

Once everything is working:

### **Main Services:**
- 🏠 **Homarr Dashboard**: http://your-server-ip:7575
- 🎬 **Plex Media Server**: http://your-server-ip:32400/web
- 📱 **Overseerr (Requests)**: http://your-server-ip:5055
- 📊 **Tautulli (Analytics)**: http://your-server-ip:8181

### **Management Services:**
- 🔍 **Prowlarr (Indexers)**: http://your-server-ip:9696
- 📺 **Sonarr (TV)**: http://your-server-ip:8989
- 🎬 **Radarr (Movies)**: http://your-server-ip:7878
- 🎵 **Lidarr (Music)**: http://your-server-ip:8686
- 💬 **Bazarr (Subtitles)**: http://your-server-ip:6767
- ⬇️ **qBittorrent**: http://your-server-ip:8080

## 📚 Next Steps

### Essential Configuration
1. **Quality Profiles**: Configure preferred video/audio quality in Sonarr/Radarr
2. **Indexers**: Add your preferred torrent sites/Usenet providers in Prowlarr
3. **Notifications**: Setup Discord/Slack webhooks for download notifications
4. **FileBot License**: Install license for advanced file processing features

### Advanced Features
1. **Bazarr**: Configure automatic subtitle downloads
2. **ErsatzTV**: Create virtual TV channels from your media
3. **Hardware Transcoding**: Optimize Plex for your hardware
4. **Remote Access**: Configure Plex for streaming outside your network

### Monitoring & Maintenance
1. **Tautulli**: Set up monitoring and notifications
2. **Backups**: Configure automatic backups of configurations
3. **Updates**: Monitor Watchtower for container updates
4. **Storage**: Set up alerts for low disk space

## 🆘 Need Help?

- **📖 Full Documentation**: Check the main [README.md](../README.md)
- **🔧 Troubleshooting**: See [TROUBLESHOOTING.md](TROUBLESHOOTING.md)
- **💬 Community**: Join discussions on Reddit r/selfhosted
- **🐛 Issues**: Report bugs on [GitHub Issues](https://github.com/yourusername/homelab-media-stack/issues)

---

**Total Setup Time**: ~30 minutes for basic functionality, ~2 hours for complete configuration

*Happy streaming! 🎬*
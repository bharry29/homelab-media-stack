Quick Start Guide
This guide will get your Homelab Media Stack running in under 30 minutes.

⚡ Prerequisites Check
Before starting, ensure you have:

 Docker & Docker Compose installed and running
 VPN provider account (NordVPN, Privado, etc.) with OpenVPN credentials
 Sufficient storage space (minimum 500GB recommended)
 Network access to your server from devices you'll use
 Basic command line access to your server (SSH or local terminal)
🚀 Installation Steps
Step 1: Download & Prepare
bash
# Clone the repository
git clone https://github.com/bharry29/homelab-media-stack.git
cd homelab-media-stack
Step 2: Create Directory Structure
Choose the method that works for your system:

Linux/Mac/NAS Command Line:
bash
# Create all required directories
mkdir -p /volume1/docker/{servarr,streamarr}
mkdir -p /volume1/data/{downloads/{complete,incomplete},media/{movies,tv,music},plex_transcode}

# Set proper permissions (find your IDs with: id)
chown -R 1001:1000 /volume1/docker /volume1/data
chmod -R 755 /volume1/docker /volume1/data
NAS Web Interface (Synology, QNAP, etc.):
File Manager → Create shared folder: docker
File Manager → Create shared folder: data
Inside docker folder, create:
servarr folder
streamarr folder
Inside data folder, create:
downloads folder (with complete and incomplete subfolders)
media folder (with movies, tv, music subfolders)
plex_transcode folder
Windows:
powershell
# Create directory structure
New-Item -ItemType Directory -Path "C:\homelab-media-stack\docker\servarr" -Force
New-Item -ItemType Directory -Path "C:\homelab-media-stack\docker\streamarr" -Force
New-Item -ItemType Directory -Path "C:\homelab-media-stack\data\downloads\complete" -Force
New-Item -ItemType Directory -Path "C:\homelab-media-stack\data\downloads\incomplete" -Force
New-Item -ItemType Directory -Path "C:\homelab-media-stack\data\media\movies" -Force
New-Item -ItemType Directory -Path "C:\homelab-media-stack\data\media\tv" -Force
New-Item -ItemType Directory -Path "C:\homelab-media-stack\data\media\music" -Force
New-Item -ItemType Directory -Path "C:\homelab-media-stack\data\plex_transcode" -Force
Step 3: Deploy the Stacks
bash
# Docker Compose will automatically create the required networks
# Start download & management stack
docker-compose --env-file .env-servarr -f docker-compose-servarr.yml up -d

# Wait for VPN connection (2-3 minutes), then start streaming stack
docker-compose --env-file .env-streamarr -f docker-compose-streamarr.yml up -d
Step 4: Configure Environment Files
Copy Example Files:
bash
cp .env-servarr.example .env-servarr
cp .env-streamarr.example .env-streamarr
Configure SERVARR Stack (Downloads):
bash
# Edit the servarr environment file
nano .env-servarr  # Linux/Mac
notepad .env-servarr  # Windows
Essential Settings to Change:

bash
# System Configuration (find with: id command)
PUID=1001  # Your user ID
PGID=1000  # Your group ID
TZ=America/Los_Angeles  # Your timezone

# VPN Configuration - CRITICAL
VPN_SERVICE_PROVIDER=privado  # Your VPN provider
OPENVPN_USER=your-vpn-username  # Your VPN provider username
OPENVPN_PASSWORD=your-vpn-password  # Your VPN provider password
SERVER_COUNTRIES=United States  # Preferred VPN location

# Directory Paths (adjust if you used different paths)
SERVARR_CONFIG_PATH=/volume1/docker/servarr
DATA_PATH=/volume1/data
MEDIA_DATA_PATH=/volume1/data/media
Configure STREAMARR Stack (Streaming):
bash
# Edit the streamarr environment file
nano .env-streamarr  # Linux/Mac
notepad .env-streamarr  # Windows
Essential Settings to Change:

bash
# System Configuration (same as servarr)
PUID=1001
PGID=1000
TZ=America/Los_Angeles

# Plex Configuration - Get token from https://plex.tv/claim
PLEX_CLAIM_TOKEN=claim-xxxxxxxxxx  # Expires in 4 minutes!
PLEX_ADVERTISE_URL=http://192.168.1.100:32400  # Your server's IP
PLEX_NO_AUTH_NETWORKS=192.168.1.0/24,172.40.0.0/24  # Your local network

# Directory Paths
STREAMARR_CONFIG_PATH=/volume1/docker/streamarr
DATA_PATH=/volume1/data
Platform-Specific Path Adjustments:

Platform	Base Path	PUID:PGID
Synology	/volume1	1026:100
QNAP	/share	1000:1000
Unraid	/mnt/user	99:100
Windows	C:\homelab-media-stack	1000:1000
Linux	/home/user/media-stack	Your user ID
Step 5: Verify Deployment
Verify VPN Connection (CRITICAL):
bash
# Wait 2-3 minutes for VPN to connect, then check:
docker logs gluetun | grep "You are running"
# Should show: "You are running with the external IP address of XXX.XXX.XXX.XXX"
Step 6: Verify Everything is Running
bash
# Check all containers are up
docker ps

# Verify VPN protection (CRITICAL SECURITY CHECK)
docker exec qbittorrent curl -s ifconfig.me
# This should show your VPN IP, NOT your real home IP

# Compare with your real IP
curl -s ifconfig.me
# Should be different from the above command
🎯 Essential Configuration (First Time)
1. Access Your Services
Replace your-server-ip with your actual server IP address:

🏠 Homarr Dashboard: http://your-server-ip:7575
⬇️ qBittorrent: http://your-server-ip:8080
🎬 Plex: http://your-server-ip:32400/web
📱 Overseerr: http://your-server-ip:5055
📺 Sonarr: http://your-server-ip:8989
🎥 Radarr: http://your-server-ip:7878
2. Configure qBittorrent (5 minutes)
1. Go to http://your-server-ip:8080
2. Login: admin / adminadmin
3. IMMEDIATELY change password: Tools → Options → Web UI → Authentication
4. Set download paths: Tools → Options → Downloads:
   - Save files to: /data/downloads/incomplete
   - Copy completed downloads to: /data/downloads/complete
5. Save settings
3. Configure Sonarr (TV Shows) (5 minutes)
1. Go to http://your-server-ip:8989
2. Settings → Media Management → Root Folders:
   - Add Root Folder: /data/media/tv
3. Settings → Download Clients → Add → qBittorrent:
   - Host: 172.39.0.2 (Gluetun container IP)
   - Port: 8080
   - Username: admin
   - Password: [your new qBittorrent password]
   - Test and Save
4. Note the API Key from Settings → General → Security
4. Configure Radarr (Movies) (5 minutes)
1. Go to http://your-server-ip:7878
2. Settings → Media Management → Root Folders:
   - Add Root Folder: /data/media/movies
3. Settings → Download Clients:
   - Add qBittorrent (same settings as Sonarr)
4. Note the API Key from Settings → General → Security
5. Configure Plex Media Server (8 minutes)
1. Go to http://your-server-ip:32400/web
2. Complete initial setup wizard
3. Add Libraries:
   - Movies: /data/media/movies
   - TV Shows: /data/media/tv
   - Music: /data/media/music (optional)
4. Settings → Transcoder (if you have Intel CPU with QuickSync):
   - Use hardware acceleration: ✓ Enable
5. Settings → Remote Access:
   - Enable remote access for streaming outside your network
6. Configure Overseerr (Request Management) (7 minutes)
1. Go to http://your-server-ip:5055
2. Setup wizard → Connect to Plex:
   - Plex server: http://172.40.0.1:32400 (container IP)
   - Sign in with your Plex account
3. Add Sonarr service:
   - Server: http://your-server-ip:8989
   - API Key: [from Sonarr setup]
   - Test and Save
4. Add Radarr service:
   - Server: http://your-server-ip:7878
   - API Key: [from Radarr setup]
   - Test and Save
✅ Test Your Complete Setup
End-to-End Test (The Fun Part!)
1. Go to Overseerr: http://your-server-ip:5055
2. Search for a popular movie (e.g., "The Matrix")
3. Click "Request"
4. Monitor the workflow:
   a) Check Radarr: Should appear in "Activity"
   b) Check qBittorrent: Download should start
   c) Verify VPN protection: docker exec qbittorrent curl -s ifconfig.me
   d) Wait for completion (varies by file size and connection)
   e) Check Plex: Movie should appear in library automatically
Verify VPN Protection (Security Check)
bash
# This is the most important check - ensure downloads are protected
docker exec qbittorrent curl -s ifconfig.me
# Should show VPN IP (different from your home IP)

# If this shows your real IP, STOP and troubleshoot VPN before proceeding
🚨 Quick Troubleshooting
VPN Not Working?
bash
# Check VPN logs
docker logs gluetun | tail -20

# Common fixes:
docker restart gluetun
# Check VPN credentials in .env-servarr
# Try different SERVER_COUNTRIES
Can't Access Services?
Check if containers are running: docker ps
Verify server IP address is correct
Check firewall settings on your server
Ensure ports aren't blocked by router
Downloads Not Starting?
bash
# Check if qBittorrent can reach the internet via VPN
docker exec qbittorrent curl -s google.com

# Check Sonarr/Radarr logs
docker logs sonarr | tail -10
docker logs radarr | tail -10
Permission Issues?
bash
# Fix ownership (adjust PUID/PGID for your system)
chown -R 1001:1000 /volume1/docker /volume1/data

# Check current permissions
ls -la /volume1/data/downloads/
🎉 You're Ready!
Once everything is working:

Main Services:
🏠 Homarr Dashboard: http://your-server-ip:7575 (overview of everything)
🎬 Plex Media Server: http://your-server-ip:32400/web (watch your content)
📱 Overseerr: http://your-server-ip:5055 (request new content)
📊 Tautulli: http://your-server-ip:8181 (viewing statistics)
Family Usage:
Family requests content via Overseerr on their phones
System automatically downloads and organizes everything
Content appears in Plex ready for streaming
You monitor everything via Homarr dashboard
📚 Next Steps
Optional Enhancements
Add Indexers: Configure Prowlarr with your preferred torrent sites
Quality Profiles: Set up quality preferences in Sonarr/Radarr
Notifications: Set up Discord/Slack webhooks for download notifications
Subtitles: Configure Bazarr for automatic subtitle downloads
FileBot License: Purchase license for advanced file processing features
Regular Maintenance
Check VPN protection: Occasionally verify downloads are VPN-protected
Monitor disk space: Keep an eye on storage usage
Update containers: Watchtower handles this automatically
Health monitoring: Use ./scripts/health-check.sh if available
🆘 Need Help?
Check the main README.md for detailed information
Review TROUBLESHOOTING.md for common issues
Read COMMUNITY_IMPACT.md to understand the project's vision and value
Open a GitHub Issue for bugs
Join GitHub Discussions for questions
Total Setup Time: ~30 minutes for basic functionality

Result: Complete automated media server with VPN-protected downloads, request management, and streaming ready for your family to enjoy!

Happy streaming! 🎬


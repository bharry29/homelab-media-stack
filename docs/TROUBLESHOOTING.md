# Troubleshooting Guide

This guide covers common issues and their solutions for the Homelab Media Stack.

## 🚨 Quick Diagnosis Commands

### Check All Services Status
```bash
# Check all containers
docker ps -a

# Check specific stack
docker-compose --env-file .env-servarr -f docker-compose-servarr.yml ps
docker-compose --env-file .env-streamarr -f docker-compose-streamarr.yml ps

# Check Docker networks
docker network ls | grep -E "(servarr|streamarr)"
```

### Check Logs
```bash
# View logs for specific service
docker logs [container-name]

# Follow logs in real-time
docker logs -f [container-name]

# View last 50 lines
docker logs --tail 50 [container-name]
```

### Check Resource Usage
```bash
# Check disk space
df -h

# Check docker disk usage
docker system df

# Check container resource usage
docker stats
```

## 🔧 Common Issues & Solutions

### 1. VPN Connection Issues

#### Problem: VPN won't connect
```bash
# Check Gluetun logs
docker logs gluetun

# Common error messages:
# - "authentication failed"
# - "connection timeout"
# - "TLS handshake failed"
```

**Solutions:**
```bash
# 1. Verify VPN credentials
nano .env-servarr
# Check OPENVPN_USER and OPENVPN_PASSWORD

# 2. Try different server location
# Edit .env-servarr:
SERVER_COUNTRIES=Germany
# Or try: United States, Canada, United Kingdom

# 3. Check VPN provider status
# Visit your VPN provider's status page

# 4. Restart Gluetun
docker restart gluetun

# 5. Check supported providers
# https://github.com/qdm12/gluetun/wiki
```

#### Problem: Download clients can't connect to internet
```bash
# Test internet connectivity from qBittorrent
docker exec qbittorrent curl -s ifconfig.me

# Should show VPN IP, not your real IP
```

**Solutions:**
```bash
# 1. Wait for VPN to fully connect
docker logs gluetun | grep "You are running"

# 2. Check Gluetun health
docker inspect gluetun | grep -A 10 "Health"

# 3. Restart dependent services
docker restart qbittorrent sabnzbd prowlarr
```

#### Problem: VPN keeps disconnecting
```bash
# Check for connection drops
docker logs gluetun | grep -i "disconnect\|error\|timeout"
```

**Solutions:**
```bash
# 1. Try different VPN protocol
# Edit .env-servarr:
VPN_TYPE=wireguard  # or openvpn

# 2. Increase health check duration
HEALTH_VPN_DURATION_INITIAL=120s

# 3. Try different server location
SERVER_COUNTRIES=Netherlands,Germany,Canada

# 4. Check provider-specific settings
# Each VPN provider may have unique requirements
```

### 2. Permission Issues

#### Problem: "Permission denied" errors
```bash
# Check logs for permission errors
docker logs sonarr | grep -i permission
docker logs radarr | grep -i permission
```

**Solutions:**
```bash
# 1. Check current ownership
ls -la /volume1/docker/
ls -la /volume1/data/

# 2. Fix ownership (adjust PUID:PGID as needed)
sudo chown -R 1001:1000 /volume1/docker/
sudo chown -R 1001:1000 /volume1/data/

# 3. Fix permissions
sudo chmod -R 755 /volume1/docker/
sudo chmod -R 755 /volume1/data/

# 4. Verify PUID/PGID in environment files
grep -E "PUID|PGID" .env-servarr .env-streamarr

# 5. Find your actual user ID
id $(whoami)
```

#### Problem: FileBot can't process files
```bash
# Check FileBot logs
docker logs filebot-watcher

# Common errors:
# - "Permission denied"
# - "Cannot create directory"
# - "Failed to move file"
```

**Solutions:**
```bash
# 1. Check download completion directory
ls -la /volume1/data/downloads/complete/

# 2. Check media output directory
ls -la /volume1/data/media/

# 3. Manually test FileBot
docker exec filebot-watcher filebot -script fn:amc \
  /data_path/downloads/complete --output /media_data_path --action TEST

# 4. Check FileBot license
docker exec filebot-node filebot --license

# 5. Check file ownership in downloads
sudo chown -R 1001:1000 /volume1/data/downloads/
```

### 3. Network & Connectivity Issues

#### Problem: Docker network conflicts during setup
```bash
# Check for existing networks
docker network ls | grep -E "(servarr|streamarr)"

# Check if networks are in use
docker network inspect servarr-network
docker network inspect streamarr-network
```

**Solutions:**
```bash
# 1. Remove conflicting networks (if no containers are attached)
docker network rm servarr-network
docker network rm streamarr-network

# 2. Let Docker Compose recreate networks
docker-compose --env-file .env-servarr -f docker-compose-servarr.yml up -d
docker-compose --env-file .env-streamarr -f docker-compose-streamarr.yml up -d

# 3. Use the setup script which handles conflicts automatically
./scripts/setup.sh

# 4. Complete cleanup and restart
./scripts/uninstall.sh
./scripts/setup.sh
```

#### Problem: Can't access web interfaces
```bash
# Check if containers are running
docker ps | grep -E "(sonarr|radarr|plex|overseerr)"

# Check port bindings
docker port sonarr
docker port plex
```

**Solutions:**
```bash
# 1. Check firewall settings
sudo ufw status

# If using UFW, allow ports:
sudo ufw allow 8989  # Sonarr
sudo ufw allow 7878  # Radarr
sudo ufw allow 32400 # Plex
sudo ufw allow 5055  # Overseerr

# 2. Check if ports are in use
netstat -tulpn | grep -E "(8989|7878|32400|5055)"

# 3. Test local connectivity
curl -I http://localhost:8989
curl -I http://localhost:32400

# 4. Check Docker networks
docker network ls
docker network inspect servarr-network
docker network inspect streamarr-network

# 5. Find your server IP
hostname -I | awk '{print $1}'
```

#### Problem: Services can't communicate with each other
```bash
# Test connectivity between services
docker exec sonarr ping 172.39.0.2  # Ping Gluetun
docker exec overseerr ping $(hostname -I | awk '{print $1}')  # Ping to host services
```

**Solutions:**
```bash
# 1. Check network configuration
docker network inspect servarr-network
docker network inspect streamarr-network

# 2. Recreate networks if needed
docker network rm servarr-network streamarr-network
# Docker Compose will recreate networks automatically on next deployment
docker-compose --env-file .env-servarr -f docker-compose-servarr.yml up -d
docker-compose --env-file .env-streamarr -f docker-compose-streamarr.yml up -d

# 3. Restart services
docker-compose --env-file .env-servarr -f docker-compose-servarr.yml restart
docker-compose --env-file .env-streamarr -f docker-compose-streamarr.yml restart

# 4. Check internal DNS resolution
docker exec sonarr nslookup gluetun
```

### 4. Plex Issues

#### Problem: Plex won't start
```bash
# Check Plex logs
docker logs plex

# Common issues:
# - "Claim token expired"
# - "Permission denied"
# - "Hardware device not found"
```

**Solutions:**
```bash
# 1. Check/refresh Plex claim token
# Get new token from: https://plex.tv/claim
# Update .env-streamarr with new token (token expires in 4 minutes)

# 2. Remove hardware transcoding if not supported
# Edit docker-compose-streamarr.yml, comment out:
# devices:
#   - /dev/dri:/dev/dri

# 3. Check Plex advertise URL
grep PLEX_ADVERTISE_URL .env-streamarr
# Should match your server's actual IP

# 4. Manual Plex setup (if claim token issues)
# Remove PLEX_CLAIM_TOKEN from environment
# Access http://your-server-ip:32400/web
# Complete setup manually

# 5. Check container networking
docker exec plex ping google.com
```

#### Problem: Plex libraries empty or not scanning
```bash
# Check media directories
ls -la /volume1/data/media/movies/
ls -la /volume1/data/media/tv/

# Check Plex library paths in web interface
# Settings → Libraries → [Library Name] → Edit
```

**Solutions:**
```bash
# 1. Verify media files exist
find /volume1/data/media/ -type f -name "*.mkv" -o -name "*.mp4" | head -10

# 2. Check Plex library paths should point to:
# Movies: /data/media/movies
# TV: /data/media/tv
# Music: /data/media/music

# 3. Force library scan
# In Plex web interface: Settings → Libraries → [Library] → Scan Library Files

# 4. Check FileBot processing
docker logs filebot-watcher | tail -20

# 5. Manually trigger Plex scan
docker exec plex '/usr/lib/plexmediaserver/Plex Media Scanner' --scan --refresh --section 1

# 6. Check file permissions
ls -la /volume1/data/media/movies/
# Files should be readable by PUID:PGID
```

#### Problem: Remote access not working
```bash
# Check Plex network settings
docker logs plex | grep -i "remote\|network"
```

**Solutions:**
```bash
# 1. Check PLEX_ADVERTISE_URL
echo $PLEX_ADVERTISE_URL
# Should be: http://YOUR_REAL_IP:32400

# 2. Check firewall/router
# Port 32400 must be open for remote access
sudo ufw allow 32400

# 3. Check Plex settings
# Settings → Remote Access → Enable Remote Access

# 4. Check no-auth networks
grep PLEX_NO_AUTH_NETWORKS .env-streamarr
# Should include your local network: 192.168.1.0/24

# 5. Test external connectivity
curl -I http://your-external-ip:32400
```

### 5. Download Issues

#### Problem: Downloads not starting
```bash
# Check qBittorrent logs
docker logs qbittorrent

# Check Sonarr/Radarr logs for download attempts
docker logs sonarr | grep -i download
docker logs radarr | grep -i download
```

**Solutions:**
```bash
# 1. Check indexers in Prowlarr
# Access: http://your-server-ip:9696
# Test indexers: Indexers → Test All

# 2. Check download client connection in *arr apps
# In Sonarr/Radarr: Settings → Download Clients
# Test qBittorrent connection (should use 172.39.0.2:8080)

# 3. Check qBittorrent settings
# Access: http://your-server-ip:8080
# Downloads → Save files to: /data/downloads/incomplete
# Downloads → Copy completed downloads to: /data/downloads/complete

# 4. Verify VPN IP from download client
docker exec qbittorrent curl -s ifconfig.me

# 5. Check indexer connectivity through VPN
docker exec prowlarr curl -s ifconfig.me
```

#### Problem: Downloads stuck or very slow
```bash
# Check qBittorrent status
# Access web interface: http://your-server-ip:8080
# Check transfer tab for active torrents
```

**Solutions:**
```bash
# 1. Check VPN server performance
# Try different VPN location in .env-servarr:
SERVER_COUNTRIES=Germany,Netherlands,United States
# Restart Gluetun after change

# 2. Configure port forwarding (if VPN supports it)
# Edit .env-servarr:
FIREWALL_VPN_INPUT_PORTS=51820
# Check with your VPN provider for port forwarding support

# 3. Check download client limits
# In qBittorrent: Tools → Options → Speed
# Remove or increase speed limits

# 4. Check disk space
df -h /volume1/data/

# 5. Check indexer quality and availability
# Use multiple indexers for better results
```

### 6. FileBot Processing Issues

#### Problem: Files not being processed automatically
```bash
# Check FileBot Watcher logs
docker logs filebot-watcher

# Check if files exist in completion directory
ls -la /volume1/data/downloads/complete/
```

**Solutions:**
```bash
# 1. Check FileBot license
docker exec filebot-node filebot --license

# 2. Test manual processing
docker exec filebot-watcher filebot -script fn:amc \
  "/data_path/downloads/complete" \
  --output "/media_data_path/" \
  --action TEST \
  --log-file amc.log

# 3. Check file permissions
ls -la /volume1/data/downloads/complete/
ls -la /volume1/data/media/

# 4. Restart FileBot services
docker restart filebot-watcher filebot-node

# 5. Check FileBot configuration
# Access FileBot Node: http://your-server-ip:5452
# Check AMC script configuration

# 6. Manual file processing via web interface
# Use FileBot Node web interface for manual processing
```

#### Problem: Wrong file organization or naming
```bash
# Check FileBot processing results
docker logs filebot-watcher | grep -A 5 -B 5 "MOVE\|COPY"
```

**Solutions:**
```bash
# 1. Check FileBot command configuration
# Edit docker-compose-servarr.yml
# Modify filebot-watcher command section for custom formats

# 2. Test with specific format
docker exec filebot-watcher filebot -rename \
  "/data_path/downloads/complete/test-file.mkv" \
  --format "{n} ({y})" \
  --action TEST

# 3. Use FileBot Node for manual processing
# Access: http://your-server-ip:5452
# Process files with custom formats

# 4. Check AMC exclude list
docker exec filebot-watcher cat /data/amc-exclude-list.txt

# 5. Verify movie/TV detection
# FileBot needs proper file naming to detect content type
```

### 7. Service Integration Issues

#### Problem: Overseerr can't connect to Sonarr/Radarr
```bash
# Check Overseerr logs
docker logs overseerr | grep -i "sonarr\|radarr\|connection"
```

**Solutions:**
```bash
# 1. Use correct connection URLs in Overseerr
# Sonarr: http://your-server-ip:8989
# Radarr: http://your-server-ip:7878
# NOT the container IPs (those are for internal communication)

# 2. Get API keys from Sonarr/Radarr
# Settings → General → Security → API Key

# 3. Test connectivity from Overseerr container
docker exec overseerr curl -I http://your-server-ip:8989
docker exec overseerr curl -I http://your-server-ip:7878

# 4. Check if services are running and accessible
docker ps | grep -E "(sonarr|radarr)"
curl -I http://localhost:8989/api/v3/system/status

# 5. Verify network connectivity
# All services should be able to reach each other via host networking
```

#### Problem: Prowlarr not syncing with *arr apps
```bash
# Check Prowlarr logs
docker logs prowlarr | grep -i "sync\|app"
```

**Solutions:**
```bash
# 1. Add applications in Prowlarr
# Settings → Apps → Add Application
# Use full URLs: http://your-server-ip:8989 (Sonarr)

# 2. Check API keys match
# Compare keys in Prowlarr Apps settings with Sonarr/Radarr General settings

# 3. Test sync manually
# Settings → Apps → [App] → Test and Save
# Then: Settings → Apps → Sync App Indexers

# 4. Check app connectivity
# Prowlarr should be able to reach *arr apps through VPN
docker exec prowlarr curl -I http://your-server-ip:8989

# 5. Manual indexer addition fallback
# Add indexers individually in each *arr application if sync fails
```

## 🔄 Recovery Procedures

### Complete Stack Reset
```bash
# 1. Stop all services
docker-compose --env-file .env-servarr -f docker-compose-servarr.yml down
docker-compose --env-file .env-streamarr -f docker-compose-streamarr.yml down

# 2. Remove containers (optional - keeps data)
docker system prune -f

# 3. Restart services
docker-compose --env-file .env-servarr -f docker-compose-servarr.yml up -d
# Wait for VPN connection
docker-compose --env-file .env-streamarr -f docker-compose-streamarr.yml up -d
```

### Database Corruption Recovery
```bash
# 1. Stop affected service
docker stop sonarr

# 2. Backup current database
cp /volume1/docker/servarr/sonarr/sonarr.db /volume1/docker/servarr/sonarr/sonarr.db.backup

# 3. Try database repair (if sqlite3 installed)
sqlite3 /volume1/docker/servarr/sonarr/sonarr.db "PRAGMA integrity_check;"

# 4. If corrupted, restore from backup or start fresh
# rm /volume1/docker/servarr/sonarr/sonarr.db
# docker start sonarr
```

### Network Issues Recovery
```bash
# 1. Remove and recreate Docker networks
docker network rm servarr-network streamarr-network

# 2. Recreate networks
docker network create --driver bridge --subnet=172.39.0.0/24 servarr-network
docker network create --driver bridge --subnet=172.40.0.0/24 streamarr-network

# 3. Restart all services
docker-compose --env-file .env-servarr -f docker-compose-servarr.yml down
docker-compose --env-file .env-streamarr -f docker-compose-streamarr.yml down
docker-compose --env-file .env-servarr -f docker-compose-servarr.yml up -d
docker-compose --env-file .env-streamarr -f docker-compose-streamarr.yml up -d
```

## 📊 Monitoring & Maintenance

### Health Check Script
```bash
#!/bin/bash
# health-check.sh - Run weekly

echo "=== Container Status ==="
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

echo -e "\n=== Disk Usage ==="
df -h /volume1/

echo -e "\n=== VPN Status ==="
docker exec gluetun curl -s ifconfig.me
echo " (VPN IP)"

echo -e "\n=== Recent Errors ==="
docker logs --since 24h gluetun 2>&1 | grep -i error | tail -5
docker logs --since 24h sonarr 2>&1 | grep -i error | tail -5
docker logs --since 24h radarr 2>&1 | grep -i error | tail -5
```

### Performance Monitoring
```bash
# Check resource usage
docker stats --no-stream

# Check network usage
sudo iftop

# Check file system I/O
sudo iotop -ao

# Check directory sizes
du -sh /volume1/docker/*/
du -sh /volume1/data/*/
```

## 📞 Getting Help

### Log Collection for Support
```bash
# Create support bundle
mkdir support-logs-$(date +%Y%m%d)
cd support-logs-$(date +%Y%m%d)

# System info
uname -a > system-info.txt
docker version >> system-info.txt
docker-compose version >> system-info.txt

# Container logs (last 100 lines)
docker logs --tail 100 gluetun > gluetun.log 2>&1
docker logs --tail 100 sonarr > sonarr.log 2>&1
docker logs --tail 100 radarr > radarr.log 2>&1
docker logs --tail 100 plex > plex.log 2>&1
docker logs --tail 100 overseerr > overseerr.log 2>&1

# Configuration (REMOVE SENSITIVE DATA before sharing!)
cp ../.env-servarr env-servarr.txt
cp ../.env-streamarr env-streamarr.txt
# IMPORTANT: Edit these files to remove VPN credentials and personal info!

# Container status
docker ps -a > container-status.txt

# Network info
docker network ls > networks.txt
docker network inspect servarr-network > servarr-network.txt
docker network inspect streamarr-network > streamarr-network.txt

# Create archive
cd ..
tar -czf support-logs-$(date +%Y%m%d).tar.gz support-logs-$(date +%Y%m%d)/

echo "Support bundle created: support-logs-$(date +%Y%m%d).tar.gz"
echo "REMEMBER: Remove sensitive data before sharing!"
```

### Community Resources
- **GitHub Issues**: [Report bugs and get help](https://github.com/yourusername/homelab-media-stack/issues)
- **GitHub Discussions**: [Community Q&A](https://github.com/yourusername/homelab-media-stack/discussions)
- **Reddit Communities**: r/selfhosted, r/PleX, r/sonarr, r/radarr
- **Discord Communities**: Various homelab and self-hosted communities

## 🎯 Prevention Tips

1. **Regular Backups**: Backup configurations weekly
2. **Monitor Disk Space**: Set alerts for low disk space (< 10GB free)
3. **Update Regularly**: Use Watchtower or manual updates monthly
4. **Monitor Logs**: Check logs weekly for early warning signs
5. **Test Connectivity**: Periodically test VPN and service connectivity
6. **Document Changes**: Keep notes of configuration changes
7. **Health Checks**: Run the health check script weekly

## 🔍 Debug Mode

### Enable Debug Logging
```bash
# Enable debug mode for specific services
# Edit docker-compose files and add:
# environment:
#   - LOG_LEVEL=debug

# For Gluetun VPN debugging:
# Edit .env-servarr:
VPN_LOG_LEVEL=debug

# Restart services after changes
docker-compose --env-file .env-servarr -f docker-compose-servarr.yml restart gluetun
```

### Advanced Debugging
```bash
# Enter container for debugging
docker exec -it gluetun /bin/sh
docker exec -it sonarr /bin/bash

# Check network connectivity from inside container
docker exec gluetun ping google.com
docker exec gluetun curl -s ifconfig.me

# Check file system from inside container
docker exec sonarr ls -la /data/
docker exec filebot-watcher ls -la /data_path/downloads/complete/
```

Remember: Most issues are related to permissions, networking, or VPN connectivity. Start with these basics when troubleshooting!
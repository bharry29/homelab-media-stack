# Scripts Directory

This directory contains utility scripts for maintaining your Homelab Media Stack.

## 📁 Available Scripts

### 🛡️ `health-check.sh`
**Purpose**: Monitor system health and VPN protection

**Usage:**
```bash
# Basic health check
./scripts/health-check.sh

# Detailed diagnostics
./scripts/health-check.sh --verbose

# Automated monitoring (for cron)
./scripts/health-check.sh --quiet

# Send results to Discord/Slack
./scripts/health-check.sh --webhook https://your-webhook-url
```

**Features:**
- ✅ VPN leak detection (critical for privacy)
- ✅ Container health monitoring
- ✅ Resource usage tracking
- ✅ Webhook notifications
- ✅ Exit codes for automation

**Automation Example:**
```bash
# Add to crontab for automated monitoring
*/15 * * * * /path/to/homelab-media-stack/scripts/health-check.sh --quiet
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
- ✅ Configuration file backups
- ✅ Service database backups (Plex, Sonarr, Radarr, etc.)
- ✅ FileBot license and configuration
- ✅ Automatic cleanup of old backups
- ✅ Backup verification and restoration info

**What Gets Backed Up:**
- **Config Only**: Environment files, Docker configs, scripts (~100MB)
- **Full Backup**: Everything above + databases + metadata (~1-5GB)

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

### Directory Creation
```bash
# Create all required directories
mkdir -p /volume1/docker/{servarr,streamarr}
mkdir -p /volume1/data/{downloads/{complete,incomplete},media/{movies,tv,music},plex_transcode}

# Set permissions
chown -R 1001:1000 /volume1/docker /volume1/data
```

### Network Setup
```bash
# Create Docker networks
docker network create --driver bridge --subnet=172.39.0.0/24 servarr-network
docker network create --driver bridge --subnet=172.40.0.0/24 streamarr-network
```

## 🎯 Why This Approach?

**Simplified Philosophy:**
- ✅ **Keep high-value scripts** that solve complex problems
- ✅ **Remove setup complexity** that Docker handles automatically
- ✅ **Focus on monitoring and maintenance** where scripts add real value
- ✅ **Make the project approachable** for all skill levels

**The real magic is in the Docker Compose architecture, not setup scripts!**
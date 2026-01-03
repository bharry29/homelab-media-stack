# Directory Structure & Data Flow Guide

This guide explains the complete directory structure and data flow for the Homelab Media Stack, helping you understand how files move through the system and where everything is stored.

## 📁 Complete Directory Structure

### Base Directory Layout
```
/volume1/                               # Base path (customizable)
├── docker/                            # Docker configurations
│   ├── servarr/                       # Download & management configs
│   ├── streamarr/                     # Streaming & request configs
│   ├── creatarr/                      # Creative content & entertainment configs
│   ├── business/                      # Business & productivity configs
│   └── infrastructure/               # System management configs
└── data/                              # Shared media & downloads
    ├── downloads/                     # Download staging area
    ├── media/                         # Organized media library
    ├── plex_transcode/                # Plex transcoding cache
    ├── roms/                          # RetroArch game ROMs
    ├── comics/                        # Komga comic library
    ├── audiobooks/                    # Audiobookshelf audiobook library
    ├── podcasts/                      # Audiobookshelf podcast library
    ├── books/                         # Calibre-Web ebook library
    ├── recipes/                       # Mealie recipe files
    └── saves/                         # RetroArch save files
```

### Detailed Structure
```
/volume1/
├── docker/                            # Container configurations
│   ├── servarr/                       # SERVARR STACK CONFIGS
│   │   ├── gluetun/                   # VPN configuration & logs
│   │   │   ├── gluetun.conf           # OpenVPN configuration
│   │   │   └── logs/                  # VPN connection logs
│   │   ├── qbittorrent/               # BitTorrent client config
│   │   │   ├── qBittorrent.conf       # Client settings
│   │   │   ├── BT_backup/             # Torrent state backups
│   │   │   └── logs/                  # Download logs
│   │   ├── sabnzbd/                   # Usenet client config
│   │   │   ├── sabnzbd.ini            # Client configuration
│   │   │   ├── admin/                 # Web interface settings
│   │   │   └── logs/                  # Processing logs
│   │   ├── prowlarr/                  # Indexer management
│   │   │   ├── prowlarr.db            # Indexer database
│   │   │   ├── config.xml             # Application settings
│   │   │   └── logs/                  # Search & sync logs
│   │   ├── sonarr/                    # TV show automation
│   │   │   ├── sonarr.db              # TV show database
│   │   │   ├── config.xml             # App configuration
│   │   │   ├── MediaCover/            # Series artwork cache
│   │   │   └── logs/                  # Activity logs
│   │   ├── radarr/                    # Movie automation
│   │   │   ├── radarr.db              # Movie database
│   │   │   ├── config.xml             # App configuration
│   │   │   ├── MediaCover/            # Movie artwork cache
│   │   │   └── logs/                  # Activity logs
│   │   ├── lidarr/                    # Music automation
│   │   │   ├── lidarr.db              # Music database
│   │   │   ├── config.xml             # App configuration
│   │   │   └── logs/                  # Processing logs
│   │   ├── bazarr/                    # Subtitle management
│   │   │   ├── bazarr.db              # Subtitle database
│   │   │   ├── config/                # Configuration files
│   │   │   └── logs/                  # Subtitle logs
│   ├── infrastructure/                # INFRASTRUCTURE STACK CONFIGS
│   │   ├── homarr/                    # Dashboard configuration
│   │   │   ├── configs/               # Dashboard settings
│   │   │   │   ├── default.json       # Default dashboard config
│   │   │   │   └── [user].json        # User-specific configs
│   │   │   ├── icons/                 # Custom service icons
│   │   │   └── data/                  # Dashboard data
│   │   └── uptime-kuma/               # System monitoring
│   │       └── data/                  # Monitoring database
│   ├── streamarr/                     # STREAMARR STACK CONFIGS
│   │   ├── plex/                      # Plex Media Server config
│       │   ├── Library/               # Plex database & metadata
│       │   │   ├── Application Support/
│       │   │   │   └── Plex Media Server/
│       │   │   │       ├── Plug-in Support/ # Plugins & agents
│       │   │   │       ├── Media/           # Metadata cache
│       │   │   │       ├── Metadata/        # Movie/TV metadata
│       │   │   │       └── Databases/       # Plex databases
│       │   ├── Logs/                  # Plex server logs
│       │   └── Crash Reports/         # Error reports
│       ├── overseerr/                 # Request management
│       │   ├── db/                    # Request database
│       │   ├── config/                # App configuration
│       │   └── logs/                  # Request logs
│       ├── tautulli/                  # Analytics & monitoring
│       │   ├── tautulli.db            # Analytics database
│       │   ├── config.ini             # App settings
│       │   ├── cache/                 # Cached data
│       │   └── logs/                  # Analytics logs
│       └── ersatztv/                  # Virtual TV channels
│           ├── ersatztv.db            # Channel database
│           ├── cache/                 # EPG & metadata cache
│           └── logs/                  # Channel logs
│   ├── business/                      # BUSINESS STACK CONFIGS
│   │   ├── n8n/                       # n8n workflow automation
│   │   │   ├── config/                 # n8n configuration
│   │   │   │   ├── config.json         # Main config file
│   │   │   │   └── encryptionKey       # Encryption key for HTTPS
│   │   │   ├── workflows/              # Saved workflows
│   │   │   └── logs/                   # Workflow execution logs
│   │   ├── n8n-postgres/               # n8n database
│   │   │   ├── postgresql/             # PostgreSQL data
│   │   │   └── logs/                   # Database logs
│   │   ├── mealie/                     # Mealie recipe management
│   │   │   ├── data/                   # Recipe database & files
│   │   │   └── logs/                   # Recipe logs
│   │   └── mealie-db/                  # Mealie database
│   │       └── postgresql/             # PostgreSQL data
│   └── creatarr/                      # CREATARR STACK CONFIGS
│       ├── retroarch/                  # RetroArch gaming emulator
│       │   ├── config/                 # Emulator configuration
│       │   ├── saves/                  # Game save files
│       │   └── states/                  # Game state files
│       ├── komga/                      # Komga comic server
│       │   ├── config/                 # Server configuration
│       │   ├── database/               # Comic database
│       │   └── logs/                    # Server logs
│       ├── audiobookshelf/             # Audiobookshelf server
│       │   ├── config/                 # Server configuration
│       │   ├── metadata/               # Metadata database
│       │   └── logs/                    # Server logs
│       ├── calibre-web/                # Calibre-Web e-book server
│       │   ├── config/                 # Server configuration
│       │   ├── database/               # E-book database
│       │   └── logs/                    # Server logs
│       ├── noisedash/                  # Noisedash ambient sounds
│       │   └── data/                    # Sound library
│       └── swing-music/                # Swing Music player
│           ├── config/                 # Player configuration
│           └── data/                    # Music library
│       │   ├── database/               # Audiobook database
│       │   └── logs/                   # Library logs
│       └── calibre-web/                # Calibre-Web ebook library
│           ├── config/                 # Library configuration
│           ├── database/               # Ebook database
│           └── logs/                    # Library logs
└── data/                              # SHARED DATA VOLUME
    ├── downloads/                     # Download staging area
    │   ├── complete/                  # Completed downloads (FileBot input)
    │   │   ├── movies/                # Completed movie downloads
    │   │   │   └── Movie.Name.2023.1080p.BluRay.x264/
    │   │   │       ├── Movie.Name.2023.1080p.BluRay.x264.mkv
    │   │   │       ├── Movie.Name.2023.1080p.BluRay.x264.nfo
    │   │   │       └── Subs/          # Subtitle files
    │   │   ├── tv/                    # Completed TV downloads
    │   │   │   └── Show.Name.S01E01.1080p.WEB.x264/
    │   │   │       ├── Show.Name.S01E01.1080p.WEB.x264.mkv
    │   │   │       └── Show.Name.S01E01.1080p.WEB.x264.nfo
    │   │   └── music/                 # Completed music downloads
    │   │       └── Artist.Name.Album.Name.2023.FLAC/
    │   └── incomplete/                # In-progress downloads
    │       ├── [partial files]        # qBittorrent/SABnzbd temp files
    │       └── [extraction dirs]/     # SABnzbd extraction directories
    ├── media/                         # Organized media library (FileBot output)
    │   ├── movies/                    # Movie library (Plex source)
    │   │   ├── Action/                # Genre-based organization (optional)
    │   │   │   └── Movie Name (2023)/
    │   │   │       ├── Movie Name (2023).mkv
    │   │   │       ├── Movie Name (2023).nfo
    │   │   │       ├── poster.jpg     # Movie poster
    │   │   │       ├── fanart.jpg     # Background art
    │   │   │       └── Subs/          # Subtitle files
    │   │   │           ├── Movie Name (2023).en.srt
    │   │   │           └── Movie Name (2023).es.srt
    │   │   ├── Comedy/                # Another genre folder
    │   │   └── Drama/                 # Yet another genre folder
    │   ├── tv/                        # TV show library (Plex source)
    │   │   ├── Series Name (2020)/    # Individual show folders
    │   │   │   ├── Season 01/         # Season-based organization
    │   │   │   │   ├── Series Name (2020) - S01E01 - Episode Title.mkv
    │   │   │   │   ├── Series Name (2020) - S01E02 - Episode Title.mkv
    │   │   │   │   └── metadata/      # Episode metadata
    │   │   │   ├── Season 02/
    │   │   │   │   └── [episodes]
    │   │   │   ├── series.nfo         # Show metadata
    │   │   │   ├── poster.jpg         # Show poster
    │   │   │   └── fanart.jpg         # Show background
    │   │   └── Another Series (2021)/
    │   └── music/                     # Music library (Plex source)
    │       ├── Artist Name/           # Artist-based organization
    │       │   ├── Album Name (2023)/ # Album folders
    │       │   │   ├── 01 - Track Name.flac
    │       │   │   ├── 02 - Track Name.flac
    │       │   │   ├── album.nfo      # Album metadata
    │       │   │   └── folder.jpg     # Album artwork
    │       │   └── Another Album (2022)/
    │       └── Another Artist/
    ├── plex_transcode/                # Plex transcoding cache
    │   ├── Sessions/                  # Active transcoding sessions
    │   │   └── [session-id]/          # Individual transcode sessions
    │   └── Updates/                   # Plex update cache
    ├── roms/                          # RetroArch game ROMs
    │   ├── nes/                       # NES ROMs
    │   ├── snes/                      # SNES ROMs
    │   ├── genesis/                   # Sega Genesis ROMs
    │   ├── psx/                       # PlayStation ROMs
    │   └── [other-consoles]/          # Other console ROMs
    ├── comics/                        # Komga comic library
    │   ├── [series]/                  # Comic series folders
    │   │   ├── [issue]/               # Individual issues
    │   │   │   ├── cover.jpg          # Issue cover
    │   │   │   └── pages/              # Comic pages
    │   │   └── series.nfo             # Series metadata
    │   └── [other-series]/            # Other comic series
    ├── audiobooks/                    # Audiobookshelf audiobook library
    │   ├── [author]/                  # Author folders
    │   │   ├── [book]/                # Book folders
    │   │   │   ├── [chapters]/        # Audio chapters
    │   │   │   ├── cover.jpg          # Book cover
    │   │   │   └── metadata.nfo       # Book metadata
    │   │   └── [other-books]/         # Other books by author
    │   └── [other-authors]/           # Other authors
    ├── podcasts/                      # Audiobookshelf podcast library
    │   ├── [podcast]/                 # Podcast folders
    │   │   ├── [episodes]/            # Podcast episodes
    │   │   ├── cover.jpg              # Podcast cover
    │   │   └── feed.xml               # RSS feed
    │   └── [other-podcasts]/          # Other podcasts
    ├── books/                         # Calibre-Web ebook library
    │   ├── [author]/                  # Author folders
    │   │   ├── [book]/                # Book folders
    │   │   │   ├── book.epub          # Ebook file
    │   │   │   ├── cover.jpg          # Book cover
    │   │   │   └── metadata.opf       # Book metadata
    │   │   └── [other-books]/         # Other books by author
    │   └── [other-authors]/           # Other authors
    ├── recipes/                       # Mealie recipe files
    │   ├── [recipe-name]/             # Recipe folders
    │   │   ├── recipe.json            # Recipe data
    │   │   ├── image.jpg              # Recipe image
    │   │   └── notes.txt              # Recipe notes
    │   └── [other-recipes]/           # Other recipes
    └── saves/                         # RetroArch save files
        ├── [game-name]/               # Game save folders
        │   ├── save.srm               # Save state
        │   ├── savestate.sav          # Quick save
        │   └── screenshot.png         # Game screenshot
        └── [other-games]/             # Other game saves
```

## 🔄 Data Flow Process

### Complete Workflow Overview
```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   User Request  │    │   Content Search │    │   Download      │
│   (Overseerr)   │───▶│   (Prowlarr +    │───▶│   (qBittorrent/ │
│                 │    │    Indexers)     │    │    SABnzbd)     │
└─────────────────┘    └──────────────────┘    └─────────────────┘
                                                        │
                                                        ▼
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│  Media Serving  │    │ File Processing  │    │ Download        │
│     (Plex)      │◀───│    (FileBot)     │◀───│  Completion     │
│                 │    │                  │    │ /data/downloads/│
└─────────────────┘    └──────────────────┘    │   complete/     │
                                               └─────────────────┘
```

### Detailed Step-by-Step Flow

#### 1. Request Initiation
```
User (Web/Mobile) → Overseerr (Port 5055) → Request Database
                                          ↓
                   Sonarr/Radarr APIs ← Request Processing
```

#### 2. Content Discovery
```
Sonarr/Radarr → Prowlarr API → Indexer Search → Results Ranking
     ↓               ↓              ↓              ↓
  Quality       Indexer Sync    Torrent/NZB    Best Match
  Profiles      Management       Sources       Selection
```

#### 3. Download Process
```
Download Decision → qBittorrent/SABnzbd (via VPN) → /data/downloads/incomplete/
      ↓                    ↓                              ↓
  Quality Check       VPN Tunnel               Partial Files
  & Preferences    (172.39.0.2 network)      & Progress Data
```

#### 4. Download Completion
```
Download Complete → Move to /data/downloads/complete/ → FileBot Watcher Trigger
       ↓                        ↓                            ↓
   File Integrity         Category Sorting              Processing Queue
   Verification         (movies/tv/music)              & Error Handling
```

#### 5. File Processing & Organization
```
FileBot Watcher → Metadata Detection → File Renaming → /data/media/ Organization
       ↓                 ↓                 ↓                    ↓
   File Analysis    TheMovieDB/         Standard          Genre/Year/
   & Recognition     TheTVDB API        Naming Format     Quality Folders
```

#### 6. Media Library Update
```
New Files in /data/media/ → Plex Scanner → Library Update → Content Available
         ↓                       ↓             ↓              ↓
    File Detection         Metadata Fetch   Database      Streaming
    & Monitoring          & Artwork Cache   Update        Ready
```

#### 7. User Access & Analytics
```
Plex Clients → Media Streaming → Tautulli Monitoring → Usage Analytics
     ↓              ↓                    ↓                   ↓
  Web/Mobile    Transcoding         Activity Logging    Reports &
  Interfaces    (if needed)         & Statistics       Notifications
```

## Directory Purpose & Management

### Configuration Directories (`/volume1/docker/`)

#### SERVARR Stack Configs
| Directory | Purpose | Critical Files | Backup Priority |
|-----------|---------|----------------|-----------------|
| `gluetun/` | VPN settings & logs | `gluetun.conf` | Medium |
| `qbittorrent/` | Download client config | `qBittorrent.conf` | High |
| `prowlarr/` | Indexer management | `prowlarr.db` | High |
| `sonarr/` | TV automation | `sonarr.db`, `config.xml` | Critical |
| `radarr/` | Movie automation | `radarr.db`, `config.xml` | Critical |
| `lidarr/` | Music automation | `lidarr.db`, `config.xml` | High |
| `bazarr/` | Subtitle management | `bazarr.db` | Medium |

#### STREAMARR Stack Configs
| Directory | Purpose | Critical Files | Backup Priority |
|-----------|---------|----------------|-----------------|
| `plex/` | Media server database | `Databases/`, `Preferences.xml` | Critical |
| `overseerr/` | Request management | `db/`, `config/` | High |
| `tautulli/` | Analytics & monitoring | `tautulli.db`, `config.ini` | Medium |
| `ersatztv/` | Virtual TV channels | `ersatztv.db` | Low |

### Data Directories (`/volume1/data/`)

#### Downloads (`/data/downloads/`)
- **Purpose**: Temporary storage for download process
- **Management**: Automatic cleanup by FileBot
- **Size**: 50-200GB (adjust based on download speed)
- **Monitoring**: Watch for stuck files and disk space

#### Media Library (`/data/media/`)
- **Purpose**: Final organized media storage
- **Management**: Read-only for most services
- **Size**: Primary storage requirement (1TB+)
- **Monitoring**: Growth rate and quality distribution

#### Transcoding Cache (`/data/plex_transcode/`)
- **Purpose**: Temporary transcoding files
- **Management**: Automatic cleanup by Plex
- **Size**: 20-100GB depending on concurrent streams
- **Monitoring**: Disk I/O and cleanup effectiveness

## Storage Allocation Guidelines

### Minimum Setup (500GB)
```
Docker Configs:      10GB  (2%)
Downloads (active):  50GB  (10%)
Media Library:      400GB  (80%)
Plex Transcoding:    40GB  (8%)
```

### Recommended Setup (2TB+)
```
Docker Configs:      20GB  (1%)
Downloads (active): 200GB  (10%)
Media Library:     1.5TB  (75%)
Plex Transcoding:  100GB  (5%)
Backup Space:      200GB  (9%)
```

### Enterprise Setup (10TB+)
```
Docker Configs:      50GB  (0.5%)
Downloads (active): 500GB  (5%)
Media Library:       8TB  (80%)
Plex Transcoding:   500GB  (5%)
Backup Space:        1TB  (9.5%)
```

## 🔧 Directory Management Best Practices

### Permission Management
```bash
# Set proper ownership for all directories
sudo chown -R 1001:1000 /volume1/docker/
sudo chown -R 1001:1000 /volume1/data/

# Set appropriate permissions
sudo chmod -R 755 /volume1/docker/
sudo chmod -R 755 /volume1/data/

# Verify permissions
ls -la /volume1/docker/
ls -la /volume1/data/
```

### Disk Space Monitoring
```bash
# Check overall disk usage
df -h /volume1/

# Check specific directory sizes
du -sh /volume1/docker/*/
du -sh /volume1/data/*/

# Find large files in downloads
find /volume1/data/downloads/ -size +1G -type f -exec ls -lh {} \;

# Monitor transcoding disk usage
du -sh /volume1/data/plex_transcode/
```

### Cleanup Automation
```bash
# Clean up old transcoding files (if needed)
find /volume1/data/plex_transcode/Sessions/ -mtime +1 -delete

# Clean up failed downloads (manual review recommended)
find /volume1/data/downloads/incomplete/ -mtime +7 -type d

# Clean up empty directories
find /volume1/data/downloads/complete/ -type d -empty -delete
```

## 🗃️ Backup Strategy by Directory

### Critical Backup (Daily)
- **Plex Database**: `/volume1/docker/streamarr/plex/Library/Application Support/Plex Media Server/`
- **Servarr Databases**: `/volume1/docker/servarr/*/[app].db`
- **Configuration Files**: `/volume1/docker/*/config.xml`

### Important Backup (Weekly)
- **Complete Configs**: `/volume1/docker/`
- **Overseerr Data**: `/volume1/docker/streamarr/overseerr/`
- **FileBot Data**: Docker volume `filebot-data`

### Optional Backup (Monthly)
- **Media Metadata**: `/volume1/data/media/*/metadata/`
- **Artwork Cache**: `/volume1/docker/*/MediaCover/`
- **Analytics Data**: `/volume1/docker/streamarr/tautulli/`

### No Backup Needed
- **Downloads**: `/volume1/data/downloads/` (temporary files)
- **Transcoding**: `/volume1/data/plex_transcode/` (cache files)
- **Log Files**: `/volume1/docker/*/logs/` (can be regenerated)

## Troubleshooting by Directory

### Common Directory Issues

#### Permission Problems
```bash
# Symptoms: "Permission denied" errors in logs
# Check: File ownership and permissions
ls -la /volume1/data/downloads/complete/
sudo chown -R 1001:1000 /volume1/data/
```

#### Disk Space Issues
```bash
# Symptoms: Downloads failing, transcoding errors
# Check: Available space
df -h /volume1/
# Clean: Old transcoding files and failed downloads
```

#### FileBot Processing Issues
```bash
# Symptoms: Files not moving from downloads/complete to media
# Check: FileBot logs and file permissions
docker logs filebot-watcher
ls -la /volume1/data/downloads/complete/
```

#### Plex Library Issues
```bash
# Symptoms: Media not appearing in Plex
# Check: File organization and Plex library paths
ls -la /volume1/data/media/movies/
# Verify Plex library points to /data/media/movies
```

### Directory Health Monitoring
```bash
# Create a health check script
#!/bin/bash
echo "=== Directory Health Check ==="
echo "Total Space: $(df -h /volume1/ | tail -1 | awk '{print $2 " used: " $3 " available: " $4}')"
echo "Config Size: $(du -sh /volume1/docker/ | awk '{print $1}')"
echo "Downloads: $(du -sh /volume1/data/downloads/ | awk '{print $1}')"
echo "Media Library: $(du -sh /volume1/data/media/ | awk '{print $1}')"
echo "Recent Files: $(find /volume1/data/media/ -mtime -1 -type f | wc -l) files added today"
```

This directory structure provides a solid foundation for understanding how your media automation system organizes and processes files efficiently.
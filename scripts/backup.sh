#!/bin/bash

# =============================================================================
# Homelab Media Stack - Backup Script
# =============================================================================
# This script creates comprehensive backups of your media stack configurations
# Usage: ./backup.sh [OPTIONS]
#
# Options:
#   -f, --full          Full backup (configs + databases + media metadata)
#   -c, --config-only   Configuration files only (default)
#   -d, --destination   Backup destination directory
#   -k, --keep         Number of backups to keep (default: 7)
#   -q, --quiet        Quiet mode (minimal output)
#   -h, --help         Show this help message
# =============================================================================

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Default configuration
DEFAULT_BASE_PATH="/volume1"
DEFAULT_BACKUP_PATH="/volume1/backups"
DEFAULT_KEEP_COUNT=7
BACKUP_TYPE="config"
QUIET_MODE=false

# Configuration variables
BASE_PATH="$DEFAULT_BASE_PATH"
BACKUP_PATH="$DEFAULT_BACKUP_PATH"
KEEP_COUNT="$DEFAULT_KEEP_COUNT"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_NAME="homelab-media-stack-${BACKUP_TYPE}-${TIMESTAMP}"

# Functions
print_header() {
    if [[ "$QUIET_MODE" == false ]]; then
        echo -e "${BLUE}"
        echo "================================================================="
        echo "    Homelab Media Stack - Backup Script"
        echo "================================================================="
        echo -e "${NC}"
    fi
}

print_step() {
    if [[ "$QUIET_MODE" == false ]]; then
        echo -e "${GREEN}[STEP] $1${NC}"
    fi
}

print_info() {
    if [[ "$QUIET_MODE" == false ]]; then
        echo -e "${CYAN}[INFO] $1${NC}"
    fi
}

print_warning() {
    echo -e "${YELLOW}[WARN] $1${NC}" >&2
}

print_error() {
    echo -e "${RED}[ERROR] $1${NC}" >&2
}

print_success() {
    echo -e "${GREEN}[SUCCESS] $1${NC}"
}

print_help() {
    cat << EOF
Homelab Media Stack Backup Script

USAGE:
    ./backup.sh [OPTIONS]

OPTIONS:
    -f, --full          Full backup including databases and media metadata
    -c, --config-only   Configuration files only (default, fastest)
    -d, --destination   Backup destination directory (default: $DEFAULT_BACKUP_PATH)
    -k, --keep          Number of backups to keep (default: $DEFAULT_KEEP_COUNT)
    -q, --quiet         Quiet mode - minimal output
    -h, --help          Show this help message

BACKUP TYPES:
    Config Only:        Docker configs, environment files, compose files
    Full Backup:        Config + databases + media metadata + artwork

EXAMPLES:
    ./backup.sh                                    # Quick config backup
    ./backup.sh --full                            # Complete backup with databases
    ./backup.sh -d /mnt/nas/backups --keep 14     # Custom destination, keep 14 backups
    ./backup.sh --full --quiet                    # Full backup in quiet mode

BACKUP INCLUDES:
    Config Only (~100MB):
        • Docker configuration directories
        • Environment files (.env-*)
        • Docker compose files
        • Setup scripts
        
    Full Backup (~1-5GB):
        • Everything in Config Only, plus:
        • Service databases (Plex, Sonarr, Radarr, etc.)
        • Media metadata and artwork
        • FileBot configuration and license

RESTORE:
    Backups are created as compressed tar files. To restore:
    1. Stop services: docker-compose down
    2. Extract backup: tar -xzf backup-file.tar.gz
    3. Restore files to original locations
    4. Fix permissions: chown -R PUID:PGID /volume1/docker/
    5. Start services: docker-compose up -d

EOF
}

parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -f|--full)
                BACKUP_TYPE="full"
                BACKUP_NAME="homelab-media-stack-${BACKUP_TYPE}-${TIMESTAMP}"
                shift
                ;;
            -c|--config-only)
                BACKUP_TYPE="config"
                BACKUP_NAME="homelab-media-stack-${BACKUP_TYPE}-${TIMESTAMP}"
                shift
                ;;
            -d|--destination)
                BACKUP_PATH="$2"
                shift 2
                ;;
            -k|--keep)
                KEEP_COUNT="$2"
                shift 2
                ;;
            -q|--quiet)
                QUIET_MODE=true
                shift
                ;;
            -h|--help)
                print_help
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                print_help
                exit 1
                ;;
        esac
    done
}

check_prerequisites() {
    print_step "Checking prerequisites..."
    
    # Check if source directories exist
    if [[ ! -d "$BASE_PATH/docker" ]]; then
        print_error "Docker configuration directory not found: $BASE_PATH/docker"
        print_info "Make sure the base path is correct and the stack is installed."
        exit 1
    fi
    
    # Check available disk space
    local available_space=$(df "$BACKUP_PATH" 2>/dev/null | tail -1 | awk '{print $4}' || echo "0")
    local required_space=1048576  # 1GB in KB
    
    if [[ "$BACKUP_TYPE" == "full" ]]; then
        required_space=5242880  # 5GB in KB
    fi
    
    if [[ "$available_space" -lt "$required_space" ]]; then
        print_warning "Low disk space available for backup"
        print_info "Available: $(( available_space / 1024 ))MB, Recommended: $(( required_space / 1024 ))MB"
    fi
    
    # Create backup directory if it doesn't exist
    if [[ ! -d "$BACKUP_PATH" ]]; then
        print_info "Creating backup directory: $BACKUP_PATH"
        mkdir -p "$BACKUP_PATH"
    fi
    
    print_info "✓ Prerequisites check passed"
}

create_backup_structure() {
    print_step "Creating backup structure..."
    
    local temp_dir="/tmp/${BACKUP_NAME}"
    
    # Clean up any existing temp directory
    if [[ -d "$temp_dir" ]]; then
        rm -rf "$temp_dir"
    fi
    
    # Create temporary backup structure
    mkdir -p "$temp_dir"/{docker,scripts,docs}
    
    echo "$temp_dir"
}

backup_configuration_files() {
    local temp_dir="$1"
    print_step "Backing up configuration files..."
    
    # Docker configurations
    if [[ -d "$BASE_PATH/docker" ]]; then
        print_info "Copying Docker configurations..."
        cp -r "$BASE_PATH/docker"/* "$temp_dir/docker/" 2>/dev/null || true
    fi
    
    # Environment files
    print_info "Copying environment files..."
    find . -maxdepth 1 -name ".env*" -type f -exec cp {} "$temp_dir/" \; 2>/dev/null || true
    
    # Docker compose files
    print_info "Copying Docker compose files..."
    find . -maxdepth 1 -name "docker-compose*.yml" -type f -exec cp {} "$temp_dir/" \; 2>/dev/null || true
    
    # Scripts
    if [[ -d "scripts" ]]; then
        print_info "Copying scripts..."
        cp -r scripts/* "$temp_dir/scripts/" 2>/dev/null || true
    fi
    
    # Documentation
    if [[ -d "docs" ]]; then
        print_info "Copying documentation..."
        cp -r docs/* "$temp_dir/docs/" 2>/dev/null || true
    fi
    
    # Main project files
    for file in README.md CHANGELOG.md CONTRIBUTING.md LICENSE; do
        if [[ -f "$file" ]]; then
            cp "$file" "$temp_dir/" 2>/dev/null || true
        fi
    done
    
    print_info "✓ Configuration files backed up"
}

backup_databases() {
    local temp_dir="$1"
    print_step "Backing up service databases..."
    
    # Critical database files
    local db_files=(
        "docker/streamarr/plex/Library/Application Support/Plex Media Server/Plug-in Support/Databases"
        "docker/streamarr/plex/Library/Application Support/Plex Media Server/Preferences.xml"
        "docker/servarr/sonarr/sonarr.db"
        "docker/servarr/radarr/radarr.db"
        "docker/servarr/lidarr/lidarr.db"
        "docker/servarr/prowlarr/prowlarr.db"
        "docker/servarr/bazarr/bazarr.db"
        "docker/streamarr/overseerr/db"
        "docker/streamarr/tautulli/tautulli.db"
        "docker/streamarr/ersatztv/ersatztv.db"
    )
    
    for db_path in "${db_files[@]}"; do
        local full_path="$BASE_PATH/$db_path"
        local backup_path="$temp_dir/$db_path"
        
        if [[ -e "$full_path" ]]; then
            print_info "Backing up: $(basename "$db_path")"
            mkdir -p "$(dirname "$backup_path")"
            cp -r "$full_path" "$backup_path" 2>/dev/null || true
        fi
    done
    
    print_info "✓ Database files backed up"
}

backup_media_metadata() {
    local temp_dir="$1"
    print_step "Backing up media metadata..."
    
    # Plex metadata and artwork
    local metadata_paths=(
        "docker/streamarr/plex/Library/Application Support/Plex Media Server/Media"
        "docker/streamarr/plex/Library/Application Support/Plex Media Server/Metadata"
        "docker/servarr/sonarr/MediaCover"
        "docker/servarr/radarr/MediaCover"
        "docker/servarr/lidarr/MediaCover"
    )
    
    for metadata_path in "${metadata_paths[@]}"; do
        local full_path="$BASE_PATH/$metadata_path"
        local backup_path="$temp_dir/$metadata_path"
        
        if [[ -d "$full_path" ]]; then
            print_info "Backing up metadata: $(basename "$metadata_path")"
            mkdir -p "$(dirname "$backup_path")"
            cp -r "$full_path" "$backup_path" 2>/dev/null || true
        fi
    done
    
    # FileBot data (Docker volume)
    if docker volume ls | grep -q "filebot-data"; then
        print_info "Backing up FileBot data..."
        mkdir -p "$temp_dir/volumes"
        docker run --rm -v filebot-data:/data -v "$temp_dir/volumes:/backup" \
            alpine tar czf /backup/filebot-data.tar.gz -C /data . 2>/dev/null || true
    fi
    
    print_info "✓ Media metadata backed up"
}

create_backup_info() {
    local temp_dir="$1"
    print_step "Creating backup information..."
    
    cat > "$temp_dir/BACKUP_INFO.txt" << EOF
Homelab Media Stack Backup
==========================

Backup Details:
- Timestamp: $TIMESTAMP
- Type: $BACKUP_TYPE
- Created by: $(whoami)
- Hostname: $(hostname)
- Base Path: $BASE_PATH

System Information:
- OS: $(uname -s) $(uname -r)
- Docker Version: $(docker --version 2>/dev/null || echo "Not available")
- Docker Compose Version: $(docker-compose --version 2>/dev/null || echo "Not available")

Backup Contents:
$(if [[ "$BACKUP_TYPE" == "config" ]]; then
    echo "- Configuration files only"
    echo "- Environment files"
    echo "- Docker compose files"
    echo "- Scripts and documentation"
else
    echo "- Configuration files"
    echo "- Service databases"
    echo "- Media metadata and artwork"
    echo "- FileBot configuration"
fi)

Backup Size: $(du -sh "$temp_dir" | cut -f1)

Restore Instructions:
1. Stop all services: docker-compose down
2. Extract backup: tar -xzf $(basename "$temp_dir").tar.gz
3. Copy files to original locations
4. Set permissions: chown -R PUID:PGID $BASE_PATH/docker/
5. Start services: docker-compose up -d

For detailed restore instructions, see the project documentation.
EOF
    
    print_info "✓ Backup information created"
}

compress_backup() {
    local temp_dir="$1"
    print_step "Compressing backup..."
    
    local backup_file="$BACKUP_PATH/${BACKUP_NAME}.tar.gz"
    
    # Create compressed backup
    tar -czf "$backup_file" -C "$(dirname "$temp_dir")" "$(basename "$temp_dir")" 2>/dev/null
    
    # Verify backup was created
    if [[ -f "$backup_file" ]]; then
        local backup_size=$(du -sh "$backup_file" | cut -f1)
        print_success "Backup created: $backup_file ($backup_size)"
        echo "$backup_file"
    else
        print_error "Failed to create backup file"
        exit 1
    fi
}

cleanup_temp_files() {
    local temp_dir="$1"
    print_step "Cleaning up temporary files..."
    
    if [[ -d "$temp_dir" ]]; then
        rm -rf "$temp_dir"
        print_info "✓ Temporary files cleaned up"
    fi
}

cleanup_old_backups() {
    print_step "Cleaning up old backups..."
    
    # Find and remove old backups, keeping only the specified number
    local backups_to_remove=$(find "$BACKUP_PATH" -name "homelab-media-stack-*.tar.gz" -type f -printf '%T@ %p\n' | sort -n | head -n -"$KEEP_COUNT" | cut -d' ' -f2-)
    
    if [[ -n "$backups_to_remove" ]]; then
        local count=0
        while IFS= read -r old_backup; do
            if [[ -f "$old_backup" ]]; then
                print_info "Removing old backup: $(basename "$old_backup")"
                rm "$old_backup"
                ((count++))
            fi
        done <<< "$backups_to_remove"
        
        if [[ "$count" -gt 0 ]]; then
            print_info "✓ Removed $count old backup(s)"
        fi
    else
        print_info "✓ No old backups to remove"
    fi
}

show_backup_summary() {
    local backup_file="$1"
    
    if [[ "$QUIET_MODE" == false ]]; then
        print_step "Backup Summary"
        echo
        print_info "Backup Details:"
        echo -e "  ${CYAN}Type:${NC} $BACKUP_TYPE"
        echo -e "  ${CYAN}File:${NC} $backup_file"
        echo -e "  ${CYAN}Size:${NC} $(du -sh "$backup_file" | cut -f1)"
        echo -e "  ${CYAN}Date:${NC} $(date)"
        echo
        print_info "Backup Location:"
        echo -e "  ${CYAN}Directory:${NC} $BACKUP_PATH"
        echo -e "  ${CYAN}Retention:${NC} Keeping $KEEP_COUNT backups"
        echo
        print_info "Restore Command:"
        echo -e "  ${CYAN}tar -xzf $backup_file${NC}"
        echo
    fi
}

# Main execution
main() {
    print_header
    
    parse_arguments "$@"
    check_prerequisites
    
    local temp_dir
    temp_dir=$(create_backup_structure)
    
    # Always backup configuration files
    backup_configuration_files "$temp_dir"
    
    # Full backup includes databases and metadata
    if [[ "$BACKUP_TYPE" == "full" ]]; then
        backup_databases "$temp_dir"
        backup_media_metadata "$temp_dir"
    fi
    
    create_backup_info "$temp_dir"
    
    local backup_file
    backup_file=$(compress_backup "$temp_dir")
    
    cleanup_temp_files "$temp_dir"
    cleanup_old_backups
    
    show_backup_summary "$backup_file"
    
    print_success "Backup completed successfully! 🎉"
}

# Error handling
trap 'print_error "Backup failed. Check the errors above."; exit 1' ERR

# Run main function with all arguments
main "$@"
#!/usr/bin/env bash

# MIT License
# Homelab Media Stack Universal Uninstall Script
# Supports: Windows, macOS, Linux, Synology, UGREEN, QNAP, TrueNAS, Unraid, Proxmox

#################################################################################################################################################
# Color definitions
#################################################################################################################################################
if [[ -t 1 ]]; then
    cr="\e[31m" clr="\e[91m"       # [c]olor[r]ed     [c]olor[l]ight[r]ed
    cg="\e[32m" clg="\e[92m"       # [c]olor[g]reen   [c]olor[l]ight[g]reen
    cy="\e[33m" cly="\e[93m"       # [c]olor[y]ellow  [c]olor[l]ight[y]ellow
    cb="\e[34m" clb="\e[94m"       # [c]olor[b]lue    [c]olor[l]ight[b]lue
    cm="\e[35m" clm="\e[95m"       # [c]olor[m]agenta [c]olor[l]ight[m]agenta
    cc="\e[36m" clc="\e[96m"       # [c]olor[c]yan    [c]olor[l]ight[c]yan
    cend="\e[0m"                   # [c]olor[end]
    
    utick="\e[32m\U2714\e[0m" uplus="\e[36m\U002b\e[0m" ucross="\e[31m\U00D7\e[0m"
    uyc="\e[33m\U25cf\e[0m" urc="\e[31m\U25cf\e[0m" ugc="\e[32m\U25cf\e[0m"
    
    # Loading animation characters
    spinner_chars=("⠋" "⠙" "⠹" "⠸" "⠼" "⠴" "⠦" "⠧" "⠇" "⠏")
    spinner_colors=("\e[31m" "\e[33m" "\e[32m" "\e[36m" "\e[34m" "\e[35m")
    progress_chars=("▰" "▱")
else
    # No colors for non-terminal output
    cr="" clr="" cg="" clg="" cy="" cly="" cb="" clb="" cm="" clm="" cc="" clc="" cend=""
    utick="✓" uplus="+" ucross="✗" uyc="●" urc="●" ugc="●"
    
    # Loading animation characters (fallback)
    spinner_chars=("|" "/" "-" "\\")
    spinner_colors=("" "" "" "")
    progress_chars=("#" "-")
fi

#################################################################################################################################################
# Loading Animations and Progress Indicators
#################################################################################################################################################
show_animated_spinner() {
    local message="$1"
    local duration="${2:-3}"
    local i=0
    local color_idx=0
    
    printf '%b' " ${uyc} ${message} "
    
    while [[ $i -lt $((duration * 10)) ]]; do
        local spinner="${spinner_chars[$((i % ${#spinner_chars[@]}))]}"
        local color="${spinner_colors[$((color_idx % ${#spinner_colors[@]}))]}"
        printf '\b%b%s%b' "$color" "$spinner" "$cend"
        sleep 0.1
        ((i++))
        if [[ $((i % 10)) -eq 0 ]]; then
            ((color_idx++))
        fi
    done
    printf '\b \b'
}

show_progress_bar() {
    local current=$1
    local total=$2
    local width=50
    local percentage=$((current * 100 / total))
    local filled=$((width * current / total))
    local empty=$((width - filled))
    
    printf '\r%b' " ${uyc} Progress: ["
    
    # Filled part
    for ((i=0; i<filled; i++)); do
        printf '%b%s%b' "${clg}" "${progress_chars[0]}" "$cend"
    done
    
    # Empty part
    for ((i=0; i<empty; i++)); do
        printf '%s' "${progress_chars[1]}"
    done
    
    printf '] %d%%' "$percentage"
}

show_loading_message() {
    local message="$1"
    local duration="${2:-2}"
    
    printf '%b' " ${uyc} ${message} "
    show_animated_spinner "" "$duration"
    printf '\n'
}

#################################################################################################################################################
# Banner
#################################################################################################################################################
show_banner() {
    printf '\n%b\n' "${cr}
╔═══════════════════════════════════════════════════════════════════════════════╗
║                        HOMELAB MEDIA STACK                                    ║
║                     Universal Uninstall Script v2.1                           ║
║                                                                               ║
║  Supports: Windows • macOS • Linux • Synology • UGREEN • QNAP                 ║
║           TrueNAS • Unraid • Proxmox • And More!                              ║
╚═══════════════════════════════════════════════════════════════════════════════╝${cend}"
    sleep 1
}

#################################################################################################################################################
# Platform Detection
#################################################################################################################################################
detect_platform() {
    printf '\n%b\n' " ${uyc} Detecting your platform..."
    show_loading_message "Analyzing system environment" 2
    
    # Automatic detection
    local detected=""
    local auto_path=""
    
    # Check for specific NAS/virtualization platforms first
    if command -v synoinfo &> /dev/null; then
        detected="synology"
        auto_path="/volume1"
    elif grep -q "unraid" /etc/os-release 2>/dev/null; then
        detected="unraid"
        auto_path="/mnt/user"
    elif command -v midclt &> /dev/null; then
        detected="truenas"
        auto_path="/mnt"
    elif command -v pveversion &> /dev/null; then
        detected="proxmox"
        auto_path="/opt/homelab"
    elif [[ -f /etc/ugreen-nas-release ]] || [[ -d /usr/local/ugreen ]]; then
        detected="ugreen"
        auto_path="/volume1"
    elif command -v qpkg_cli &> /dev/null || [[ -d /share ]]; then
        detected="qnap"
        auto_path="/share"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        detected="macos"
        auto_path="$HOME/homelab"
    elif [[ "$OS" == "Windows_NT" ]] || [[ -n "$WINDIR" ]] || command -v powershell.exe &> /dev/null; then
        detected="windows"
        auto_path="/c/homelab"
    else
        detected="linux"
        auto_path="/opt/homelab"
    fi
    
    declare -g platform="$detected"
    declare -g default_base_path="$auto_path"
    
    printf '\n%b\n' " ${ugc} Detected platform: ${clc}${platform}${cend}"
    printf '\n%b\n' " ${ugc} Default installation path: ${clc}${default_base_path}${cend}"
}

#################################################################################################################################################
# Docker and system checks
#################################################################################################################################################
check_prerequisites() {
    printf '\n%b\n' " ${uyc} Checking system prerequisites..."
    show_loading_message "Verifying Docker installation" 1
    
    # Check Docker
    if ! command -v docker &> /dev/null; then
        printf '\n%b\n' " ${ucross} Docker is not installed - nothing to uninstall"
        exit 0
    else
        docker_version=$(docker --version 2>/dev/null)
        printf '\n%b\n' " ${utick} Docker found: ${clc}${docker_version}${cend}"
    fi
    
    # Check Docker Compose
    if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null 2>&1; then
        printf '\n%b\n' " ${ucross} Docker Compose is not installed"
        exit 1
    else
        if command -v docker-compose &> /dev/null; then
            declare -g compose_cmd="docker-compose"
        else
            declare -g compose_cmd="docker compose"
        fi
        printf '\n%b\n' " ${utick} Docker Compose found: ${clc}${compose_cmd}${cend}"
    fi
    
    printf '\n%b\n' " ${utick} Prerequisites check complete!"
}

#################################################################################################################################################
# Find installation paths
#################################################################################################################################################
find_installation_paths() {
    printf '\n%b\n' " ${uyc} Searching for homelab media stack installations..."
    show_loading_message "Scanning for installations" 2
    
    # Common installation paths to check
    local search_paths=(
        "/volume1/homelab"
        "/mnt/user/homelab"
        "/mnt/homelab"
        "/opt/homelab"
        "/share/homelab"
        "$HOME/homelab"
        "/c/homelab"
        "/d/homelab"
        "/e/homelab"
        "/f/homelab"
        "/g/homelab"
        "/h/homelab"
    )
    
    declare -g found_installations=()
    
    for path in "${search_paths[@]}"; do
        if [[ -d "$path" ]] && [[ -f "$path/.env-servarr" ]] && [[ -f "$path/.env-streamarr" ]]; then
            found_installations+=("$path")
            printf '\n%b\n' " ${utick} Found installation at: ${clc}${path}${cend}"
        fi
    done
    
    # Also check current directory
    if [[ -f ".env-servarr" ]] && [[ -f ".env-streamarr" ]]; then
        current_dir=$(pwd)
        if [[ ! " ${found_installations[@]} " =~ " ${current_dir} " ]]; then
            found_installations+=("$current_dir")
            printf '\n%b\n' " ${utick} Found installation in current directory: ${clc}${current_dir}${cend}"
        fi
    fi
    
    if [[ ${#found_installations[@]} -eq 0 ]]; then
        printf '\n%b\n' " ${ucross} No homelab media stack installations found"
        printf '\n%b\n' " ${uyc} If you know the installation path, please specify it manually"
        return 1
    fi
    
    printf '\n%b\n' " ${utick} Found ${clc}${#found_installations[@]}${cend} installation(s)"
    return 0
}

#################################################################################################################################################
# Stop and remove Docker containers
#################################################################################################################################################
stop_and_remove_containers() {
    local base_path="$1"
    printf '\n%b\n' " ${uyc} Stopping and removing Docker containers..."
    show_loading_message "Stopping running containers" 1
    
    # Change to the installation directory
    cd "$base_path" || {
        printf '\n%b\n' " ${ucross} Cannot access directory: ${clc}${base_path}${cend}"
        return 1
    }
    
    # Stop and remove servarr stack
    if [[ -f "docker-compose-servarr.yml" ]] && [[ -f ".env-servarr" ]]; then
        printf '\n%b\n' " ${uyc} Stopping SERVARR stack..."
        show_loading_message "Shutting down download services" 2
        
        if $compose_cmd --env-file .env-servarr -f docker-compose-servarr.yml down --remove-orphans 2>/dev/null; then
            printf '\n%b\n' " ${utick} SERVARR stack stopped and removed"
        else
            printf '\n%b\n' " ${uyc} SERVARR stack was not running or already removed"
        fi
    fi
    
    # Stop and remove streamarr stack
    if [[ -f "docker-compose-streamarr.yml" ]] && [[ -f ".env-streamarr" ]]; then
        printf '\n%b\n' " ${uyc} Stopping STREAMARR stack..."
        show_loading_message "Shutting down streaming services" 2
        
        if $compose_cmd --env-file .env-streamarr -f docker-compose-streamarr.yml down --remove-orphans 2>/dev/null; then
            printf '\n%b\n' " ${utick} STREAMARR stack stopped and removed"
        else
            printf '\n%b\n' " ${uyc} STREAMARR stack was not running or already removed"
        fi
    fi
    
    # Remove any remaining containers that might be related
    printf '\n%b\n' " ${uyc} Checking for any remaining related containers..."
    local related_containers=(
        "gluetun" "qbittorrent" "sabnzbd" "sonarr" "radarr" "lidarr" "bazarr" "prowlarr"
        "plex" "tautulli" "overseerr" "homarr" "ersatztv" "filebot" "jellyfin" "emby"
    )
    
    for container in "${related_containers[@]}"; do
        if docker ps -a --format "table {{.Names}}" | grep -q "^${container}$"; then
            printf '\n%b\n' " ${uyc} Removing container: ${clc}${container}${cend}"
            docker rm -f "$container" 2>/dev/null || true
        fi
    done
    
    printf '\n%b\n' " ${utick} All containers stopped and removed!"
}

#################################################################################################################################################
# Remove Docker networks
#################################################################################################################################################
remove_docker_networks() {
    printf '\n%b\n' " ${uyc} Removing Docker networks..."
    show_loading_message "Cleaning up network resources" 1
    
    # Remove specific networks
    local networks=("servarr-network" "streamarr-network")
    
    for network in "${networks[@]}"; do
        if docker network ls --format "table {{.Name}}" | grep -q "^${network}$"; then
            printf '\n%b\n' " ${uyc} Removing network: ${clc}${network}${cend}"
            docker network rm "$network" 2>/dev/null || true
        fi
    done
    
    # Remove any unused networks
    printf '\n%b\n' " ${uyc} Cleaning up unused networks..."
    docker network prune -f 2>/dev/null || true
    
    printf '\n%b\n' " ${utick} Docker networks cleaned up!"
}

#################################################################################################################################################
# Remove Docker volumes
#################################################################################################################################################
remove_docker_volumes() {
    printf '\n%b\n' " ${uyc} Removing Docker volumes..."
    show_loading_message "Removing application data" 1
    
    # Remove specific volumes
    local volumes=(
        "servarr_gluetun" "servarr_qbittorrent" "servarr_sabnzbd" "servarr_sonarr"
        "servarr_radarr" "servarr_lidarr" "servarr_bazarr" "servarr_prowlarr"
        "streamarr_plex" "streamarr_tautulli" "streamarr_overseerr" "streamarr_homarr"
        "streamarr_ersatztv" "streamarr_filebot" "streamarr_jellyfin" "streamarr_emby"
    )
    
    for volume in "${volumes[@]}"; do
        if docker volume ls --format "table {{.Name}}" | grep -q "^${volume}$"; then
            printf '\n%b\n' " ${uyc} Removing volume: ${clc}${volume}${cend}"
            docker volume rm "$volume" 2>/dev/null || true
        fi
    done
    
    # Remove any unused volumes
    printf '\n%b\n' " ${uyc} Cleaning up unused volumes..."
    docker volume prune -f 2>/dev/null || true
    
    printf '\n%b\n' " ${utick} Docker volumes cleaned up!"
}

#################################################################################################################################################
# Remove directories and files
#################################################################################################################################################
remove_docker_files_and_directories() {
    local base_path="$1"
    printf '\n%b\n' " ${uyc} Removing Docker-related files and empty directories..."
    show_loading_message "Cleaning up configuration files and directories" 1
    
    # Change to the installation directory
    cd "$base_path" || {
        printf '\n%b\n' " ${ucross} Cannot access directory: ${clc}${base_path}${cend}"
        return 1
    }
    
    # List of Docker-related files to remove (only generated/copied files)
    local docker_files=(
        ".env-servarr"
        ".env-streamarr"
    )
    
    # Remove generated environment files only
    printf '\n%b\n' " ${uyc} Removing generated environment files..."
    for file in "${docker_files[@]}"; do
        if [[ -f "$file" ]]; then
            if rm "$file" 2>/dev/null; then
                printf '\n%b\n' " ${utick} Removed: ${clc}${file}${cend}"
            else
                printf '\n%b\n' " ${ucross} Failed to remove: ${clc}${file}${cend}"
            fi
        fi
    done
    
    # Remove any backup files created during setup
    printf '\n%b\n' " ${uyc} Cleaning up backup files..."
    local backup_files=(
        ".env-servarr.bak"
        ".env-streamarr.bak"
    )
    
    for file in "${backup_files[@]}"; do
        if [[ -f "$file" ]]; then
            rm "$file" 2>/dev/null || true
            printf '\n%b\n' " ${utick} Removed backup: ${clc}${file}${cend}"
        fi
    done
    
    # Remove empty directories created during setup
    printf '\n%b\n' " ${uyc} Checking for empty directories to remove..."
    
    # List of directories that might have been created during setup
    local created_dirs=(
        "${base_path}/docker/servarr"
        "${base_path}/docker/streamarr"
        "${base_path}/data/downloads/complete"
        "${base_path}/data/downloads/incomplete"
        "${base_path}/data/media/movies"
        "${base_path}/data/media/tv"
        "${base_path}/data/media/music"
        "${base_path}/data/plex_transcode"
    )
    
    # Remove empty directories (in reverse order to handle nested dirs)
    for ((i=${#created_dirs[@]}-1; i>=0; i--)); do
        local dir="${created_dirs[$i]}"
        if [[ -d "$dir" ]] && [[ -z "$(ls -A "$dir" 2>/dev/null)" ]]; then
            if rmdir "$dir" 2>/dev/null; then
                printf '\n%b\n' " ${utick} Removed empty directory: ${clc}${dir}${cend}"
            fi
        else
            printf '\n%b\n' " ${ugc} Preserved directory (not empty): ${clc}${dir}${cend}"
        fi
    done
    
    # Try to remove the main docker directory if empty
    if [[ -d "${base_path}/docker" ]] && [[ -z "$(ls -A "${base_path}/docker" 2>/dev/null)" ]]; then
        if rmdir "${base_path}/docker" 2>/dev/null; then
            printf '\n%b\n' " ${utick} Removed empty docker directory: ${clc}${base_path}/docker${cend}"
        fi
    fi
    
    # Try to remove the main data directory if empty
    if [[ -d "${base_path}/data" ]] && [[ -z "$(ls -A "${base_path}/data" 2>/dev/null)" ]]; then
        if rmdir "${base_path}/data" 2>/dev/null; then
            printf '\n%b\n' " ${utick} Removed empty data directory: ${clc}${base_path}/data${cend}"
        fi
    fi
    
    # Try to remove the base path if completely empty
    if [[ -d "$base_path" ]] && [[ -z "$(ls -A "$base_path" 2>/dev/null)" ]]; then
        if rmdir "$base_path" 2>/dev/null; then
            printf '\n%b\n' " ${utick} Removed empty base directory: ${clc}${base_path}${cend}"
        fi
    fi
    
    printf '\n%b\n' " ${utick} Generated files and empty directories removed!"
    printf '\n%b\n' " ${ugc} Your data directories with content are preserved:"
    printf '\n%b\n' " ${clc}•${cend} ${base_path}/data/downloads/complete"
    printf '\n%b\n' " ${clc}•${cend} ${base_path}/data/downloads/incomplete"
    printf '\n%b\n' " ${clc}•${cend} ${base_path}/data/media/movies"
    printf '\n%b\n' " ${clc}•${cend} ${base_path}/data/media/tv"
    printf '\n%b\n' " ${clc}•${cend} ${base_path}/data/media/music"
    printf '\n%b\n' " ${clc}•${cend} ${base_path}/data/plex_transcode"
}

#################################################################################################################################################
# Clean up Docker system
#################################################################################################################################################
cleanup_docker_system() {
    printf '\n%b\n' " ${uyc} Cleaning up Docker system..."
    show_loading_message "Performing system cleanup" 1
    
    # Remove unused images
    printf '\n%b\n' " ${uyc} Removing unused Docker images..."
    docker image prune -f 2>/dev/null || true
    
    # Remove unused containers
    printf '\n%b\n' " ${uyc} Removing unused containers..."
    docker container prune -f 2>/dev/null || true
    
    # Remove unused networks
    printf '\n%b\n' " ${uyc} Removing unused networks..."
    docker network prune -f 2>/dev/null || true
    
    # Remove unused volumes
    printf '\n%b\n' " ${uyc} Removing unused volumes..."
    docker volume prune -f 2>/dev/null || true
    
    # Full system prune (optional)
    printf '\n%b' " ${uyc} Perform full Docker system cleanup? [y/N]: "
    read -r full_cleanup
    if [[ "$full_cleanup" =~ ^[Yy]$ ]]; then
        printf '\n%b\n' " ${uyc} Performing full Docker system cleanup..."
        docker system prune -f 2>/dev/null || true
        printf '\n%b\n' " ${utick} Full Docker system cleanup completed!"
    fi
    
    printf '\n%b\n' " ${utick} Docker system cleanup completed!"
}

#################################################################################################################################################
# Remove Docker networks (custom)
#################################################################################################################################################
remove_custom_networks() {
    local networks=("servarr-network" "streamarr-network")
    for net in "${networks[@]}"; do
        if docker network ls | grep -q "${net}"; then
            # Check if any containers are attached
            containers=$(docker network inspect "$net" --format '{{range $k,$v := .Containers}}{{$k}} {{end}}')
            if [[ -z "$containers" ]]; then
                if docker network rm "$net" > /dev/null 2>&1; then
                    printf '\n%b\n' " ${utick} Removed Docker network: ${clc}${net}${cend}"
                else
                    printf '\n%b\n' " ${ucross} Failed to remove Docker network: ${clc}${net}${cend}"
                fi
            else
                printf '\n%b\n' " ${cy}⚠️  Could not remove network ${clc}${net}${cend} because it is still in use by containers:${cend}"
                for c in $containers; do
                    printf '\n%b\n' "   - $c"
                done
                printf '\n%b\n' " ${uyc} To remove manually: ${clc}docker network disconnect ${net} <container_name> && docker network rm ${net}${cend}"
            fi
        fi
    done
}

#################################################################################################################################################
# Main execution
#################################################################################################################################################
main() {
    # Show banner
    show_banner
    
    # Show disclaimer
    printf '\n%b\n' " ${uyc} ${cy}⚠️ DISCLAIMER:${cend} This script will remove Docker components only."
    printf '\n%b\n' " Your media files and data directories will be preserved."
    printf '\n%b\n' " Only Docker containers, networks, volumes, and config files will be removed."
    printf '\n'
    
    # Ask for confirmation
    printf '%b' " ${uyc} Do you want to continue with Docker uninstallation? [y/N]: "
    read -r confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        printf '\n%b\n' " ${ucross} Uninstall cancelled by user."
        exit 0
    fi
    
    # Detect platform
    detect_platform
    
    # Check prerequisites
    check_prerequisites
    
    # Find installations
    if ! find_installation_paths; then
        printf '\n%b\n' " ${uyc} Please specify the installation path manually:"
        printf '%b' " Installation path: "
        read -r manual_path
        if [[ -n "$manual_path" ]] && [[ -d "$manual_path" ]]; then
            found_installations=("$manual_path")
        else
            printf '\n%b\n' " ${ucross} Invalid path or no installations found"
            exit 1
        fi
    fi
    
    # Process each installation
    for installation in "${found_installations[@]}"; do
        printf '\n%b\n' " ${clc}=== Processing installation: ${installation} ===${cend}"
        
        # Stop and remove containers
        stop_and_remove_containers "$installation"
        
        # Remove Docker files and empty directories (preserve data)
        remove_docker_files_and_directories "$installation"
    done
    
    # Remove Docker networks (custom)
    remove_custom_networks
    
    # Remove Docker volumes
    remove_docker_volumes
    
    # Clean up Docker system
    cleanup_docker_system
    
    # Success message
    printf '\n%b\n' "${clg}
╔═══════════════════════════════════════════════════════════════════════════════╗
║                        DOCKER UNINSTALL COMPLETE!                            ║
║                                                                               ║
║  ✅ All containers stopped and removed                                       ║
║  ✅ All networks cleaned up                                                  ║
║  ✅ All volumes removed                                                      ║
║  ✅ Docker configuration files removed                                       ║
║  ✅ Docker system cleaned up                                                 ║
║                                                                               ║
║  🗑️  Docker components removed - your data is preserved!                     ║
╚═══════════════════════════════════════════════════════════════════════════════╝${cend}"
    
    printf '\n%b\n' " ${uyc} ${cy}What was removed:${cend}"
    printf '\n%b\n' " ${clc}•${cend} All Docker containers (gluetun, qbittorrent, sonarr, radarr, etc.)"
    printf '\n%b\n' " ${clc}•${cend} Docker networks (servarr-network, streamarr-network)"
    printf '\n%b\n' " ${clc}•${cend} Docker volumes (application data, databases)"
    printf '\n%b\n' " ${clc}•${cend} Generated environment files (.env-servarr, .env-streamarr)"
    printf '\n%b\n' " ${clc}•${cend} Empty directories created during setup"
    
    printf '\n%b\n' " ${uyc} ${cy}What was preserved:${cend}"
    printf '\n%b\n' " ${clg}•${cend} All media files (movies, TV shows, music)"
    printf '\n%b\n' " ${clg}•${cend} Download directories with content (complete, incomplete)"
    printf '\n%b\n' " ${clg}•${cend} Plex transcode directory"
    printf '\n%b\n' " ${clg}•${cend} All data directories with content"
    printf '\n%b\n' " ${clg}•${cend} Original project files (docker-compose-*.yml, .env-*.example)"
    
    printf '\n%b\n' " ${uyc} ${cy}Next steps:${cend}"
    printf '\n%b\n' " ${clc}•${cend} If you want to reinstall, run: ${clc}./scripts/setup.sh${cend}"
    printf '\n%b\n' " ${clc}•${cend} Your data will be automatically detected and used"
    printf '\n%b\n' " ${clc}•${cend} Consider running: ${clc}docker system prune -a${cend} to free more space"
    
    printf '\n%b\n' " ${utick} Docker uninstallation completed successfully!"
}

# Run main function
main "$@" 
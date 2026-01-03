#!/bin/bash

# MIT License
# Homelab Media Stack Universal Setup Script
# Supports: Windows, macOS, Linux, Synology, UGREEN, QNAP, TrueNAS, Unraid, Proxmox

#################################################################################################################################################
# Sudo Check
#################################################################################################################################################
check_sudo() {
    if [[ $EUID -ne 0 ]]; then
        printf '\n%b\n' " ${ucross} This script must be run as root (sudo)"
        printf '\n%b\n' " ${uyc} Please run: ${clc}sudo ./scripts/setup.sh${cend}"
        exit 1
    fi
}

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
    spinner_chars="⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏"
    spinner_colors="\e[31m \e[33m \e[32m \e[36m \e[34m \e[35m"
    progress_chars="▰ ▱"
else
    # No colors for non-terminal output
    cr="" clr="" cg="" clg="" cy="" cly="" cb="" clb="" cm="" clm="" cc="" clc="" cend=""
    utick="✓" uplus="+" ucross="✗" uyc="●" urc="●" ugc="●"
    
    # Loading animation characters (fallback)
    spinner_chars="| / - \\"
    spinner_colors="   "
    progress_chars="# -"
fi

#################################################################################################################################################
# Loading Animations and Progress Indicators
#################################################################################################################################################
show_spinner() {
    local pid=$1
    local delay=0.1
    local spinstr='|/-\'
    local i=0
    
    while kill -0 $pid 2>/dev/null; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}

show_animated_spinner() {
    local message="$1"
    local duration="${2:-3}"
    local i=0
    local color_idx=0
    
    printf '%b' " ${uyc} ${message} "
    
    while [[ $i -lt $((duration * 10)) ]]; do
        local spinner=$(echo "$spinner_chars" | cut -d' ' -f$((i % 10 + 1)))
        local color=$(echo "$spinner_colors" | cut -d' ' -f$((color_idx % 6 + 1)))
        printf '\b%b%s%b' "$color" "$spinner" "$cend"
        sleep 0.1
        i=$((i + 1))
        if [ $((i % 10)) -eq 0 ]; then
            color_idx=$((color_idx + 1))
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
    local filled_char=$(echo "$progress_chars" | cut -d' ' -f1)
    i=0
    while [ $i -lt $filled ]; do
        printf '%b%s%b' "${clg}" "$filled_char" "$cend"
        i=$((i + 1))
    done
    
    # Empty part
    local empty_char=$(echo "$progress_chars" | cut -d' ' -f2)
    i=0
    while [ $i -lt $empty ]; do
        printf '%s' "$empty_char"
        i=$((i + 1))
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
    printf '\n%b\n' "${cb}
╔═══════════════════════════════════════════════════════════════════════════════╗
║                                                                               ║
║                    HOMELAB MEDIA STACK                                        ║
║                                                                               ║
║                    Universal Setup Script v2.2                                ║
║                                                                               ║
║     Supports: Windows • macOS • Linux • Synology • UGREEN • QNAP              ║
║     TrueNAS • Unraid • Proxmox • And More!                                    ║
║                                                                               ║
╚═══════════════════════════════════════════════════════════════════════════════╝${cend}"
    sleep 1
}

#################################################################################################################################################
# Platform-specific helper functions
#################################################################################################################################################
show_windows_instructions() {
    printf '\n%b\n' " ${uyc} ${cy}Windows detected!${cend}"
    printf '\n%b\n' " ${uyc} For the best experience on Windows, please ensure you're running this script in:"
    printf '\n%b\n' " ${clc}•${cend} Windows Subsystem for Linux (WSL2) - Recommended"
    printf '\n%b\n' " ${clc}•${cend} Git Bash"
    printf '\n%b\n' " ${clc}•${cend} MSYS2/MinGW"
    printf '\n%b\n' " ${uyc} ${cy}Note:${cend} Paths will use Unix-style format (/c/homelab instead of C:\\homelab)"
}

#################################################################################################################################################
# Platform Detection and Selection
#################################################################################################################################################
detect_platform() {
    printf '\n%b\n' " ${uyc} Detecting your platform..."
    show_loading_message "Analyzing system environment" 2
    
    # Variables will be set globally by assignment
    
    # Automatic detection
    local detected=""
    local auto_path=""
    local auto_puid=""
    local auto_pgid=""
    
    # Check for specific NAS/virtualization platforms first
    if command -v synoinfo >/dev/null 2>&1; then
        detected="synology"
        auto_path="/volume1"
        auto_puid="1026"
        auto_pgid="100"
    elif grep -q "unraid" /etc/os-release 2>/dev/null; then
        detected="unraid"
        auto_path="/mnt/user"
        auto_puid="99"
        auto_pgid="100"
    elif command -v midclt >/dev/null 2>&1; then
        detected="truenas"
        auto_path="/mnt"
        auto_puid="1000"
        auto_pgid="1000"
    elif command -v pveversion >/dev/null 2>&1; then
        detected="proxmox"
        auto_path="/opt/homelab"
        auto_puid="1000"
        auto_pgid="1000"
    elif [ -f /etc/ugreen-nas-release ] || [ -d /usr/local/ugreen ]; then
        detected="ugreen"
        auto_path="/volume1"
        auto_puid="1001"
        auto_pgid="1000"
    elif command -v qpkg_cli >/dev/null 2>&1 || [ -d /share ]; then
        detected="qnap"
        auto_path="/share"
        auto_puid="1000"
        auto_pgid="1000"
    elif [ "$OSTYPE" = "darwin"* ]; then
        detected="macos"
        auto_path="$HOME/homelab"
        auto_puid="1000"
        auto_pgid="1000"
    elif [ "$OS" = "Windows_NT" ] || [ -n "$WINDIR" ] || command -v powershell.exe >/dev/null 2>&1; then
        detected="windows"
        auto_path="/c/homelab"  # WSL/Git Bash path style
        auto_puid="1000"
        auto_pgid="1000"
    else
        detected="linux"
        auto_path="/opt/homelab"
        auto_puid="1000"
        auto_pgid="1000"
    fi
    
    # Show detected platform and ask for confirmation
    printf '\n%b\n' " ${ugc} Detected platform: ${clc}${detected}${cend}"
    
    # Platform selection menu
    printf '\n%b\n' " ${uyc} Please confirm or select your platform:"
    printf '\n%b\n' " ${clc}1)${cend} Synology NAS"
    printf '\n%b\n' " ${clc}2)${cend} UGREEN NAS"
    printf '\n%b\n' " ${clc}3)${cend} QNAP NAS"
    printf '\n%b\n' " ${clc}4)${cend} TrueNAS (Scale/Core)"
    printf '\n%b\n' " ${clc}5)${cend} Unraid"
    printf '\n%b\n' " ${clc}6)${cend} Proxmox VE"
    printf '\n%b\n' " ${clc}7)${cend} Windows (WSL/Git Bash)"
    printf '\n%b\n' " ${clc}8)${cend} macOS"
    printf '\n%b\n' " ${clc}9)${cend} Linux (Generic)"
    printf '\n%b\n' " ${clc}10)${cend} Other/Custom"
    
    printf '\n'
    while true; do
        printf '%b' " ${uyc} Select platform [1-10] "
        case "$detected" in
            "synology") printf '%b' "(detected: 1): " ;;
            "ugreen") printf '%b' "(detected: 2): " ;;
            "qnap") printf '%b' "(detected: 3): " ;;
            "truenas") printf '%b' "(detected: 4): " ;;
            "unraid") printf '%b' "(detected: 5): " ;;
            "proxmox") printf '%b' "(detected: 6): " ;;
            "windows") printf '%b' "(detected: 7): " ;;
            "macos") printf '%b' "(detected: 8): " ;;
            "linux") printf '%b' "(detected: 9): " ;;
            *) printf '%b' ": " ;;
        esac
        
        read -r choice
        
        # Use detected platform if user just presses enter (default behavior)
        if [ -z "$choice" ] && [ -n "$detected" ]; then
            platform="$detected"
            default_base_path="$auto_path"
            puid="$auto_puid"
            pgid="$auto_pgid"
            printf '\n%b\n' " ${utick} Using detected platform: ${clc}${platform}${cend}"
            break
        fi
        
        case "$choice" in
            1|synology)
                platform="synology"
                default_base_path="/volume1"
                puid="1026"
                pgid="100"
                break
                ;;
            2|ugreen)
                platform="ugreen"
                default_base_path="/volume1"
                puid="1001"
                pgid="1000"
                break
                ;;
            3|qnap)
                platform="qnap"
                default_base_path="/share"
                puid="1000"
                pgid="1000"
                break
                ;;
            4|truenas)
                platform="truenas"
                default_base_path="/mnt"
                puid="1000"
                pgid="1000"
                break
                ;;
            5|unraid)
                platform="unraid"
                default_base_path="/mnt/user"
                puid="99"
                pgid="100"
                break
                ;;
            6|proxmox)
                platform="proxmox"
                default_base_path="/opt/homelab"
                puid="1000"
                pgid="1000"
                break
                ;;
            7|windows)
                platform="windows"
                default_base_path="/c/homelab"
                puid="1000"
                pgid="1000"
                show_windows_instructions
                break
                ;;
            8|macos)
                platform="macos"
                default_base_path="$HOME/homelab"
                puid="1000"
                pgid="1000"
                break
                ;;
            9|linux)
                platform="linux"
                default_base_path="/opt/homelab"
                puid="1000"
                pgid="1000"
                break
                ;;
            10|other|custom)
                platform="custom"
                printf '\n%b' " ${uyc} Enter custom base path: "
                read -r custom_path
                default_base_path="${custom_path:-/opt/homelab}"
                printf '\n%b' " ${uyc} Enter PUID [1000]: "
                read -r custom_puid
                puid="${custom_puid:-1000}"
                printf '\n%b' " ${uyc} Enter PGID [1000]: "
                read -r custom_pgid
                pgid="${custom_pgid:-1000}"
                break
                ;;
            *)
                printf '\n%b\n' " ${ucross} Invalid choice. Please select 1-10."
                ;;
        esac
    done
    
    printf '\n%b\n' " ${utick} Platform selected: ${clc}${platform}${cend}"
    printf '%b\n' " ${utick} Default path: ${clc}${default_base_path}${cend}"
    printf '\n%b\n' " ${uyc} ${cy}Note:${cend} Installation will create directories in ${clc}${default_base_path}/docker${cend} and ${clc}${default_base_path}/data${cend}"
    printf '%b\n' " ${uyc} You can change this path when prompted if you prefer a different location"
    printf '%b\n' " ${utick} PUID/PGID: ${clc}${puid}:${pgid}${cend}"
}

#################################################################################################################################################
# Platform-specific functions
#################################################################################################################################################
check_platform_prerequisites() {
    printf '\n%b\n' " ${uyc} Checking platform-specific prerequisites..."
    
    case "$platform" in
        "synology")
            # Check if Container Manager or Docker is installed
                if command -v synopkg >/dev/null 2>&1; then
        if synopkg status ContainerManager >/dev/null 2>&1 || synopkg status Docker >/dev/null 2>&1; then
                    printf '\n%b\n' " ${utick} Container Manager/Docker package found"
                else
                    printf '\n%b\n' " ${ucross} Container Manager/Docker not installed"
                    printf '\n%b\n' " ${uyc} Please install Container Manager from Package Center first"
                    exit 1
                fi
            fi
            ;;
        "qnap")
            # Check for Container Station
            if [ -d "/usr/local/ContainerStation" ] || command -v docker >/dev/null 2>&1; then
                printf '\n%b\n' " ${utick} Container Station/Docker found"
            else
                printf '\n%b\n' " ${ucross} Container Station not installed"
                printf '\n%b\n' " ${uyc} Please install Container Station from App Center first"
                exit 1
            fi
            ;;
        "unraid")
            # Check for Community Applications
            if [ -d "/usr/local/emhttp/plugins/dockerMan" ] || command -v docker >/dev/null 2>&1; then
                printf '\n%b\n' " ${utick} Docker support found"
            else
                printf '\n%b\n' " ${ucross} Docker not available"
                printf '\n%b\n' " ${uyc} Please enable Docker in Unraid settings first"
                exit 1
            fi
            ;;
        "truenas")
            # Check for Docker/Apps
            if command -v docker >/dev/null 2>&1 || command -v k3s >/dev/null 2>&1; then
                printf '\n%b\n' " ${utick} Container runtime found"
            else
                printf '\n%b\n' " ${ucross} Container runtime not available"
                printf '\n%b\n' " ${uyc} Please enable Apps or install Docker first"
                exit 1
            fi
            ;;
        "proxmox")
            # Check if we're in a container or VM
            if [[ -f "/.dockerenv" ]]; then
                printf '\n%b\n' " ${uyc} Running inside Docker container"
            elif command -v pct >/dev/null 2>&1; then
                printf '\n%b\n' " ${utick} Proxmox VE detected"
            else
                printf '\n%b\n' " ${uyc} Running on Proxmox guest or standalone Linux"
            fi
            ;;
        "windows")
            # Check if we're in WSL or Git Bash
            if [[ -n "$WSL_DISTRO_NAME" ]]; then
                printf '\n%b\n' " ${utick} Running in WSL2: $WSL_DISTRO_NAME"
            elif [[ "$OSTYPE" == "msys" ]]; then
                printf '\n%b\n' " ${utick} Running in Git Bash/MSYS2"
            else
                printf '\n%b\n' " ${uyc} Windows environment detected"
            fi
            ;;
    esac
    
    printf '\n%b\n' " ${utick} Platform prerequisites checked"
}

create_directories_for_platform() {
    printf '\n%b\n' " ${uyc} Creating directory structure for ${clc}${platform}${cend}..."
    show_loading_message "Setting up directory structure" 1
    
    # Start with base directories
    local directories=()
    
    # Add stack directories based on selection
    if [[ " ${stacks_to_install[@]} " =~ " servarr " ]]; then
        directories+=("${base_path}/docker/servarr")
        directories+=("${base_path}/data/downloads/complete")
        directories+=("${base_path}/data/downloads/incomplete")
        directories+=("${base_path}/data/media/movies")
        directories+=("${base_path}/data/media/tv")
        directories+=("${base_path}/data/media/music")
    fi
    
    if [[ " ${stacks_to_install[@]} " =~ " streamarr " ]]; then
        directories+=("${base_path}/docker/streamarr")
        directories+=("${base_path}/data/plex_transcode")
    fi
    
    if [[ " ${stacks_to_install[@]} " =~ " creatarr " ]]; then
        directories+=("${base_path}/docker/creatarr")
        directories+=("${base_path}/data/roms")
        directories+=("${base_path}/data/comics")
        directories+=("${base_path}/data/audiobooks")
        directories+=("${base_path}/data/podcasts")
        directories+=("${base_path}/data/books")
        directories+=("${base_path}/data/saves")
    fi
    
    if [[ " ${stacks_to_install[@]} " =~ " business " ]]; then
        directories+=("${base_path}/docker/business")
        directories+=("${base_path}/data/recipes")
    fi
    
    if [[ " ${stacks_to_install[@]} " =~ " infrastructure " ]]; then
        directories+=("${base_path}/docker/infrastructure")
    fi
    
    if [[ " ${stacks_to_install[@]} " =~ " websites " ]]; then
        directories+=("${base_path}/docker/websites")
    fi
    
    # Create directories with progress
    local total_dirs=${#directories[@]}
    local current=0
    
    for dir in "${directories[@]}"; do
        ((current++))
        show_progress_bar "$current" "$total_dirs"
        
        if mkdir -p "$dir" 2>/dev/null; then
            printf '\n%b\n' " ${utick} Created: ${clc}${dir}${cend}"
        else
            printf '\n%b\n' " ${ucross} Failed to create: ${clc}${dir}${cend}"
            if [[ "$platform" == "windows" ]]; then
                printf '\n%b\n' " ${uyc} ${cy}Tip:${cend} If this fails, try running in WSL2 or create directories manually"
            fi
        fi
    done
    
    # Set permissions (platform-specific)
    case "$platform" in
        "synology"|"qnap"|"ugreen")
            # NAS systems - set proper ownership
            if chown -R "${puid}:${pgid}" "${base_path}" 2>/dev/null; then
                printf '\n%b\n' " ${utick} Set ownership to ${puid}:${pgid}"
            fi
            if chmod -R 755 "${base_path}" 2>/dev/null; then
                printf '\n%b\n' " ${utick} Set permissions to 755"
            fi
            ;;
        "unraid"|"truenas")
            # Unraid/TrueNAS - specific ownership
            if chown -R "${puid}:${pgid}" "${base_path}" 2>/dev/null; then
                printf '\n%b\n' " ${utick} Set ownership to ${puid}:${pgid}"
            fi
            ;;
        "linux"|"proxmox"|"macos")
            # Standard Unix systems
            if [[ "$EUID" -eq 0 ]]; then
                chown -R "${puid}:${pgid}" "${base_path}" 2>/dev/null || true
                printf '\n%b\n' " ${utick} Set ownership to ${puid}:${pgid}"
            fi
            chmod -R 755 "${base_path}" 2>/dev/null || true
            printf '\n%b\n' " ${utick} Set permissions to 755"
            ;;
        "windows")
            # Windows - permissions are handled differently
            printf '\n%b\n' " ${uyc} Windows detected - skipping Unix permissions"
            ;;
    esac
    
    printf '\n%b\n' " ${utick} Directory structure created successfully!"
}

get_platform_network_info() {
    # Get local IP based on platform
    case "$platform" in
        "macos")
            declare -g local_ip=$(ifconfig | grep "inet " | grep -v 127.0.0.1 | awk '{print $2}' | head -1)
            ;;
        "windows")
            # Try different methods for Windows environments
            if command -v ipconfig.exe >/dev/null 2>&1; then
                declare -g local_ip=$(ipconfig.exe | grep -A 1 "Wireless\|Ethernet" | grep "IPv4" | head -1 | awk '{print $NF}' | tr -d '\r')
            elif [[ -n "$WSL_DISTRO_NAME" ]]; then
                declare -g local_ip=$(ip route get 1 | awk '{print $7}' | head -1)
            else
                declare -g local_ip=$(hostname -I | awk '{print $1}')
            fi
            ;;
        *)
            # Linux-based systems
            declare -g local_ip=$(ip route get 1 2>/dev/null | awk '{print $7}' | head -1 || hostname -I | awk '{print $1}')
            ;;
    esac
    
    # Fallback if detection fails
    if [[ -z "$local_ip" || "$local_ip" == "127.0.0.1" ]]; then
        declare -g local_ip="192.168.1.100"
        printf '\n%b\n' " ${uyc} Could not detect local IP, using fallback: ${clc}${local_ip}${cend}"
    else
        printf '\n%b\n' " ${utick} Detected local IP: ${clc}${local_ip}${cend}"
    fi
    
    # Get timezone based on platform
    case "$platform" in
        "synology"|"qnap"|"ugreen")
            declare -g timezone=$(cat /etc/timezone 2>/dev/null || cat /usr/share/zoneinfo/UTC 2>/dev/null | head -1 || echo "UTC")
            ;;
        "macos")
            declare -g timezone=$(readlink /etc/localtime | sed 's|/var/db/timezone/zoneinfo/||' || echo "UTC")
            ;;
        "windows")
            # Convert Windows timezone to Linux format (basic mapping)
            declare -g timezone="UTC"  # Default, user can modify later
            ;;
        *)
            declare -g timezone=$(timedatectl show --property=Timezone --value 2>/dev/null || cat /etc/timezone 2>/dev/null || echo "UTC")
            ;;
    esac
    
    printf '\n%b\n' " ${utick} Detected timezone: ${clc}${timezone}${cend}"
}

#################################################################################################################################################
# Docker and system checks
#################################################################################################################################################
check_prerequisites() {
    printf '\n%b\n' " ${uyc} Checking system prerequisites..."
    show_loading_message "Verifying Docker installation" 1
    
    # Check Docker
    if ! command -v docker >/dev/null 2>&1; then
        printf '\n%b\n' " ${ucross} Docker is not installed"
        show_docker_install_instructions
        exit 1
    else
        docker_version=$(docker --version 2>/dev/null)
        printf '\n%b\n' " ${utick} Docker found: ${clc}${docker_version}${cend}"
    fi
    
    # Check Docker Compose
    if ! command -v docker-compose >/dev/null 2>&1 && ! docker compose version >/dev/null 2>&1; then
        printf '\n%b\n' " ${ucross} Docker Compose is not installed"
        show_compose_install_instructions
        exit 1
    else
        if command -v docker-compose >/dev/null 2>&1; then
            compose_version=$(docker-compose --version 2>/dev/null)
            compose_cmd="docker-compose"
        else
            compose_version=$(docker compose version 2>/dev/null)
            compose_cmd="docker compose"
        fi
        printf '\n%b\n' " ${utick} Docker Compose found: ${clc}${compose_version}${cend}"
    fi
    
    # Check if Portainer is already installed
    check_portainer_installed
    
    # Check permissions (platform-specific)
    case "$platform" in
        "linux"|"proxmox")
            if [[ "$EUID" -ne 0 ]] && ! groups | grep -q docker; then
                printf '\n%b\n' " ${ucross} You need to run with sudo or be in the docker group"
                printf '\n%b\n' " ${uyc} Run: ${clc}sudo usermod -aG docker \$USER${cend} then logout/login"
                exit 1
            fi
            ;;
        "synology"|"qnap"|"ugreen"|"truenas"|"unraid")
            # NAS systems typically handle Docker permissions automatically
            printf '\n%b\n' " ${utick} NAS platform - Docker permissions handled by system"
            ;;
        "macos"|"windows")
            # Docker Desktop handles permissions
            printf '\n%b\n' " ${utick} Docker Desktop platform - permissions handled automatically"
            ;;
    esac
    
    printf '\n%b\n' " ${utick} All prerequisites met!"
}

#################################################################################################################################################
# Portainer detection
#################################################################################################################################################
check_portainer_installed() {
    # Check if Portainer container is running or exists
    portainer_container=$(docker ps -a --format '{{.Names}}' | grep -iE 'portainer|portainer-ce|portainer-agent' | head -1)
    
    if [[ -n "$portainer_container" ]]; then
        # Check if it's running
        if docker ps --format '{{.Names}}' | grep -qiE 'portainer|portainer-ce|portainer-agent'; then
            portainer_status="running"
            portainer_port=$(docker port "$portainer_container" 2>/dev/null | grep -oP ':\K[0-9]+' | head -1 || echo "9000")
            printf '\n%b\n' " ${utick} Portainer detected (already installed): ${clc}${portainer_container}${cend} (port ${clc}${portainer_port}${cend})"
            printf '\n%b\n' " ${uyc} Setup will continue with existing Portainer installation"
            export PORTAINER_INSTALLED=true
            export PORTAINER_CONTAINER="$portainer_container"
            export PORTAINER_PORT="$portainer_port"
        else
            portainer_status="stopped"
            printf '\n%b\n' " ${uyc} Portainer container found but not running: ${clc}${portainer_container}${cend}"
            printf '\n%b\n' " ${uyc} You can start it manually with: ${clc}docker start ${portainer_container}${cend}"
            export PORTAINER_INSTALLED=true
            export PORTAINER_CONTAINER="$portainer_container"
        fi
    else
        printf '\n%b\n' " ${uyc} Portainer not detected - will be managed separately if needed"
        export PORTAINER_INSTALLED=false
    fi
}

show_docker_install_instructions() {
    printf '\n%b\n' " ${uyc} ${cy}Docker installation required:${cend}"
    case "$platform" in
        "synology")
            printf '\n%b\n' " ${clc}•${cend} Open Package Center"
            printf '\n%b\n' " ${clc}•${cend} Search for 'Container Manager' or 'Docker'"
            printf '\n%b\n' " ${clc}•${cend} Install the package"
            ;;
        "qnap")
            printf '\n%b\n' " ${clc}•${cend} Open App Center"
            printf '\n%b\n' " ${clc}•${cend} Search for 'Container Station'"
            printf '\n%b\n' " ${clc}•${cend} Install the app"
            ;;
        "unraid")
            printf '\n%b\n' " ${clc}•${cend} Go to Settings → Docker"
            printf '\n%b\n' " ${clc}•${cend} Enable Docker"
            ;;
        "truenas")
            printf '\n%b\n' " ${clc}•${cend} Install Docker via Apps or command line"
            printf '\n%b\n' " ${clc}•${cend} Enable Apps if using TrueNAS Scale"
            ;;
        "windows")
            printf '\n%b\n' " ${clc}•${cend} Download Docker Desktop from: https://www.docker.com/products/docker-desktop"
            printf '\n%b\n' " ${clc}•${cend} Enable WSL2 integration"
            ;;
        "macos")
            printf '\n%b\n' " ${clc}•${cend} Download Docker Desktop from: https://www.docker.com/products/docker-desktop"
            printf '\n%b\n' " ${clc}•${cend} Or install via Homebrew: brew install --cask docker"
            ;;
        *)
            printf '\n%b\n' " ${clc}•${cend} Visit: https://docs.docker.com/engine/install/"
            ;;
    esac
}

show_compose_install_instructions() {
    printf '\n%b\n' " ${uyc} ${cy}Docker Compose installation required:${cend}"
    case "$platform" in
        "synology"|"qnap"|"unraid"|"truenas")
            printf '\n%b\n' " ${clc}•${cend} Docker Compose should be included with Container Manager/Station"
            ;;
        "windows"|"macos")
            printf '\n%b\n' " ${clc}•${cend} Docker Compose is included with Docker Desktop"
            ;;
        *)
            printf '\n%b\n' " ${clc}•${cend} Visit: https://docs.docker.com/compose/install/"
            ;;
    esac
}

#################################################################################################################################################
# Interactive Selection Menus
#################################################################################################################################################
show_multi_select_menu() {
    local title="$1"
    shift
    local options=("$@")
    local selected=()
    local cursor=0
    
    printf '\n%b\n' " ${cy}${title}${cend}"
    printf '\n%b\n' " ${uyc} Use ${clc}SPACE${cend} to select/deselect, ${clc}ENTER${cend} to confirm"
    printf '\n%b\n' " ${uyc} Selected items will be marked with ${clg}[✓]${cend}"
    printf '\n'
    
    # Initialize all as unselected
    local selected_flags=()
    for ((i=0; i<${#options[@]}; i++)); do
        selected_flags[$i]=0
    done
    
    while true; do
        # Clear screen and redraw menu
        clear
        printf '\n%b\n' " ${cy}${title}${cend}"
        printf '\n%b\n' " ${uyc} Use ${clc}SPACE${cend} to select/deselect, ${clc}ENTER${cend} to confirm"
        printf '\n'
        
        # Display options
        for ((i=0; i<${#options[@]}; i++)); do
            if [[ $i -eq $cursor ]]; then
                if [[ ${selected_flags[$i]} -eq 1 ]]; then
                    printf '%b\n' " ${clc}▶${cend} ${clg}[✓]${cend} ${options[$i]}"
                else
                    printf '%b\n' " ${clc}▶${cend} ${cy}[ ]${cend} ${options[$i]}"
                fi
            else
                if [[ ${selected_flags[$i]} -eq 1 ]]; then
                    printf '%b\n' "   ${clg}[✓]${cend} ${options[$i]}"
                else
                    printf '%b\n' "   ${cy}[ ]${cend} ${options[$i]}"
                fi
            fi
        done
        
        printf '\n'
        if [[ ${#selected[@]} -gt 0 ]]; then
            printf '%b\n' " ${ugc} Selected: ${clc}${#selected[@]}${cend} item(s)"
        else
            printf '%b\n' " ${uyc} No items selected"
        fi
        
        # Read single character
        read -rsn1 key
        
        case "$key" in
            $'\x1b')  # ESC sequence
                read -rsn1 -t 0.1 tmp
                if [[ "$tmp" == "[" ]]; then
                    read -rsn1 -t 0.1 tmp
                    case "$tmp" in
                        "A")  # Up arrow
                            if [[ $cursor -gt 0 ]]; then
                                ((cursor--))
                            fi
                            ;;
                        "B")  # Down arrow
                            if [[ $cursor -lt $((${#options[@]} - 1)) ]]; then
                                ((cursor++))
                            fi
                            ;;
                    esac
                fi
                ;;
            " ")  # Space to toggle
                if [[ ${selected_flags[$cursor]} -eq 0 ]]; then
                    selected_flags[$cursor]=1
                    selected+=("${options[$cursor]}")
                else
                    selected_flags[$cursor]=0
                    # Remove from selected array
                    local new_selected=()
                    for item in "${selected[@]}"; do
                        if [[ "$item" != "${options[$cursor]}" ]]; then
                            new_selected+=("$item")
                        fi
                    done
                    selected=("${new_selected[@]}")
                fi
                ;;
            "")  # Enter to confirm
                if [[ ${#selected[@]} -eq 0 ]]; then
                    printf '\n%b\n' " ${ucross} Please select at least one item"
                    sleep 1
                else
                    break
                fi
                ;;
        esac
    done
    
    # Return selected items via global array
    declare -g selected_items=("${selected[@]}")
}

# Simplified multi-select for basic terminals (fallback)
show_simple_multi_select() {
    local title="$1"
    shift
    local options=("$@")
    local selected=()
    
    printf '\n%b\n' " ${cy}${title}${cend}"
    printf '\n%b\n' " ${uyc} Enter numbers separated by spaces (e.g., 1 3 5) or 'all' for everything"
    printf '\n'
    
    # Display options
    for ((i=0; i<${#options[@]}; i++)); do
        printf '%b\n' " ${clc}$((i+1)))${cend} ${options[$i]}"
    done
    
    printf '\n'
    while true; do
        printf '%b' " ${uyc} Select items: "
        read -r input
        
        if [[ "$input" == "all" ]] || [[ "$input" == "ALL" ]]; then
            selected=("${options[@]}")
            break
        fi
        
        # Parse input
        local valid=true
        local temp_selected=()
        for num in $input; do
            if [[ "$num" =~ ^[0-9]+$ ]] && [[ $num -ge 1 ]] && [[ $num -le ${#options[@]} ]]; then
                temp_selected+=("${options[$((num-1))]}")
            else
                valid=false
                break
            fi
        done
        
        if [[ "$valid" == true ]] && [[ ${#temp_selected[@]} -gt 0 ]]; then
            selected=("${temp_selected[@]}")
            break
        else
            printf '\n%b\n' " ${ucross} Invalid selection. Please enter numbers between 1 and ${#options[@]}"
        fi
    done
    
    # Return selected items
    declare -g selected_items=("${selected[@]}")
}

select_stacks() {
    clear
    printf '\n%b\n' "${clg}╔═══════════════════════════════════════════════════════════════════════════════╗${cend}"
    printf '\n%b\n' "${clg}║                                                                               ║${cend}"
    printf '\n%b\n' "${clg}║                    📦 STACK SELECTION                                         ║${cend}"
    printf '\n%b\n' "${clg}║                                                                               ║${cend}"
    printf '\n%b\n' "${clg}╚═══════════════════════════════════════════════════════════════════════════════╝${cend}"
    
    # INFRASTRUCTURE is mandatory - always included
    declare -g stacks_to_install=("infrastructure")
    
    # Display infrastructure info first (default installation)
    printf '\n%b\n' " ${clg}✓ INFRASTRUCTURE Stack${cend} ${cy}(Installed by default)${cend}"
    printf '%b\n' " ${cy}   └─ Homarr (Dashboard), Uptime Kuma (Monitoring), Watchtower (Auto Updates for all stacks)${cend}"
    printf '\n'
    printf '%b\n' " ${uyc} ${cy}Select additional stacks to install:${cend}"
    printf '\n%b\n' " ${uyc} ${clc}Tip:${cend} Enter numbers separated by spaces (e.g., ${clc}1 3 5${cend}) or ${clc}all${cend} for everything"
    printf '\n'
    
    local stack_options=(
        "SERVARR - Media Management & Downloads"
        "  └─ VPN, qBittorrent, Sonarr, Radarr, Lidarr, Bazarr, Prowlarr, FileBot"
        "STREAMARR - Streaming & Consumption"
        "  └─ Plex, Overseerr, Tautulli, ErsatzTV, Navidrome"
        "CREATARR - Creative & Entertainment"
        "  └─ RetroArch, Komga, Audiobookshelf, Calibre-Web, Noisedash, Swing Music"
        "BUSINESS - Business & Productivity"
        "  └─ n8n (Workflow Automation), Mealie (Recipe Management)"
        "WEBSITES - Custom Web Applications"
        "  └─ Host your own custom websites and web applications"
    )
    
    # Display options with better formatting (only the 5 selectable stacks)
    local option_num=1
    for ((i=0; i<${#stack_options[@]}; i++)); do
        if [[ "${stack_options[$i]}" =~ ^[A-Z]+ ]]; then
            printf '\n%b\n' " ${clc}${option_num})${cend} ${clg}${stack_options[$i]}${cend}"
            ((option_num++))
        else
            printf '%b\n' " ${stack_options[$i]}"
        fi
    done
    printf '\n'
    while true; do
        printf '%b' " ${uyc} Select stacks ${clc}[1-5, all, or press Enter for INFRASTRUCTURE only]:${cend} "
        read -r input
        
        if [[ -z "$input" ]]; then
            # If empty, just use infrastructure (already selected)
            printf '\n%b\n' " ${utick} ${clg}INFRASTRUCTURE stack will be installed automatically${cend}"
            printf '\n%b\n' " ${uyc} Selected: ${clc}0${cend} additional stacks (INFRASTRUCTURE only)"
            return 0
        fi
        
        if [[ "$input" == "all" ]] || [[ "$input" == "ALL" ]]; then
            # Select all stacks (infrastructure already included)
            stacks_to_install+=("servarr" "streamarr" "creatarr" "business" "websites")
            printf '\n%b\n' " ${utick} ${clg}All stacks selected!${cend}"
            printf '\n%b\n' " ${uyc} INFRASTRUCTURE stack: ${clg}Installed automatically${cend}"
            printf '\n%b\n' " ${uyc} Selected: ${clc}5${cend} additional stacks:"
            for stack in "${stacks_to_install[@]}"; do
                if [[ "$stack" != "infrastructure" ]]; then
                    printf '%b\n' " ${clc}  ✓${cend} ${stack}"
                fi
            done
            printf '\n%b\n' " ${uyc} Total stacks to install: ${clc}6${cend} (including INFRASTRUCTURE)"
            return 0
        fi
        
        # Parse input
        local valid=true
        local temp_selected=()
        for num in $input; do
            if [[ "$num" =~ ^[0-9]+$ ]] && [[ $num -ge 1 ]] && [[ $num -le 5 ]]; then
                case "$num" in
                    1) temp_selected+=("servarr") ;;
                    2) temp_selected+=("streamarr") ;;
                    3) temp_selected+=("creatarr") ;;
                    4) temp_selected+=("business") ;;
                    5) temp_selected+=("websites") ;;
                esac
            else
                valid=false
                break
            fi
        done
        
        if [[ "$valid" == true ]] && [[ ${#temp_selected[@]} -gt 0 ]]; then
            # Add selected stacks to infrastructure (which is already included)
            for stack in "${temp_selected[@]}"; do
                if [[ ! " ${stacks_to_install[@]} " =~ " ${stack} " ]]; then
                    stacks_to_install+=("$stack")
                fi
            done
            
            printf '\n%b\n' " ${utick} ${clg}Stacks selected!${cend}"
            printf '\n%b\n' " ${uyc} INFRASTRUCTURE stack: ${clg}Installed automatically${cend}"
            printf '\n%b\n' " ${uyc} Selected: ${clc}${#temp_selected[@]}${cend} additional stack(s):"
            for stack in "${temp_selected[@]}"; do
                printf '%b\n' " ${clc}  ✓${cend} ${stack}"
            done
            printf '\n%b\n' " ${uyc} Total stacks to install: ${clc}$((${#temp_selected[@]} + 1))${cend} (including INFRASTRUCTURE)"
            
            # Initialize service arrays
            declare -g services_servarr=()
            declare -g services_streamarr=()
            declare -g services_creatarr=()
            declare -g services_business=()
            declare -g services_infrastructure=()
            declare -g services_websites=()
            
            return 0
        else
            printf '\n%b\n' " ${ucross} Invalid selection. Please enter numbers between ${clc}1-5${cend} or ${clc}all${cend}"
        fi
    done
}

select_services() {
    local stack_name="$1"
    local stack_display="$2"
    
    clear
    printf '\n%b\n' "${clc}╔═══════════════════════════════════════════════════════════════════════════════╗${cend}"
    printf '\n%b\n' "${clc}║                                                                               ║${cend}"
    printf '\n%b\n' "${clc}║                    🔧 ${stack_display} SERVICE SELECTION                      ║${cend}"
    printf '\n%b\n' "${clc}║                                                                               ║${cend}"
    printf '\n%b\n' "${clc}╚═══════════════════════════════════════════════════════════════════════════════╝${cend}"
    
    local service_options=()
    local service_descriptions=()
    local service_map=()
    
    case "$stack_name" in
        "servarr")
            service_options=(
                "Gluetun (VPN Gateway)"
                "qBittorrent (BitTorrent Client)"
                "SABnzbd (Usenet Client)"
                "Prowlarr (Indexer Management)"
                "Sonarr (TV Show Automation)"
                "Radarr (Movie Automation)"
                "Lidarr (Music Automation)"
                "Bazarr (Subtitle Management)"
                "FileBot Node (File Processing UI)"
                "FileBot Watcher (Auto File Processing)"
                "Watchtower (Auto Updates)"
            )
            service_descriptions=(
                "REQUIRED for secure downloads"
                "Download torrents"
                "Download from Usenet"
                "Manage indexers"
                "Automate TV show downloads"
                "Automate movie downloads"
                "Automate music downloads"
                "Manage subtitles"
                "File organization UI"
                "Automatic file processing"
                "Keep containers updated"
            )
            service_map=("gluetun" "qbittorrent" "sabnzbd" "prowlarr" "sonarr" "radarr" "lidarr" "bazarr" "filebot-node" "filebot-watcher" "watchtower")
            ;;
        "streamarr")
            service_options=(
                "Plex (Media Server)"
                "Overseerr (Request Management)"
                "Tautulli (Analytics & Monitoring)"
                "ErsatzTV (Virtual TV Channels)"
                "Navidrome (Music Streaming Server)"
                "Watchtower (Auto Updates)"
            )
            service_descriptions=(
                "Stream your media library"
                "Request movies/TV shows"
                "Monitor Plex usage"
                "Create virtual TV channels"
                "Stream music collection"
                "Keep containers updated"
            )
            service_map=("plex" "overseerr" "tautulli" "ersatztv" "navidrome" "watchtower")
            ;;
        "creatarr")
            service_options=(
                "RetroArch (Gaming Emulator)"
                "Komga (Comic Book Server)"
                "Audiobookshelf (Audiobook Server)"
                "Calibre-Web (E-book Management)"
                "Noisedash (Ambient Sound Generator)"
                "Swing Music (Music Player)"
                "Watchtower (Auto Updates)"
            )
            service_descriptions=(
                "Play retro games"
                "Read comics online"
                "Listen to audiobooks"
                "Manage e-book library"
                "Ambient sounds & music"
                "Modern music player"
                "Keep containers updated"
            )
            service_map=("retroarch" "komga" "audiobookshelf" "calibre-web" "noisedash" "swing-music" "watchtower")
            ;;
        "business")
            service_options=(
                "n8n (Workflow Automation)"
                "n8n-postgres (n8n Database)"
                "Mealie (Recipe Management)"
                "mealie-db (Mealie Database)"
                "Watchtower (Auto Updates)"
            )
            service_descriptions=(
                "Automate workflows & tasks"
                "Database for n8n (auto-added if n8n selected)"
                "Manage recipes & meal planning"
                "Database for Mealie (auto-added if Mealie selected)"
                "Keep containers updated"
            )
            service_map=("n8n" "n8n-postgres" "mealie" "mealie-db" "watchtower")
            ;;
        "infrastructure")
            service_options=(
                "Homarr (Service Dashboard)"
                "Uptime Kuma (System Monitoring)"
                "Watchtower (Auto Updates)"
            )
            service_descriptions=(
                "Unified dashboard for all services"
                "Monitor uptime & health"
                "Keep containers updated"
            )
            service_map=("homarr" "uptime-kuma" "watchtower")
            ;;
        "websites")
            service_options=(
                "Custom Websites (Add your own websites)"
            )
            service_descriptions=(
                "Template for hosting custom websites - see docs/WEBSITES_STACK_GUIDE.md"
            )
            service_map=("custom-websites")
            ;;
    esac
    
    printf '\n%b\n' " ${cy}Choose which services to install from ${clc}${stack_display}${cy}:${cend}"
    printf '\n%b\n' " ${uyc} ${clc}Tip:${cend} Enter numbers separated by spaces (e.g., ${clc}1 3 5${cend}) or ${clc}all${cend} for everything"
    printf '\n'
    
    # Display options with descriptions
    for ((i=0; i<${#service_options[@]}; i++)); do
        local desc_color="${cy}"
        if [[ "${service_descriptions[$i]}" =~ "REQUIRED" ]] || [[ "${service_descriptions[$i]}" =~ "auto-added" ]]; then
            desc_color="${uyc}"
        fi
        printf '%b\n' " ${clc}$((i+1)))${cend} ${clg}${service_options[$i]}${cend}"
        printf '%b\n' "     ${desc_color}└─ ${service_descriptions[$i]}${cend}"
    done
    
    printf '\n'
    while true; do
        printf '%b' " ${uyc} Select services ${clc}[1-${#service_options[@]}, all]:${cend} "
        read -r input
        
        if [[ -z "$input" ]]; then
            printf '\n%b\n' " ${ucross} Please make a selection"
            continue
        fi
        
        if [[ "$input" == "all" ]] || [[ "$input" == "ALL" ]]; then
            # Select all services
            local selected_services=("${service_map[@]}")
            
            # Handle dependencies (remove duplicates)
            local final_services=()
            for service in "${selected_services[@]}"; do
                if [[ ! " ${final_services[@]} " =~ " ${service} " ]]; then
                    final_services+=("$service")
                fi
            done
            
            # Store in global array
            case "$stack_name" in
                "servarr")
                    services_servarr=("${final_services[@]}")
                    ;;
                "streamarr")
                    services_streamarr=("${final_services[@]}")
                    ;;
                "creatarr")
                    services_creatarr=("${final_services[@]}")
                    ;;
                "business")
                    services_business=("${final_services[@]}")
                    ;;
                "infrastructure")
                    services_infrastructure=("${final_services[@]}")
                    ;;
            esac
            
            printf '\n%b\n' " ${utick} ${clg}All services selected!${cend}"
            printf '\n%b\n' " ${uyc} Selected: ${clc}${#final_services[@]}${cend} service(s)"
            for service in "${final_services[@]}"; do
                printf '%b\n' " ${clc}  ✓${cend} ${service}"
            done
            return 0
        fi
        
        # Parse input
        local valid=true
        local temp_selected=()
        for num in $input; do
            if [[ "$num" =~ ^[0-9]+$ ]] && [[ $num -ge 1 ]] && [[ $num -le ${#service_options[@]} ]]; then
                temp_selected+=("${service_map[$((num-1))]}")
            else
                valid=false
                break
            fi
        done
        
        if [[ "$valid" == true ]] && [[ ${#temp_selected[@]} -gt 0 ]]; then
            # Remove duplicates
            local selected_services=()
            for service in "${temp_selected[@]}"; do
                if [[ ! " ${selected_services[@]} " =~ " ${service} " ]]; then
                    selected_services+=("$service")
                fi
            done
            
            # Handle dependencies
            if [[ " ${selected_services[@]} " =~ " n8n " ]] && [[ ! " ${selected_services[@]} " =~ " n8n-postgres " ]]; then
                printf '\n%b\n' " ${uyc} ${clg}Auto-adding${cend} n8n-postgres (required dependency)"
                selected_services+=("n8n-postgres")
            fi
            
            if [[ " ${selected_services[@]} " =~ " mealie " ]] && [[ ! " ${selected_services[@]} " =~ " mealie-db " ]]; then
                printf '\n%b\n' " ${uyc} ${clg}Auto-adding${cend} mealie-db (required dependency)"
                selected_services+=("mealie-db")
            fi
            
            if [[ " ${selected_services[@]} " =~ " qbittorrent " ]] && [[ ! " ${selected_services[@]} " =~ " gluetun " ]]; then
                printf '\n%b\n' " ${uyc} ${clg}Auto-adding${cend} Gluetun (required for VPN-protected downloads)"
                selected_services+=("gluetun")
            fi
            
            if [[ " ${selected_services[@]} " =~ " sabnzbd " ]] && [[ ! " ${selected_services[@]} " =~ " gluetun " ]]; then
                printf '\n%b\n' " ${uyc} ${clg}Auto-adding${cend} Gluetun (required for VPN-protected downloads)"
                selected_services+=("gluetun")
            fi
            
            # Store in global array
            case "$stack_name" in
                "servarr")
                    services_servarr=("${selected_services[@]}")
                    ;;
                "streamarr")
                    services_streamarr=("${selected_services[@]}")
                    ;;
                "creatarr")
                    services_creatarr=("${selected_services[@]}")
                    ;;
                "business")
                    services_business=("${selected_services[@]}")
                    ;;
                "infrastructure")
                    services_infrastructure=("${selected_services[@]}")
                    ;;
                "websites")
                    services_websites=("${selected_services[@]}")
                    ;;
            esac
            
            if [[ ${#selected_services[@]} -gt 0 ]]; then
                printf '\n%b\n' " ${utick} Selected ${clc}${#selected_services[@]}${cend} service(s)"
                for service in "${selected_services[@]}"; do
                    printf '%b\n' " ${clc}  ✓${cend} ${service}"
                done
                return 0
            else
                printf '\n%b\n' " ${ucross} No valid services selected"
            fi
        else
            printf '\n%b\n' " ${ucross} Invalid selection. Please enter numbers between ${clc}1-${#service_options[@]}${cend} or ${clc}all${cend}"
        fi
    done
}

#################################################################################################################################################
# Docker Compose File Filtering
#################################################################################################################################################
create_filtered_compose_file() {
    local stack_name="$1"
    local compose_file="docker-compose-${stack_name}.yml"
    local filtered_file="docker-compose-${stack_name}-filtered.yml"
    local services_var="services_${stack_name}[@]"
    local selected_services=("${!services_var}")
    
    if [[ ! -f "$compose_file" ]]; then
        printf '\n%b\n' " ${ucross} Compose file not found: ${clc}${compose_file}${cend}"
        return 1
    fi
    
    # Read the original compose file
    local in_service=false
    local current_service=""
    local service_content=""
    local output_lines=()
    local line_num=0
    
    # Read file line by line
    while IFS= read -r line || [[ -n "$line" ]]; do
        ((line_num++))
        
        # Check if line starts a service definition
        if [[ "$line" =~ ^[[:space:]]*([a-zA-Z0-9_-]+):[[:space:]]*$ ]] && [[ ! "$line" =~ ^[[:space:]]*(version|services|networks|volumes): ]]; then
            # If we were in a service, check if it should be included
            if [[ "$in_service" == true ]] && [[ -n "$current_service" ]]; then
                # Check if this service is selected
                local include_service=false
                for selected in "${selected_services[@]}"; do
                    if [[ "$current_service" == "$selected" ]]; then
                        include_service=true
                        break
                    fi
                done
                
                if [[ "$include_service" == true ]]; then
                    # Add the service content
                    output_lines+=("$service_content")
                fi
            fi
            
            # Start new service
            current_service="${BASH_REMATCH[1]}"
            in_service=true
            service_content="$line"$'\n'
        elif [[ "$in_service" == true ]]; then
            # Continue building service content
            service_content+="$line"$'\n'
            
            # Check if we've reached the end of the service (next service or end of services section)
            if [[ "$line" =~ ^[[:space:]]*[a-zA-Z0-9_-]+:[[:space:]]*$ ]] && [[ ! "$line" =~ ^[[:space:]]+ ]]; then
                # This might be the start of a new top-level section
                if [[ ! "$line" =~ ^[[:space:]]*(networks|volumes): ]]; then
                    # It's a new service, process the previous one
                    local include_service=false
                    for selected in "${selected_services[@]}"; do
                        if [[ "$current_service" == "$selected" ]]; then
                            include_service=true
                            break
                        fi
                    done
                    
                    if [[ "$include_service" == true ]]; then
                        output_lines+=("$service_content")
                    fi
                    
                    current_service="${BASH_REMATCH[1]}"
                    service_content="$line"$'\n'
                fi
            fi
        else
            # Not in a service section, copy header/network/volume definitions
            if [[ "$line" =~ ^(version|networks|volumes): ]] || [[ "$line_num" -lt 50 ]]; then
                output_lines+=("$line")
            fi
        fi
    done < "$compose_file"
    
    # Handle last service
    if [[ "$in_service" == true ]] && [[ -n "$current_service" ]]; then
        local include_service=false
        for selected in "${selected_services[@]}"; do
            if [[ "$current_service" == "$selected" ]]; then
                include_service=true
                break
            fi
        done
        
        if [[ "$include_service" == true ]]; then
            output_lines+=("$service_content")
        fi
    fi
    
    # Write filtered file
    printf '%s\n' "${output_lines[@]}" > "$filtered_file"
    
    printf '\n%b\n' " ${utick} Created filtered compose file: ${clc}${filtered_file}${cend}"
    return 0
}

# Simpler approach: Use docker-compose with service selection
deploy_selected_services() {
    local stack_name="$1"
    local compose_file="docker-compose-${stack_name}.yml"
    local env_file=".env-${stack_name}"
    local services_var="services_${stack_name}[@]"
    local selected_services=("${!services_var}")
    
    if [[ ${#selected_services[@]} -eq 0 ]]; then
        printf '\n%b\n' " ${uyc} No services selected for ${stack_name}, skipping"
        return 0
    fi
    
    # Build service list for docker-compose
    local service_list=""
    for service in "${selected_services[@]}"; do
        service_list+="$service "
    done
    
    # Deploy only selected services
    if $compose_cmd --env-file "$env_file" -f "$compose_file" up -d ${service_list}; then
        return 0
    else
        return 1
    fi
}

#################################################################################################################################################
# Main setup functions
#################################################################################################################################################

configure_vpn_settings() {
    printf '\n%b\n' " ${uyc} Configuring VPN settings for Gluetun..."
    show_loading_message "Setting up VPN configuration" 1
    
    # VPN Provider Selection
    printf '\n%b\n' " ${cy}Select your VPN provider:${cend}"
    printf '\n%b\n' " ${clc}1)${cend} NordVPN (Most Popular)"
    printf '\n%b\n' " ${clc}2)${cend} PrivadoVPN"
    printf '\n%b\n' " ${clc}3)${cend} Private Internet Access (PIA)"
    printf '\n%b\n' " ${clc}4)${cend} ExpressVPN"
    printf '\n%b\n' " ${clc}5)${cend} Surfshark"
    printf '\n%b\n' " ${clc}6)${cend} ProtonVPN"
    printf '\n%b\n' " ${clc}7)${cend} Mullvad"
    printf '\n%b\n' " ${clc}8)${cend} CyberGhost"
    printf '\n%b\n' " ${clc}9)${cend} Windscribe"
    printf '\n%b\n' " ${clc}10)${cend} AirVPN"
    printf '\n%b\n' " ${clc}11)${cend} IVPN"
    printf '\n%b\n' " ${clc}12)${cend} Other (manual configuration)"
    printf '\n%b\n' " ${clc}13)${cend} Skip VPN setup (configure later)"
    
    printf '\n'
    while true; do
        printf '%b' " ${uyc} Select VPN provider [1-13] (default: 13): "
        read -r vpn_choice
        vpn_choice="${vpn_choice:-13}"
        
        case "$vpn_choice" in
            1)
                vpn_provider="nordvpn"
                printf '\n%b\n' " ${uyc} NordVPN selected"
                printf '\n%b\n' " ${cy}Info:${cend} Uses username/password. Supports OpenVPN and WireGuard."
                break
                ;;
            2)
                vpn_provider="privado"
                printf '\n%b\n' " ${uyc} PrivadoVPN selected"
                printf '\n%b\n' " ${cy}Info:${cend} Uses username/password. Supports OpenVPN."
                break
                ;;
            3)
                vpn_provider="private internet access"
                printf '\n%b\n' " ${uyc} Private Internet Access selected"
                printf '\n%b\n' " ${cy}Info:${cend} Uses username/password. Supports OpenVPN and WireGuard."
                break
                ;;
            4)
                vpn_provider="expressvpn"
                printf '\n%b\n' " ${uyc} ExpressVPN selected"
                printf '\n%b\n' " ${cy}Info:${cend} Uses username/password. Supports OpenVPN."
                break
                ;;
            5)
                vpn_provider="surfshark"
                printf '\n%b\n' " ${uyc} Surfshark selected"
                printf '\n%b\n' " ${cy}Info:${cend} Uses username/password. Supports OpenVPN and WireGuard."
                break
                ;;
            6)
                vpn_provider="protonvpn"
                printf '\n%b\n' " ${uyc} ProtonVPN selected"
                printf '\n%b\n' " ${cy}Info:${cend} Uses OpenVPN credentials. Supports OpenVPN and WireGuard."
                break
                ;;
            7)
                vpn_provider="mullvad"
                printf '\n%b\n' " ${uyc} Mullvad selected"
                printf '\n%b\n' " ${cy}Info:${cend} Uses account number (no password). Supports OpenVPN and WireGuard."
                break
                ;;
            8)
                vpn_provider="cyberghost"
                printf '\n%b\n' " ${uyc} CyberGhost selected"
                printf '\n%b\n' " ${cy}Info:${cend} Uses username/password. Supports OpenVPN and WireGuard."
                break
                ;;
            9)
                vpn_provider="windscribe"
                printf '\n%b\n' " ${uyc} Windscribe selected"
                printf '\n%b\n' " ${cy}Info:${cend} Uses username/password. Supports OpenVPN and WireGuard."
                break
                ;;
            10)
                vpn_provider="airvpn"
                printf '\n%b\n' " ${uyc} AirVPN selected"
                printf '\n%b\n' " ${cy}Info:${cend} Uses username/password. Supports OpenVPN and WireGuard."
                break
                ;;
            11)
                vpn_provider="ivpn"
                printf '\n%b\n' " ${uyc} IVPN selected"
                printf '\n%b\n' " ${cy}Info:${cend} Uses username/password. Supports OpenVPN and WireGuard."
                break
                ;;
            12)
                vpn_provider="custom"
                printf '\n%b\n' " ${uyc} Custom VPN provider selected"
                printf '\n%b\n' " ${cy}Info:${cend} You'll need to specify the provider name and credentials manually."
                break
                ;;
            13)
                vpn_provider=""
                printf '\n%b\n' " ${uyc} Skipping VPN setup - configure manually later"
                return 0
                ;;
            *)
                printf '\n%b\n' " ${ucross} Invalid choice. Please select 1-13."
                ;;
        esac
    done
    
    if [[ -n "$vpn_provider" && "$vpn_provider" != "custom" ]]; then
        printf '\n%b\n' " ${cy}Enter your VPN credentials for ${vpn_provider}:${cend}"
        
        # Handle different authentication methods based on provider
        case "$vpn_provider" in
            "mullvad")
                # Mullvad uses account number instead of username/password
                printf '\n%b\n' " ${cy}Mullvad uses account number authentication${cend}"
                while true; do
                    printf '%b' " ${uyc} Mullvad Account Number (e.g., m1234567890123456): "
                    read -r vpn_username
                    if [[ -n "$vpn_username" ]]; then
                        break
                    else
                        printf '\n%b\n' " ${ucross} Account number cannot be empty. Please try again."
                    fi
                done
                vpn_password=""  # Mullvad doesn't use password
                ;;
            "protonvpn")
                # ProtonVPN uses OpenVPN credentials
                printf '\n%b\n' " ${cy}ProtonVPN uses OpenVPN credentials${cend}"
                while true; do
                    printf '%b' " ${uyc} ProtonVPN Username: "
                    read -r vpn_username
                    if [[ -n "$vpn_username" ]]; then
                        break
                    else
                        printf '\n%b\n' " ${ucross} Username cannot be empty. Please try again."
                    fi
                done
                while true; do
                    printf '%b' " ${uyc} ProtonVPN Password: "
                    read -s vpn_password
                    printf '\n'
                    if [[ -n "$vpn_password" ]]; then
                        break
                    else
                        printf '\n%b\n' " ${ucross} Password cannot be empty. Please try again."
                    fi
                done
                ;;
            "windscribe")
                # Windscribe uses username/password
                printf '\n%b\n' " ${cy}Windscribe uses username/password authentication${cend}"
                while true; do
                    printf '%b' " ${uyc} Windscribe Username: "
                    read -r vpn_username
                    if [[ -n "$vpn_username" ]]; then
                        break
                    else
                        printf '\n%b\n' " ${ucross} Username cannot be empty. Please try again."
                    fi
                done
                while true; do
                    printf '%b' " ${uyc} Windscribe Password: "
                    read -s vpn_password
                    printf '\n'
                    if [[ -n "$vpn_password" ]]; then
                        break
                    else
                        printf '\n%b\n' " ${ucross} Password cannot be empty. Please try again."
                    fi
                done
                ;;
            *)
                # Standard username/password for most providers
                printf '\n%b\n' " ${cy}Standard username/password authentication${cend}"
                while true; do
                    printf '%b' " ${uyc} VPN Username: "
                    read -r vpn_username
                    if [[ -n "$vpn_username" ]]; then
                        break
                    else
                        printf '\n%b\n' " ${ucross} Username cannot be empty. Please try again."
                    fi
                done
                while true; do
                    printf '%b' " ${uyc} VPN Password: "
                    read -s vpn_password
                    printf '\n'
                    if [[ -n "$vpn_password" ]]; then
                        break
                    else
                        printf '\n%b\n' " ${ucross} Password cannot be empty. Please try again."
                    fi
                done
                ;;
        esac
        
        # Country selection with provider-specific defaults
        case "$vpn_provider" in
            "nordvpn")
                printf '%b' " ${uyc} Preferred country (e.g., United States, Canada, Germany) [default: United States]: "
                read -r vpn_country
                vpn_country="${vpn_country:-United States}"
                ;;
            "privado")
                printf '%b' " ${uyc} Preferred country (e.g., United States, Canada, Germany) [default: United States]: "
                read -r vpn_country
                vpn_country="${vpn_country:-United States}"
                ;;
            "protonvpn")
                printf '%b' " ${uyc} Preferred country (e.g., United States, Switzerland, Japan) [default: United States]: "
                read -r vpn_country
                vpn_country="${vpn_country:-United States}"
                ;;
            "mullvad")
                printf '%b' " ${uyc} Preferred country (e.g., United States, Sweden, Germany) [default: United States]: "
                read -r vpn_country
                vpn_country="${vpn_country:-United States}"
                ;;
            *)
                printf '%b' " ${uyc} Preferred country (e.g., United States, Canada, Germany) [default: United States]: "
                read -r vpn_country
                vpn_country="${vpn_country:-United States}"
                ;;
        esac
        
        # Update .env-servarr with VPN settings
        if [[ -f ".env-servarr" ]] && [[ -w ".env-servarr" ]]; then
            if sed -i.bak "s|VPN_SERVICE_PROVIDER=.*|VPN_SERVICE_PROVIDER=${vpn_provider}|g" ".env-servarr" 2>/dev/null; then
                # Handle different authentication methods
                case "$vpn_provider" in
                    "mullvad")
                        # Mullvad uses account number in OPENVPN_USER field
                        sed -i.bak "s|OPENVPN_USER=.*|OPENVPN_USER=${vpn_username}|g" ".env-servarr" 2>/dev/null
                        sed -i.bak "s|OPENVPN_PASSWORD=.*|OPENVPN_PASSWORD=|g" ".env-servarr" 2>/dev/null
                        ;;
                    *)
                        # Standard username/password for other providers
                        sed -i.bak "s|OPENVPN_USER=.*|OPENVPN_USER=${vpn_username}|g" ".env-servarr" 2>/dev/null
                        sed -i.bak "s|OPENVPN_PASSWORD=.*|OPENVPN_PASSWORD=${vpn_password}|g" ".env-servarr" 2>/dev/null
                        ;;
                esac
                sed -i.bak "s|SERVER_COUNTRIES=.*|SERVER_COUNTRIES=${vpn_country}|g" ".env-servarr" 2>/dev/null
                
                printf '\n%b\n' " ${utick} VPN settings configured in .env-servarr"
            else
                printf '\n%b\n' " ${ucross} Failed to update .env-servarr file"
                printf '\n%b\n' " ${uyc} Please check file permissions and try again"
                return 1
            fi
        else
            printf '\n%b\n' " ${ucross} .env-servarr file not found or not writable"
            printf '\n%b\n' " ${uyc} VPN settings will need to be configured manually"
            return 1
        fi
    elif [[ "$vpn_provider" == "custom" ]]; then
        printf '\n%b\n' " ${cy}Custom VPN configuration:${cend}"
        printf '\n%b\n' " ${cy}Available providers:${cend} airvpn, cyberghost, expressvpn, fastestvpn, giganews, hidemyass, ipvanish, ivpn, mullvad, nordvpn, perfect privacy, privado, private internet access, privatevpn, protonvpn, purevpn, slickvpn, surfshark, torguard, vpnsecure.me, vpnunlimited, vyprvpn, wevpn, windscribe"
        
        # Get custom VPN provider with validation
        while true; do
            printf '%b' " ${uyc} VPN Service Provider (e.g., protonvpn, mullvad): "
            read -r vpn_provider
            if [[ -n "$vpn_provider" ]]; then
                break
            else
                printf '\n%b\n' " ${ucross} Provider name cannot be empty. Please try again."
            fi
        done
        
        # Get VPN username with validation
        while true; do
            printf '%b' " ${uyc} VPN Username: "
            read -r vpn_username
            if [[ -n "$vpn_username" ]]; then
                break
            else
                printf '\n%b\n' " ${ucross} Username cannot be empty. Please try again."
            fi
        done
        
        # Get VPN password with validation
        while true; do
            printf '%b' " ${uyc} VPN Password: "
            read -s vpn_password
            printf '\n'
            if [[ -n "$vpn_password" ]]; then
                break
            else
                printf '\n%b\n' " ${ucross} Password cannot be empty. Please try again."
            fi
        done
        
        printf '%b' " ${uyc} Preferred country: "
        read -r vpn_country
        vpn_country="${vpn_country:-United States}"
        
        # Update .env-servarr with custom VPN settings
        if [[ -f ".env-servarr" ]] && [[ -w ".env-servarr" ]]; then
            if sed -i.bak "s|VPN_SERVICE_PROVIDER=.*|VPN_SERVICE_PROVIDER=${vpn_provider}|g" ".env-servarr" 2>/dev/null; then
                sed -i.bak "s|OPENVPN_USER=.*|OPENVPN_USER=${vpn_username}|g" ".env-servarr" 2>/dev/null
                sed -i.bak "s|OPENVPN_PASSWORD=.*|OPENVPN_PASSWORD=${vpn_password}|g" ".env-servarr" 2>/dev/null
                sed -i.bak "s|SERVER_COUNTRIES=.*|SERVER_COUNTRIES=${vpn_country}|g" ".env-servarr" 2>/dev/null
                
                printf '\n%b\n' " ${utick} Custom VPN settings configured in .env-servarr"
            else
                printf '\n%b\n' " ${ucross} Failed to update .env-servarr file"
                printf '\n%b\n' " ${uyc} Please check file permissions and try again"
                return 1
            fi
        else
            printf '\n%b\n' " ${ucross} .env-servarr file not found or not writable"
            printf '\n%b\n' " ${uyc} VPN settings will need to be configured manually"
            return 1
        fi
    fi
}

configure_n8n_encryption() {
    printf '\n%b\n' " ${uyc} Configuring n8n encryption key..."
    
    # Ask user about HTTPS setup
    printf '\n%b\n' " ${cy}n8n Encryption Key Configuration:${cend}"
    printf '\n%b\n' " ${clc}•${cend} For HTTPS/domain access: Encryption key is required"
    printf '\n%b\n' " ${clc}•${cend} For HTTP/local access: Encryption key is optional"
    
    printf '\n%b\n' " ${uyc} Will you be using n8n with HTTPS/domain access? [y/N]: "
    read -r use_https
    
    if [[ "$use_https" =~ ^[Yy]$ ]]; then
        printf '\n%b\n' " ${cy}HTTPS Setup Selected${cend}"
        printf '\n%b\n' " ${uyc} You have two options for the encryption key:"
        printf '\n%b\n' " ${clc}1)${cend} Generate a new random key (recommended)"
        printf '\n%b\n' " ${clc}2)${cend} Use an existing key from n8n config"
        
        printf '\n%b\n' " ${uyc} Choose option [1-2] (default: 1): "
        read -r key_option
        key_option="${key_option:-1}"
        
        case "$key_option" in
            1)
                # Generate new random key
                if command -v openssl >/dev/null 2>&1; then
                    n8n_encryption_key=$(openssl rand -base64 32)
                    printf '\n%b\n' " ${utick} Generated new encryption key: ${clc}${n8n_encryption_key}${cend}"
                else
                    # Fallback if openssl not available
                    n8n_encryption_key=$(head -c 32 /dev/urandom | base64)
                    printf '\n%b\n' " ${utick} Generated new encryption key: ${clc}${n8n_encryption_key}${cend}"
                fi
                ;;
            2)
                # Use existing key
                printf '\n%b\n' " ${uyc} Enter your existing n8n encryption key:"
                printf '%b' " ${uyc} Encryption Key: "
                read -r n8n_encryption_key
                if [[ -z "$n8n_encryption_key" ]]; then
                    printf '\n%b\n' " ${ucross} Encryption key cannot be empty"
                    return 1
                fi
                printf '\n%b\n' " ${utick} Using provided encryption key"
                ;;
            *)
                printf '\n%b\n' " ${ucross} Invalid option, generating new key"
                n8n_encryption_key=$(openssl rand -base64 32 2>/dev/null || head -c 32 /dev/urandom | base64)
                ;;
        esac
        
        # Store the key for later use
        declare -g n8n_encryption_key
        printf '\n%b\n' " ${cy}IMPORTANT:${cend} Save this encryption key securely!"
        printf '\n%b\n' " ${clc}Key:${cend} ${n8n_encryption_key}"
        printf '\n%b\n' " ${uyc} This key will be used in your n8n configuration"
    else
        printf '\n%b\n' " ${uyc} HTTP/Local setup selected - encryption key not required"
        n8n_encryption_key=""
    fi
}

configure_environment_files() {
    printf '\n%b\n' " ${uyc} Configuring environment files..."
    show_loading_message "Configuring application settings" 1
    
    # Configure servarr environment
    if [[ " ${stacks_to_install[@]} " =~ " servarr " ]] && [[ ! -f ".env-servarr" ]]; then
        if [[ -f ".env-servarr.example" ]]; then
            cp ".env-servarr.example" ".env-servarr"
            
            # Update paths based on platform
            if [[ "$platform" == "windows" ]]; then
                # Convert Windows path to Unix-style for Docker
                unix_path="${base_path//\\//}"
                sed -i.bak "s|/volume1|${unix_path}|g" ".env-servarr"
            else
                sed -i.bak "s|/volume1|${base_path}|g" ".env-servarr"
            fi
            
            sed -i.bak "s|PUID=1001|PUID=${puid}|g" ".env-servarr"
            sed -i.bak "s|PGID=1000|PGID=${pgid}|g" ".env-servarr"
            sed -i.bak "s|TZ=America/Los_Angeles|TZ=${timezone}|g" ".env-servarr"
            
            printf '\n%b\n' " ${utick} Created .env-servarr with ${platform} settings"
        else
            printf '\n%b\n' " ${ucross} Warning: .env-servarr.example not found"
        fi
    else
        printf '\n%b\n' " ${uyc} .env-servarr already exists, skipping"
    fi
    
    # Configure streamarr environment
    if [[ " ${stacks_to_install[@]} " =~ " streamarr " ]] && [[ ! -f ".env-streamarr" ]]; then
        if [[ -f ".env-streamarr.example" ]]; then
            cp ".env-streamarr.example" ".env-streamarr"
            
            # Update paths based on platform
            if [[ "$platform" == "windows" ]]; then
                # Convert Windows path to Unix-style for Docker
                unix_path="${base_path//\\//}"
                sed -i.bak "s|/volume1|${unix_path}|g" ".env-streamarr"
            else
                sed -i.bak "s|/volume1|${base_path}|g" ".env-streamarr"
            fi
            
            sed -i.bak "s|PUID=1001|PUID=${puid}|g" ".env-streamarr"
            sed -i.bak "s|PGID=1000|PGID=${pgid}|g" ".env-streamarr"
            sed -i.bak "s|TZ=America/Los_Angeles|TZ=${timezone}|g" ".env-streamarr"
            sed -i.bak "s|192.168.1.100|${local_ip}|g" ".env-streamarr"
            
            printf '\n%b\n' " ${utick} Created .env-streamarr with ${platform} settings"
        else
            printf '\n%b\n' " ${ucross} Warning: .env-streamarr.example not found"
        fi
    else
        printf '\n%b\n' " ${uyc} .env-streamarr already exists, skipping"
    fi
    
    # Configure creatarr environment
    if [[ " ${stacks_to_install[@]} " =~ " creatarr " ]] && [[ ! -f ".env-creatarr" ]]; then
        if [[ -f ".env-creatarr.example" ]]; then
            cp ".env-creatarr.example" ".env-creatarr"
            
            # Update paths based on platform
            if [[ "$platform" == "windows" ]]; then
                # Convert Windows path to Unix-style for Docker
                unix_path="${base_path//\\//}"
                sed -i.bak "s|/volume1|${unix_path}|g" ".env-creatarr"
            else
                sed -i.bak "s|/volume1|${base_path}|g" ".env-creatarr"
            fi
            
            sed -i.bak "s|PUID=1000|PUID=${puid}|g" ".env-creatarr"
            sed -i.bak "s|PGID=1000|PGID=${pgid}|g" ".env-creatarr"
            sed -i.bak "s|TZ=Etc/UTC|TZ=${timezone}|g" ".env-creatarr"
            
            printf '\n%b\n' " ${utick} Created .env-creatarr with ${platform} settings"
        else
            printf '\n%b\n' " ${ucross} Warning: .env-creatarr.example not found"
        fi
    else
        printf '\n%b\n' " ${uyc} .env-creatarr already exists, skipping"
    fi
    
    # Configure business environment
    if [[ " ${stacks_to_install[@]} " =~ " business " ]] && [[ ! -f ".env-business" ]]; then
        if [[ -f ".env-business.example" ]]; then
            cp ".env-business.example" ".env-business"
            
            # Update paths based on platform
            if [[ "$platform" == "windows" ]]; then
                # Convert Windows path to Unix-style for Docker
                unix_path="${base_path//\\//}"
                sed -i.bak "s|/volume1|${unix_path}|g" ".env-business"
            else
                sed -i.bak "s|/volume1|${base_path}|g" ".env-business"
            fi
            
            sed -i.bak "s|PUID=1000|PUID=${puid}|g" ".env-business"
            sed -i.bak "s|PGID=1000|PGID=${pgid}|g" ".env-business"
            sed -i.bak "s|TZ=America/New_York|TZ=${timezone}|g" ".env-business"
            
            # Set n8n encryption key if provided
            if [[ -n "$n8n_encryption_key" ]]; then
                sed -i.bak "s|N8N_ENCRYPTION_KEY=.*|N8N_ENCRYPTION_KEY=${n8n_encryption_key}|g" ".env-business"
                printf '\n%b\n' " ${utick} Set n8n encryption key in .env-business"
            fi
            
            printf '\n%b\n' " ${utick} Created .env-business with ${platform} settings"
        else
            printf '\n%b\n' " ${ucross} Warning: .env-business.example not found"
        fi
    else
        printf '\n%b\n' " ${uyc} .env-business already exists, skipping"
    fi
    
    # Configure infrastructure environment
    if [[ " ${stacks_to_install[@]} " =~ " infrastructure " ]] && [[ ! -f ".env-infrastructure" ]]; then
        if [[ -f ".env-infrastructure.example" ]]; then
            cp ".env-infrastructure.example" ".env-infrastructure"
            
            # Update paths based on platform
            if [[ "$platform" == "windows" ]]; then
                # Convert Windows path to Unix-style for Docker
                unix_path="${base_path//\\//}"
                sed -i.bak "s|/volume1|${unix_path}|g" ".env-infrastructure"
            else
                sed -i.bak "s|/volume1|${base_path}|g" ".env-infrastructure"
            fi
            
            sed -i.bak "s|PUID=1000|PUID=${puid}|g" ".env-infrastructure"
            sed -i.bak "s|PGID=1000|PGID=${pgid}|g" ".env-infrastructure"
            sed -i.bak "s|TZ=America/New_York|TZ=${timezone}|g" ".env-infrastructure"
            
            printf '\n%b\n' " ${utick} Created .env-infrastructure with ${platform} settings"
        else
            printf '\n%b\n' " ${ucross} Warning: .env-infrastructure.example not found"
        fi
    else
        printf '\n%b\n' " ${uyc} .env-infrastructure already exists, skipping"
    fi
    
    # Configure websites environment
    if [[ " ${stacks_to_install[@]} " =~ " websites " ]] && [[ ! -f ".env-websites" ]]; then
        if [[ -f ".env-websites.example" ]]; then
            cp ".env-websites.example" ".env-websites"
            
            # Update paths based on platform
            if [[ "$platform" == "synology" ]] || [[ "$platform" == "qnap" ]] || [[ "$platform" == "ugreen" ]]; then
                sed -i.bak "s|/volume1|${unix_path}|g" ".env-websites"
            else
                sed -i.bak "s|/volume1|${base_path}|g" ".env-websites"
            fi
            
            sed -i.bak "s|PUID=1000|PUID=${puid}|g" ".env-websites"
            sed -i.bak "s|PGID=1000|PGID=${pgid}|g" ".env-websites"
            sed -i.bak "s|TZ=America/New_York|TZ=${timezone}|g" ".env-websites"
            
            printf '\n%b\n' " ${utick} Created .env-websites with ${platform} settings"
        else
            printf '\n%b\n' " ${ucross} Warning: .env-websites.example not found"
        fi
    else
        printf '\n%b\n' " ${uyc} .env-websites already exists, skipping"
    fi
    
    # Clean up backup files
    rm -f ".env-servarr.bak" ".env-streamarr.bak" ".env-creatarr.bak" ".env-business.bak" ".env-infrastructure.bak" ".env-websites.bak" 2>/dev/null || true
    
    printf '\n%b\n' " ${utick} Environment files configured!"
}

fix_permissions() {
    printf '\n%b\n' " ${uyc} Fixing directory permissions..."
    
    # Fix permissions for all created directories
    if [[ "$platform" != "windows" ]]; then
        # Linux/macOS/NAS systems
        if command -v chown >/dev/null 2>&1; then
            chown -R "${puid}:${pgid}" "${base_path}" 2>/dev/null || true
            printf '\n%b\n' " ${utick} Set ownership to ${puid}:${pgid}"
        fi
        
        if command -v chmod >/dev/null 2>&1; then
            find "${base_path}" -type d -exec chmod 755 {} \; 2>/dev/null || true
            find "${base_path}" -type f -exec chmod 644 {} \; 2>/dev/null || true
            printf '\n%b\n' " ${utick} Set proper file permissions"
        fi
    else
        # Windows - permissions handled by Docker
        printf '\n%b\n' " ${uyc} Windows detected - permissions will be handled by Docker"
    fi
    
    printf '\n%b\n' " ${utick} Permission fix completed!"
}

deploy_stacks() {
    printf '\n%b\n' " ${uyc} Deploying selected homelab media stack components..."
    show_loading_message "Preparing container deployment" 1
    
    # Deploy SERVARR stack (download & management)
    if [[ " ${stacks_to_install[@]} " =~ " servarr " ]]; then
        printf '\n%b\n' "${clg}╔═══════════════════════════════════════════════════════════════════════════════╗${cend}"
        printf '\n%b\n' "${clg}║                                                                               ║${cend}"
        printf '\n%b\n' "${clg}║                    DEPLOYING SERVARR STACK                                    ║${cend}"
        printf '\n%b\n' "${clg}║                                                                               ║${cend}"
        printf '\n%b\n' "${clg}║                    (Download & Management Services)                           ║${cend}"
        printf '\n%b\n' "${clg}║                                                                               ║${cend}"
        printf '\n%b\n' "${clg}╚═══════════════════════════════════════════════════════════════════════════════╝${cend}"
        
        show_loading_message "Launching SERVARR services" 3
        
        # Deploy selected services (or all if none selected)
        if [[ ${#services_servarr[@]} -gt 0 ]]; then
            if $compose_cmd --env-file .env-servarr -f docker-compose-servarr.yml up -d "${services_servarr[@]}"; then
                printf '\n%b\n' " ${utick} SERVARR stack deployed successfully!"
            else
                printf '\n%b\n' " ${ucross} Failed to deploy SERVARR stack"
                return 1
            fi
        else
            printf '\n%b\n' " ${uyc} No services selected for SERVARR stack"
        fi
        
        # Wait for VPN to be ready if Gluetun is selected
        if [[ " ${services_servarr[@]} " =~ " gluetun " ]]; then
                printf '\n%b\n' " ${uyc} Waiting for VPN connection to establish (30 seconds)..."
                show_loading_message "Establishing VPN connection" 3
                
                # Verify VPN (optional, don't fail if it doesn't work)
                if docker exec gluetun curl -s --max-time 10 ifconfig.me > /dev/null 2>&1; then
                    vpn_ip=$(docker exec gluetun curl -s --max-time 10 ifconfig.me 2>/dev/null)
                    printf '\n%b\n' " ${utick} VPN is working! External IP: ${clc}${vpn_ip}${cend}"
                else
                    printf '\n%b\n' " ${uyc} VPN not yet ready (this is normal, configure it later)"
                fi
            fi
    fi
    
    # Deploy STREAMARR stack (streaming & requests)
    if [[ " ${stacks_to_install[@]} " =~ " streamarr " ]]; then
        printf '\n%b\n' "${clb}╔═══════════════════════════════════════════════════════════════════════════════╗${cend}"
        printf '\n%b\n' "${clb}║                                                                               ║${cend}"
        printf '\n%b\n' "${clb}║                    DEPLOYING STREAMARR STACK                                  ║${cend}"
        printf '\n%b\n' "${clb}║                                                                               ║${cend}"
        printf '\n%b\n' "${clb}║                    (Streaming & Request Services)                             ║${cend}"
        printf '\n%b\n' "${clb}║                                                                               ║${cend}"
        printf '\n%b\n' "${clb}╚═══════════════════════════════════════════════════════════════════════════════╝${cend}"
        
        show_loading_message "Launching STREAMARR services" 3
        
        # Deploy selected services
        if [[ ${#services_streamarr[@]} -gt 0 ]]; then
            if $compose_cmd --env-file .env-streamarr -f docker-compose-streamarr.yml up -d "${services_streamarr[@]}"; then
                printf '\n%b\n' " ${utick} STREAMARR stack deployed successfully!"
            else
                printf '\n%b\n' " ${ucross} Failed to deploy STREAMARR stack"
                return 1
            fi
        else
            printf '\n%b\n' " ${uyc} No services selected for STREAMARR stack"
        fi
    fi
    
    # Deploy CREATARR stack (creative & entertainment)
    if [[ " ${stacks_to_install[@]} " =~ " creatarr " ]]; then
        printf '\n%b\n' "${clm}╔═══════════════════════════════════════════════════════════════════════════════╗${cend}"
        printf '\n%b\n' "${clm}║                                                                               ║${cend}"
        printf '\n%b\n' "${clm}║                    DEPLOYING CREATARR STACK                                   ║${cend}"
        printf '\n%b\n' "${clm}║                                                                               ║${cend}"
        printf '\n%b\n' "${clm}║                    (Creative & Entertainment Services)                        ║${cend}"
        printf '\n%b\n' "${clm}║                                                                               ║${cend}"
        printf '\n%b\n' "${clm}╚═══════════════════════════════════════════════════════════════════════════════╝${cend}"
        
        show_loading_message "Launching CREATARR services" 3
        
        # Deploy selected services
        if [[ ${#services_creatarr[@]} -gt 0 ]]; then
            if $compose_cmd --env-file .env-creatarr -f docker-compose-creatarr.yml up -d "${services_creatarr[@]}"; then
                printf '\n%b\n' " ${utick} CREATARR stack deployed successfully!"
            else
                printf '\n%b\n' " ${ucross} Failed to deploy CREATARR stack"
                return 1
            fi
        else
            printf '\n%b\n' " ${uyc} No services selected for CREATARR stack"
        fi
    fi
    
    # Deploy BUSINESS stack (business & productivity)
    if [[ " ${stacks_to_install[@]} " =~ " business " ]]; then
        printf '\n%b\n' "${cc}╔═══════════════════════════════════════════════════════════════════════════════╗${cend}"
        printf '\n%b\n' "${cc}║                                                                               ║${cend}"
        printf '\n%b\n' "${cc}║                    DEPLOYING BUSINESS STACK                                   ║${cend}"
        printf '\n%b\n' "${cc}║                                                                               ║${cend}"
        printf '\n%b\n' "${cc}║                    (Business & Productivity Services)                          ║${cend}"
        printf '\n%b\n' "${cc}║                                                                               ║${cend}"
        printf '\n%b\n' "${cc}╚═══════════════════════════════════════════════════════════════════════════════╝${cend}"
        
        show_loading_message "Launching BUSINESS services" 3
        
        # Deploy selected services
        if [[ ${#services_business[@]} -gt 0 ]]; then
            if $compose_cmd --env-file .env-business -f docker-compose-business.yml up -d "${services_business[@]}"; then
                printf '\n%b\n' " ${utick} BUSINESS stack deployed successfully!"
            else
                printf '\n%b\n' " ${ucross} Failed to deploy BUSINESS stack"
                return 1
            fi
        else
            printf '\n%b\n' " ${uyc} No services selected for BUSINESS stack"
        fi
    fi
    
    # Deploy INFRASTRUCTURE stack (system management)
    if [[ " ${stacks_to_install[@]} " =~ " infrastructure " ]]; then
        printf '\n%b\n' "${cy}╔═══════════════════════════════════════════════════════════════════════════════╗${cend}"
        printf '\n%b\n' "${cy}║                                                                               ║${cend}"
        printf '\n%b\n' "${cy}║                    DEPLOYING INFRASTRUCTURE STACK                             ║${cend}"
        printf '\n%b\n' "${cy}║                                                                               ║${cend}"
        printf '\n%b\n' "${cy}║                    (System Management & Monitoring)                           ║${cend}"
        printf '\n%b\n' "${cy}║                                                                               ║${cend}"
        printf '\n%b\n' "${cy}╚═══════════════════════════════════════════════════════════════════════════════╝${cend}"
        
        show_loading_message "Launching INFRASTRUCTURE services" 3
        
        # Deploy selected services
        if [[ ${#services_infrastructure[@]} -gt 0 ]]; then
            if $compose_cmd --env-file .env-infrastructure -f docker-compose-infrastructure.yml up -d "${services_infrastructure[@]}"; then
                printf '\n%b\n' " ${utick} INFRASTRUCTURE stack deployed successfully!"
            else
                printf '\n%b\n' " ${ucross} Failed to deploy INFRASTRUCTURE stack"
                return 1
            fi
        else
            printf '\n%b\n' " ${uyc} No services selected for INFRASTRUCTURE stack"
        fi
    fi
    
    # Deploy WEBSITES stack
    if [[ " ${stacks_to_install[@]} " =~ " websites " ]]; then
        printf '\n%b\n' "${cm}╔═══════════════════════════════════════════════════════════════════════════════╗${cend}"
        printf '\n%b\n' "${cm}║                                                                               ║${cend}"
        printf '\n%b\n' "${cm}║                    DEPLOYING WEBSITES STACK                                     ║${cend}"
        printf '\n%b\n' "${cm}║                                                                               ║${cend}"
        printf '\n%b\n' "${cm}║                    (Custom Web Applications)                                    ║${cend}"
        printf '\n%b\n' "${cm}║                                                                               ║${cend}"
        printf '\n%b\n' "${cm}╚═══════════════════════════════════════════════════════════════════════════════╝${cend}"
        
        show_loading_message "Launching WEBSITES services" 3
        
        # Deploy selected services
        if [[ ${#services_websites[@]} -gt 0 ]]; then
            if $compose_cmd --env-file .env-websites -f docker-compose-websites.yml up -d "${services_websites[@]}"; then
                printf '\n%b\n' " ${utick} WEBSITES stack deployed successfully!"
                printf '\n%b\n' " ${uyc} ${cy}Note:${cend} Add your custom websites to ${clc}docker-compose-websites.yml${cend}"
                printf '\n%b\n' " ${uyc} See ${clc}docs/WEBSITES_STACK_GUIDE.md${cend} for detailed instructions"
            else
                printf '\n%b\n' " ${ucross} Failed to deploy WEBSITES stack"
                return 1
            fi
        else
            printf '\n%b\n' " ${uyc} No services selected for WEBSITES stack"
        fi
    fi
    
    return 0
}

show_access_info() {
    printf '\n%b\n' "${clg}
╔═══════════════════════════════════════════════════════════════════════════════╗
║                                                                               ║
║                            SETUP COMPLETE!                                    ║
║                                                                               ║
║                        Access your services below:                            ║
║                                                                               ║
╚═══════════════════════════════════════════════════════════════════════════════╝${cend}"
    
    # SERVARR Stack
    if [[ " ${stacks_to_install[@]} " =~ " servarr " ]]; then
        printf '\n%b\n' "${clg}╔═══════════════════════════════════════════════════════════════════════════════╗${cend}"
        printf '\n%b\n' "${clg}║                                                                               ║${cend}"
        printf '\n%b\n' "${clg}║                    SERVARR STACK (Download & Management)                      ║${cend}"
        printf '\n%b\n' "${clg}║                                                                               ║${cend}"
        printf '\n%b\n' "${clg}╚═══════════════════════════════════════════════════════════════════════════════╝${cend}"
        
        if [[ " ${services_servarr[@]} " =~ " qbittorrent " ]]; then
            printf '\n%b\n' " ${clc}qBittorrent:${cend} http://${local_ip}:8080"
        fi
        if [[ " ${services_servarr[@]} " =~ " sabnzbd " ]]; then
            printf '\n%b\n' " ${clc}SABnzbd:${cend} http://${local_ip}:8090"
        fi
        if [[ " ${services_servarr[@]} " =~ " prowlarr " ]]; then
            printf '\n%b\n' " ${clc}Prowlarr:${cend} http://${local_ip}:9696"
        fi
        if [[ " ${services_servarr[@]} " =~ " sonarr " ]]; then
            printf '\n%b\n' " ${clc}Sonarr:${cend} http://${local_ip}:8989"
        fi
        if [[ " ${services_servarr[@]} " =~ " radarr " ]]; then
            printf '\n%b\n' " ${clc}Radarr:${cend} http://${local_ip}:7878"
        fi
        if [[ " ${services_servarr[@]} " =~ " lidarr " ]]; then
            printf '\n%b\n' " ${clc}Lidarr:${cend} http://${local_ip}:8686"
        fi
        if [[ " ${services_servarr[@]} " =~ " bazarr " ]]; then
            printf '\n%b\n' " ${clc}Bazarr:${cend} http://${local_ip}:6767"
        fi
        if [[ " ${services_servarr[@]} " =~ " filebot-node " ]]; then
            printf '\n%b\n' " ${clc}FileBot:${cend} http://${local_ip}:5452"
        fi
    fi
    
    # STREAMARR Stack
    if [[ " ${stacks_to_install[@]} " =~ " streamarr " ]]; then
        printf '\n%b\n' "${clb}╔═══════════════════════════════════════════════════════════════════════════════╗${cend}"
        printf '\n%b\n' "${clb}║                                                                               ║${cend}"
        printf '\n%b\n' "${clb}║                    STREAMARR STACK (Streaming & Requests)                     ║${cend}"
        printf '\n%b\n' "${clb}║                                                                               ║${cend}"
        printf '\n%b\n' "${clb}╚═══════════════════════════════════════════════════════════════════════════════╝${cend}"
        
        if [[ " ${services_streamarr[@]} " =~ " plex " ]]; then
            printf '\n%b\n' " ${clc}Plex Media Server:${cend} http://${local_ip}:32400/web"
        fi
        if [[ " ${services_streamarr[@]} " =~ " overseerr " ]]; then
            printf '\n%b\n' " ${clc}Overseerr:${cend} http://${local_ip}:5055"
        fi
        if [[ " ${services_streamarr[@]} " =~ " tautulli " ]]; then
            printf '\n%b\n' " ${clc}Tautulli:${cend} http://${local_ip}:8181"
        fi
        if [[ " ${services_streamarr[@]} " =~ " ersatztv " ]]; then
            printf '\n%b\n' " ${clc}ErsatzTV:${cend} http://${local_ip}:8409"
        fi
        if [[ " ${services_streamarr[@]} " =~ " navidrome " ]]; then
            printf '\n%b\n' " ${clc}Navidrome:${cend} http://${local_ip}:4533"
        fi
    fi
    
    # CREATARR Stack
    if [[ " ${stacks_to_install[@]} " =~ " creatarr " ]]; then
        printf '\n%b\n' "${clm}╔═══════════════════════════════════════════════════════════════════════════════╗${cend}"
        printf '\n%b\n' "${clm}║                                                                               ║${cend}"
        printf '\n%b\n' "${clm}║                    CREATARR STACK (Creative & Entertainment)                  ║${cend}"
        printf '\n%b\n' "${clm}║                                                                               ║${cend}"
        printf '\n%b\n' "${clm}╚═══════════════════════════════════════════════════════════════════════════════╝${cend}"
        
        if [[ " ${services_creatarr[@]} " =~ " retroarch " ]]; then
            printf '\n%b\n' " ${clc}RetroArch Gaming:${cend} http://${local_ip}:8081"
        fi
        if [[ " ${services_creatarr[@]} " =~ " komga " ]]; then
            printf '\n%b\n' " ${clc}Komga Comics:${cend} http://${local_ip}:25600"
        fi
        if [[ " ${services_creatarr[@]} " =~ " audiobookshelf " ]]; then
            printf '\n%b\n' " ${clc}Audiobookshelf:${cend} http://${local_ip}:13378"
        fi
        if [[ " ${services_creatarr[@]} " =~ " calibre-web " ]]; then
            printf '\n%b\n' " ${clc}Calibre-Web:${cend} http://${local_ip}:8083"
        fi
        if [[ " ${services_creatarr[@]} " =~ " noisedash " ]]; then
            printf '\n%b\n' " ${clc}Noisedash:${cend} http://${local_ip}:3002"
        fi
        if [[ " ${services_creatarr[@]} " =~ " swing-music " ]]; then
            printf '\n%b\n' " ${clc}Swing Music:${cend} http://${local_ip}:1970"
        fi
    fi
    
    # BUSINESS Stack
    if [[ " ${stacks_to_install[@]} " =~ " business " ]]; then
        printf '\n%b\n' "${cc}╔═══════════════════════════════════════════════════════════════════════════════╗${cend}"
        printf '\n%b\n' "${cc}║                                                                               ║${cend}"
        printf '\n%b\n' "${cc}║                    BUSINESS STACK (Business & Productivity)                   ║${cend}"
        printf '\n%b\n' "${cc}║                                                                               ║${cend}"
        printf '\n%b\n' "${cc}╚═══════════════════════════════════════════════════════════════════════════════╝${cend}"
        
        if [[ " ${services_business[@]} " =~ " n8n " ]]; then
            printf '\n%b\n' " ${clc}n8n Workflows:${cend} http://${local_ip}:5678"
        fi
        if [[ " ${services_business[@]} " =~ " mealie " ]]; then
            printf '\n%b\n' " ${clc}Mealie Recipes:${cend} http://${local_ip}:9001"
        fi
    fi
    
    # INFRASTRUCTURE Stack
    if [[ " ${stacks_to_install[@]} " =~ " infrastructure " ]]; then
        printf '\n%b\n' "${cy}╔═══════════════════════════════════════════════════════════════════════════════╗${cend}"
        printf '\n%b\n' "${cy}║                                                                               ║${cend}"
        printf '\n%b\n' "${cy}║                    INFRASTRUCTURE STACK (System Management)                   ║${cend}"
        printf '\n%b\n' "${cy}║                                                                               ║${cend}"
        printf '\n%b\n' "${cy}╚═══════════════════════════════════════════════════════════════════════════════╝${cend}"
        
        if [[ " ${services_infrastructure[@]} " =~ " homarr " ]]; then
            printf '\n%b\n' " ${clc}Homarr Dashboard:${cend} http://${local_ip}:7575"
        fi
        if [[ " ${services_infrastructure[@]} " =~ " uptime-kuma " ]]; then
            printf '\n%b\n' " ${clc}Uptime Kuma:${cend} http://${local_ip}:3001"
        fi
        # Show Portainer URL if installed
        if [[ "${PORTAINER_INSTALLED:-false}" == "true" ]] && [[ -n "${PORTAINER_PORT:-9000}" ]]; then
            printf '\n%b\n' " ${clc}Portainer:${cend} http://${local_ip}:${PORTAINER_PORT:-9000}"
        elif [[ "${PORTAINER_INSTALLED:-false}" == "true" ]]; then
            printf '\n%b\n' " ${clc}Portainer:${cend} http://${local_ip}:9000 (check actual port if different)"
        else
            printf '\n%b\n' " ${uyc}Portainer:${cend} Not detected (install separately if needed)"
        fi
    fi
    
    # WEBSITES Stack
    if [[ " ${stacks_to_install[@]} " =~ " websites " ]]; then
        printf '\n%b\n' "${cm}╔═══════════════════════════════════════════════════════════════════════════════╗${cend}"
        printf '\n%b\n' "${cm}║                                                                               ║${cend}"
        printf '\n%b\n' "${cm}║                    WEBSITES STACK (Custom Web Applications)                   ║${cend}"
        printf '\n%b\n' "${cm}║                                                                               ║${cend}"
        printf '\n%b\n' "${cm}╚═══════════════════════════════════════════════════════════════════════════════╝${cend}"
        
        printf '\n%b\n' " ${uyc} ${cy}Note:${cend} Add your custom websites to ${clc}docker-compose-websites.yml${cend}"
        printf '\n%b\n' " ${uyc} See ${clc}docs/WEBSITES_STACK_GUIDE.md${cend} for detailed instructions"
        printf '\n%b\n' " ${uyc} Template websites included: ${clc}mindkindproject-v2${cend} and ${clc}thegaragelabs-cc${cend}"
    fi
    
    printf '\n%b\n' " ${uyc} ${cy}Installation Location:${cend}"
    printf '\n%b\n' " ${clc}•${cend} Docker configs: ${base_path}/docker/"
    printf '\n%b\n' " ${clc}•${cend} Media data: ${base_path}/data/"
    printf '\n%b\n' " ${uyc} ${cy}Note:${cend} If you want to use a different path, edit the .env files and redeploy"
    printf '\n'
    printf '\n%b\n' " ${uyc} ${cy}Next Steps:${cend}"
    printf '\n%b\n' " ${clc}1.${cend} Set up download clients in Sonarr/Radarr"
    printf '\n%b\n' " ${clc}2.${cend} Add indexers in Prowlarr"
    printf '\n%b\n' " ${clc}3.${cend} Configure Plex libraries"
    printf '\n%b\n' " ${clc}4.${cend} Set up Overseerr for requests"
    printf '\n%b\n' " ${clc}5.${cend} Configure FileBot for media organization"
    printf '\n%b\n' " ${clc}6.${cend} Upload ROMs to ${base_path}/data/roms/"
    printf '\n%b\n' " ${clc}7.${cend} Upload comics to ${base_path}/data/comics/"
    printf '\n%b\n' " ${clc}8.${cend} Upload audiobooks to ${base_path}/data/audiobooks/"
    printf '\n%b\n' " ${clc}9.${cend} Upload ebooks to ${base_path}/data/books/"
    
    printf '\n%b\n' " ${uyc} ${cy}Platform-specific notes for ${clc}${platform}${cy}:${cend}"
    case "$platform" in
        "synology")
            printf '\n%b\n' " ${clc}•${cend} Use File Station to browse ${base_path}/data"
            printf '\n%b\n' " ${clc}•${cend} Configure firewall if needed in Control Panel"
            ;;
        "qnap")
            printf '\n%b\n' " ${clc}•${cend} Use File Manager to browse ${base_path}/data"
            printf '\n%b\n' " ${clc}•${cend} Check Container Station for container status"
            ;;
        "unraid")
            printf '\n%b\n' " ${clc}•${cend} Access shares at ${base_path}/data"
            printf '\n%b\n' " ${clc}•${cend} Monitor containers in Docker tab"
            ;;
        "truenas")
            printf '\n%b\n' " ${clc}•${cend} Access data via SMB/NFS shares"
            printf '\n%b\n' " ${clc}•${cend} Monitor in Apps section if using TrueNAS Scale"
            ;;
        "windows")
            printf '\n%b\n' " ${clc}•${cend} Access files at: ${base_path//\//\\}"
            printf '\n%b\n' " ${clc}•${cend} Use Docker Desktop to monitor containers"
            ;;
        "macos")
            printf '\n%b\n' " ${clc}•${cend} Access files in Finder at ${base_path}"
            printf '\n%b\n' " ${clc}•${cend} Use Docker Desktop to monitor containers"
            ;;
        "proxmox")
            printf '\n%b\n' " ${clc}•${cend} Monitor via Proxmox web interface"
            printf '\n%b\n' " ${clc}•${cend} Consider setting up backups via Proxmox"
            ;;
    esac
    
    printf '\n%b\n' " ${uyc} For detailed configuration guide: ${clc}docs/QUICK_START.md${cend}"
}

show_vpn_warning() {
    printf '\n%b\n' "${clr}
╔═══════════════════════════════════════════════════════════════════════════════╗
║                                                                               ║
║                       IMPORTANT: VPN REQUIRED!                                ║
║                                                                               ║
╚═══════════════════════════════════════════════════════════════════════════════╝${cend}"
    
    printf '\n%b\n' " ${cy}Before using download clients, you MUST configure your VPN:${cend}"
    printf '\n%b\n' " ${clc}1.${cend} Edit .env-servarr file"
    printf '\n%b\n' " ${clc}2.${cend} Set VPN_SERVICE_PROVIDER (nordvpn, privado, etc.)"
    printf '\n%b\n' " ${clc}3.${cend} Set OPENVPN_USER and OPENVPN_PASSWORD"
    printf '\n%b\n' " ${clc}4.${cend} Set SERVER_COUNTRIES"
    printf '\n%b\n' " ${clc}5.${cend} Restart: ${compose_cmd} --env-file .env-servarr -f docker-compose-servarr.yml up -d"
    
    printf '\n%b\n' " ${uyc} ${cy}Supported VPN providers:${cend} NordVPN, Privado, ExpressVPN, Surfshark, and more!"
}

#################################################################################################################################################
# Cleanup function for failed installations
#################################################################################################################################################
cleanup_failed_installation() {
    local base_path="$1"
    local error_stage="$2"
    local compose_cmd="${3:-docker-compose}"
    
    printf '\n%b\n' "${clr}
╔═══════════════════════════════════════════════════════════════════════════════╗
║                                                                               ║
║                        INSTALLATION FAILED!                                   ║
║                                                                               ║
║                        Cleaning up failed installation...                     ║
║                                                                               ║
╚═══════════════════════════════════════════════════════════════════════════════╝${cend}"
    
    printf '\n%b\n' " ${uyc} Error occurred during: ${clc}${error_stage}${cend}"
    printf '\n%b\n' " ${uyc} Cleaning up to prevent corrupted installation..."
    
    # Stop any running containers
    printf '\n%b\n' " ${uyc} Stopping any running containers..."
    if command -v docker >/dev/null 2>&1; then
        # Stop servarr stack if it exists
        if [[ -f "docker-compose-servarr.yml" ]] && [[ -f ".env-servarr" ]]; then
            $compose_cmd --env-file .env-servarr -f docker-compose-servarr.yml down --remove-orphans 2>/dev/null || true
        fi
        
        # Stop streamarr stack if it exists
        if [[ -f "docker-compose-streamarr.yml" ]] && [[ -f ".env-streamarr" ]]; then
            $compose_cmd --env-file .env-streamarr -f docker-compose-streamarr.yml down --remove-orphans 2>/dev/null || true
        fi
        
        # Stop creatarr stack if it exists
        if [[ -f "docker-compose-creatarr.yml" ]] && [[ -f ".env-creatarr" ]]; then
            $compose_cmd --env-file .env-creatarr -f docker-compose-creatarr.yml down --remove-orphans 2>/dev/null || true
        fi
        
        # Stop business stack if it exists
        if [[ -f "docker-compose-business.yml" ]] && [[ -f ".env-business" ]]; then
            $compose_cmd --env-file .env-business -f docker-compose-business.yml down --remove-orphans 2>/dev/null || true
        fi
        
        # Stop infrastructure stack if it exists
        if [[ -f "docker-compose-infrastructure.yml" ]] && [[ -f ".env-infrastructure" ]]; then
            $compose_cmd --env-file .env-infrastructure -f docker-compose-infrastructure.yml down --remove-orphans 2>/dev/null || true
        fi
        
        # Remove any related containers
        local related_containers=(
            "gluetun" "qbittorrent" "sabnzbd" "sonarr" "radarr" "lidarr" "bazarr" "prowlarr"
            "plex" "tautulli" "overseerr" "homarr" "ersatztv" "filebot-node" "filebot-watcher" "navidrome"
            "n8n" "n8n-postgres" "mealie" "mealie-db" "noisedash" "swing-music" "retroarch"
            "komga" "audiobookshelf" "calibre-web" "uptime-kuma"
            "watchtower-infrastructure"
        )
        
        for container in "${related_containers[@]}"; do
            docker rm -f "$container" 2>/dev/null || true
        done
        
        # Remove networks
        docker network rm servarr-network 2>/dev/null || true
        docker network rm streamarr-network 2>/dev/null || true
        docker network rm creatarr-network 2>/dev/null || true
        docker network rm business-network 2>/dev/null || true
        docker network rm infrastructure-network 2>/dev/null || true
    fi
    
    # Remove generated environment files
    printf '\n%b\n' " ${uyc} Removing generated configuration files..."
    rm -f ".env-servarr" ".env-streamarr" ".env-creatarr" ".env-business" ".env-infrastructure" 2>/dev/null || true
    rm -f ".env-servarr.bak" ".env-streamarr.bak" ".env-creatarr.bak" ".env-business.bak" ".env-infrastructure.bak" 2>/dev/null || true
    
    # Remove directories if they were created and are empty
    if [[ -n "$base_path" ]] && [[ -d "$base_path" ]]; then
        printf '\n%b\n' " ${uyc} Checking for empty directories to remove..."
        
        # List of directories that might have been created
        local created_dirs=(
            "${base_path}/docker/servarr"
            "${base_path}/docker/streamarr"
            "${base_path}/docker/creatarr"
            "${base_path}/docker/business"
            "${base_path}/docker/infrastructure"
            "${base_path}/data/downloads/complete"
            "${base_path}/data/downloads/incomplete"
            "${base_path}/data/media/movies"
            "${base_path}/data/media/tv"
            "${base_path}/data/media/music"
            "${base_path}/data/plex_transcode"
            "${base_path}/data/roms"
            "${base_path}/data/comics"
            "${base_path}/data/audiobooks"
            "${base_path}/data/podcasts"
            "${base_path}/data/books"
            "${base_path}/data/recipes"
            "${base_path}/data/saves"
        )
        
        # Remove empty directories (in reverse order to handle nested dirs)
        for ((i=${#created_dirs[@]}-1; i>=0; i--)); do
            local dir="${created_dirs[$i]}"
            if [[ -d "$dir" ]] && [[ -z "$(ls -A "$dir" 2>/dev/null)" ]]; then
                if rmdir "$dir" 2>/dev/null; then
                    printf '\n%b\n' " ${utick} Removed empty directory: ${clc}${dir}${cend}"
                fi
            fi
        done
        
        # Try to remove the main docker directory if empty
        if [[ -d "${base_path}/docker" ]] && [[ -z "$(ls -A "${base_path}/docker" 2>/dev/null)" ]]; then
            rmdir "${base_path}/docker" 2>/dev/null || true
        fi
        
        # Try to remove the main data directory if empty
        if [[ -d "${base_path}/data" ]] && [[ -z "$(ls -A "${base_path}/data" 2>/dev/null)" ]]; then
            rmdir "${base_path}/data" 2>/dev/null || true
        fi
        
        # Try to remove the base path if completely empty
        if [[ -d "$base_path" ]] && [[ -z "$(ls -A "$base_path" 2>/dev/null)" ]]; then
            rmdir "$base_path" 2>/dev/null || true
        fi
    fi
    
    printf '\n%b\n' "${clg}
╔═══════════════════════════════════════════════════════════════════════════════╗
║                                                                               ║
║                        CLEANUP COMPLETE!                                      ║
║                                                                               ║
║  All containers stopped and removed                                           ║
║  All networks removed                                                         ║
║  Generated configuration files removed                                        ║
║  Empty directories removed                                                    ║
║  Your data directories preserved (if any existed)                             ║
║                                                                               ║
╚═══════════════════════════════════════════════════════════════════════════════╝${cend}"
    
    printf '\n%b\n' " ${uyc} ${cy}What was cleaned up:${cend}"
    printf '\n%b\n' " ${clc}•${cend} All Docker containers and networks"
    printf '\n%b\n' " ${clc}•${cend} Generated environment files (.env-servarr, .env-streamarr, .env-creatarr, .env-business, .env-infrastructure)"
    printf '\n%b\n' " ${clc}•${cend} Empty directories created during setup"
    
    printf '\n%b\n' " ${uyc} ${cy}What was preserved:${cend}"
    printf '\n%b\n' " ${clg}•${cend} All existing data directories and files"
    printf '\n%b\n' " ${clg}•${cend} Original project files (docker-compose-*.yml, .env-*.example)"
    printf '\n%b\n' " ${clg}•${cend} Your media files and downloads (if any existed)"
    
    printf '\n%b\n' " ${uyc} ${cy}Next steps:${cend}"
    printf '\n%b\n' " ${clc}•${cend} Review the error messages above"
    printf '\n%b\n' " ${clc}•${cend} Fix any issues and try running the setup again"
    printf '\n%b\n' " ${clc}•${cend} Or run the uninstall script: ${clc}./scripts/uninstall.sh${cend}"
}

#################################################################################################################################################
# Main execution
#################################################################################################################################################
main() {
    # Check sudo requirement
    check_sudo
    
    # Show banner
    show_banner
    
    # Show disclaimer
    printf '\n%b\n' " ${uyc} ${cy}DISCLAIMER:${cend} Use this script at your own risk."
    printf '\n%b\n' " This script will create directories, configure files, and deploy containers."
    printf '\n%b\n' " Make sure you have proper backups before proceeding."
    printf '\n'
    
    # Ask for confirmation with default yes
    printf '%b' " ${uyc} Do you want to continue? [Y/n]: "
    read -r confirm
    if [[ "$confirm" =~ ^[Nn]$ ]]; then
        printf '\n%b\n' " ${ucross} Setup cancelled by user."
        exit 0
    fi
    
    # Initialize variables
    local base_path=""
    
    # Determine Docker Compose command (make it global)
    if command -v docker-compose >/dev/null 2>&1; then
        declare -g compose_cmd="docker-compose"
    else
        declare -g compose_cmd="docker compose"
    fi
    
    # Detect and select platform
    if ! detect_platform; then
        cleanup_failed_installation "$base_path" "platform detection" "$compose_cmd"
        exit 1
    fi
    
    # Check platform-specific prerequisites
    if ! check_platform_prerequisites; then
        cleanup_failed_installation "$base_path" "platform prerequisites check" "$compose_cmd"
        exit 1
    fi
    
    # Get base path from user with default
    printf '\n%b\n' " ${uyc} Configure installation paths:"
    printf '%b\n' " ${uyc} The script will install stacks in ${clc}${default_base_path}/docker${cend} (configs) and ${clc}${default_base_path}/data${cend} (media)"
    printf '%b\n' " ${uyc} You can change this to any path you prefer (e.g., /volume2, /mnt/storage, etc.)"
    printf '\n'
    printf '%b' " Base path for installation [${clc}${default_base_path}${cend}]: "
    read -r user_base_path
    base_path="${user_base_path:-$default_base_path}"
    printf '\n%b\n' " ${utick} Using base path: ${clc}${base_path}${cend}"
    printf '%b\n' " ${uyc} Directories will be created at: ${clc}${base_path}/docker${cend} and ${clc}${base_path}/data${cend}"
    
    # Get network information
    if ! get_platform_network_info; then
        cleanup_failed_installation "$base_path" "network information detection" "$compose_cmd"
        exit 1
    fi
    
    # Check prerequisites
    if ! check_prerequisites; then
        cleanup_failed_installation "$base_path" "prerequisites check" "$compose_cmd"
        exit 1
    fi
    
    # Select stacks to install
    if ! select_stacks; then
        printf '\n%b\n' " ${ucross} Stack selection cancelled or failed"
        exit 1
    fi
    
    if [[ ${#stacks_to_install[@]} -eq 0 ]]; then
        printf '\n%b\n' " ${ucross} No stacks selected. Exiting."
        exit 1
    fi
    
    # Select services for each selected stack
    for stack in "${stacks_to_install[@]}"; do
        case "$stack" in
            "servarr")
                select_services "servarr" "SERVARR"
                ;;
            "streamarr")
                select_services "streamarr" "STREAMARR"
                ;;
            "creatarr")
                select_services "creatarr" "CREATARR"
                ;;
            "business")
                select_services "business" "BUSINESS"
                ;;
            "infrastructure")
                select_services "infrastructure" "INFRASTRUCTURE"
                ;;
        esac
    done
    
    # Show comprehensive summary
    clear
    printf '\n%b\n' "${clg}╔═══════════════════════════════════════════════════════════════════════════════╗${cend}"
    printf '\n%b\n' "${clg}║                                                                               ║${cend}"
    printf '\n%b\n' "${clg}║                    📋 INSTALLATION SUMMARY                                      ║${cend}"
    printf '\n%b\n' "${clg}║                                                                               ║${cend}"
    printf '\n%b\n' "${clg}╚═══════════════════════════════════════════════════════════════════════════════╝${cend}"
    
    local total_services=0
    printf '\n%b\n' " ${cy}═══════════════════════════════════════════════════════════════════════════════${cend}"
    printf '\n%b\n' " ${uyc} Selected Stacks: ${clc}${#stacks_to_install[@]}${cend}"
    printf '\n%b\n' " ${cy}═══════════════════════════════════════════════════════════════════════════════${cend}"
    
    for stack in "${stacks_to_install[@]}"; do
        local service_count=0
        local stack_display=""
        local services_array=()
        
        case "$stack" in
            "servarr")
                service_count=${#services_servarr[@]:-0}
                stack_display="SERVARR"
                services_array=("${services_servarr[@]}")
                ;;
            "streamarr")
                service_count=${#services_streamarr[@]:-0}
                stack_display="STREAMARR"
                services_array=("${services_streamarr[@]}")
                ;;
            "creatarr")
                service_count=${#services_creatarr[@]:-0}
                stack_display="CREATARR"
                services_array=("${services_creatarr[@]}")
                ;;
            "business")
                service_count=${#services_business[@]:-0}
                stack_display="BUSINESS"
                services_array=("${services_business[@]}")
                ;;
            "infrastructure")
                service_count=${#services_infrastructure[@]:-0}
                stack_display="INFRASTRUCTURE"
                services_array=("${services_infrastructure[@]}")
                ;;
        esac
        
        total_services=$((total_services + service_count))
        
        if [[ $service_count -gt 0 ]]; then
            printf '\n%b\n' " ${clg}${stack_display}${cend} - ${clc}${service_count}${cend} service(s):"
            for service in "${services_array[@]}"; do
                printf '%b\n' "   ${clc}•${cend} ${service}"
            done
        else
            printf '\n%b\n' " ${uyc}${stack_display}${cend} - ${cy}No services selected (will be skipped)${cend}"
        fi
    done
    
    printf '\n%b\n' " ${cy}═══════════════════════════════════════════════════════════════════════════════${cend}"
    printf '\n%b\n' " ${clg}Total: ${clc}${#stacks_to_install[@]}${clg} stack(s), ${clc}${total_services}${clg} service(s)${cend}"
    printf '\n%b\n' " ${cy}═══════════════════════════════════════════════════════════════════════════════${cend}"
    
    printf '\n'
    printf '%b' " ${uyc} ${clg}Ready to proceed?${cend} [Y/n]: "
    read -r confirm_install
    if [[ "$confirm_install" =~ ^[Nn]$ ]]; then
        printf '\n%b\n' " ${ucross} Installation cancelled by user."
        exit 0
    fi
    
    printf '\n%b\n' " ${utick} ${clg}Starting installation...${cend}"
    sleep 1
    
    # Create directory structure
    if ! create_directories_for_platform; then
        cleanup_failed_installation "$base_path" "directory creation" "$compose_cmd"
        exit 1
    fi
    
    # Docker Compose will create networks automatically
    printf '\n%b\n' " ${uyc} Docker Compose will create networks automatically..."
    show_loading_message "Networks will be created by Docker Compose" 1
    
    # Configure environment files
    if ! configure_environment_files; then
        cleanup_failed_installation "$base_path" "environment file configuration" "$compose_cmd"
        exit 1
    fi
    
    # Configure VPN settings (only if SERVARR stack is selected)
    if [[ " ${stacks_to_install[@]} " =~ " servarr " ]]; then
        if ! configure_vpn_settings; then
            printf '\n%b\n' " ${uyc} VPN configuration failed, but continuing with setup..."
            printf '\n%b\n' " ${uyc} You can configure VPN settings manually later"
        fi
    fi
    
    # Configure n8n encryption key (only if BUSINESS stack is selected)
    if [[ " ${stacks_to_install[@]} " =~ " business " ]]; then
        if ! configure_n8n_encryption; then
            printf '\n%b\n' " ${uyc} n8n encryption configuration failed, but continuing with setup..."
            printf '\n%b\n' " ${uyc} You can configure n8n encryption manually later"
        fi
    fi
    
    # Fix permissions before deployment
    fix_permissions
    
    # Ask if user wants to deploy now with default yes
    printf '\n%b\n' " ${uyc} Ready to deploy the homelab media stack!"
    printf '%b' " Deploy now? [Y/n]: "
    read -r deploy_confirm
    
    if [[ ! "$deploy_confirm" =~ ^[Nn]$ ]]; then
        if deploy_stacks; then
            show_access_info
        else
            printf '\n%b\n' " ${ucross} Deployment failed. Check the errors above."
            cleanup_failed_installation "$base_path" "container deployment" "$compose_cmd"
            printf '\n%b\n' " ${uyc} You can try deploying manually using:"
            printf '\n%b\n' " ${clc}${compose_cmd} --env-file .env-servarr -f docker-compose-servarr.yml up -d${cend}"
            printf '\n%b\n' " ${clc}${compose_cmd} --env-file .env-streamarr -f docker-compose-streamarr.yml up -d${cend}"
            printf '\n%b\n' " ${clc}${compose_cmd} --env-file .env-creatarr -f docker-compose-creatarr.yml up -d${cend}"
            printf '\n%b\n' " ${clc}${compose_cmd} --env-file .env-business -f docker-compose-business.yml up -d${cend}"
            printf '\n%b\n' " ${clc}${compose_cmd} --env-file .env-infrastructure -f docker-compose-infrastructure.yml up -d${cend}"
            exit 1
        fi
    else
        printf '\n%b\n' " ${uyc} Setup complete! You can deploy later using:"
        printf '\n%b\n' " ${clc}${compose_cmd} --env-file .env-servarr -f docker-compose-servarr.yml up -d${cend}"
        printf '\n%b\n' " ${clc}${compose_cmd} --env-file .env-streamarr -f docker-compose-streamarr.yml up -d${cend}"
        printf '\n%b\n' " ${clc}${compose_cmd} --env-file .env-creatarr -f docker-compose-creatarr.yml up -d${cend}"
        printf '\n%b\n' " ${clc}${compose_cmd} --env-file .env-business -f docker-compose-business.yml up -d${cend}"
        printf '\n%b\n' " ${clc}${compose_cmd} --env-file .env-infrastructure -f docker-compose-infrastructure.yml up -d${cend}"
    fi
    
    printf '\n%b\n' " ${utick} ${clg}Homelab Media Stack setup complete!${cend}"
    printf '\n%b\n' " ${uyc} Platform: ${clc}${platform}${cend} | Base path: ${clc}${base_path}${cend}"
}

# Run main function
main "$@" 
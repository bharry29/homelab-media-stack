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
    
    # Directory list
    directories=(
        "${base_path}/docker/servarr"
        "${base_path}/docker/streamarr"
        "${base_path}/data/downloads/complete"
        "${base_path}/data/downloads/incomplete"
        "${base_path}/data/media/movies"
        "${base_path}/data/media/tv"
        "${base_path}/data/media/music"
        "${base_path}/data/plex_transcode"
    )
    
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

configure_environment_files() {
    printf '\n%b\n' " ${uyc} Configuring environment files..."
    show_loading_message "Configuring application settings" 1
    
    # Configure servarr environment
    if [[ ! -f ".env-servarr" ]]; then
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
    if [[ ! -f ".env-streamarr" ]]; then
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
    
    # Clean up backup files
    rm -f ".env-servarr.bak" ".env-streamarr.bak" 2>/dev/null || true
    
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
    printf '\n%b\n' " ${uyc} Deploying homelab media stack..."
    show_loading_message "Preparing container deployment" 1
    
    # Deploy SERVARR stack (download & management)
    printf '\n%b\n' "${clg}╔═══════════════════════════════════════════════════════════════════════════════╗${cend}"
    printf '\n%b\n' "${clg}║                                                                               ║${cend}"
    printf '\n%b\n' "${clg}║                    DEPLOYING SERVARR STACK                                    ║${cend}"
    printf '\n%b\n' "${clg}║                                                                               ║${cend}"
    printf '\n%b\n' "${clg}║                    (Download & Management Services)                           ║${cend}"
    printf '\n%b\n' "${clg}║                                                                               ║${cend}"
    printf '\n%b\n' "${clg}╚═══════════════════════════════════════════════════════════════════════════════╝${cend}"
    
    show_loading_message "Launching SERVARR services (VPN, downloads, automation)" 3
    
    if $compose_cmd --env-file .env-servarr -f docker-compose-servarr.yml up -d; then
        printf '\n%b\n' " ${utick} SERVARR stack deployed successfully!"
        printf '\n%b\n' " ${uyc} Services: Gluetun (VPN), qBittorrent, SABnzbd, Prowlarr, Sonarr, Radarr, Lidarr, Bazarr, FileBot, Homarr"
    else
        printf '\n%b\n' " ${ucross} Failed to deploy SERVARR stack"
        return 1
    fi
    
    # Wait for VPN to be ready
    printf '\n%b\n' " ${uyc} Waiting for VPN connection to establish (30 seconds)..."
    show_loading_message "Establishing VPN connection" 3
    
    # Verify VPN (optional, don't fail if it doesn't work)
    if docker exec gluetun curl -s --max-time 10 ifconfig.me > /dev/null 2>&1; then
        vpn_ip=$(docker exec gluetun curl -s --max-time 10 ifconfig.me 2>/dev/null)
        printf '\n%b\n' " ${utick} VPN is working! External IP: ${clc}${vpn_ip}${cend}"
    else
        printf '\n%b\n' " ${uyc} VPN not yet ready (this is normal, configure it later)"
    fi
    
    # Deploy STREAMARR stack (streaming & requests)
    printf '\n%b\n' "${clb}╔═══════════════════════════════════════════════════════════════════════════════╗${cend}"
    printf '\n%b\n' "${clb}║                                                                               ║${cend}"
    printf '\n%b\n' "${clb}║                    DEPLOYING STREAMARR STACK                                  ║${cend}"
    printf '\n%b\n' "${clb}║                                                                               ║${cend}"
    printf '\n%b\n' "${clb}║                    (Streaming & Request Services)                             ║${cend}"
    printf '\n%b\n' "${clb}║                                                                               ║${cend}"
    printf '\n%b\n' "${clb}╚═══════════════════════════════════════════════════════════════════════════════╝${cend}"
    
    show_loading_message "Launching STREAMARR services (Plex, Overseerr, Tautulli, ErsatzTV)" 3
    
    if $compose_cmd --env-file .env-streamarr -f docker-compose-streamarr.yml up -d; then
        printf '\n%b\n' " ${utick} STREAMARR stack deployed successfully!"
        printf '\n%b\n' " ${uyc} Services: Plex Media Server, Overseerr, Tautulli, ErsatzTV"
        return 0
    else
        printf '\n%b\n' " ${ucross} Failed to deploy STREAMARR stack"
        return 1
    fi
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
    
    printf '\n%b\n' "${clg}╔═══════════════════════════════════════════════════════════════════════════════╗${cend}"
    printf '\n%b\n' "${clg}║                                                                               ║${cend}"
    printf '\n%b\n' "${clg}║                    SERVARR STACK (Download & Management)                      ║${cend}"
    printf '\n%b\n' "${clg}║                                                                               ║${cend}"
    printf '\n%b\n' "${clg}╚═══════════════════════════════════════════════════════════════════════════════╝${cend}"
    
    printf '\n%b\n' " ${clc}Homarr Dashboard:${cend} http://${local_ip}:7575"
    printf '\n%b\n' " ${clc}qBittorrent:${cend} http://${local_ip}:8080"
    printf '\n%b\n' " ${clc}SABnzbd:${cend} http://${local_ip}:8090"
    printf '\n%b\n' " ${clc}Prowlarr:${cend} http://${local_ip}:9696"
    printf '\n%b\n' " ${clc}Sonarr:${cend} http://${local_ip}:8989"
    printf '\n%b\n' " ${clc}Radarr:${cend} http://${local_ip}:7878"
    printf '\n%b\n' " ${clc}Lidarr:${cend} http://${local_ip}:8686"
    printf '\n%b\n' " ${clc}Bazarr:${cend} http://${local_ip}:6767"
    printf '\n%b\n' " ${clc}FileBot:${cend} http://${local_ip}:5452"
    
    printf '\n%b\n' "${clb}╔═══════════════════════════════════════════════════════════════════════════════╗${cend}"
    printf '\n%b\n' "${clb}║                                                                               ║${cend}"
    printf '\n%b\n' "${clb}║                    STREAMARR STACK (Streaming & Requests)                     ║${cend}"
    printf '\n%b\n' "${clb}║                                                                               ║${cend}"
    printf '\n%b\n' "${clb}╚═══════════════════════════════════════════════════════════════════════════════╝${cend}"
    
    printf '\n%b\n' " ${clc}Plex Media Server:${cend} http://${local_ip}:32400/web"
    printf '\n%b\n' " ${clc}Overseerr:${cend} http://${local_ip}:5055"
    printf '\n%b\n' " ${clc}Tautulli:${cend} http://${local_ip}:8181"
    printf '\n%b\n' " ${clc}ErsatzTV:${cend} http://${local_ip}:8409"
    
    printf '\n%b\n' " ${uyc} ${cy}Next Steps:${cend}"
    printf '\n%b\n' " ${clc}1.${cend} Set up download clients in Sonarr/Radarr"
    printf '\n%b\n' " ${clc}2.${cend} Add indexers in Prowlarr"
    printf '\n%b\n' " ${clc}3.${cend} Configure Plex libraries"
    printf '\n%b\n' " ${clc}4.${cend} Set up Overseerr for requests"
    printf '\n%b\n' " ${clc}5.${cend} Configure FileBot for media organization"
    
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
        
        # Remove any related containers
        local related_containers=(
            "gluetun" "qbittorrent" "sabnzbd" "sonarr" "radarr" "lidarr" "bazarr" "prowlarr"
            "plex" "tautulli" "overseerr" "homarr" "ersatztv" "filebot"
        )
        
        for container in "${related_containers[@]}"; do
            docker rm -f "$container" 2>/dev/null || true
        done
        
        # Remove networks
        docker network rm servarr-network 2>/dev/null || true
        docker network rm streamarr-network 2>/dev/null || true
    fi
    
    # Remove generated environment files
    printf '\n%b\n' " ${uyc} Removing generated configuration files..."
    rm -f ".env-servarr" ".env-streamarr" 2>/dev/null || true
    rm -f ".env-servarr.bak" ".env-streamarr.bak" 2>/dev/null || true
    
    # Remove directories if they were created and are empty
    if [[ -n "$base_path" ]] && [[ -d "$base_path" ]]; then
        printf '\n%b\n' " ${uyc} Checking for empty directories to remove..."
        
        # List of directories that might have been created
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
    printf '\n%b\n' " ${clc}•${cend} Generated environment files (.env-servarr, .env-streamarr)"
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
    printf '%b' " Base path for installation [${clc}${default_base_path}${cend}]: "
    read -r user_base_path
    base_path="${user_base_path:-$default_base_path}"
    printf '\n%b\n' " ${utick} Using base path: ${clc}${base_path}${cend}"
    
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
    
    # Configure VPN settings
    if ! configure_vpn_settings; then
        printf '\n%b\n' " ${uyc} VPN configuration failed, but continuing with setup..."
        printf '\n%b\n' " ${uyc} You can configure VPN settings manually later"
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
            exit 1
        fi
    else
        printf '\n%b\n' " ${uyc} Setup complete! You can deploy later using:"
        printf '\n%b\n' " ${clc}${compose_cmd} --env-file .env-servarr -f docker-compose-servarr.yml up -d${cend}"
        printf '\n%b\n' " ${clc}${compose_cmd} --env-file .env-streamarr -f docker-compose-streamarr.yml up -d${cend}"
    fi
    
    printf '\n%b\n' " ${utick} ${clg}Homelab Media Stack setup complete!${cend}"
    printf '\n%b\n' " ${uyc} Platform: ${clc}${platform}${cend} | Base path: ${clc}${base_path}${cend}"
}

# Run main function
main "$@" 
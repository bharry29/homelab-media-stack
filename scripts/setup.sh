#!/usr/bin/env bash

# MIT License
# Homelab Media Stack Universal Setup Script
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
    printf '\n%b\n' "${cb}
╔═══════════════════════════════════════════════════════════════════════════════╗
║                          HOMELAB MEDIA STACK                                  ║
║                       Universal Setup Script v2.0                             ║
║                                                                               ║
║  Supports: Windows • macOS • Linux • Synology • UGREEN • QNAP                 ║
║           TrueNAS • Unraid • Proxmox • And More!                              ║
╚═══════════════════════════════════════════════════════════════════════════════╝${cend}"
    sleep 1
}

#################################################################################################################################################
# Platform Detection and Selection
#################################################################################################################################################
detect_platform() {
    printf '\n%b\n' " ${uyc} Detecting your platform..."
    show_loading_message "Analyzing system environment" 2
    
    # Automatic detection
    local detected=""
    local auto_path=""
    local auto_puid=""
    local auto_pgid=""
    
    # Check for specific NAS/virtualization platforms first
    if command -v synoinfo &> /dev/null; then
        detected="synology"
        auto_path="/volume1"
        auto_puid="1026"
        auto_pgid="100"
    elif grep -q "unraid" /etc/os-release 2>/dev/null; then
        detected="unraid"
        auto_path="/mnt/user"
        auto_puid="99"
        auto_pgid="100"
    elif command -v midclt &> /dev/null; then
        detected="truenas"
        auto_path="/mnt"
        auto_puid="1000"
        auto_pgid="1000"
    elif command -v pveversion &> /dev/null; then
        detected="proxmox"
        auto_path="/opt/homelab"
        auto_puid="1000"
        auto_pgid="1000"
    elif [[ -f /etc/ugreen-nas-release ]] || [[ -d /usr/local/ugreen ]]; then
        detected="ugreen"
        auto_path="/volume1"
        auto_puid="1001"
        auto_pgid="1000"
    elif command -v qpkg_cli &> /dev/null || [[ -d /share ]]; then
        detected="qnap"
        auto_path="/share"
        auto_puid="1000"
        auto_pgid="1000"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        detected="macos"
        auto_path="$HOME/homelab"
        auto_puid="1000"
        auto_pgid="1000"
    elif [[ "$OS" == "Windows_NT" ]] || [[ -n "$WINDIR" ]] || command -v powershell.exe &> /dev/null; then
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
        
        # Use detected platform if user just presses enter
        if [[ -z "$choice" && -n "$detected" ]]; then
            platform="$detected"
            default_base_path="$auto_path"
            puid="$auto_puid"
            pgid="$auto_pgid"
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

show_windows_instructions() {
    printf '\n%b\n' " ${uyc} ${cy}Windows detected!${cend}"
    printf '\n%b\n' " ${uyc} For the best experience on Windows, please ensure you're running this script in:"
    printf '\n%b\n' " ${clc}•${cend} Windows Subsystem for Linux (WSL2) - Recommended"
    printf '\n%b\n' " ${clc}•${cend} Git Bash"
    printf '\n%b\n' " ${clc}•${cend} MSYS2/MinGW"
    printf '\n%b\n' " ${uyc} ${cy}Note:${cend} Paths will use Unix-style format (/c/homelab instead of C:\\homelab)"
}

#################################################################################################################################################
# Platform-specific functions
#################################################################################################################################################
check_platform_prerequisites() {
    printf '\n%b\n' " ${uyc} Checking platform-specific prerequisites..."
    
    case "$platform" in
        "synology")
            # Check if Container Manager or Docker is installed
            if command -v synopkg &> /dev/null; then
                if synopkg status ContainerManager &> /dev/null || synopkg status Docker &> /dev/null; then
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
            if [[ -d "/usr/local/ContainerStation" ]] || command -v docker &> /dev/null; then
                printf '\n%b\n' " ${utick} Container Station/Docker found"
            else
                printf '\n%b\n' " ${ucross} Container Station not installed"
                printf '\n%b\n' " ${uyc} Please install Container Station from App Center first"
                exit 1
            fi
            ;;
        "unraid")
            # Check for Community Applications
            if [[ -d "/usr/local/emhttp/plugins/dockerMan" ]] || command -v docker &> /dev/null; then
                printf '\n%b\n' " ${utick} Docker support found"
            else
                printf '\n%b\n' " ${ucross} Docker not available"
                printf '\n%b\n' " ${uyc} Please enable Docker in Unraid settings first"
                exit 1
            fi
            ;;
        "truenas")
            # Check for Docker/Apps
            if command -v docker &> /dev/null || command -v k3s &> /dev/null; then
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
            elif command -v pct &> /dev/null; then
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
            local_ip=$(ifconfig | grep "inet " | grep -v 127.0.0.1 | awk '{print $2}' | head -1)
            ;;
        "windows")
            # Try different methods for Windows environments
            if command -v ipconfig.exe &> /dev/null; then
                local_ip=$(ipconfig.exe | grep -A 1 "Wireless\|Ethernet" | grep "IPv4" | head -1 | awk '{print $NF}' | tr -d '\r')
            elif [[ -n "$WSL_DISTRO_NAME" ]]; then
                local_ip=$(ip route get 1 | awk '{print $7}' | head -1)
            else
                local_ip=$(hostname -I | awk '{print $1}')
            fi
            ;;
        *)
            # Linux-based systems
            local_ip=$(ip route get 1 2>/dev/null | awk '{print $7}' | head -1 || hostname -I | awk '{print $1}')
            ;;
    esac
    
    # Fallback if detection fails
    if [[ -z "$local_ip" || "$local_ip" == "127.0.0.1" ]]; then
        local_ip="192.168.1.100"
        printf '\n%b\n' " ${uyc} Could not detect local IP, using fallback: ${clc}${local_ip}${cend}"
    else
        printf '\n%b\n' " ${utick} Detected local IP: ${clc}${local_ip}${cend}"
    fi
    
    # Get timezone based on platform
    case "$platform" in
        "synology"|"qnap"|"ugreen")
            timezone=$(cat /etc/timezone 2>/dev/null || cat /usr/share/zoneinfo/UTC 2>/dev/null | head -1 || echo "UTC")
            ;;
        "macos")
            timezone=$(readlink /etc/localtime | sed 's|/var/db/timezone/zoneinfo/||' || echo "UTC")
            ;;
        "windows")
            # Convert Windows timezone to Linux format (basic mapping)
            timezone="UTC"  # Default, user can modify later
            ;;
        *)
            timezone=$(timedatectl show --property=Timezone --value 2>/dev/null || cat /etc/timezone 2>/dev/null || echo "UTC")
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
    if ! command -v docker &> /dev/null; then
        printf '\n%b\n' " ${ucross} Docker is not installed"
        show_docker_install_instructions
        exit 1
    else
        docker_version=$(docker --version 2>/dev/null)
        printf '\n%b\n' " ${utick} Docker found: ${clc}${docker_version}${cend}"
    fi
    
    # Check Docker Compose
    if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null 2>&1; then
        printf '\n%b\n' " ${ucross} Docker Compose is not installed"
        show_compose_install_instructions
        exit 1
    else
        if command -v docker-compose &> /dev/null; then
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
create_docker_networks() {
    printf '\n%b\n' " ${uyc} Creating Docker networks..."
    show_loading_message "Setting up network isolation" 1
    
    # Function to check if network was created by Docker Compose
    check_compose_network() {
        local network_name="$1"
        docker network inspect "$network_name" 2>/dev/null | grep -q '"com.docker.compose.network": "'"$network_name"'"'
    }
    
    # Arrays to store conflicting networks
    declare -a conflicting_networks=()
    declare -a existing_networks=()
    declare -A network_containers
    
    # Check servarr-network
    if docker network ls | grep -q "servarr-network"; then
        if check_compose_network "servarr-network"; then
            printf '\n%b\n' " ${utick} servarr-network already exists (created by Docker Compose)"
        else
            conflicting_networks+=("servarr-network")
            # Get containers attached
            containers=$(docker network inspect servarr-network --format '{{range $k,$v := .Containers}}{{$k}} {{end}}')
            network_containers["servarr-network"]="$containers"
        fi
    else
        existing_networks+=("servarr-network")
    fi
    
    # Check streamarr-network
    if docker network ls | grep -q "streamarr-network"; then
        if check_compose_network "streamarr-network"; then
            printf '\n%b\n' " ${utick} streamarr-network already exists (created by Docker Compose)"
        else
            conflicting_networks+=("streamarr-network")
            containers=$(docker network inspect streamarr-network --format '{{range $k,$v := .Containers}}{{$k}} {{end}}')
            network_containers["streamarr-network"]="$containers"
        fi
    else
        existing_networks+=("streamarr-network")
    fi
    
    # Handle conflicting networks
    if [[ ${#conflicting_networks[@]} -gt 0 ]]; then
        printf '\n%b\n' " ${cy}⚠️  NETWORK CONFLICTS DETECTED:${cend}"
        printf '\n%b\n' " ${uyc} The following networks exist but were not created by Docker Compose:"
        for network in "${conflicting_networks[@]}"; do
            printf '\n%b\n' " ${clc}•${cend} ${network}"
        done
        printf '\n%b\n' " ${cy}⚠️  WARNING:${cend} These networks may be used by other containers."
        
        for network in "${conflicting_networks[@]}"; do
            containers="${network_containers[$network]}"
            if [[ -z "$containers" ]]; then
                printf '\n%b\n' " ${uyc} No containers are attached to ${network}. Removing automatically..."
                if docker network rm "$network" > /dev/null 2>&1; then
                    printf '\n%b\n' " ${utick} Removed ${network}"
                    existing_networks+=("$network")
                else
                    printf '\n%b\n' " ${ucross} Failed to remove ${network}"
                    printf '\n%b\n' " ${uyc} Try: ${clc}docker network rm ${network}${cend} manually."
                    return 1
                fi
            else
                printf '\n%b\n' " ${cy}⚠️  Containers attached to ${network}:${cend}"
                for c in $containers; do
                    printf '\n%b\n' "   - $c"
                done
                printf '\n%b' " ${uyc} Remove ${network} and disconnect these containers? [y/N]: "
                read -r remove_network
                if [[ "$remove_network" =~ ^[Yy]$ ]]; then
                    if docker network rm "$network" > /dev/null 2>&1; then
                        printf '\n%b\n' " ${utick} Removed ${network}"
                        existing_networks+=("$network")
                    else
                        printf '\n%b\n' " ${ucross} Failed to remove ${network}"
                        printf '\n%b\n' " ${uyc} Try: ${clc}docker network disconnect ${network} <container_name>${cend} manually."
                        return 1
                    fi
                else
                    printf '\n%b\n' " ${uyc} Skipping network setup for ${network}. You may need to handle this manually."
                    printf '\n%b\n' " ${uyc} Consider running: ${clc}docker network rm ${network}${cend} manually."
                    return 1
                fi
            fi
        done
    fi
    
    # Create networks that don't exist
    for network in "${existing_networks[@]}"; do
        case "$network" in
            "servarr-network")
                if docker network create --driver bridge --subnet=172.39.0.0/24 servarr-network > /dev/null 2>&1; then
                    printf '\n%b\n' " ${utick} Created servarr-network (172.39.0.0/24)"
                else
                    printf '\n%b\n' " ${ucross} Failed to create servarr-network"
                    return 1
                fi
                ;;
            "streamarr-network")
                if docker network create --driver bridge --subnet=172.40.0.0/24 streamarr-network > /dev/null 2>&1; then
                    printf '\n%b\n' " ${utick} Created streamarr-network (172.40.0.0/24)"
                else
                    printf '\n%b\n' " ${ucross} Failed to create streamarr-network"
                    return 1
                fi
                ;;
        esac
    done
    
    printf '\n%b\n' " ${utick} Docker networks ready!"
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

deploy_stacks() {
    printf '\n%b\n' " ${uyc} Deploying homelab media stack..."
    show_loading_message "Preparing container deployment" 1
    
    # Deploy servarr stack
    printf '\n%b\n' " ${uyc} Starting SERVARR stack (download & management)..."
    show_loading_message "Launching download services" 2
    
    if $compose_cmd --env-file .env-servarr -f docker-compose-servarr.yml up -d; then
        printf '\n%b\n' " ${utick} SERVARR stack started successfully!"
    else
        printf '\n%b\n' " ${ucross} Failed to start SERVARR stack"
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
    
    # Deploy streamarr stack
    printf '\n%b\n' " ${uyc} Starting STREAMARR stack (streaming & requests)..."
    show_loading_message "Launching streaming services" 2
    
    if $compose_cmd --env-file .env-streamarr -f docker-compose-streamarr.yml up -d; then
        printf '\n%b\n' " ${utick} STREAMARR stack started successfully!"
        return 0
    else
        printf '\n%b\n' " ${ucross} Failed to start STREAMARR stack"
        return 1
    fi
}

show_access_info() {
    printf '\n%b\n' "${clg}
╔═══════════════════════════════════════════════════════════════════════════════╗
║                             SETUP COMPLETE!                                   ║
║                        Access your services below:                            ║
╚═══════════════════════════════════════════════════════════════════════════════╝${cend}"
    
    printf '\n%b\n' " ${clc}🏠 Homarr Dashboard:${cend} http://${local_ip}:7575"
    printf '\n%b\n' " ${clc}🎬 Plex Media Server:${cend} http://${local_ip}:32400/web"
    printf '\n%b\n' " ${clc}📱 Overseerr:${cend} http://${local_ip}:5055"
    printf '\n%b\n' " ${clc}⬇️ qBittorrent:${cend} http://${local_ip}:8080"
    printf '\n%b\n' " ${clc}📺 Sonarr:${cend} http://${local_ip}:8989"
    printf '\n%b\n' " ${clc}🎥 Radarr:${cend} http://${local_ip}:7878"
    printf '\n%b\n' " ${clc}🎵 Lidarr:${cend} http://${local_ip}:8686"
    printf '\n%b\n' " ${clc}💬 Bazarr:${cend} http://${local_ip}:6767"
    printf '\n%b\n' " ${clc}🔍 Prowlarr:${cend} http://${local_ip}:9696"
    printf '\n%b\n' " ${clc}📊 Tautulli:${cend} http://${local_ip}:8181"
    printf '\n%b\n' " ${clc}📺 ErsatzTV:${cend} http://${local_ip}:8409"
    printf '\n%b\n' " ${clc}📋 SABnzbd:${cend} http://${local_ip}:8090"
    printf '\n%b\n' " ${clc}🗂️ FileBot:${cend} http://${local_ip}:5452"
    
    printf '\n%b\n' " ${uyc} ${cy}Next Steps:${cend}"
    printf '\n%b\n' " ${clc}1.${cend} Configure your VPN settings in .env-servarr"
    printf '\n%b\n' " ${clc}2.${cend} Set up download clients in Sonarr/Radarr"
    printf '\n%b\n' " ${clc}3.${cend} Add indexers in Prowlarr"
    printf '\n%b\n' " ${clc}4.${cend} Configure Plex libraries"
    printf '\n%b\n' " ${clc}5.${cend} Set up Overseerr for requests"
    
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
║                       ⚠️  IMPORTANT: VPN REQUIRED! ⚠️                        ║
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
# Main execution
#################################################################################################################################################
main() {
    # Show banner
    show_banner
    
    # Show disclaimer
    printf '\n%b\n' " ${uyc} ${cy}⚠️ DISCLAIMER:${cend} Use this script at your own risk."
    printf '\n%b\n' " This script will create directories, configure files, and deploy containers."
    printf '\n%b\n' " Make sure you have proper backups before proceeding."
    printf '\n'
    
    # Ask for confirmation
    printf '%b' " ${uyc} Do you want to continue? [y/N]: "
    read -r confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        printf '\n%b\n' " ${ucross} Setup cancelled by user."
        exit 0
    fi
    
    # Detect and select platform
    detect_platform
    
    # Check platform-specific prerequisites
    check_platform_prerequisites
    
    # Get base path from user
    printf '\n%b\n' " ${uyc} Configure installation paths:"
    printf '%b' " Base path for installation [${clc}${default_base_path}${cend}]: "
    read -r user_base_path
    base_path="${user_base_path:-$default_base_path}"
    
    # Get network information
    get_platform_network_info
    
    # Check prerequisites
    check_prerequisites
    
    # Create directory structure
    create_directories_for_platform
    
    # Docker Compose will create networks automatically
    printf '\n%b\n' " ${uyc} Docker Compose will create networks automatically..."
    show_loading_message "Networks will be created by Docker Compose" 1
    
    # Configure environment files
    configure_environment_files
    
    # Show VPN warning
    show_vpn_warning
    
    # Ask if user wants to deploy now
    printf '\n%b\n' " ${uyc} Ready to deploy the homelab media stack!"
    printf '%b' " Deploy now? [y/N]: "
    read -r deploy_confirm
    
    if [[ "$deploy_confirm" =~ ^[Yy]$ ]]; then
        if deploy_stacks; then
            show_access_info
        else
            printf '\n%b\n' " ${ucross} Deployment failed. Check the errors above."
            printf '\n%b\n' " ${uyc} You can try deploying manually using:"
            printf '\n%b\n' " ${clc}${compose_cmd} --env-file .env-servarr -f docker-compose-servarr.yml up -d${cend}"
            printf '\n%b\n' " ${clc}${compose_cmd} --env-file .env-streamarr -f docker-compose-streamarr.yml up -d${cend}"
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
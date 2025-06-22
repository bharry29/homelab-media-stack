#!/bin/bash

# =============================================================================
# Homelab Media Stack Setup Script for Linux/Mac
# =============================================================================
# This script prepares your system for the media stack deployment
# Usage: ./setup.sh [OPTIONS]
#
# Options:
#   -p, --path PATH     Base path for installation (default: /volume1)
#   -u, --puid PUID     User ID (default: current user)
#   -g, --pgid PGID     Group ID (default: current user)
#   -h, --help          Show this help message
# =============================================================================

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
GRAY='\033[0;37m'
NC='\033[0m' # No Color

# Default configuration
DEFAULT_BASE_PATH="/volume1"
DEFAULT_PUID=$(id -u)
DEFAULT_PGID=$(id -g)

# Configuration variables
BASE_PATH="$DEFAULT_BASE_PATH"
PUID="$DEFAULT_PUID"
PGID="$DEFAULT_PGID"

# Functions
print_header() {
    echo -e "${BLUE}"
    echo "================================================================="
    echo "    Homelab Media Stack Setup Script for Linux/Mac"
    echo "================================================================="
    echo -e "${NC}"
}

print_step() {
    echo -e "${GREEN}[STEP] $1${NC}"
}

print_info() {
    echo -e "${CYAN}[INFO] $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}[WARN] $1${NC}"
}

print_error() {
    echo -e "${RED}[ERROR] $1${NC}"
}

print_success() {
    echo -e "${GREEN}[SUCCESS] $1${NC}"
}

print_help() {
    cat << EOF
Homelab Media Stack Setup Script

USAGE:
    ./setup.sh [OPTIONS]

OPTIONS:
    -p, --path PATH     Base path for installation (default: $DEFAULT_BASE_PATH)
    -u, --puid PUID     User ID (default: $DEFAULT_PUID)
    -g, --pgid PGID     Group ID (default: $DEFAULT_PGID)
    -h, --help          Show this help message

EXAMPLES:
    ./setup.sh                                    # Use defaults
    ./setup.sh -p /mnt/storage                   # Custom base path
    ./setup.sh -p /home/user/media -u 1000 -g 1000  # Custom path and IDs

DESCRIPTION:
    This script creates the directory structure and Docker networks required
    for the Homelab Media Stack. It will:
    
    1. Check system prerequisites
    2. Create directory structure for configs and data
    3. Set up Docker networks with proper isolation
    4. Update environment file templates
    5. Verify the setup completed successfully

EOF
}

parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -p|--path)
                BASE_PATH="$2"
                shift 2
                ;;
            -u|--puid)
                PUID="$2"
                shift 2
                ;;
            -g|--pgid)
                PGID="$2"
                shift 2
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
    
    # Check if running as root
    if [[ $EUID -eq 0 ]]; then
        print_error "This script should not be run as root!"
        print_info "Run as your regular user, you'll be prompted for sudo when needed."
        exit 1
    fi
    
    # Check Docker
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed!"
        print_info "Please install Docker first:"
        print_info "  Ubuntu/Debian: sudo apt update && sudo apt install docker.io"
        print_info "  CentOS/RHEL: sudo yum install docker"
        print_info "  macOS: Install Docker Desktop from https://www.docker.com/products/docker-desktop"
        exit 1
    fi
    
    # Check Docker Compose
    if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
        print_error "Docker Compose is not installed!"
        print_info "Please install Docker Compose first:"
        print_info "  https://docs.docker.com/compose/install/"
        exit 1
    fi
    
    # Check if user is in docker group
    if ! groups | grep -q docker; then
        print_warning "Current user is not in 'docker' group"
        print_info "You may need to run: sudo usermod -aG docker $USER"
        print_info "Then logout and login again"
    fi
    
    # Check Docker daemon
    if ! docker info &> /dev/null; then
        print_error "Docker daemon is not running!"
        print_info "Please start Docker first:"
        print_info "  Linux: sudo systemctl start docker"
        print_info "  macOS: Start Docker Desktop"
        exit 1
    fi
    
    print_success "Prerequisites check passed"
}

confirm_configuration() {
    print_step "Configuration review..."
    echo
    print_info "Configuration:"
    echo -e "  ${GRAY}Base Path: ${YELLOW}$BASE_PATH${NC}"
    echo -e "  ${GRAY}User ID (PUID): ${YELLOW}$PUID${NC}"
    echo -e "  ${GRAY}Group ID (PGID): ${YELLOW}$PGID${NC}"
    echo -e "  ${GRAY}Current User: ${YELLOW}$(whoami)${NC}"
    echo
    
    print_info "Directory structure will be created at:"
    echo -e "  ${GRAY}• Configs: ${YELLOW}$BASE_PATH/docker/${NC}"
    echo -e "  ${GRAY}• Data: ${YELLOW}$BASE_PATH/data/${NC}"
    echo
    
    read -p "Continue with this configuration? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "Setup cancelled by user."
        exit 0
    fi
}

create_directories() {
    print_step "Creating directory structure..."
    
    # Define directory arrays
    local SERVARR_DIRS=(
        "gluetun"
        "qbittorrent" 
        "sabnzbd"
        "prowlarr"
        "sonarr"
        "radarr"
        "lidarr"
        "bazarr"
        "homarr/configs"
        "homarr/icons"
        "homarr/data"
    )
    
    local STREAMARR_DIRS=(
        "plex"
        "overseerr"
        "tautulli"
        "ersatztv"
    )
    
    local DATA_DIRS=(
        "downloads/complete"
        "downloads/incomplete"
        "media/movies"
        "media/tv"
        "media/music"
        "plex_transcode"
    )
    
    local created_count=0
    
    # Create base directories
    print_info "Creating base directories..."
    for base_dir in "docker/servarr" "docker/streamarr" "data"; do
        if [[ ! -d "$BASE_PATH/$base_dir" ]]; then
            sudo mkdir -p "$BASE_PATH/$base_dir"
            echo -e "  ${GRAY}✓ $BASE_PATH/$base_dir${NC}"
            ((created_count++))
        else
            echo -e "  ${YELLOW}ℹ $BASE_PATH/$base_dir (exists)${NC}"
        fi
    done
    
    # Create servarr directories
    print_info "Creating servarr config directories..."
    for dir in "${SERVARR_DIRS[@]}"; do
        local full_path="$BASE_PATH/docker/servarr/$dir"
        if [[ ! -d "$full_path" ]]; then
            sudo mkdir -p "$full_path"
            echo -e "  ${GRAY}✓ $full_path${NC}"
            ((created_count++))
        else
            echo -e "  ${YELLOW}ℹ $full_path (exists)${NC}"
        fi
    done
    
    # Create streamarr directories
    print_info "Creating streamarr config directories..."
    for dir in "${STREAMARR_DIRS[@]}"; do
        local full_path="$BASE_PATH/docker/streamarr/$dir"
        if [[ ! -d "$full_path" ]]; then
            sudo mkdir -p "$full_path"
            echo -e "  ${GRAY}✓ $full_path${NC}"
            ((created_count++))
        else
            echo -e "  ${YELLOW}ℹ $full_path (exists)${NC}"
        fi
    done
    
    # Create data directories
    print_info "Creating data directories..."
    for dir in "${DATA_DIRS[@]}"; do
        local full_path="$BASE_PATH/data/$dir"
        if [[ ! -d "$full_path" ]]; then
            sudo mkdir -p "$full_path"
            echo -e "  ${GRAY}✓ $full_path${NC}"
            ((created_count++))
        else
            echo -e "  ${YELLOW}ℹ $full_path (exists)${NC}"
        fi
    done
    
    print_success "Created $created_count new directories"
}

set_permissions() {
    print_step "Setting directory permissions..."
    
    print_info "Setting ownership to $PUID:$PGID..."
    sudo chown -R "$PUID:$PGID" "$BASE_PATH/docker"
    sudo chown -R "$PUID:$PGID" "$BASE_PATH/data"
    
    print_info "Setting directory permissions..."
    sudo chmod -R 755 "$BASE_PATH/docker"
    sudo chmod -R 755 "$BASE_PATH/data"
    
    print_success "Permissions set successfully"
}

create_docker_networks() {
    print_step "Creating Docker networks..."
    
    local networks=(
        "servarr-network:172.39.0.0/24"
        "streamarr-network:172.40.0.0/24"
    )
    
    for network_info in "${networks[@]}"; do
        local network_name="${network_info%%:*}"
        local subnet="${network_info##*:}"
        
        if docker network ls | grep -q "$network_name"; then
            print_info "Network already exists: $network_name"
        else
            if docker network create --driver bridge --subnet="$subnet" "$network_name" > /dev/null; then
                echo -e "  ${GRAY}✓ Created network: $network_name ($subnet)${NC}"
            else
                print_error "Failed to create network: $network_name"
                exit 1
            fi
        fi
    done
    
    print_success "Docker networks configured"
}

update_environment_files() {
    print_step "Updating environment file templates..."
    
    # Update .env-servarr.example
    if [[ -f ".env-servarr.example" ]]; then
        # Create backup
        cp .env-servarr.example .env-servarr.example.bak
        
        # Update paths and IDs
        sed -i.tmp \
            -e "s|PUID=1001|PUID=$PUID|g" \
            -e "s|PGID=1000|PGID=$PGID|g" \
            -e "s|SERVARR_CONFIG_PATH=/volume1/docker/servarr|SERVARR_CONFIG_PATH=$BASE_PATH/docker/servarr|g" \
            -e "s|DATA_PATH=/volume1/data|DATA_PATH=$BASE_PATH/data|g" \
            -e "s|MEDIA_DATA_PATH=/volume1/data/media|MEDIA_DATA_PATH=$BASE_PATH/data/media|g" \
            .env-servarr.example
        
        rm -f .env-servarr.example.tmp
        echo -e "  ${GRAY}✓ Updated .env-servarr.example${NC}"
    else
        print_warning ".env-servarr.example not found"
    fi
    
    # Update .env-streamarr.example  
    if [[ -f ".env-streamarr.example" ]]; then
        # Create backup
        cp .env-streamarr.example .env-streamarr.example.bak
        
        # Update paths and IDs
        sed -i.tmp \
            -e "s|PUID=1001|PUID=$PUID|g" \
            -e "s|PGID=1000|PGID=$PGID|g" \
            -e "s|STREAMARR_CONFIG_PATH=/volume1/docker/streamarr|STREAMARR_CONFIG_PATH=$BASE_PATH/docker/streamarr|g" \
            -e "s|DATA_PATH=/volume1/data|DATA_PATH=$BASE_PATH/data|g" \
            .env-streamarr.example
        
        rm -f .env-streamarr.example.tmp
        echo -e "  ${GRAY}✓ Updated .env-streamarr.example${NC}"
    else
        print_warning ".env-streamarr.example not found"
    fi
    
    print_success "Environment files updated"
}

verify_setup() {
    print_step "Verifying setup..."
    
    local verification_passed=true
    
    # Check directories exist and have correct ownership
    local dirs_to_check=(
        "$BASE_PATH/docker/servarr"
        "$BASE_PATH/docker/streamarr"
        "$BASE_PATH/data/downloads"
        "$BASE_PATH/data/media"
    )
    
    for dir in "${dirs_to_check[@]}"; do
        if [[ -d "$dir" ]]; then
            local owner=$(stat -c '%U:%G' "$dir" 2>/dev/null || stat -f '%Su:%Sg' "$dir" 2>/dev/null || echo "unknown")
            echo -e "  ${GRAY}✓ $dir (owner: $owner)${NC}"
        else
            echo -e "  ${RED}✗ $dir does not exist${NC}"
            verification_passed=false
        fi
    done
    
    # Check Docker networks
    local networks=("servarr-network" "streamarr-network")
    for network in "${networks[@]}"; do
        if docker network ls | grep -q "$network"; then
            echo -e "  ${GRAY}✓ Docker network: $network${NC}"
        else
            echo -e "  ${RED}✗ Docker network missing: $network${NC}"
            verification_passed=false
        fi
    done
    
    if [[ "$verification_passed" == true ]]; then
        print_success "Setup verification passed"
        return 0
    else
        print_error "Setup verification failed"
        return 1
    fi
}

print_next_steps() {
    print_step "Setup complete! Next steps:"
    echo
    print_info "1. Configure environment files:"
    echo -e "   ${GRAY}cp .env-servarr.example .env-servarr${NC}"
    echo -e "   ${GRAY}cp .env-streamarr.example .env-streamarr${NC}"
    echo -e "   ${GRAY}# Edit the .env files with your VPN and Plex settings${NC}"
    echo
    print_info "2. Deploy the stacks:"
    echo -e "   ${GRAY}# Start download & management stack:${NC}"
    echo -e "   ${GRAY}docker-compose --env-file .env-servarr -f docker-compose-servarr.yml up -d${NC}"
    echo
    echo -e "   ${GRAY}# Wait for VPN to connect, then start streaming stack:${NC}"
    echo -e "   ${GRAY}docker-compose --env-file .env-streamarr -f docker-compose-streamarr.yml up -d${NC}"
    echo
    print_info "3. Access services:"
    local server_ip=$(hostname -I | awk '{print $1}' 2>/dev/null || echo "localhost")
    echo -e "   ${GRAY}• Homarr Dashboard: http://$server_ip:7575${NC}"
    echo -e "   ${GRAY}• qBittorrent: http://$server_ip:8080${NC}"
    echo -e "   ${GRAY}• Plex: http://$server_ip:32400/web${NC}"
    echo -e "   ${GRAY}• Overseerr: http://$server_ip:5055${NC}"
    echo
    print_info "Configuration locations:"
    echo -e "   ${GRAY}• Servarr configs: $BASE_PATH/docker/servarr/${NC}"
    echo -e "   ${GRAY}• Streamarr configs: $BASE_PATH/docker/streamarr/${NC}"
    echo -e "   ${GRAY}• Media data: $BASE_PATH/data/${NC}"
    echo
    print_info "Documentation:"
    echo -e "   ${GRAY}• Quick Start Guide: docs/QUICK_START.md${NC}"
    echo -e "   ${GRAY}• Main README: README.md${NC}"
    echo -e "   ${GRAY}• Troubleshooting: docs/TROUBLESHOOTING.md${NC}"
    echo
    print_success "Setup completed successfully! 🎉"
}

cleanup_on_error() {
    print_error "Setup failed. Check the errors above."
    print_info "You can re-run this script after fixing the issues."
    exit 1
}

# Main execution
main() {
    # Set up error handling
    trap cleanup_on_error ERR
    
    print_header
    
    parse_arguments "$@"
    check_prerequisites
    confirm_configuration
    create_directories
    set_permissions
    create_docker_networks
    update_environment_files
    
    if verify_setup; then
        print_next_steps
    else
        cleanup_on_error
    fi
}

# Run main function with all arguments
main "$@"
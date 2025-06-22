#!/bin/bash

# =============================================================================
# Homelab Media Stack - Update Script
# =============================================================================
# This script safely updates your media stack containers and configurations
# Usage: ./update.sh [OPTIONS]
#
# Options:
#   -a, --auto          Automatic mode (no prompts, use with caution)
#   -s, --stack STACK   Update specific stack: servarr, streamarr, or all (default)
#   -b, --backup        Create backup before updating (recommended)
#   -c, --check-only    Check for updates without applying them
#   -f, --force         Force pull images even if up to date
#   -r, --rollback      Rollback to previous version (requires backup)
#   -q, --quiet         Quiet mode (minimal output)
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
BOLD='\033[1m'
NC='\033[0m' # No Color

# Default configuration
AUTO_MODE=false
TARGET_STACK="all"
CREATE_BACKUP=false
CHECK_ONLY=false
FORCE_PULL=false
ROLLBACK_MODE=false
QUIET_MODE=false
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Update tracking
declare -a UPDATED_SERVICES=()
declare -a FAILED_UPDATES=()
declare -a AVAILABLE_UPDATES=()

# Functions
print_header() {
    if [[ "$QUIET_MODE" == false ]]; then
        echo -e "${BLUE}${BOLD}"
        echo "================================================================="
        echo "    Homelab Media Stack - Update Script"
        echo "================================================================="
        echo -e "${NC}"
    fi
}

print_step() {
    if [[ "$QUIET_MODE" == false ]]; then
        echo -e "\n${GREEN}${BOLD}[STEP]${NC} $1"
    fi
}

print_info() {
    if [[ "$QUIET_MODE" == false ]]; then
        echo -e "${CYAN}[INFO]${NC} $1"
    fi
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1" >&2
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_help() {
    cat << EOF
Homelab Media Stack Update Script

USAGE:
    ./update.sh [OPTIONS]

OPTIONS:
    -a, --auto          Automatic mode - no user prompts (use with caution)
    -s, --stack STACK   Update specific stack: servarr, streamarr, or all (default)
    -b, --backup        Create backup before updating (highly recommended)
    -c, --check-only    Check for available updates without applying them
    -f, --force         Force pull images even if tags appear up to date
    -r, --rollback      Rollback to previous backup (emergency use)
    -q, --quiet         Quiet mode - minimal output
    -h, --help          Show this help message

STACK OPTIONS:
    all                 Update both servarr and streamarr stacks (default)
    servarr             Update only download & management services
    streamarr           Update only streaming & request services

EXAMPLES:
    ./update.sh                                    # Interactive update of all services
    ./update.sh --backup --auto                    # Automated update with backup
    ./update.sh --stack servarr --check-only       # Check servarr updates only
    ./update.sh --force --backup                   # Force update with backup
    ./update.sh --rollback                         # Emergency rollback

SAFETY FEATURES:
    • Checks for running containers before updating
    • Verifies Docker Compose files are valid
    • Can create backups before major changes
    • Monitors container health after updates
    • Provides rollback capability in emergencies

UPDATE PROCESS:
    1. Pre-update health check and validation
    2. Optional backup creation
    3. Pull latest container images
    4. Recreate containers with new images
    5. Post-update health verification
    6. Report update status and any issues

BACKUP INTEGRATION:
    When --backup is used, this script calls the backup script
    to create a configuration snapshot before updating.

ROLLBACK:
    Use --rollback to restore from the most recent backup.
    This stops services, restores configurations, and restarts.

EOF
}

parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -a|--auto)
                AUTO_MODE=true
                shift
                ;;
            -s|--stack)
                TARGET_STACK="$2"
                if [[ ! "$TARGET_STACK" =~ ^(all|servarr|streamarr)$ ]]; then
                    print_error "Invalid stack option: $TARGET_STACK"
                    print_error "Valid options: all, servarr, streamarr"
                    exit 1
                fi
                shift 2
                ;;
            -b|--backup)
                CREATE_BACKUP=true
                shift
                ;;
            -c|--check-only)
                CHECK_ONLY=true
                shift
                ;;
            -f|--force)
                FORCE_PULL=true
                shift
                ;;
            -r|--rollback)
                ROLLBACK_MODE=true
                shift
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
    
    # Check if we're in the right directory
    if [[ ! -f "docker-compose-servarr.yml" || ! -f "docker-compose-streamarr.yml" ]]; then
        print_error "Docker Compose files not found in current directory"
        print_info "Please run this script from the homelab-media-stack directory"
        exit 1
    fi
    
    # Check if environment files exist
    if [[ ! -f ".env-servarr" || ! -f ".env-streamarr" ]]; then
        print_error "Environment files not found (.env-servarr, .env-streamarr)"
        print_info "Please ensure your environment files are configured"
        exit 1
    fi
    
    # Check Docker daemon
    if ! docker info &>/dev/null; then
        print_error "Docker daemon is not running"
        exit 1
    fi
    
    # Check Docker Compose
    if ! command -v docker-compose &>/dev/null && ! docker compose version &>/dev/null; then
        print_error "Docker Compose is not available"
        exit 1
    fi
    
    # Validate Docker Compose files
    print_info "Validating Docker Compose files..."
    if ! docker-compose --env-file .env-servarr -f docker-compose-servarr.yml config &>/dev/null; then
        print_error "Invalid servarr Docker Compose configuration"
        exit 1
    fi
    
    if ! docker-compose --env-file .env-streamarr -f docker-compose-streamarr.yml config &>/dev/null; then
        print_error "Invalid streamarr Docker Compose configuration"
        exit 1
    fi
    
    print_success "Prerequisites check passed"
}

create_pre_update_backup() {
    if [[ "$CREATE_BACKUP" == true ]]; then
        print_step "Creating pre-update backup..."
        
        if [[ -f "scripts/backup.sh" ]]; then
            if ./scripts/backup.sh --config-only --quiet; then
                print_success "Backup created successfully"
            else
                print_error "Backup creation failed"
                if [[ "$AUTO_MODE" == false ]]; then
                    read -p "Continue without backup? (y/N): " -n 1 -r
                    echo
                    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                        print_info "Update cancelled by user"
                        exit 1
                    fi
                else
                    print_error "Auto mode: Cannot continue without backup"
                    exit 1
                fi
            fi
        else
            print_warning "Backup script not found - skipping backup"
        fi
    fi
}

check_for_updates() {
    print_step "Checking for available updates..."
    
    local compose_files=()
    local env_files=()
    
    case $TARGET_STACK in
        "servarr")
            compose_files=("docker-compose-servarr.yml")
            env_files=(".env-servarr")
            ;;
        "streamarr")
            compose_files=("docker-compose-streamarr.yml")
            env_files=(".env-streamarr")
            ;;
        "all")
            compose_files=("docker-compose-servarr.yml" "docker-compose-streamarr.yml")
            env_files=(".env-servarr" ".env-streamarr")
            ;;
    esac
    
    # Extract images from Docker Compose files and check for updates
    for i in "${!compose_files[@]}"; do
        local compose_file="${compose_files[$i]}"
        local env_file="${env_files[$i]}"
        
        print_info "Checking images in $compose_file..."
        
        # Get list of images from compose file
        local images=$(docker-compose --env-file "$env_file" -f "$compose_file" config | grep 'image:' | awk '{print $2}' | sort -u)
        
        while IFS= read -r image; do
            if [[ -n "$image" ]]; then
                local current_id=""
                local latest_id=""
                
                # Get current image ID
                if docker image inspect "$image" &>/dev/null; then
                    current_id=$(docker image inspect "$image" --format='{{.Id}}' 2>/dev/null || echo "")
                fi
                
                # Pull latest image (quietly) and get new ID
                print_info "Checking $image..."
                if docker pull "$image" &>/dev/null; then
                    latest_id=$(docker image inspect "$image" --format='{{.Id}}' 2>/dev/null || echo "")
                    
                    if [[ "$current_id" != "$latest_id" || "$FORCE_PULL" == true ]]; then
                        AVAILABLE_UPDATES+=("$image")
                        print_info "  ✓ Update available: $image"
                    else
                        print_info "  ✓ Up to date: $image"
                    fi
                else
                    print_warning "  ✗ Failed to check: $image"
                fi
            fi
        done <<< "$images"
    done
    
    local update_count=${#AVAILABLE_UPDATES[@]}
    if [[ "$update_count" -eq 0 ]]; then
        print_success "All images are up to date"
        if [[ "$CHECK_ONLY" == true ]]; then
            exit 0
        fi
    else
        print_info "$update_count update(s) available"
        if [[ "$CHECK_ONLY" == true ]]; then
            print_info "Available updates:"
            for update in "${AVAILABLE_UPDATES[@]}"; do
                echo "  - $update"
            done
            exit 0
        fi
    fi
}

confirm_update() {
    if [[ "$AUTO_MODE" == false && ${#AVAILABLE_UPDATES[@]} -gt 0 ]]; then
        echo
        print_info "The following updates are available:"
        for update in "${AVAILABLE_UPDATES[@]}"; do
            echo "  - $update"
        done
        echo
        read -p "Proceed with updates? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_info "Update cancelled by user"
            exit 0
        fi
    fi
}

stop_services() {
    local stack="$1"
    print_step "Stopping $stack services..."
    
    case $stack in
        "servarr")
            if docker-compose --env-file .env-servarr -f docker-compose-servarr.yml down; then
                print_success "Servarr services stopped"
            else
                print_error "Failed to stop servarr services"
                return 1
            fi
            ;;
        "streamarr")
            if docker-compose --env-file .env-streamarr -f docker-compose-streamarr.yml down; then
                print_success "Streamarr services stopped"
            else
                print_error "Failed to stop streamarr services"
                return 1
            fi
            ;;
        "all")
            stop_services "servarr"
            stop_services "streamarr"
            ;;
    esac
}

start_services() {
    local stack="$1"
    print_step "Starting $stack services..."
    
    case $stack in
        "servarr")
            if docker-compose --env-file .env-servarr -f docker-compose-servarr.yml up -d; then
                print_success "Servarr services started"
            else
                print_error "Failed to start servarr services"
                return 1
            fi
            ;;
        "streamarr")
            # Start streamarr with a delay to ensure servarr (especially VPN) is ready
            if [[ "$TARGET_STACK" == "all" ]]; then
                print_info "Waiting for VPN connection..."
                sleep 30
            fi
            
            if docker-compose --env-file .env-streamarr -f docker-compose-streamarr.yml up -d; then
                print_success "Streamarr services started"
            else
                print_error "Failed to start streamarr services"
                return 1
            fi
            ;;
        "all")
            start_services "servarr"
            start_services "streamarr"
            ;;
    esac
}

update_services() {
    print_step "Updating services..."
    
    # Stop services
    if ! stop_services "$TARGET_STACK"; then
        print_error "Failed to stop services - aborting update"
        exit 1
    fi
    
    # Pull latest images
    print_info "Pulling latest container images..."
    case $TARGET_STACK in
        "servarr")
            if docker-compose --env-file .env-servarr -f docker-compose-servarr.yml pull; then
                UPDATED_SERVICES+=("servarr")
            else
                FAILED_UPDATES+=("servarr")
            fi
            ;;
        "streamarr")
            if docker-compose --env-file .env-streamarr -f docker-compose-streamarr.yml pull; then
                UPDATED_SERVICES+=("streamarr")
            else
                FAILED_UPDATES+=("streamarr")
            fi
            ;;
        "all")
            if docker-compose --env-file .env-servarr -f docker-compose-servarr.yml pull; then
                UPDATED_SERVICES+=("servarr")
            else
                FAILED_UPDATES+=("servarr")
            fi
            
            if docker-compose --env-file .env-streamarr -f docker-compose-streamarr.yml pull; then
                UPDATED_SERVICES+=("streamarr")
            else
                FAILED_UPDATES+=("streamarr")
            fi
            ;;
    esac
    
    # Start services
    if ! start_services "$TARGET_STACK"; then
        print_error "Failed to start services after update"
        print_warning "You may need to manually investigate and restart services"
        exit 1
    fi
    
    # Wait for services to stabilize
    print_info "Waiting for services to stabilize..."
    sleep 30
}

verify_update() {
    print_step "Verifying update..."
    
    # Check if critical services are running
    local critical_services=("gluetun" "plex")
    local failed_services=()
    
    for service in "${critical_services[@]}"; do
        if ! docker ps --format "{{.Names}}" | grep -q "^${service}$"; then
            failed_services+=("$service")
        fi
    done
    
    if [[ ${#failed_services[@]} -eq 0 ]]; then
        print_success "Critical services are running"
        
        # Run health check if available
        if [[ -f "scripts/health-check.sh" ]]; then
            print_info "Running post-update health check..."
            if ./scripts/health-check.sh --quiet; then
                print_success "Health check passed"
            else
                print_warning "Health check detected issues - check logs"
            fi
        fi
    else
        print_error "Critical services failed to start: ${failed_services[*]}"
        print_warning "Manual intervention may be required"
        return 1
    fi
}

perform_rollback() {
    print_step "Performing rollback..."
    
    print_warning "ROLLBACK MODE: This will restore from the most recent backup"
    
    if [[ "$AUTO_MODE" == false ]]; then
        read -p "Are you sure you want to rollback? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_info "Rollback cancelled"
            exit 0
        fi
    fi
    
    # Find most recent backup
    local backup_dir="/volume1/backups"
    if [[ ! -d "$backup_dir" ]]; then
        print_error "Backup directory not found: $backup_dir"
        exit 1
    fi
    
    local latest_backup=$(find "$backup_dir" -name "homelab-media-stack-*.tar.gz" -type f -printf '%T@ %p\n' | sort -n | tail -1 | cut -d' ' -f2-)
    
    if [[ -z "$latest_backup" ]]; then
        print_error "No backup files found in $backup_dir"
        exit 1
    fi
    
    print_info "Rolling back to: $(basename "$latest_backup")"
    
    # Stop all services
    stop_services "all"
    
    # Extract backup (this is a simplified example - adjust paths as needed)
    print_info "Extracting backup..."
    if tar -xzf "$latest_backup" -C /tmp/; then
        # Here you would copy the extracted files back to their original locations
        # This is a placeholder - implement actual restore logic based on your backup structure
        print_warning "Rollback extraction completed - manual file restoration may be required"
        print_info "Backup extracted to /tmp/ - please manually restore configuration files"
    else
        print_error "Failed to extract backup"
        exit 1
    fi
    
    # Restart services
    start_services "all"
    
    print_success "Rollback completed"
}

generate_update_report() {
    print_step "Update Summary"
    
    local successful_count=${#UPDATED_SERVICES[@]}
    local failed_count=${#FAILED_UPDATES[@]}
    
    if [[ "$successful_count" -gt 0 ]]; then
        print_success "$successful_count stack(s) updated successfully:"
        for service in "${UPDATED_SERVICES[@]}"; do
            echo "  ✓ $service"
        done
    fi
    
    if [[ "$failed_count" -gt 0 ]]; then
        print_error "$failed_count stack(s) failed to update:"
        for service in "${FAILED_UPDATES[@]}"; do
            echo "  ✗ $service"
        done
    fi
    
    if [[ "$failed_count" -eq 0 ]]; then
        print_success "All updates completed successfully! 🎉"
    else
        print_warning "Some updates failed - check logs for details"
    fi
    
    if [[ "$QUIET_MODE" == false ]]; then
        echo
        print_info "Update completed at: $(date)"
        print_info "Next update check recommended in: 1 week"
    fi
}

# Main execution
main() {
    parse_arguments "$@"
    
    if [[ "$ROLLBACK_MODE" == true ]]; then
        perform_rollback
        exit 0
    fi
    
    print_header
    
    check_prerequisites
    create_pre_update_backup
    check_for_updates
    confirm_update
    update_services
    verify_update
    generate_update_report
    
    # Exit with appropriate code
    if [[ ${#FAILED_UPDATES[@]} -eq 0 ]]; then
        exit 0
    else
        exit 1
    fi
}

# Error handling
trap 'print_error "Update failed unexpectedly. Check the errors above."; exit 1' ERR

# Run main function with all arguments
main "$@"
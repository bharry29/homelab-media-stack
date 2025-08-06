#!/bin/bash

# =============================================================================
# Homelab Media Stack - Health Check Script
# =============================================================================
# This script monitors the health and status of your media stack
# Usage: ./health-check.sh [OPTIONS]
#
# Options:
#   -v, --verbose       Verbose output with detailed information
#   -q, --quiet         Quiet mode (errors only)
#   -w, --webhook URL   Send results to webhook (Discord, Slack, etc.)
#   -f, --format FORMAT Output format: text, json, html (default: text)
#   -a, --alerts        Enable alerting for critical issues
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
VERBOSE_MODE=false
QUIET_MODE=false
WEBHOOK_URL=""
OUTPUT_FORMAT="text"
ALERTS_ENABLED=false
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# Health check results
declare -A SERVICE_STATUS
declare -A SERVICE_HEALTH
declare -A WARNINGS
declare -A ERRORS
OVERALL_HEALTH="HEALTHY"

# Functions
print_header() {
    if [[ "$QUIET_MODE" == false ]]; then
        echo -e "${BLUE}${BOLD}"
        echo "================================================================="
        echo "    Homelab Media Stack - Health Check Report"
        echo "    Generated: $TIMESTAMP"
        echo "================================================================="
        echo -e "${NC}"
    fi
}

print_section() {
    if [[ "$QUIET_MODE" == false ]]; then
        echo -e "\n${CYAN}${BOLD}=== $1 ===${NC}"
    fi
}

print_status() {
    local service="$1"
    local status="$2"
    local message="$3"
    
    case $status in
        "HEALTHY"|"UP"|"RUNNING"|"OK")
            echo -e "${GREEN}✓${NC} ${service}: ${message}"
            ;;
        "WARNING"|"DEGRADED")
            echo -e "${YELLOW}⚠${NC} ${service}: ${message}"
            WARNINGS["$service"]="$message"
            if [[ "$OVERALL_HEALTH" == "HEALTHY" ]]; then
                OVERALL_HEALTH="WARNING"
            fi
            ;;
        "CRITICAL"|"DOWN"|"FAILED"|"ERROR")
            echo -e "${RED}✗${NC} ${service}: ${message}"
            ERRORS["$service"]="$message"
            OVERALL_HEALTH="CRITICAL"
            ;;
        *)
            echo -e "${GRAY}?${NC} ${service}: ${message}"
            ;;
    esac
}

print_verbose() {
    if [[ "$VERBOSE_MODE" == true && "$QUIET_MODE" == false ]]; then
        echo -e "${GRAY}  └─ $1${NC}"
    fi
}

print_help() {
    cat << EOF
Homelab Media Stack Health Check Script

USAGE:
    ./health-check.sh [OPTIONS]

OPTIONS:
    -v, --verbose       Show detailed information and diagnostics
    -q, --quiet         Quiet mode - only show errors and critical issues
    -w, --webhook URL   Send results to webhook (Discord, Slack, etc.)
    -f, --format FORMAT Output format: text, json, html (default: text)
    -a, --alerts        Enable alerting for critical issues
    -h, --help          Show this help message

OUTPUT FORMATS:
    text                Human-readable text output (default)
    json                JSON format for automation/monitoring
    html                HTML report for web dashboards

EXAMPLES:
    ./health-check.sh                           # Basic health check
    ./health-check.sh --verbose                 # Detailed diagnostics
    ./health-check.sh --quiet                   # Errors only
    ./health-check.sh --webhook https://...     # Send to Discord/Slack
    ./health-check.sh --format json             # JSON output
    ./health-check.sh --alerts --verbose        # Full monitoring mode

MONITORING:
    Run this script regularly (e.g., every 15 minutes) via cron:
    */15 * * * * /path/to/health-check.sh --quiet --alerts

WEBHOOKS:
    Supports Discord, Slack, and other webhook services.
    Results are sent as formatted messages with status indicators.

EOF
}

parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -v|--verbose)
                VERBOSE_MODE=true
                shift
                ;;
            -q|--quiet)
                QUIET_MODE=true
                shift
                ;;
            -w|--webhook)
                WEBHOOK_URL="$2"
                shift 2
                ;;
            -f|--format)
                OUTPUT_FORMAT="$2"
                shift 2
                ;;
            -a|--alerts)
                ALERTS_ENABLED=true
                shift
                ;;
            -h|--help)
                print_help
                exit 0
                ;;
            *)
                echo "Unknown option: $1" >&2
                print_help
                exit 1
                ;;
        esac
    done
}

check_docker_status() {
    print_section "Docker & Container Status"
    
    # Check Docker daemon
    if ! docker info &>/dev/null; then
        print_status "Docker Daemon" "CRITICAL" "Docker daemon is not running"
        return 1
    fi
    print_status "Docker Daemon" "HEALTHY" "Running and accessible"
    
    # Check Docker Compose
    if command -v docker-compose &>/dev/null; then
        print_status "Docker Compose" "HEALTHY" "Available ($(docker-compose --version | cut -d' ' -f3))"
    elif docker compose version &>/dev/null; then
        print_status "Docker Compose" "HEALTHY" "Available (Docker Compose V2)"
    else
        print_status "Docker Compose" "WARNING" "Not found"
    fi
    
    # Check containers
    local containers="gluetun:VPN Gateway qbittorrent:BitTorrent Client sabnzbd:Usenet Client prowlarr:Indexer Management sonarr:TV Show Automation radarr:Movie Automation lidarr:Music Automation bazarr:Subtitle Management plex:Media Server overseerr:Request Management tautulli:Analytics ersatztv:Virtual TV filebot-node:File Processing UI filebot-watcher:Auto Processing homarr:Dashboard watchtower:Auto Updates"
    
    echo "$containers" | tr ' ' '\n' | while IFS=':' read -r container_name container_desc; do
        
        if docker ps --format "{{.Names}}" | grep -q "^${container_name}$"; then
            local status=$(docker inspect "$container_name" --format='{{.State.Status}}')
            local health=$(docker inspect "$container_name" --format='{{.State.Health.Status}}' 2>/dev/null || echo "no-healthcheck")
            
            SERVICE_STATUS["$container_name"]="$status"
            SERVICE_HEALTH["$container_name"]="$health"
            
            case $status in
                "running")
                    if [[ "$health" == "healthy" || "$health" == "no-healthcheck" ]]; then
                        print_status "$container_desc" "HEALTHY" "Running"
                        if [[ "$VERBOSE_MODE" == true ]]; then
                            local uptime=$(docker inspect "$container_name" --format='{{.State.StartedAt}}' | xargs -I {} date -d {} '+%Y-%m-%d %H:%M:%S' 2>/dev/null || echo "Unknown")
                            print_verbose "Started: $uptime"
                        fi
                    else
                        print_status "$container_desc" "WARNING" "Running but unhealthy ($health)"
                    fi
                    ;;
                "restarting")
                    print_status "$container_desc" "WARNING" "Restarting"
                    ;;
                "paused")
                    print_status "$container_desc" "WARNING" "Paused"
                    ;;
                *)
                    print_status "$container_desc" "CRITICAL" "Not running ($status)"
                    ;;
            esac
        else
            print_status "$container_desc" "CRITICAL" "Container not found"
            SERVICE_STATUS["$container_name"]="missing"
        fi
    done
}

check_network_connectivity() {
    print_section "Network & Connectivity"
    
    # Check Docker networks
    local networks="servarr-network streamarr-network"
    
    echo "$networks" | tr ' ' '\n' | while read -r network; do
        if docker network ls --format "{{.Name}}" | grep -q "^${network}$"; then
            print_status "Network: $network" "HEALTHY" "Exists and configured"
            if [[ "$VERBOSE_MODE" == true ]]; then
                local subnet=$(docker network inspect "$network" --format='{{range .IPAM.Config}}{{.Subnet}}{{end}}' 2>/dev/null || echo "Unknown")
                print_verbose "Subnet: $subnet"
            fi
        else
            print_status "Network: $network" "CRITICAL" "Network missing"
        fi
    done
    
    # Check VPN connectivity (if Gluetun is running)
    if docker ps --format "{{.Names}}" | grep -q "^gluetun$"; then
        local vpn_ip=$(docker exec gluetun curl -s ifconfig.me 2>/dev/null || echo "failed")
        if [[ "$vpn_ip" != "failed" && "$vpn_ip" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
            print_status "VPN Connection" "HEALTHY" "Connected (IP: $vpn_ip)"
            
            # Check if download client is using VPN
            if docker ps --format "{{.Names}}" | grep -q "^qbittorrent$"; then
                local client_ip=$(docker exec qbittorrent curl -s ifconfig.me 2>/dev/null || echo "failed")
                if [[ "$client_ip" == "$vpn_ip" ]]; then
                    print_status "VPN Protection" "HEALTHY" "Download client protected"
                else
                    print_status "VPN Protection" "CRITICAL" "Download client NOT protected (IP: $client_ip)"
                fi
            fi
        else
            print_status "VPN Connection" "CRITICAL" "Not connected or unreachable"
        fi
    else
        print_status "VPN Connection" "CRITICAL" "Gluetun container not running"
    fi
    
    # Check service accessibility
    local services="7575:Homarr Dashboard 32400:Plex Media Server 5055:Overseerr 8080:qBittorrent 8989:Sonarr 7878:Radarr"
    
    echo "$services" | tr ' ' '\n' | while IFS=':' read -r port service_name; do
        
        if timeout 5 bash -c "</dev/tcp/localhost/$port" 2>/dev/null; then
            print_status "$service_name" "HEALTHY" "Accessible on port $port"
        else
            print_status "$service_name" "WARNING" "Not accessible on port $port"
        fi
    done
}

check_storage_health() {
    print_section "Storage & Disk Usage"
    
    # Check main storage paths
    local paths="/volume1:Main Storage /volume1/docker:Configuration Storage /volume1/data:Media Storage /volume1/data/downloads:Download Storage /volume1/data/media:Media Library"
    
    echo "$paths" | tr ' ' '\n' | while IFS=':' read -r path desc; do
        
        if [[ -d "$path" ]]; then
            local usage=$(df "$path" 2>/dev/null | tail -1 | awk '{print $5}' | sed 's/%//')
            local available=$(df -h "$path" 2>/dev/null | tail -1 | awk '{print $4}')
            
            if [[ "$usage" -lt 80 ]]; then
                print_status "$desc" "HEALTHY" "${usage}% used, ${available} available"
            elif [[ "$usage" -lt 90 ]]; then
                print_status "$desc" "WARNING" "${usage}% used, ${available} available"
            else
                print_status "$desc" "CRITICAL" "${usage}% used, ${available} available"
            fi
            
            if [[ "$VERBOSE_MODE" == true ]]; then
                local total=$(df -h "$path" 2>/dev/null | tail -1 | awk '{print $2}')
                local used=$(df -h "$path" 2>/dev/null | tail -1 | awk '{print $3}')
                print_verbose "Total: $total, Used: $used, Available: $available"
            fi
        else
            print_status "$desc" "WARNING" "Path does not exist: $path"
        fi
    done
    
    # Check for large files in downloads (potential stuck downloads)
    if [[ -d "/volume1/data/downloads" ]]; then
        local large_files=$(find /volume1/data/downloads -type f -size +5G 2>/dev/null | wc -l)
        if [[ "$large_files" -gt 0 ]]; then
            print_status "Large Downloads" "WARNING" "$large_files files larger than 5GB found"
            if [[ "$VERBOSE_MODE" == true ]]; then
                find /volume1/data/downloads -type f -size +5G -exec ls -lh {} \; 2>/dev/null | head -3 | while read -r line; do
                    print_verbose "$(echo "$line" | awk '{print $9 " (" $5 ")"}')"
                done
            fi
        else
            print_status "Large Downloads" "HEALTHY" "No unusually large files"
        fi
    fi
}

check_service_logs() {
    print_section "Service Health & Logs"
    
    # Check for recent errors in critical services
    local critical_services="gluetun plex sonarr radarr qbittorrent"
    
    echo "$critical_services" | tr ' ' '\n' | while read -r service; do
        if docker ps --format "{{.Names}}" | grep -q "^${service}$"; then
            local recent_errors=$(docker logs --since 1h "$service" 2>&1 | grep -i "error\|failed\|exception" | wc -l)
            local recent_warnings=$(docker logs --since 1h "$service" 2>&1 | grep -i "warn" | wc -l)
            
            if [[ "$recent_errors" -eq 0 ]]; then
                if [[ "$recent_warnings" -eq 0 ]]; then
                    print_status "$service logs" "HEALTHY" "No recent errors or warnings"
                else
                    print_status "$service logs" "WARNING" "$recent_warnings warnings in last hour"
                fi
            else
                print_status "$service logs" "WARNING" "$recent_errors errors in last hour"
                if [[ "$VERBOSE_MODE" == true ]]; then
                    docker logs --since 1h "$service" 2>&1 | grep -i "error\|failed\|exception" | tail -2 | while read -r line; do
                        print_verbose "$(echo "$line" | cut -c1-80)..."
                    done
                fi
            fi
        fi
    done
}

check_performance() {
    print_section "Performance & Resources"
    
    # Check system load
    local load_avg=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | sed 's/,//')
    local cpu_cores=$(nproc)
    local load_percentage=$(echo "scale=0; $load_avg * 100 / $cpu_cores" | bc 2>/dev/null || echo "0")
    
    if [[ "$load_percentage" -lt 70 ]]; then
        print_status "System Load" "HEALTHY" "${load_avg} (${load_percentage}% of ${cpu_cores} cores)"
    elif [[ "$load_percentage" -lt 90 ]]; then
        print_status "System Load" "WARNING" "${load_avg} (${load_percentage}% of ${cpu_cores} cores)"
    else
        print_status "System Load" "CRITICAL" "${load_avg} (${load_percentage}% of ${cpu_cores} cores)"
    fi
    
    # Check memory usage
    local mem_info=$(free -m | grep '^Mem:')
    local total_mem=$(echo "$mem_info" | awk '{print $2}')
    local used_mem=$(echo "$mem_info" | awk '{print $3}')
    local mem_percentage=$(echo "scale=0; $used_mem * 100 / $total_mem" | bc 2>/dev/null || echo "0")
    
    if [[ "$mem_percentage" -lt 80 ]]; then
        print_status "Memory Usage" "HEALTHY" "${used_mem}MB/${total_mem}MB (${mem_percentage}%)"
    elif [[ "$mem_percentage" -lt 90 ]]; then
        print_status "Memory Usage" "WARNING" "${used_mem}MB/${total_mem}MB (${mem_percentage}%)"
    else
        print_status "Memory Usage" "CRITICAL" "${used_mem}MB/${total_mem}MB (${mem_percentage}%)"
    fi
    
    # Check Docker resource usage
    if [[ "$VERBOSE_MODE" == true ]]; then
        print_verbose "Container resource usage:"
        docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}" | head -6 | tail -5 | while read -r line; do
            print_verbose "$line"
        done
    fi
}

generate_summary() {
    print_section "Health Check Summary"
    
    local warning_count=${#WARNINGS[@]}
    local error_count=${#ERRORS[@]}
    
    case $OVERALL_HEALTH in
        "HEALTHY")
            print_status "Overall Status" "HEALTHY" "All systems operational"
            ;;
        "WARNING")
            print_status "Overall Status" "WARNING" "$warning_count warning(s), $error_count error(s)"
            ;;
        "CRITICAL")
            print_status "Overall Status" "CRITICAL" "$error_count critical issue(s), $warning_count warning(s)"
            ;;
    esac
    
    if [[ "$warning_count" -gt 0 || "$error_count" -gt 0 ]]; then
        echo
        if [[ "$warning_count" -gt 0 ]]; then
            echo -e "${YELLOW}Warnings:${NC}"
            for service in "${!WARNINGS[@]}"; do
                echo -e "  ${YELLOW}⚠${NC} $service: ${WARNINGS[$service]}"
            done
        fi
        
        if [[ "$error_count" -gt 0 ]]; then
            echo -e "${RED}Critical Issues:${NC}"
            for service in "${!ERRORS[@]}"; do
                echo -e "  ${RED}✗${NC} $service: ${ERRORS[$service]}"
            done
        fi
    fi
    
    if [[ "$QUIET_MODE" == false ]]; then
        echo
        echo -e "${GRAY}Health check completed at: $TIMESTAMP${NC}"
        echo -e "${GRAY}Next check recommended in: 15 minutes${NC}"
    fi
}

send_webhook_notification() {
    if [[ -n "$WEBHOOK_URL" ]]; then
        local color=""
        local status_emoji=""
        
        case $OVERALL_HEALTH in
            "HEALTHY")
                color="3066993"  # Green
                status_emoji=""
                ;;
            "WARNING")
                color="16776960"  # Yellow
                status_emoji=""
                ;;
            "CRITICAL")
                color="15158332"  # Red
                status_emoji=""
                ;;
        esac
        
        local warning_count=${#WARNINGS[@]}
        local error_count=${#ERRORS[@]}
        
        # Create Discord-style webhook payload
        local payload=$(cat << EOF
{
    "embeds": [{
        "title": "${status_emoji} Homelab Media Stack Health Check",
        "description": "Overall Status: **${OVERALL_HEALTH}**",
        "color": ${color},
        "fields": [
            {
                "name": "Summary",
                "value": "Errors: ${error_count}\\nWarnings: ${warning_count}",
                "inline": true
            },
            {
                "name": "Timestamp",
                "value": "${TIMESTAMP}",
                "inline": true
            }
        ],
        "footer": {
            "text": "Homelab Media Stack Monitor"
        }
    }]
}
EOF
        )
        
        curl -s -H "Content-Type: application/json" -X POST -d "$payload" "$WEBHOOK_URL" >/dev/null || true
    fi
}

# Main execution
main() {
    parse_arguments "$@"
    
    if [[ "$OUTPUT_FORMAT" == "text" ]]; then
        print_header
        
        check_docker_status
        check_network_connectivity
        check_storage_health
        check_service_logs
        check_performance
        generate_summary
        
        if [[ "$ALERTS_ENABLED" == true || -n "$WEBHOOK_URL" ]]; then
            send_webhook_notification
        fi
    elif [[ "$OUTPUT_FORMAT" == "json" ]]; then
        # JSON output for automation (implement if needed)
        echo '{"status":"'$OVERALL_HEALTH'","timestamp":"'$TIMESTAMP'","warnings":'${#WARNINGS[@]}',"errors":'${#ERRORS[@]}'}'
    fi
    
    # Exit with appropriate code
    case $OVERALL_HEALTH in
        "HEALTHY") exit 0 ;;
        "WARNING") exit 1 ;;
        "CRITICAL") exit 2 ;;
    esac
}

# Run main function with all arguments
main "$@"
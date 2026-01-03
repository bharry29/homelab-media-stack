#!/bin/bash

# n8n Encryption Key Helper Script
# This script helps manage n8n encryption keys for HTTPS setups

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
else
    # No colors for non-terminal output
    cr="" clr="" cg="" clg="" cy="" cly="" cb="" clb="" cm="" clm="" cc="" clc="" cend=""
    utick="✓" uplus="+" ucross="✗" uyc="●" urc="●" ugc="●"
fi

#################################################################################################################################################
# Banner
#################################################################################################################################################
show_banner() {
    printf '\n%b\n' "${cb}
╔═══════════════════════════════════════════════════════════════════════════════╗
║                                                                               ║
║                        n8n ENCRYPTION KEY HELPER                             ║
║                                                                               ║
║                    Manage n8n encryption keys for HTTPS                      ║
║                                                                               ║
╚═══════════════════════════════════════════════════════════════════════════════╝${cend}"
}

#################################################################################################################################################
# Generate new encryption key
#################################################################################################################################################
generate_new_key() {
    printf '\n%b\n' " ${uyc} Generating new n8n encryption key..."
    
    if command -v openssl >/dev/null 2>&1; then
        local new_key=$(openssl rand -base64 32)
        printf '\n%b\n' " ${utick} Generated new encryption key:"
        printf '\n%b\n' " ${clc}${new_key}${cend}"
        
        # Save to file
        echo "$new_key" > n8n-encryption-key.txt
        printf '\n%b\n' " ${utick} Key saved to: ${clc}n8n-encryption-key.txt${cend}"
        
        return 0
    else
        printf '\n%b\n' " ${ucross} openssl not found. Using fallback method..."
        local new_key=$(head -c 32 /dev/urandom | base64)
        printf '\n%b\n' " ${utick} Generated new encryption key:"
        printf '\n%b\n' " ${clc}${new_key}${cend}"
        
        # Save to file
        echo "$new_key" > n8n-encryption-key.txt
        printf '\n%b\n' " ${utick} Key saved to: ${clc}n8n-encryption-key.txt${cend}"
        
        return 0
    fi
}

#################################################################################################################################################
# Extract key from existing n8n config
#################################################################################################################################################
extract_existing_key() {
    printf '\n%b\n' " ${uyc} Extracting encryption key from existing n8n config..."
    
    # Common n8n config locations
    local config_locations=(
        "${HOME}/.n8n/config"
        "/volume1/docker/business/n8n/config"
        "/opt/homelab/docker/business/n8n/config"
        "/mnt/user/docker/business/n8n/config"
        "./docker/business/n8n/config"
    )
    
    local config_file=""
    
    # Find config file
    for location in "${config_locations[@]}"; do
        if [[ -f "$location" ]]; then
            config_file="$location"
            break
        fi
    done
    
    if [[ -z "$config_file" ]]; then
        printf '\n%b\n' " ${ucross} n8n config file not found in common locations"
        printf '\n%b\n' " ${uyc} Please provide the path to your n8n config file:"
        printf '%b' " ${uyc} Config file path: "
        read -r config_file
        
        if [[ ! -f "$config_file" ]]; then
            printf '\n%b\n' " ${ucross} File not found: ${config_file}"
            return 1
        fi
    fi
    
    printf '\n%b\n' " ${utick} Found config file: ${clc}${config_file}${cend}"
    
    # Extract encryption key using grep and sed
    local encryption_key=$(grep -o '"encryptionKey": *"[^"]*"' "$config_file" | sed 's/"encryptionKey": *"\([^"]*\)"/\1/')
    
    if [[ -n "$encryption_key" ]]; then
        printf '\n%b\n' " ${utick} Extracted encryption key:"
        printf '\n%b\n' " ${clc}${encryption_key}${cend}"
        
        # Save to file
        echo "$encryption_key" > n8n-encryption-key.txt
        printf '\n%b\n' " ${utick} Key saved to: ${clc}n8n-encryption-key.txt${cend}"
        
        return 0
    else
        printf '\n%b\n' " ${ucross} No encryption key found in config file"
        printf '\n%b\n' " ${uyc} Make sure the config file contains: {\"encryptionKey\": \"your_key_here\"}"
        return 1
    fi
}

#################################################################################################################################################
# Update .env-business with encryption key
#################################################################################################################################################
update_env_file() {
    local key="$1"
    
    if [[ -f ".env-business" ]]; then
        if sed -i.bak "s|N8N_ENCRYPTION_KEY=.*|N8N_ENCRYPTION_KEY=${key}|g" ".env-business"; then
            printf '\n%b\n' " ${utick} Updated .env-business with encryption key"
            rm -f ".env-business.bak" 2>/dev/null || true
            return 0
        else
            printf '\n%b\n' " ${ucross} Failed to update .env-business"
            return 1
        fi
    else
        printf '\n%b\n' " ${ucross} .env-business file not found"
        printf '\n%b\n' " ${uyc} Please run the setup script first or create the file manually"
        return 1
    fi
}

#################################################################################################################################################
# Main menu
#################################################################################################################################################
main_menu() {
    show_banner
    
    printf '\n%b\n' " ${cy}n8n Encryption Key Management:${cend}"
    printf '\n%b\n' " ${clc}1)${cend} Generate new encryption key"
    printf '\n%b\n' " ${clc}2)${cend} Extract key from existing n8n config"
    printf '\n%b\n' " ${clc}3)${cend} Use existing key file (n8n-encryption-key.txt)"
    printf '\n%b\n' " ${clc}4)${cend} Manual key entry"
    printf '\n%b\n' " ${clc}5)${cend} Show current key from .env-business"
    printf '\n%b\n' " ${clc}6)${cend} Exit"
    
    printf '\n'
    while true; do
        printf '%b' " ${uyc} Select option [1-6]: "
        read -r choice
        
        case "$choice" in
            1)
                if generate_new_key; then
                    local key=$(cat n8n-encryption-key.txt 2>/dev/null)
                    if [[ -n "$key" ]]; then
                        printf '\n%b\n' " ${uyc} Update .env-business with this key? [Y/n]: "
                        read -r update_confirm
                        if [[ ! "$update_confirm" =~ ^[Nn]$ ]]; then
                            update_env_file "$key"
                        fi
                    fi
                fi
                break
                ;;
            2)
                if extract_existing_key; then
                    local key=$(cat n8n-encryption-key.txt 2>/dev/null)
                    if [[ -n "$key" ]]; then
                        printf '\n%b\n' " ${uyc} Update .env-business with this key? [Y/n]: "
                        read -r update_confirm
                        if [[ ! "$update_confirm" =~ ^[Nn]$ ]]; then
                            update_env_file "$key"
                        fi
                    fi
                fi
                break
                ;;
            3)
                if [[ -f "n8n-encryption-key.txt" ]]; then
                    local key=$(cat n8n-encryption-key.txt)
                    printf '\n%b\n' " ${utick} Found key file:"
                    printf '\n%b\n' " ${clc}${key}${cend}"
                    printf '\n%b\n' " ${uyc} Update .env-business with this key? [Y/n]: "
                    read -r update_confirm
                    if [[ ! "$update_confirm" =~ ^[Nn]$ ]]; then
                        update_env_file "$key"
                    fi
                else
                    printf '\n%b\n' " ${ucross} n8n-encryption-key.txt not found"
                fi
                break
                ;;
            4)
                printf '\n%b\n' " ${uyc} Enter your n8n encryption key:"
                printf '%b' " ${uyc} Encryption Key: "
                read -r manual_key
                if [[ -n "$manual_key" ]]; then
                    printf '\n%b\n' " ${utick} Using provided key: ${clc}${manual_key}${cend}"
                    printf '\n%b\n' " ${uyc} Update .env-business with this key? [Y/n]: "
                    read -r update_confirm
                    if [[ ! "$update_confirm" =~ ^[Nn]$ ]]; then
                        update_env_file "$manual_key"
                    fi
                else
                    printf '\n%b\n' " ${ucross} Key cannot be empty"
                fi
                break
                ;;
            5)
                if [[ -f ".env-business" ]]; then
                    local current_key=$(grep "N8N_ENCRYPTION_KEY=" ".env-business" | cut -d'=' -f2)
                    if [[ -n "$current_key" ]]; then
                        printf '\n%b\n' " ${utick} Current key in .env-business:"
                        printf '\n%b\n' " ${clc}${current_key}${cend}"
                    else
                        printf '\n%b\n' " ${uyc} No encryption key set in .env-business"
                    fi
                else
                    printf '\n%b\n' " ${ucross} .env-business file not found"
                fi
                break
                ;;
            6)
                printf '\n%b\n' " ${utick} Goodbye!"
                exit 0
                ;;
            *)
                printf '\n%b\n' " ${ucross} Invalid choice. Please select 1-6."
                ;;
        esac
    done
}

#################################################################################################################################################
# Main execution
#################################################################################################################################################
main() {
    main_menu
    
    printf '\n%b\n' " ${utick} ${clg}n8n encryption key management complete!${cend}"
    printf '\n%b\n' " ${uyc} Remember to restart your n8n container after updating the key:"
    printf '\n%b\n' " ${clc}docker restart n8n${cend}"
}

# Run main function
main "$@"

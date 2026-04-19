#!/bin/bash
#
# update-lists.sh - Update IP lists from remote sources
#
# NOTE: list-general.txt is NOT updated remotely - it's maintained locally
#       Only ipset-all.txt is fetched from GitHub
#

set -e

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
LISTS_DIR="$SCRIPT_DIR/lists"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# URL for ipset (this one exists in the repo)
IPSET_URL="https://raw.githubusercontent.com/Flowseal/zapret-discord-youtube/refs/heads/main/.service/ipset-service.txt"

# Get original owner of lists directory for permission fix
get_dir_owner() {
    stat -c '%U:%G' "$LISTS_DIR" 2>/dev/null || echo "root:root"
}

download() {
    local url="$1"
    local output="$2"
    
    if command -v curl &>/dev/null; then
        curl -sL --connect-timeout 10 -o "$output" "$url" 2>/dev/null
        return $?
    elif command -v wget &>/dev/null; then
        wget -q --timeout=10 -O "$output" "$url" 2>/dev/null
        return $?
    else
        echo -e "${RED}Error: curl or wget required${NC}"
        return 1
    fi
}

fix_permissions() {
    local file="$1"
    local owner=$(get_dir_owner)
    
    # Set readable for all, writable for owner
    chmod 644 "$file" 2>/dev/null || true
    
    # Try to restore original owner (works if run as root)
    if [[ $EUID -eq 0 ]] && [[ "$owner" != "root:root" ]]; then
        chown "$owner" "$file" 2>/dev/null || true
    fi
}

update_ipset() {
    echo -e "${YELLOW}Updating ipset-all.txt...${NC}"
    
    local list_file="$LISTS_DIR/ipset-all.txt"
    local backup_file="$LISTS_DIR/ipset-all.txt.backup"
    local tmp_file=$(mktemp)
    
    if download "$IPSET_URL" "$tmp_file"; then
        # Check if we got an HTML error page (first line would be HTML)
        local first_line=$(head -1 "$tmp_file" 2>/dev/null)
        if echo "$first_line" | grep -qiE "^<!DOCTYPE|^<html|^404|^Not Found"; then
            echo -e "${RED}Error: Server returned error page${NC}"
            rm -f "$tmp_file"
            return 1
        fi
        
        if [[ -s "$tmp_file" ]]; then
            # Backup current file if it's a real list (not placeholder)
            if [[ -f "$list_file" ]]; then
                local current_lines=$(wc -l < "$list_file" 2>/dev/null || echo 0)
                if [[ "$current_lines" -gt 10 ]]; then
                    cp -f "$list_file" "$backup_file"
                    fix_permissions "$backup_file"
                    echo "Backed up previous list ($current_lines entries)"
                fi
            fi
            
            mv "$tmp_file" "$list_file"
            fix_permissions "$list_file"
            
            local lines=$(wc -l < "$list_file")
            echo -e "${GREEN}Updated ipset-all.txt ($lines entries)${NC}"
            return 0
        else
            echo -e "${RED}Downloaded file is empty${NC}"
            rm -f "$tmp_file"
            return 1
        fi
    else
        echo -e "${RED}Failed to download ipset${NC}"
        rm -f "$tmp_file"
        return 1
    fi
}

show_status() {
    echo ""
    echo "Current list status:"
    for list in ipset-all.txt list-general.txt list-google.txt list-exclude.txt; do
        if [[ -f "$LISTS_DIR/$list" ]]; then
            local lines=$(wc -l < "$LISTS_DIR/$list" 2>/dev/null || echo 0)
            local owner=$(stat -c '%U' "$LISTS_DIR/$list" 2>/dev/null || echo "?")
            echo -e "  $list: ${GREEN}$lines lines${NC} (owner: $owner)"
        else
            echo -e "  $list: ${RED}missing${NC}"
        fi
    done
}

restore_list_general() {
    local list_file="$LISTS_DIR/list-general.txt"
    local backup_file="$LISTS_DIR/list-general.txt.backup"
    
    # Check if list-general.txt is corrupted (contains 404)
    if [[ -f "$list_file" ]] && grep -qi "404\|not found" "$list_file" 2>/dev/null; then
        echo -e "${YELLOW}Detected corrupted list-general.txt, restoring from backup...${NC}"
        if [[ -f "$backup_file" ]]; then
            cp -f "$backup_file" "$list_file"
            fix_permissions "$list_file"
            echo -e "${GREEN}Restored list-general.txt from backup${NC}"
        else
            echo -e "${RED}No backup available. You may need to restore list-general.txt manually.${NC}"
        fi
    fi
}

# Main
echo "=== Zapret List Updater ==="
echo ""

case "${1:-all}" in
    ipset)
        update_ipset
        ;;
    fix)
        restore_list_general
        ;;
    all|*)
        update_ipset
        restore_list_general
        ;;
esac

show_status

echo ""
echo -e "${GREEN}List update complete!${NC}"
echo ""
echo "If Zapret is running, restart it to apply changes:"
echo "  sudo ./zapret.sh restart"

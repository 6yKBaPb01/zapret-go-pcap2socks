#!/bin/bash
#
# service.sh - Zapret Service Manager for Linux
#
# Interactive menu-based service management similar to Windows service.bat
#

# set -e disabled: interactive menu handles errors per-function

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
CONFIG_FILE="$SCRIPT_DIR/config"

# Cleanup temporary files on exit/interrupt
TMP_FILES=()
cleanup() {
    for f in "${TMP_FILES[@]}"; do
        rm -f "$f" 2>/dev/null
    done
}
trap cleanup EXIT INT TERM

make_tmp() {
    local f=$(mktemp)
    TMP_FILES+=("$f")
    echo "$f"
}

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Load config
[[ -f "$CONFIG_FILE" ]] && source "$CONFIG_FILE"

ZAPRET_BASE="${ZAPRET_BASE:-$SCRIPT_DIR}"
LISTS_DIR="$ZAPRET_BASE/lists"
UTILS_DIR="$ZAPRET_BASE/utils"

# Version
LOCAL_VERSION="1.9.7-linux"

# GitHub URLs (6yKBaPb01/zapret-go-pcap2socks)
GITHUB_REPO="https://github.com/6yKBaPb01/zapret-go-pcap2socks"
GITHUB_RAW="https://raw.githubusercontent.com/6yKBaPb01/zapret-go-pcap2socks/tree/main/"
GITHUB_VERSION_URL="https://github.com/6yKBaPb01/zapret-go-pcap2socks/blob/main/.service/version.txt"
IPSET_URL="https://raw.githubusercontent.com/6yKBaPb01/zapret-go-pcap2socks/blob/main/ipset-service.txt"
HOSTS_URL="https://raw.githubusercontent.com/6yKBaPb01/zapret-go-pcap2socks/blob/main/.service/hosts"

# Markers for /etc/hosts block
HOSTS_MARKER_BEGIN="# BEGIN zapret"
HOSTS_MARKER_END="# END zapret"

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================

check_user_lists() {
    if [[ ! -f "$LISTS_DIR/ipset-exclude-user.txt" ]]; then
        echo "203.0.113.113/32" > "$LISTS_DIR/ipset-exclude-user.txt"
    fi
    if [[ ! -f "$LISTS_DIR/list-general-user.txt" ]]; then
        echo "domain.example.abc" > "$LISTS_DIR/list-general-user.txt"
    fi
    if [[ ! -f "$LISTS_DIR/list-exclude-user.txt" ]]; then
        echo "domain.example.abc" > "$LISTS_DIR/list-exclude-user.txt"
    fi
}

check_user_lists

print_header() {
    clear
    echo -e "${CYAN}"
    local title="ZAPRET SERVICE MANAGER v${LOCAL_VERSION}"
    local box_w=51
    local pad_total=$((box_w - ${#title}))
    local pad_left=$((pad_total / 2))
    local pad_right=$((pad_total - pad_left))
    echo "  ╔$(printf '═%.0s' $(seq 1 $box_w))╗"
    printf "  ║%*s%s%*s║\n" $pad_left "" "$title" $pad_right ""
    echo "  ╚$(printf '═%.0s' $(seq 1 $box_w))╝"
    echo -e "${NC}"
}

print_status() {
    # Get all statuses
    get_game_filter_status
    get_ipset_status
    get_auto_update_status
    
    if [[ -f "/run/zapret.pid" ]]; then
        local pid
        pid=$(cat /run/zapret.pid 2>/dev/null)
        if [[ -n "$pid" ]] && [[ -d "/proc/$pid" ]]; then
            echo -e "  Zapret Status: ${GREEN}RUNNING${NC} (PID: $pid)"
        else
            echo -e "  Zapret Status: ${RED}STOPPED${NC}"
        fi
    else
        echo -e "  Zapret Status: ${RED}STOPPED${NC}"
    fi
    
    echo -e "  Current Strategy: ${YELLOW}${STRATEGY:-not set}${NC}"
    echo ""
}

check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}Error: This action requires root privileges${NC}"
        echo "Please run: sudo $0"
        return 1
    fi
    return 0
}

press_enter() {
    echo ""
    read -p "Press Enter to continue..."
}

download() {
    local url="$1"
    local output="$2"
    
    if command -v curl &>/dev/null; then
        curl -sL --connect-timeout 10 -o "$output" "$url" 2>/dev/null
    elif command -v wget &>/dev/null; then
        wget -q --timeout=10 -O "$output" "$url" 2>/dev/null
    else
        echo -e "${RED}Error: curl or wget required${NC}"
        return 1
    fi
}

# ============================================================================
# STATUS FUNCTIONS
# ============================================================================

get_game_filter_status() {
    # Check the actual config file instead of flag files since we have 4 modes now
    case "${GAME_FILTER,,}" in
        all|1)
            GameFilterStatus="${GREEN}all (tcp+udp)${NC}"
            ;;
        tcp)
            GameFilterStatus="${GREEN}tcp only${NC}"
            ;;
        udp)
            GameFilterStatus="${GREEN}udp only${NC}"
            ;;
        *)
            GameFilterStatus="${YELLOW}disabled${NC}"
            ;;
    esac
}

get_ipset_status() {
    local list_file="$LISTS_DIR/ipset-all.txt"
    
    if [[ ! -f "$list_file" ]]; then
        IPsetMode="missing"
        IPsetStatus="${RED}missing${NC}"
        return
    fi
    
    # Empty file (0 bytes) = ANY mode
    if [[ ! -s "$list_file" ]]; then
        IPsetMode="any"
        IPsetStatus="${YELLOW}any${NC}"
        return
    fi
    
    # Count non-empty lines
    local line_count
    line_count=$(grep -cve '^\s*$' "$list_file" 2>/dev/null) || line_count=0
    
    if [[ "$line_count" -le 1 ]] && grep -q "^203\.0\.113\.113/32$" "$list_file" 2>/dev/null; then
        IPsetMode="none"
        IPsetStatus="${YELLOW}none${NC}"
    else
        IPsetMode="loaded"
        IPsetStatus="${GREEN}loaded${NC} (${line_count} IPs)"
    fi
}

get_auto_update_status() {
    local flag_file="$UTILS_DIR/check_updates.enabled"
    
    if [[ -f "$flag_file" ]]; then
        AutoUpdateStatus="${GREEN}enabled${NC}"
    else
        AutoUpdateStatus="${YELLOW}disabled${NC}"
    fi
}

# ============================================================================
# MENU ACTIONS
# ============================================================================

menu_start() {
    check_root || { press_enter; return; }
    
    echo ""
    echo "Available strategies:"
    local strategies=($(ls -1 "$SCRIPT_DIR/strategies/"*.sh 2>/dev/null | xargs -n1 basename | sed 's/\.sh$//'))
    local i=1
    for s in "${strategies[@]}"; do
        echo "  $i. $s"
        ((i++))
    done
    echo ""
    read -p "Enter strategy number (or press Enter for default '$STRATEGY'): " choice
    
    if [[ -n "$choice" ]]; then
        if [[ $choice -gt 0 && $choice -le ${#strategies[@]} ]]; then
            local selected="${strategies[$((choice-1))]}"
            # Save selected strategy to config
            if grep -q "^STRATEGY=" "$CONFIG_FILE"; then
                sed -i "s/^STRATEGY=.*/STRATEGY=\"$selected\"/" "$CONFIG_FILE"
            else
                echo "STRATEGY=\"$selected\"" >> "$CONFIG_FILE"
            fi
            source "$CONFIG_FILE"
            "$SCRIPT_DIR/zapret.sh" start "$selected"
        else
            echo -e "${RED}Invalid choice${NC}"
        fi
    else
        "$SCRIPT_DIR/zapret.sh" start
    fi
    
    press_enter
}

menu_stop() {
    check_root || { press_enter; return; }
    "$SCRIPT_DIR/zapret.sh" stop
    press_enter
}

menu_restart() {
    check_root || { press_enter; return; }
    "$SCRIPT_DIR/zapret.sh" restart
    press_enter
}

menu_status() {
    "$SCRIPT_DIR/zapret.sh" status
    press_enter
}

menu_install_systemd() {
    check_root || { press_enter; return; }
    
    echo -e "${YELLOW}Installing systemd service...${NC}"
    
    local service_file="/etc/systemd/system/zapret.service"
    
    cat > "$service_file" << EOF
[Unit]
Description=Zapret DPI Bypass
After=network-online.target nftables.service
Wants=network-online.target

[Service]
Type=forking
PIDFile=/run/zapret.pid
ExecStart=$SCRIPT_DIR/zapret.sh start
ExecStop=$SCRIPT_DIR/zapret.sh stop
ExecReload=$SCRIPT_DIR/zapret.sh restart
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
    
    systemctl daemon-reload
    echo -e "${GREEN}Systemd service installed${NC}"
    echo ""
    echo "Commands:"
    echo "  systemctl start zapret   - Start service"
    echo "  systemctl stop zapret    - Stop service"
    echo "  systemctl enable zapret  - Enable autostart"
    echo "  systemctl status zapret  - Check status"
    
    press_enter
}

menu_uninstall_systemd() {
    check_root || { press_enter; return; }
    
    echo -e "${YELLOW}Removing systemd service...${NC}"
    
    systemctl stop zapret 2>/dev/null || true
    systemctl disable zapret 2>/dev/null || true
    rm -f /etc/systemd/system/zapret.service
    systemctl daemon-reload
    
    echo -e "${GREEN}Systemd service removed${NC}"
    press_enter
}

# ============================================================================
# GAME FILTER
# ============================================================================

menu_toggle_game_filter() {
    echo -e "${YELLOW}Select Game Filter mode:${NC}"
    echo "  1. Disable"
    echo "  2. UDP only (Default/Recommended)"
    echo "  3. TCP only"
    echo "  4. ALL (TCP + UDP)"
    echo ""
    read -p "Choose option (1-4): " gf_choice
    
    local new_val=""
    case "$gf_choice" in
        1) new_val="off" ;;
        2) new_val="udp" ;;
        3) new_val="tcp" ;;
        4) new_val="all" ;;
        *) echo -e "${RED}Invalid choice${NC}"; press_enter; return ;;
    esac
    
    # Update config file
    if grep -q "^GAME_FILTER=" "$CONFIG_FILE"; then
        sed -i "s/^GAME_FILTER=.*/GAME_FILTER=\"$new_val\"/" "$CONFIG_FILE"
    else
        echo "GAME_FILTER=\"$new_val\"" >> "$CONFIG_FILE"
    fi
    
    # Reload config to update current variables
    source "$CONFIG_FILE"
    
    echo -e "${GREEN}Game filter set to: $new_val${NC}"
    echo "Restart Zapret to apply changes"
    press_enter
}

# ============================================================================
# IPSET FILTER
# ============================================================================

menu_toggle_ipset() {
    local list_file="$LISTS_DIR/ipset-all.txt"
    local backup_file="$LISTS_DIR/ipset-all.txt.backup"
    
    get_ipset_status
    
    case "$IPsetMode" in
        loaded)
            echo "Switching to NONE mode (blocking specific IP)..."
            if [[ -f "$list_file" ]]; then
                cp -f "$list_file" "$backup_file"
            fi
            echo "203.0.113.113/32" > "$list_file"
            echo -e "${GREEN}IPSet switched to NONE mode${NC}"
            ;;
        none)
            echo "Switching to ANY mode (empty list)..."
            > "$list_file"
            echo -e "${GREEN}IPSet switched to ANY mode${NC}"
            ;;
        any)
            echo "Switching to LOADED mode..."
            if [[ -f "$backup_file" ]]; then
                cp -f "$backup_file" "$list_file"
                local count=$(wc -l < "$list_file")
                echo -e "${GREEN}IPSet restored from backup ($count IPs)${NC}"
            else
                echo -e "${RED}Error: No backup file to restore${NC}"
                echo "Run 'Update IPSet List' first to download the list"
            fi
            ;;
        *)
            echo -e "${RED}Error: Cannot determine current IPSet status${NC}"
            echo "Run 'Update IPSet List' to fix"
            ;;
    esac
    
    echo ""
    echo "Restart Zapret to apply changes"
    press_enter
}

# ============================================================================
# AUTO-UPDATE CHECK
# ============================================================================

menu_toggle_auto_update() {
    mkdir -p "$UTILS_DIR"
    local flag_file="$UTILS_DIR/check_updates.enabled"
    
    if [[ -f "$flag_file" ]]; then
        rm -f "$flag_file"
        echo -e "${YELLOW}Auto-update check disabled${NC}"
    else
        touch "$flag_file"
        echo -e "${GREEN}Auto-update check enabled${NC}"
    fi
    
    press_enter
}

# ============================================================================
# UPDATE FUNCTIONS
# ============================================================================

menu_update_ipset() {
    echo -e "${YELLOW}Updating ipset-all.txt...${NC}"
    
    local list_file="$LISTS_DIR/ipset-all.txt"
    local backup_file="$LISTS_DIR/ipset-all.txt.backup"
    local tmp_file=$(make_tmp)
    
    if download "$IPSET_URL" "$tmp_file"; then
        if [[ -s "$tmp_file" ]]; then
            # Backup current file if it has content
            if [[ -f "$list_file" ]] && [[ $(wc -l < "$list_file") -gt 1 ]]; then
                cp -f "$list_file" "$backup_file"
            fi
            
            mv "$tmp_file" "$list_file"
            chmod 644 "$list_file"
            local lines=$(wc -l < "$list_file")
            echo -e "${GREEN}Updated ipset-all.txt ($lines entries)${NC}"
        else
            echo -e "${RED}Downloaded file is empty${NC}"
            rm -f "$tmp_file"
        fi
    else
        echo -e "${RED}Failed to download ipset${NC}"
        rm -f "$tmp_file"
    fi
    
    press_enter
}

menu_update_lists() {
    echo -e "${YELLOW}Updating all lists...${NC}"
    
    if [[ -x "$SCRIPT_DIR/update-lists.sh" ]]; then
        "$SCRIPT_DIR/update-lists.sh"
    else
        menu_update_ipset
    fi
    
    press_enter
}

menu_check_updates() {
    echo -e "${YELLOW}Checking for software updates...${NC}"
    
    local tmp_file=$(make_tmp)
    local remote_version=""
    
    if download "$GITHUB_VERSION_URL" "$tmp_file"; then
        remote_version=$(tr -d '[:space:]' < "$tmp_file")
    fi
    
    if [[ -n "$remote_version" ]]; then
        echo "Local version:  $LOCAL_VERSION"
        echo "Remote version: $remote_version"
        echo ""
        
        if [[ "$LOCAL_VERSION" != "$remote_version" ]]; then
            echo -e "${YELLOW}Update available: $remote_version${NC}"
            echo ""
            echo "To update:"
            echo "  cd $(dirname "$SCRIPT_DIR")"
            echo "  git pull"
            echo ""
            echo "Or download: $GITHUB_REPO"
            echo ""
            read -p "Open in browser? (y/N): " choice
            if [[ "$choice" =~ ^[Yy]$ ]]; then
                xdg-open "$GITHUB_REPO" 2>/dev/null || echo "Visit: $GITHUB_REPO"
            fi
        else
            echo -e "${GREEN}You have the latest version${NC}"
        fi
    else
        echo -e "${RED}Failed to check for updates${NC}"
        echo "Check manually: $GITHUB_REPO"
    fi
    
    press_enter
}

# ============================================================================
# UPDATE HOSTS FILE
# ============================================================================

menu_update_hosts() {
    check_root || { press_enter; return; }
    
    local hosts_file="/etc/hosts"
    local tmp_file=$(make_tmp)
    
    echo -e "${YELLOW}Downloading hosts entries from GitHub...${NC}"
    
    if ! download "$HOSTS_URL" "$tmp_file"; then
        echo -e "${RED}Failed to download hosts file${NC}"
        echo "URL: $HOSTS_URL"
        rm -f "$tmp_file"
        press_enter
        return
    fi
    
    # Check download is valid (not HTML error page)
    local first_line=$(head -1 "$tmp_file" 2>/dev/null)
    if echo "$first_line" | grep -qiE "^<!DOCTYPE|^<html|^404"; then
        echo -e "${RED}Error: Server returned error page${NC}"
        rm -f "$tmp_file"
        press_enter
        return
    fi
    
    if [[ ! -s "$tmp_file" ]]; then
        echo -e "${RED}Downloaded file is empty${NC}"
        rm -f "$tmp_file"
        press_enter
        return
    fi
    
    local new_entries=$(cat "$tmp_file")
    local new_count=$(wc -l < "$tmp_file")
    rm -f "$tmp_file"
    
    echo -e "Downloaded ${GREEN}$new_count${NC} host entries"
    echo ""
    
    # Check if zapret block already exists
    if grep -q "$HOSTS_MARKER_BEGIN" "$hosts_file" 2>/dev/null; then
        # Extract current block content
        local current_block=$(sed -n "/$HOSTS_MARKER_BEGIN/,/$HOSTS_MARKER_END/p" "$hosts_file" | grep -v "$HOSTS_MARKER_BEGIN\|$HOSTS_MARKER_END")
        
        if [[ "$current_block" == "$new_entries" ]]; then
            echo -e "${GREEN}Hosts file is already up to date${NC}"
            press_enter
            return
        fi
        
        echo -e "${YELLOW}Updating existing zapret block in /etc/hosts...${NC}"
        
        # Lock /etc/hosts to prevent race conditions
        (
            flock -x 200 || { echo -e "${RED}Cannot lock /etc/hosts${NC}"; press_enter; return; }
            local tmp_hosts=$(make_tmp)
            sed "/$HOSTS_MARKER_BEGIN/,/$HOSTS_MARKER_END/d" "$hosts_file" > "$tmp_hosts"
            {
                cat "$tmp_hosts"
                echo ""
                echo "$HOSTS_MARKER_BEGIN"
                echo "$new_entries"
                echo "$HOSTS_MARKER_END"
            } > "$hosts_file"
        ) 200>"$hosts_file.lock"
        rm -f "$hosts_file.lock"
        
        echo -e "${GREEN}Zapret hosts block updated ($new_count entries)${NC}"
    else
        echo "Preview of entries to add:"
        echo "---"
        head -5 <<< "$new_entries"
        [[ $new_count -gt 5 ]] && echo "... ($((new_count - 5)) more)"
        echo "---"
        echo ""
        
        read -p "Add these entries to /etc/hosts? (y/N): " choice
        if [[ ! "$choice" =~ ^[Yy]$ ]]; then
            echo "Cancelled"
            press_enter
            return
        fi
        
        # Backup
        cp "$hosts_file" "${hosts_file}.backup.zapret"
        echo "Backup saved to ${hosts_file}.backup.zapret"
        
        # Append block
        {
            echo ""
            echo "$HOSTS_MARKER_BEGIN"
            echo "$new_entries"
            echo "$HOSTS_MARKER_END"
        } >> "$hosts_file"
        
        echo -e "${GREEN}Added zapret hosts block ($new_count entries)${NC}"
    fi
    
    echo ""
    echo "Entries are between markers:"
    echo "  $HOSTS_MARKER_BEGIN"
    echo "  $HOSTS_MARKER_END"
    echo "To remove: sudo sed -i '/$HOSTS_MARKER_BEGIN/,/$HOSTS_MARKER_END/d' /etc/hosts"
    
    press_enter
}

# ============================================================================
# DIAGNOSTICS
# ============================================================================

menu_diagnostics() {
    echo -e "${CYAN}=== Diagnostics ===${NC}"
    echo ""
    
    # Check nfqws binary
    if [[ -x "$SCRIPT_DIR/bin/nfqws" ]]; then
        local version=$("$SCRIPT_DIR/bin/nfqws" --version 2>&1 | head -1 || echo "unknown")
        echo -e "nfqws binary: ${GREEN}OK${NC} ($version)"
    else
        echo -e "nfqws binary: ${RED}NOT FOUND or not executable${NC}"
    fi
    
    # Check firewall backends
    if command -v nft &>/dev/null; then
        echo -e "nftables: ${GREEN}available${NC}"
    else
        echo -e "nftables: ${YELLOW}not installed${NC}"
    fi
    
    if command -v iptables &>/dev/null; then
        echo -e "iptables: ${GREEN}available${NC}"
    else
        echo -e "iptables: ${YELLOW}not installed${NC}"
    fi
    
    if ! command -v nft &>/dev/null && ! command -v iptables &>/dev/null; then
        echo -e "  ${RED}WARNING: No firewall backend found!${NC}"
        echo -e "  Install: ${YELLOW}sudo pacman -S nftables${NC} or ${YELLOW}iptables${NC}"
    fi
    
    # Check nf_tables kernel module
    if lsmod 2>/dev/null | grep -q nf_tables; then
        echo -e "nf_tables kernel module: ${GREEN}loaded${NC}"
    else
        echo -e "nf_tables kernel module: ${YELLOW}not loaded (may load on demand)${NC}"
    fi
    
    # Check NFQUEUE support
    if [[ -f /proc/net/netfilter/nfnetlink_queue ]]; then
        echo -e "NFQUEUE support: ${GREEN}available${NC}"
    else
        echo -e "NFQUEUE support: ${YELLOW}checking...${NC}"
        if modprobe nfnetlink_queue 2>/dev/null; then
            echo -e "NFQUEUE support: ${GREEN}loaded${NC}"
        else
            echo -e "NFQUEUE support: ${RED}may not be available${NC}"
        fi
    fi
    
    echo ""
    
    # Check lists
    echo "Lists status:"
    for list in list-general.txt list-google.txt ipset-all.txt ipset-exclude.txt list-exclude.txt; do
        if [[ -f "$LISTS_DIR/$list" ]]; then
            local lines=$(wc -l < "$LISTS_DIR/$list")
            echo -e "  $list: ${GREEN}$lines lines${NC}"
        else
            echo -e "  $list: ${RED}missing${NC}"
        fi
    done
    
    echo ""
    
    # Check nftables rules if running
    if nft list table inet zapret &>/dev/null; then
        echo -e "nftables zapret table: ${GREEN}active${NC}"
    else
        echo -e "nftables zapret table: ${YELLOW}not loaded${NC}"
    fi
    
    # Check for conflicting services
    echo ""
    echo "Checking for conflicts:"
    
    local conflicts=""
    for svc in opendpi goodbyedpi zapret-other; do
        if systemctl is-active --quiet "$svc" 2>/dev/null; then
            conflicts="$conflicts $svc"
        fi
    done
    
    if [[ -n "$conflicts" ]]; then
        echo -e "  Conflicting services:${RED}$conflicts${NC}"
    else
        echo -e "  No conflicting services: ${GREEN}OK${NC}"
    fi
    
    # Check VPN
    if ip link show | grep -qE "tun|tap|wg"; then
        echo -e "  VPN interface detected: ${YELLOW}may affect routing${NC}"
    else
        echo -e "  No VPN interface: ${GREEN}OK${NC}"
    fi
    
    press_enter
}

# ============================================================================
# TESTS
# ============================================================================

menu_run_tests() {
    echo -e "${CYAN}=== Connection Tests ===${NC}"
    echo ""
    
    local test_hosts=(
        "discord.com"
        "www.youtube.com"
        "www.google.com"
        "instagram.com"
    )
    
    for host in "${test_hosts[@]}"; do
        echo -n "Testing $host... "
        if curl -sI --connect-timeout 5 "https://$host" | head -1 | grep -q "200\|301\|302"; then
            echo -e "${GREEN}OK${NC}"
        else
            echo -e "${RED}FAILED${NC}"
        fi
    done
    
    echo ""
    
    # DNS test
    echo -n "DNS resolution (discord.com)... "
    if host discord.com &>/dev/null || dig discord.com +short &>/dev/null; then
        echo -e "${GREEN}OK${NC}"
    else
        echo -e "${RED}FAILED${NC}"
    fi
    
    press_enter
}

# ============================================================================
# MAIN MENU
# ============================================================================

main_menu() {
    while true; do
        print_header
        print_status
        
        echo "  ┌─ SERVICE ─────────────────────────────────────────┐"
        echo "  │  1. Start Zapret                                  │"
        echo "  │  2. Stop Zapret                                   │"
        echo "  │  3. Restart Zapret                                │"
        echo "  │  4. Check Status                                  │"
        echo "  ├─ SETTINGS ────────────────────────────────────────┤"
        echo -e "  │  5. Game Filter         [$GameFilterStatus]"
        echo -e "  │  6. IPSet Filter        [$IPsetStatus]"
        echo -e "  │  7. Auto-Update Check   [$AutoUpdateStatus]"
        echo "  │  8. Install Systemd Service                       │"
        echo "  │  9. Uninstall Systemd Service                     │"
        echo "  ├─ UPDATES ─────────────────────────────────────────┤"
        echo "  │  10. Update IPSet List                            │"
        echo "  │  11. Update Hosts File                            │"
        echo "  │  12. Update All Lists                             │"
        echo "  │  13. Check for Software Updates                   │"
        echo "  ├─ TOOLS ───────────────────────────────────────────┤"
        echo "  │  14. Run Diagnostics                              │"
        echo "  │  15. Run Connection Tests                         │"
        echo "  └───────────────────────────────────────────────────┘"
        echo "  0. Exit"
        echo ""
        
        read -p "  Select option (0-15): " choice
        
        case "$choice" in
            1) menu_start ;;
            2) menu_stop ;;
            3) menu_restart ;;
            4) menu_status ;;
            5) menu_toggle_game_filter ;;
            6) menu_toggle_ipset ;;
            7) menu_toggle_auto_update ;;
            8) menu_install_systemd ;;
            9) menu_uninstall_systemd ;;
            10) menu_update_ipset ;;
            11) menu_update_hosts ;;
            12) menu_update_lists ;;
            13) menu_check_updates ;;
            14) menu_diagnostics ;;
            15) menu_run_tests ;;
            0) exit 0 ;;
            *) echo -e "${RED}Invalid option${NC}"; sleep 1 ;;
        esac
    done
}

# Handle direct commands
case "${1:-}" in
    start|stop|restart|status)
        "$SCRIPT_DIR/zapret.sh" "$1" "$2"
        ;;
    install)
        check_root && menu_install_systemd
        ;;
    uninstall)
        check_root && menu_uninstall_systemd
        ;;
    *)
        main_menu
        ;;
esac

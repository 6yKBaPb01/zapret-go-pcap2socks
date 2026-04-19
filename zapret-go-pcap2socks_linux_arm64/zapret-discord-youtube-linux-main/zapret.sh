#!/bin/bash
#
# zapret.sh - Main launcher script for Zapret DPI bypass on Linux
#
# Usage: ./zapret.sh [start|stop|status|restart] [strategy-name]
#

set -e

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
CONFIG_FILE="$SCRIPT_DIR/config"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Load configuration
if [[ -f "$CONFIG_FILE" ]]; then
    source "$CONFIG_FILE"
else
    echo -e "${RED}Error: Config file not found: $CONFIG_FILE${NC}"
    exit 1
fi

# Override strategy if provided as argument
if [[ -n "$2" ]]; then
    STRATEGY="$2"
fi

# Paths (ZAPRET_BASE defaults to script directory if not set in config)
ZAPRET_BASE="${ZAPRET_BASE:-$SCRIPT_DIR}"
BIN_DIR="$ZAPRET_BASE/bin"
LISTS_DIR="$ZAPRET_BASE/lists"
STRATEGIES_DIR="$ZAPRET_BASE/strategies"
NFQWS="$BIN_DIR/nfqws"

# Expand game filter ports (modes: off, tcp, udp, all; legacy: 0=off, 1=all)
GAME_PORTS_TCP=""
GAME_PORTS_UDP=""
case "${GAME_FILTER,,}" in
    all|1)
        GAME_PORTS_TCP="1024-65535"
        GAME_PORTS_UDP="1024-65535"
        ;;
    tcp)
        GAME_PORTS_TCP="1024-65535"
        ;;
    udp)
        GAME_PORTS_UDP="1024-65535"
        ;;
    off|0|"")
        ;;
    *)
        echo -e "${YELLOW}Warning: Unknown GAME_FILTER value '$GAME_FILTER', using 'off'${NC}"
        ;;
esac

# ============================================================================
# FIREWALL AUTO-DETECTION
# ============================================================================

detect_firewall() {
    # Allow manual override via config
    if [[ -n "${FIREWALL_BACKEND:-}" ]]; then
        FW_BACKEND="$FIREWALL_BACKEND"
        echo -e "${YELLOW}Using firewall backend (config): $FW_BACKEND${NC}"
        return
    fi
    
    if command -v nft &>/dev/null; then
        FW_BACKEND="nftables"
    elif command -v iptables &>/dev/null; then
        FW_BACKEND="iptables"
    else
        echo -e "${RED}Error: Neither nftables nor iptables found${NC}"
        echo "Install one of them:"
        echo "  Arch:   sudo pacman -S nftables   OR   sudo pacman -S iptables"
        echo "  Debian: sudo apt install nftables  OR   sudo apt install iptables"
        exit 1
    fi
}

# ============================================================================
# NFTABLES FUNCTIONS
# ============================================================================

nft_setup() {
    echo -e "${YELLOW}Setting up nftables rules...${NC}"
    
    nft list table inet $NFT_TABLE &>/dev/null && nft delete table inet $NFT_TABLE
    
    nft add table inet $NFT_TABLE
    nft add chain inet $NFT_TABLE output "{ type filter hook output priority mangle; }"
    nft add chain inet $NFT_TABLE prerouting "{ type filter hook prerouting priority mangle; }"
    
    local tcp_dports="$TCP_PORTS"
    [[ -n "$GAME_PORTS_TCP" ]] && tcp_dports="$tcp_dports,$GAME_PORTS_TCP"
    
    local udp_dports="$UDP_PORTS"
    [[ -n "$GAME_PORTS_UDP" ]] && udp_dports="$udp_dports,$GAME_PORTS_UDP"
    
    nft add rule inet $NFT_TABLE output meta mark and $DESYNC_MARK == 0 tcp dport "{ $tcp_dports }" ct original packets 1-6 queue num $QNUM bypass
    nft add rule inet $NFT_TABLE output meta mark and $DESYNC_MARK == 0 udp dport "{ $udp_dports }" ct original packets 1-6 queue num $QNUM bypass
    nft add rule inet $NFT_TABLE prerouting tcp sport "{ 80, 443 }" ct reply packets 1-3 queue num $QNUM bypass
    
    echo -e "${GREEN}nftables rules configured${NC}"
}

nft_cleanup() {
    echo -e "${YELLOW}Cleaning up nftables rules...${NC}"
    if nft list table inet $NFT_TABLE &>/dev/null; then
        nft delete table inet $NFT_TABLE
        echo -e "${GREEN}nftables table '$NFT_TABLE' removed${NC}"
    else
        echo "nftables table '$NFT_TABLE' not found, nothing to clean"
    fi
}

nft_status() {
    echo ""
    echo "=== Firewall rules (nftables) ==="
    if nft list table inet $NFT_TABLE &>/dev/null; then
        nft list table inet $NFT_TABLE
    else
        echo -e "${YELLOW}nftables table '$NFT_TABLE' not found${NC}"
    fi
}

# ============================================================================
# IPTABLES FUNCTIONS
# ============================================================================

IPT_CHAIN="ZAPRET"

ipt_setup() {
    echo -e "${YELLOW}Setting up iptables rules...${NC}"
    
    # Cleanup first
    ipt_cleanup_quiet
    
    # Build multiport lists
    local tcp_dports="$TCP_PORTS"
    [[ -n "$GAME_PORTS_TCP" ]] && tcp_dports="$tcp_dports,$GAME_PORTS_TCP"
    
    local udp_dports="$UDP_PORTS"
    [[ -n "$GAME_PORTS_UDP" ]] && udp_dports="$udp_dports,$GAME_PORTS_UDP"
    
    # Create custom chain
    iptables -t mangle -N $IPT_CHAIN 2>/dev/null || true
    ip6tables -t mangle -N $IPT_CHAIN 2>/dev/null || true
    
    # OUTPUT: TCP — first 6 packets to NFQUEUE
    iptables -t mangle -A $IPT_CHAIN -p tcp -m multiport --dports $tcp_dports \
        -m conntrack --ctdir ORIGINAL -m connbytes --connbytes 1:6 --connbytes-mode packets --connbytes-dir original \
        -m mark ! --mark $DESYNC_MARK/$DESYNC_MARK \
        -j NFQUEUE --queue-num $QNUM --queue-bypass
    
    ip6tables -t mangle -A $IPT_CHAIN -p tcp -m multiport --dports $tcp_dports \
        -m conntrack --ctdir ORIGINAL -m connbytes --connbytes 1:6 --connbytes-mode packets --connbytes-dir original \
        -m mark ! --mark $DESYNC_MARK/$DESYNC_MARK \
        -j NFQUEUE --queue-num $QNUM --queue-bypass
    
    # OUTPUT: UDP — first 6 packets to NFQUEUE
    iptables -t mangle -A $IPT_CHAIN -p udp -m multiport --dports $udp_dports \
        -m conntrack --ctdir ORIGINAL -m connbytes --connbytes 1:6 --connbytes-mode packets --connbytes-dir original \
        -m mark ! --mark $DESYNC_MARK/$DESYNC_MARK \
        -j NFQUEUE --queue-num $QNUM --queue-bypass
    
    ip6tables -t mangle -A $IPT_CHAIN -p udp -m multiport --dports $udp_dports \
        -m conntrack --ctdir ORIGINAL -m connbytes --connbytes 1:6 --connbytes-mode packets --connbytes-dir original \
        -m mark ! --mark $DESYNC_MARK/$DESYNC_MARK \
        -j NFQUEUE --queue-num $QNUM --queue-bypass
    
    # Hook into OUTPUT
    iptables -t mangle -A OUTPUT -j $IPT_CHAIN
    ip6tables -t mangle -A OUTPUT -j $IPT_CHAIN
    
    # PREROUTING: incoming replies for autottl
    iptables -t mangle -A PREROUTING -p tcp -m multiport --sports 80,443 \
        -m conntrack --ctdir REPLY -m connbytes --connbytes 1:3 --connbytes-mode packets --connbytes-dir reply \
        -j NFQUEUE --queue-num $QNUM --queue-bypass
    
    ip6tables -t mangle -A PREROUTING -p tcp -m multiport --sports 80,443 \
        -m conntrack --ctdir REPLY -m connbytes --connbytes 1:3 --connbytes-mode packets --connbytes-dir reply \
        -j NFQUEUE --queue-num $QNUM --queue-bypass
    
    echo -e "${GREEN}iptables rules configured${NC}"
}

ipt_cleanup_quiet() {
    # Remove jump rules from OUTPUT/PREROUTING
    iptables -t mangle -D OUTPUT -j $IPT_CHAIN 2>/dev/null || true
    ip6tables -t mangle -D OUTPUT -j $IPT_CHAIN 2>/dev/null || true
    
    # Remove PREROUTING rules (by matching NFQUEUE target)
    while iptables -t mangle -D PREROUTING -p tcp -m multiport --sports 80,443 \
        -m conntrack --ctdir REPLY -m connbytes --connbytes 1:3 --connbytes-mode packets --connbytes-dir reply \
        -j NFQUEUE --queue-num $QNUM --queue-bypass 2>/dev/null; do :; done
    while ip6tables -t mangle -D PREROUTING -p tcp -m multiport --sports 80,443 \
        -m conntrack --ctdir REPLY -m connbytes --connbytes 1:3 --connbytes-mode packets --connbytes-dir reply \
        -j NFQUEUE --queue-num $QNUM --queue-bypass 2>/dev/null; do :; done
    
    # Flush and delete custom chain
    iptables -t mangle -F $IPT_CHAIN 2>/dev/null || true
    ip6tables -t mangle -F $IPT_CHAIN 2>/dev/null || true
    iptables -t mangle -X $IPT_CHAIN 2>/dev/null || true
    ip6tables -t mangle -X $IPT_CHAIN 2>/dev/null || true
}

ipt_cleanup() {
    echo -e "${YELLOW}Cleaning up iptables rules...${NC}"
    ipt_cleanup_quiet
    echo -e "${GREEN}iptables rules removed${NC}"
}

ipt_status() {
    echo ""
    echo "=== Firewall rules (iptables) ==="
    local rules=$(iptables -t mangle -L $IPT_CHAIN -n 2>/dev/null)
    if [[ -n "$rules" ]]; then
        echo "$rules"
    else
        echo -e "${YELLOW}iptables chain '$IPT_CHAIN' not found${NC}"
    fi
}

# ============================================================================
# FIREWALL DISPATCHER
# ============================================================================

fw_setup() {
    detect_firewall
    
    # Load required kernel modules for NFQUEUE and conntrack
    modprobe nfnetlink_queue 2>/dev/null || true
    modprobe nf_conntrack 2>/dev/null || true
    
    case "$FW_BACKEND" in
        nftables) nft_setup ;;
        iptables) ipt_setup ;;
    esac
}

fw_cleanup() {
    detect_firewall
    case "$FW_BACKEND" in
        nftables) nft_cleanup ;;
        iptables) ipt_cleanup ;;
    esac
}

fw_status() {
    detect_firewall
    echo "Firewall backend: $FW_BACKEND"
    case "$FW_BACKEND" in
        nftables) nft_status ;;
        iptables) ipt_status ;;
    esac
}

# ============================================================================
# SERVICE FUNCTIONS
# ============================================================================

check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}Error: This script must be run as root${NC}"
        exit 1
    fi
}

check_binary() {
    if [[ ! -x "$NFQWS" ]]; then
        echo -e "${RED}Error: nfqws binary not found or not executable: $NFQWS${NC}"
        exit 1
    fi
}

check_path_permissions() {
    # nfqws drops privileges and runs as nobody (UID=2147483647)
    # To access hostlist files, nobody needs execute (x) permission
    # on ALL parent directories in the path to ZAPRET_BASE
    local dir="$ZAPRET_BASE"
    local failed_dirs=()
    
    while [[ "$dir" != "/" ]]; do
        # Check if "others" have execute permission
        local perms=$(stat -c '%A' "$dir" 2>/dev/null)
        if [[ -n "$perms" ]] && [[ "${perms:9:1}" != "x" ]]; then
            failed_dirs+=("$dir")
        fi
        dir=$(dirname "$dir")
    done
    
    if [[ ${#failed_dirs[@]} -gt 0 ]]; then
        echo -e "${RED}Error: nfqws runs as unprivileged user (nobody) and cannot access files${NC}"
        echo -e "${RED}because the following directories lack execute permission for others:${NC}"
        echo ""
        for d in "${failed_dirs[@]}"; do
            echo -e "  ${YELLOW}$d${NC}  ($(stat -c '%A' "$d"))"
        done
        echo ""
        echo -e "${YELLOW}Fix options:${NC}"
        echo "  1. Add execute permission for others:"
        for d in "${failed_dirs[@]}"; do
            echo "     chmod o+x $d"
        done
        echo ""
        echo "  2. Move zapret to /opt (recommended):"
        echo "     sudo mv $ZAPRET_BASE /opt/zapret"
        echo ""
        echo -e "${YELLOW}See README.md section 'Права доступа' for details${NC}"
        exit 1
    fi
}

load_strategy() {
    local strategy_file="$STRATEGIES_DIR/${STRATEGY}.sh"
    
    if [[ ! -f "$strategy_file" ]]; then
        echo -e "${RED}Error: Strategy not found: $strategy_file${NC}"
        echo "Available strategies:"
        ls -1 "$STRATEGIES_DIR"/*.sh 2>/dev/null | xargs -n1 basename | sed 's/\.sh$//'
        exit 1
    fi
    
    source "$strategy_file"
    
    if [[ -z "$NFQWS_ARGS" ]]; then
        echo -e "${RED}Error: Strategy file does not define NFQWS_ARGS${NC}"
        exit 1
    fi
}

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

start_zapret() {
    check_root
    check_binary
    check_path_permissions
    check_user_lists
    
    if [[ -f "$PIDFILE" ]] && [[ -d "/proc/$(cat "$PIDFILE" 2>/dev/null)" ]]; then
        echo -e "${YELLOW}Zapret is already running (PID: $(cat "$PIDFILE"))${NC}"
        return 0
    fi
    
    echo -e "${GREEN}Starting Zapret with strategy: $STRATEGY${NC}"
    
    load_strategy
    fw_setup
    
    local cmd="$NFQWS --qnum=$QNUM $NFQWS_ARGS"
    
    [[ "$DEBUG" == "1" ]] && cmd="$cmd --debug=1"
    [[ "$DAEMON" == "1" ]] && cmd="$cmd --daemon --pidfile=$PIDFILE"
    
    echo "Running: $cmd"
    eval $cmd
    
    sleep 1
    
    if [[ -f "$PIDFILE" ]] && [[ -d "/proc/$(cat "$PIDFILE" 2>/dev/null)" ]]; then
        echo -e "${GREEN}Zapret started successfully (PID: $(cat "$PIDFILE"))${NC}"
    else
        echo -e "${RED}Failed to start Zapret${NC}"
        fw_cleanup
        exit 1
    fi
}

stop_zapret() {
    check_root
    
    echo -e "${YELLOW}Stopping Zapret...${NC}"
    
    if [[ -f "$PIDFILE" ]]; then
        local pid=$(cat "$PIDFILE")
        if kill -0 "$pid" 2>/dev/null; then
            kill "$pid"
            sleep 1
            if kill -0 "$pid" 2>/dev/null; then
                kill -9 "$pid"
            fi
            echo -e "${GREEN}nfqws process stopped${NC}"
        fi
        rm -f "$PIDFILE"
    else
        pkill -f "$NFQWS" 2>/dev/null || true
    fi
    
    fw_cleanup
    
    echo -e "${GREEN}Zapret stopped${NC}"
}

status_zapret() {
    echo "=== Zapret Status ==="
    
    if [[ -f "$PIDFILE" ]]; then
        local pid
        pid=$(cat "$PIDFILE" 2>/dev/null)
        if [[ -n "$pid" ]] && [[ -d "/proc/$pid" ]]; then
            echo -e "${GREEN}nfqws is running (PID: $pid)${NC}"
        else
            echo -e "${RED}nfqws is NOT running (stale PID file)${NC}"
        fi
    elif pgrep -f "$NFQWS" >/dev/null; then
        echo -e "${YELLOW}nfqws is running (PID file missing)${NC}"
    else
        echo -e "${RED}nfqws is NOT running${NC}"
    fi
    
    fw_status
}

# ============================================================================
# MAIN
# ============================================================================

case "${1:-}" in
    start)
        start_zapret
        ;;
    stop)
        stop_zapret
        ;;
    restart)
        stop_zapret
        sleep 1
        start_zapret
        ;;
    status)
        status_zapret
        ;;
    *)
        echo "Zapret DPI Bypass for Linux"
        echo ""
        echo "Usage: $0 {start|stop|restart|status} [strategy-name]"
        echo ""
        echo "Commands:"
        echo "  start   - Start Zapret with configured or specified strategy"
        echo "  stop    - Stop Zapret and cleanup firewall rules"
        echo "  restart - Restart Zapret"
        echo "  status  - Show current status"
        echo ""
        echo "Current configuration:"
        echo "  Strategy: $STRATEGY"
        echo "  TCP Ports: $TCP_PORTS"
        echo "  UDP Ports: $UDP_PORTS"
        echo "  Game Filter: $GAME_FILTER (tcp=$GAME_PORTS_TCP, udp=$GAME_PORTS_UDP)"
        echo ""
        echo "Available strategies:"
        ls -1 "$STRATEGIES_DIR"/*.sh 2>/dev/null | xargs -n1 basename | sed 's/\.sh$//' | column
        exit 1
        ;;
esac

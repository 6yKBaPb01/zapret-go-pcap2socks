#!/bin/bash
#
# convert.sh - Standalone Windows to Linux Zapret Strategy Converter
#
# Usage: 
#   1. Paste Windows strategy into input.txt
#   2. Run ./convert.sh
#   3. Get Linux strategy from output.txt
#

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
INPUT_FILE="$SCRIPT_DIR/input.txt"
OUTPUT_FILE="$SCRIPT_DIR/output.txt"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

VERSION="2.0"

print_usage() {
    echo "Zapret Strategy Converter v${VERSION}"
    echo ""
    echo "Converts Windows winws.exe strategies to Linux nfqws format."
    echo ""
    echo "Usage:"
    echo "  1. Paste your Windows strategy into: input.txt"
    echo "  2. Run: ./convert.sh"
    echo "  3. Get converted Linux strategy from: output.txt"
    echo ""
    echo "Input format (Windows):"
    echo "  winws.exe --wf-tcp=80,443 --filter-tcp=443 --dpi-desync=fake ..."
    echo "  or just the arguments without winws.exe"
    echo ""
    echo "Output format (Linux):"
    echo "  --qnum=200 --filter-tcp=443 --dpi-desync=fake ..."
    echo ""
    echo "Options:"
    echo "  -h, --help     Show this help"
    echo "  -q, --qnum N   Set NFQUEUE number (default: 200)"
}

convert_strategy() {
    local input="$1"
    local qnum="${2:-200}"
    
    # Remove Windows line endings
    local args=$(echo "$input" | tr -d '\r')
    
    # Join multiple lines (handle ^ continuation)
    args=$(echo "$args" | tr '\n' ' ' | sed 's/\^//g')
    
    # Remove winws.exe path if present
    args=$(echo "$args" | sed 's/.*winws\.exe[" ]*//')
    
    # Remove Windows filter options (--wf-tcp, --wf-udp) - Linux uses nftables
    args=$(echo "$args" | sed 's/--wf-tcp=[^ ]* //g; s/--wf-udp=[^ ]* //g')
    
    # Remove start command and window title if present
    args=$(echo "$args" | sed 's/^start [^-]*//')
    
    # Convert Windows path variables to Linux variables
    # %BIN% -> $BIN_DIR/ (provided by zapret.sh)
    # %LISTS% -> $LISTS_DIR/ (provided by zapret.sh)
    args=$(echo "$args" | sed 's/%BIN%/$BIN_DIR\//g; s/%LISTS%/$LISTS_DIR\//g')
    args=$(echo "$args" | sed 's/"\$BIN_DIR\//\$BIN_DIR\//g; s/"\$LISTS_DIR\//\$LISTS_DIR\//g')
    
    # Remove Windows-style quotes
    args=$(echo "$args" | sed 's/\\"//g')
    
    # Fix GameFilter variable - remove and clean up trailing commas
    args=$(echo "$args" | sed 's/,%GameFilter%//g; s/%GameFilter%,//g; s/%GameFilter%//g')
    
    # Clean up empty port filters
    args=$(echo "$args" | sed 's/--filter-tcp=, /--filter-tcp=/g; s/--filter-udp=, /--filter-udp=/g')
    args=$(echo "$args" | sed 's/--filter-tcp= --/--/g; s/--filter-udp= --/--/g')
    
    # Remove extra spaces
    args=$(echo "$args" | tr -s ' ' | sed 's/^ //; s/ $//')
    
    # Add qnum at the beginning if not present
    if ! echo "$args" | grep -q "\-\-qnum="; then
        args="--qnum=$qnum $args"
    fi
    
    echo "$args"
}

format_output() {
    local args="$1"
    
    # Put each --new on a separate line for readability
    echo "$args" | sed 's/ --new /\n--new\n/g'
}

# Parse arguments
QNUM=200
while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)
            print_usage
            exit 0
            ;;
        -q|--qnum)
            QNUM="$2"
            shift 2
            ;;
        *)
            shift
            ;;
    esac
done

# Check input file
if [[ ! -f "$INPUT_FILE" ]]; then
    echo -e "${YELLOW}Creating empty input.txt...${NC}"
    cat > "$INPUT_FILE" << 'EOF'
# Zapret Strategy Converter - Input File
#
# Paste your Windows strategy here (one or multiple lines)
# Lines starting with # are ignored
#
# Example:
# winws.exe --wf-tcp=80,443 --filter-tcp=443 --dpi-desync=fake --dpi-desync-repeats=6 --new --filter-udp=443 --dpi-desync=fake
#
# Or just the arguments:
# --filter-tcp=443 --dpi-desync=fake,multisplit --dpi-desync-split-pos=1 --new --filter-udp=443 --dpi-desync=fake
#
# Then run: ./convert.sh

EOF
    echo -e "${GREEN}Created input.txt - paste your Windows strategy there and run again${NC}"
    exit 0
fi

# Read input (ignore comments and empty lines)
INPUT=$(grep -v '^#' "$INPUT_FILE" | grep -v '^[[:space:]]*$' | tr '\n' ' ')

if [[ -z "$INPUT" ]]; then
    echo -e "${RED}Error: input.txt is empty or contains only comments${NC}"
    echo "Paste your Windows strategy into input.txt and run again"
    exit 1
fi

echo -e "${CYAN}=== Zapret Strategy Converter ===${NC}"
echo ""
echo -e "${YELLOW}Input (Windows format):${NC}"
echo "$INPUT" | head -c 200
[[ ${#INPUT} -gt 200 ]] && echo "..."
echo ""
echo ""

# Convert
CONVERTED=$(convert_strategy "$INPUT" "$QNUM")
FORMATTED=$(format_output "$CONVERTED")

# Write output
cat > "$OUTPUT_FILE" << EOF
# Zapret Strategy - Linux Format
# Converted from Windows format
# Generated: $(date '+%Y-%m-%d %H:%M:%S')
#
# Usage with nfqws:
#   nfqws $CONVERTED
#
# Or in strategy file (NFQWS_ARGS variable):

$FORMATTED
EOF

echo -e "${GREEN}Converted successfully!${NC}"
echo ""
echo -e "${YELLOW}Output (Linux format):${NC}"
echo "$FORMATTED" | head -20
echo ""
echo -e "${GREEN}Full output saved to: output.txt${NC}"

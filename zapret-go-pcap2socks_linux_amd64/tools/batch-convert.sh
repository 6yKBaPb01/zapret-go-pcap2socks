#!/bin/bash
#
# batch-convert.sh - Batch convert all Windows .bat strategies to Linux .sh
#
# Usage: ./batch-convert.sh <bat_directory> <output_directory>
# Example: ./batch-convert.sh ../../zapret-discord-youtube-1.9.6/ ../strategies/
#

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

BAT_DIR="${1:?Usage: $0 <bat_directory> <output_directory>}"
OUT_DIR="${2:?Usage: $0 <bat_directory> <output_directory>}"

if [[ ! -d "$BAT_DIR" ]]; then
    echo -e "${RED}Error: Directory not found: $BAT_DIR${NC}"
    exit 1
fi

mkdir -p "$OUT_DIR"

count=0
failed=0
set +e

for bat_file in "$BAT_DIR"/*.bat; do
    [[ ! -f "$bat_file" ]] && continue
    
    base=$(basename "$bat_file" .bat)
    # Skip service.bat
    [[ "$base" == "service" ]] && continue
    
    # Generate Linux filename: "general (ALT11)" -> "general-alt11"
    name=$(echo "$base" | tr '[:upper:]' '[:lower:]' | sed 's/ (/-/g; s/)//g; s/ /-/g')
    out="$OUT_DIR/${name}.sh"
    
    # Extract args: find the line with winws.exe, join continuations (^), take args
    args=$(tr -d '\r' < "$bat_file" | sed -n '/winws\.exe/,$ p' | tr '\n' ' ' | sed 's/.*winws\.exe[" ]*//' | sed 's/\^//g')
    
    if [[ -z "$args" ]]; then
        echo -e "${RED}SKIP: $base (no winws.exe found)${NC}"
        ((failed++))
        continue
    fi
    
    # Remove Windows-only options
    args=$(echo "$args" | sed 's/--wf-tcp=[^ ]* //g; s/--wf-udp=[^ ]* //g')
    
    # Convert paths: "%BIN%file" or %BIN%file -> $BIN_DIR/file
    args=$(echo "$args" | sed 's/"%BIN%/$BIN_DIR\//g; s/"%LISTS%/$LISTS_DIR\//g')
    args=$(echo "$args" | sed 's/%BIN%/$BIN_DIR\//g; s/%LISTS%/$LISTS_DIR\//g')
    args=$(echo "$args" | sed 's/"//g')
    
    # Convert ^! (bat escape) to literal !
    args=$(echo "$args" | sed 's/\^!/ !/g')
    
    # Remove GameFilter variables (v1.9.7: GameFilterTCP, GameFilterUDP; legacy: GameFilter)
    args=$(echo "$args" | sed 's/,%GameFilterTCP%//g; s/%GameFilterTCP%,//g; s/%GameFilterTCP%//g')
    args=$(echo "$args" | sed 's/,%GameFilterUDP%//g; s/%GameFilterUDP%,//g; s/%GameFilterUDP%//g')
    args=$(echo "$args" | sed 's/,%GameFilter%//g; s/%GameFilter%,//g; s/%GameFilter%//g')
    
    # Fix empty filters left after GameFilter removal
    args=$(echo "$args" | sed 's/--filter-tcp= --/--/g; s/--filter-udp= --/--/g')
    args=$(echo "$args" | sed 's/--filter-tcp= *$//; s/--filter-udp= *$//')
    # If filter-udp/tcp has trailing comma from removed GameFilter, clean it
    args=$(echo "$args" | sed 's/--filter-tcp=,/--filter-tcp=/g; s/--filter-udp=,/--filter-udp=/g')
    
    # Remove lines that become just empty filters (GameFilter-only lines)
    args=$(echo "$args" | sed 's/--filter-tcp= *--new/--new/g; s/--filter-udp= *--new/--new/g')
    # Remove trailing empty filter at end of args
    args=$(echo "$args" | sed 's/ *--filter-tcp= *$//; s/ *--filter-udp= *$//')
    
    # Clean up whitespace
    args=$(echo "$args" | tr -s ' ' | sed 's/^ //; s/ $//')
    
    # Format: --new on separate lines
    formatted=$(echo "$args" | sed 's/ --new /\n--new\n/g')
    
    # Write strategy file
    cat > "$out" << HEREDOC
#!/bin/bash
# Strategy: $name
# Source: $base.bat (v1.9.7)
# Note: \$BIN_DIR and \$LISTS_DIR are provided by zapret.sh

NFQWS_ARGS="
$formatted
"
HEREDOC
    
    chmod +x "$out"
    echo -e "${GREEN}OK${NC}: $base -> $name"
    ((count++))
done

echo ""
echo -e "${CYAN}=== Results ===${NC}"
echo -e "  Converted: ${GREEN}$count${NC}"
[[ $failed -gt 0 ]] && echo -e "  Failed:    ${RED}$failed${NC}"
echo -e "  Output:    $OUT_DIR"

#!/bin/bash
# Strategy: general (ALT5)
# Source: general (ALT5).bat (auto-converted)
# Note: $BIN_DIR and $LISTS_DIR are provided by zapret.sh

NFQWS_ARGS="
--filter-udp=1-65535 --filter-l7=discord,stun --dpi-desync=fake --dpi-desync-fake-discord=$BIN_DIR/quic_initial_dbankcloud_ru.bin --dpi-desync-fake-stun=$BIN_DIR/quic_initial_dbankcloud_ru.bin --dpi-desync-repeats=6
--new
--filter-l3=ipv4 --filter-tcp=1-65535 --ipset-exclude=$LISTS_DIR/ipset-exclude.txt --ipset-exclude=$LISTS_DIR/ipset-exclude-user.txt --dpi-desync=syndata,multidisorder
--new
--ipset=$LISTS_DIR/ipset-all.txt --ipset-exclude=$LISTS_DIR/ipset-exclude.txt --ipset-exclude=$LISTS_DIR/ipset-exclude-user.txt --dpi-desync=syndata,multidisorder --dpi-desync-any-protocol=1 --dpi-desync-cutoff=n3
--new
--filter-udp=1-65535 --ipset=$LISTS_DIR/ipset-all.txt --hostlist-exclude=$LISTS_DIR/list-exclude.txt --hostlist-exclude=$LISTS_DIR/list-exclude-user.txt --ipset-exclude=$LISTS_DIR/ipset-exclude.txt --ipset-exclude=$LISTS_DIR/ipset-exclude-user.txt --dpi-desync=fake --dpi-desync-repeats=6 --dpi-desync-fake-quic=$BIN_DIR/quic_initial_www_google_com.bin
--new
--ipset=$LISTS_DIR/ipset-all.txt --ipset-exclude=$LISTS_DIR/ipset-exclude.txt --ipset-exclude=$LISTS_DIR/ipset-exclude-user.txt --dpi-desync=fake --dpi-desync-repeats=14 --dpi-desync-any-protocol=1 --dpi-desync-fake-unknown-udp=$BIN_DIR/quic_initial_dbankcloud_ru.bin --dpi-desync-cutoff=n2
"

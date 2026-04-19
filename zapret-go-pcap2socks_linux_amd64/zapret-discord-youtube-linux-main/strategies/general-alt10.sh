#!/bin/bash
# Strategy: general-alt10
# Source: general (ALT10).bat (v1.9.7)
# Note: $BIN_DIR and $LISTS_DIR are provided by zapret.sh

NFQWS_ARGS="
--filter-udp=1-65535 --hostlist=$LISTS_DIR/list-general.txt --hostlist=$LISTS_DIR/list-general-user.txt --hostlist-exclude=$LISTS_DIR/list-exclude.txt --hostlist-exclude=$LISTS_DIR/list-exclude-user.txt --ipset-exclude=$LISTS_DIR/ipset-exclude.txt --ipset-exclude=$LISTS_DIR/ipset-exclude-user.txt --dpi-desync=fake --dpi-desync-repeats=6 --dpi-desync-fake-quic=$BIN_DIR/quic_initial_www_google_com.bin
--new
--filter-udp=1-65535 --filter-l7=discord,stun --dpi-desync=fake --dpi-desync-repeats=6
--new
--filter-tcp=1-65535 --hostlist-domains=discord.media --dpi-desync=fake --dpi-desync-repeats=6 --dpi-desync-fooling=ts --dpi-desync-fake-tls=$BIN_DIR/tls_clienthello_www_google_com.bin --dpi-desync-fake-tls-mod=none
--new
--filter-tcp=1-65535 --hostlist=$LISTS_DIR/list-google.txt --ip-id=zero --dpi-desync=fake --dpi-desync-repeats=6 --dpi-desync-fooling=ts --dpi-desync-fake-tls=$BIN_DIR/tls_clienthello_www_google_com.bin
--new
--filter-tcp=1-65535 --hostlist=$LISTS_DIR/list-general.txt --hostlist=$LISTS_DIR/list-general-user.txt --hostlist-exclude=$LISTS_DIR/list-exclude.txt --hostlist-exclude=$LISTS_DIR/list-exclude-user.txt --ipset-exclude=$LISTS_DIR/ipset-exclude.txt --ipset-exclude=$LISTS_DIR/ipset-exclude-user.txt --dpi-desync=fake --dpi-desync-repeats=6 --dpi-desync-fooling=ts --dpi-desync-fake-tls=$BIN_DIR/stun.bin --dpi-desync-fake-tls=$BIN_DIR/tls_clienthello_4pda_to.bin --dpi-desync-fake-http=$BIN_DIR/tls_clienthello_max_ru.bin
--new
--filter-udp=1-65535 --ipset=$LISTS_DIR/ipset-all.txt --hostlist-exclude=$LISTS_DIR/list-exclude.txt --hostlist-exclude=$LISTS_DIR/list-exclude-user.txt --ipset-exclude=$LISTS_DIR/ipset-exclude.txt --ipset-exclude=$LISTS_DIR/ipset-exclude-user.txt --dpi-desync=fake --dpi-desync-repeats=6 --dpi-desync-fake-quic=$BIN_DIR/quic_initial_www_google_com.bin
--new
--filter-tcp=1-65535 --ipset=$LISTS_DIR/ipset-all.txt --hostlist-exclude=$LISTS_DIR/list-exclude.txt --hostlist-exclude=$LISTS_DIR/list-exclude-user.txt --ipset-exclude=$LISTS_DIR/ipset-exclude.txt --ipset-exclude=$LISTS_DIR/ipset-exclude-user.txt --dpi-desync=fake --dpi-desync-repeats=6 --dpi-desync-fooling=ts --dpi-desync-fake-tls=$BIN_DIR/stun.bin --dpi-desync-fake-tls=$BIN_DIR/tls_clienthello_4pda_to.bin --dpi-desync-fake-http=$BIN_DIR/tls_clienthello_max_ru.bin
--new
--ipset=$LISTS_DIR/ipset-all.txt --ipset-exclude=$LISTS_DIR/ipset-exclude.txt --ipset-exclude=$LISTS_DIR/ipset-exclude-user.txt --dpi-desync=fake --dpi-desync-repeats=6 --dpi-desync-any-protocol=1 --dpi-desync-cutoff=n3 --dpi-desync-fooling=ts --dpi-desync-fake-tls=$BIN_DIR/stun.bin --dpi-desync-fake-tls=$BIN_DIR/tls_clienthello_4pda_to.bin --dpi-desync-fake-http=$BIN_DIR/tls_clienthello_max_ru.bin
--new
--ipset=$LISTS_DIR/ipset-all.txt --ipset-exclude=$LISTS_DIR/ipset-exclude.txt --ipset-exclude=$LISTS_DIR/ipset-exclude-user.txt --dpi-desync=fake --dpi-desync-repeats=12 --dpi-desync-any-protocol=1 --dpi-desync-fake-unknown-udp=$BIN_DIR/quic_initial_www_google_com.bin --dpi-desync-cutoff=n2
"

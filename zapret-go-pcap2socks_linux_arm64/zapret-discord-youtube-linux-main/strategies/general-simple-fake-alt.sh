#!/bin/bash
# Strategy: general-simple-fake-alt
# Source: general (SIMPLE FAKE ALT).bat (v1.9.7)
# Note: $BIN_DIR and $LISTS_DIR are provided by zapret.sh

NFQWS_ARGS="
--filter-udp=1-65535 --hostlist=$LISTS_DIR/list-general.txt --hostlist=$LISTS_DIR/list-general-user.txt --hostlist-exclude=$LISTS_DIR/list-exclude.txt --hostlist-exclude=$LISTS_DIR/list-exclude-user.txt --ipset-exclude=$LISTS_DIR/ipset-exclude.txt --ipset-exclude=$LISTS_DIR/ipset-exclude-user.txt --dpi-desync=fake --dpi-desync-repeats=6 --dpi-desync-fake-quic=$BIN_DIR/quic_initial_www_google_com.bin
--new
--filter-udp=19294-19344,50000-50100 --filter-l7=discord,stun --dpi-desync=fake --dpi-desync-repeats=6
--new
--filter-tcp=2053,2083,2087,2096,8443 --hostlist-domains=discord.media --dpi-desync=fake --dpi-desync-repeats=6 --dpi-desync-fooling=badseq --dpi-desync-badseq-increment=2 --dpi-desync-fake-tls=$BIN_DIR/tls_clienthello_www_google_com.bin
--new
--filter-tcp=443 --hostlist=$LISTS_DIR/list-google.txt --ip-id=zero --dpi-desync=fake --dpi-desync-repeats=6 --dpi-desync-fooling=badseq --dpi-desync-badseq-increment=2 --dpi-desync-fake-tls=$BIN_DIR/tls_clienthello_www_google_com.bin
--new
--filter-tcp=80,443 --hostlist=$LISTS_DIR/list-general.txt --hostlist=$LISTS_DIR/list-general-user.txt --hostlist-exclude=$LISTS_DIR/list-exclude.txt --hostlist-exclude=$LISTS_DIR/list-exclude-user.txt --ipset-exclude=$LISTS_DIR/ipset-exclude.txt --ipset-exclude=$LISTS_DIR/ipset-exclude-user.txt --dpi-desync=fake --dpi-desync-repeats=6 --dpi-desync-fooling=badseq --dpi-desync-badseq-increment=2 --dpi-desync-fake-tls=$BIN_DIR/stun.bin --dpi-desync-fake-tls=$BIN_DIR/tls_clienthello_www_google_com.bin --dpi-desync-fake-http=$BIN_DIR/tls_clienthello_max_ru.bin
--new
--filter-udp=443 --ipset=$LISTS_DIR/ipset-all.txt --hostlist-exclude=$LISTS_DIR/list-exclude.txt --hostlist-exclude=$LISTS_DIR/list-exclude-user.txt --ipset-exclude=$LISTS_DIR/ipset-exclude.txt --ipset-exclude=$LISTS_DIR/ipset-exclude-user.txt --dpi-desync=fake --dpi-desync-repeats=6 --dpi-desync-fake-quic=$BIN_DIR/quic_initial_www_google_com.bin
--new
--filter-tcp=80,443,8443 --ipset=$LISTS_DIR/ipset-all.txt --hostlist-exclude=$LISTS_DIR/list-exclude.txt --hostlist-exclude=$LISTS_DIR/list-exclude-user.txt --ipset-exclude=$LISTS_DIR/ipset-exclude.txt --ipset-exclude=$LISTS_DIR/ipset-exclude-user.txt --dpi-desync=fake --dpi-desync-repeats=6 --dpi-desync-fooling=badseq --dpi-desync-badseq-increment=2 --dpi-desync-fake-tls=$BIN_DIR/stun.bin --dpi-desync-fake-tls=$BIN_DIR/tls_clienthello_www_google_com.bin --dpi-desync-fake-http=$BIN_DIR/tls_clienthello_max_ru.bin
--new
--ipset=$LISTS_DIR/ipset-all.txt --ipset-exclude=$LISTS_DIR/ipset-exclude.txt --ipset-exclude=$LISTS_DIR/ipset-exclude-user.txt --dpi-desync=fake --dpi-desync-repeats=6 --dpi-desync-any-protocol=1 --dpi-desync-cutoff=n3 --dpi-desync-fooling=badseq --dpi-desync-badseq-increment=2 --dpi-desync-fake-tls=$BIN_DIR/stun.bin --dpi-desync-fake-tls=$BIN_DIR/tls_clienthello_www_google_com.bin --dpi-desync-fake-http=$BIN_DIR/tls_clienthello_max_ru.bin
--new
--ipset=$LISTS_DIR/ipset-all.txt --ipset-exclude=$LISTS_DIR/ipset-exclude.txt --ipset-exclude=$LISTS_DIR/ipset-exclude-user.txt --dpi-desync=fake --dpi-desync-repeats=10 --dpi-desync-any-protocol=1 --dpi-desync-fake-unknown-udp=$BIN_DIR/quic_initial_www_google_com.bin --dpi-desync-cutoff=n2
"

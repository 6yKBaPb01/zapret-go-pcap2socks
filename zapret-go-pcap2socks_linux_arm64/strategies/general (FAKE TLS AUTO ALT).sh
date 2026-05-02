#!/bin/bash
# Strategy: general (FAKE TLS AUTO ALT)
# Source: general (FAKE TLS AUTO ALT).bat (auto-converted)
# Note: $BIN_DIR and $LISTS_DIR are provided by zapret.sh

NFQWS_ARGS="
--filter-udp=1-65535 --filter-l7=discord,stun --dpi-desync=fake --dpi-desync-fake-discord=$BIN_DIR/quic_initial_dbankcloud_ru.bin --dpi-desync-fake-stun=$BIN_DIR/quic_initial_dbankcloud_ru.bin --dpi-desync-repeats=6
--new
--filter-tcp=1-65535 --hostlist-domains=discord.media --dpi-desync=multisplit --dpi-desync-split-pos=1 --dpi-desync-badseq-increment=2 --dpi-desync-repeats=8 --dpi-desync-fake-tls-mod=rnd,dupsid,sni=www.google.com --dpi-desync-split-seqovl=568 --dpi-desync-split-pos=1 --dpi-desync-split-seqovl-pattern=$BIN_DIR/tls_clienthello_4pda_to.bin
--new
--filter-tcp=1-65535 --hostlist=$LISTS_DIR/list-google.txt --ip-id=zero --dpi-desync=multisplit --dpi-desync-split-pos=1 --dpi-desync-badseq-increment=2 --dpi-desync-repeats=8 --dpi-desync-fake-tls-mod=rnd,dupsid,sni=www.google.com --dpi-desync-split-seqovl=568 --dpi-desync-split-pos=1 --dpi-desync-split-seqovl-pattern=$BIN_DIR/tls_clienthello_4pda_to.bin
--new
--filter-tcp=1-65535 --hostlist=$LISTS_DIR/list-general.txt --hostlist=$LISTS_DIR/list-general-user.txt --hostlist-exclude=$LISTS_DIR/list-exclude.txt --hostlist-exclude=$LISTS_DIR/list-exclude-user.txt --ipset-exclude=$LISTS_DIR/ipset-exclude.txt --ipset-exclude=$LISTS_DIR/ipset-exclude-user.txt --dpi-desync=multisplit --dpi-desync-split-pos=1 --dpi-desync-badseq-increment=2 --dpi-desync-repeats=8 --dpi-desync-fake-tls-mod=rnd,dupsid,sni=www.google.com --dpi-desync-split-seqovl=568 --dpi-desync-split-pos=1 --dpi-desync-split-seqovl-pattern=$BIN_DIR/tls_clienthello_4pda_to.bin
--new
--filter-udp=1-65535 --ipset=$LISTS_DIR/ipset-all.txt --hostlist-exclude=$LISTS_DIR/list-exclude.txt --hostlist-exclude=$LISTS_DIR/list-exclude-user.txt --ipset-exclude=$LISTS_DIR/ipset-exclude.txt --ipset-exclude=$LISTS_DIR/ipset-exclude-user.txt --dpi-desync=fake --dpi-desync-repeats=11 --dpi-desync-fake-quic=$BIN_DIR/quic_initial_www_google_com.bin
--new
--filter-tcp=1-65535 --ipset=$LISTS_DIR/ipset-all.txt --hostlist-exclude=$LISTS_DIR/list-exclude.txt --hostlist-exclude=$LISTS_DIR/list-exclude-user.txt --ipset-exclude=$LISTS_DIR/ipset-exclude.txt --ipset-exclude=$LISTS_DIR/ipset-exclude-user.txt --dpi-desync=multisplit --dpi-desync-split-pos=1 --dpi-desync-badseq-increment=2 --dpi-desync-repeats=8 --dpi-desync-fake-tls-mod=rnd,dupsid,sni=www.google.com --dpi-desync-split-seqovl=568 --dpi-desync-split-pos=1 --dpi-desync-split-seqovl-pattern=$BIN_DIR/tls_clienthello_4pda_to.bin
--new
--ipset=$LISTS_DIR/ipset-all.txt --ipset-exclude=$LISTS_DIR/ipset-exclude.txt --ipset-exclude=$LISTS_DIR/ipset-exclude-user.txt --dpi-desync=multisplit --dpi-desync-any-protocol=1 --dpi-desync-cutoff=n2 --dpi-desync-split-pos=1 --dpi-desync-badseq-increment=2 --dpi-desync-repeats=8 --dpi-desync-fake-tls-mod=rnd,dupsid,sni=www.google.com --dpi-desync-split-seqovl=568 --dpi-desync-split-pos=1 --dpi-desync-split-seqovl-pattern=$BIN_DIR/tls_clienthello_4pda_to.bin
--new
--ipset=$LISTS_DIR/ipset-all.txt --ipset-exclude=$LISTS_DIR/ipset-exclude.txt --ipset-exclude=$LISTS_DIR/ipset-exclude-user.txt --dpi-desync=fake --dpi-desync-repeats=10 --dpi-desync-any-protocol=1 --dpi-desync-fake-unknown-udp=$BIN_DIR/quic_initial_dbankcloud_ru.bin --dpi-desync-cutoff=n1
"

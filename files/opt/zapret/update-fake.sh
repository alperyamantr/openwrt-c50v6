#!/bin/sh
FAKE_DIR="/opt/zapret/files/fake"
LOG_FILE="/tmp/zapret-update.log"  # RAM disk, flash'e yazmaz

mkdir -p "$FAKE_DIR"
cd "$FAKE_DIR" || exit 1

echo "$(date) - Fake update started" >> "$LOG_FILE"

wget -q --no-check-certificate https://raw.githubusercontent.com/bol-van/zapret/master/files/fake/tls_clienthello_www_google_com.bin -O tls_clienthello_www_google_com.bin
wget -q --no-check-certificate https://raw.githubusercontent.com/bol-van/zapret/master/files/fake/quic_initial_www_google_com.bin -O quic_initial_www_google_com.bin
wget -q --no-check-certificate https://raw.githubusercontent.com/bol-van/zapret/master/files/fake/discord-ip-discovery-with-port.bin -O discord-ip-discovery-with-port.bin
wget -q --no-check-certificate https://raw.githubusercontent.com/bol-van/zapret/master/files/fake/stun.bin -O stun.bin

echo "$(date) - Fake update finished" >> "$LOG_FILE"
ls -l "$FAKE_DIR" >> "$LOG_FILE"

/etc/init.d/zapret restart
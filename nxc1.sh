#!/bin/bash

GREEN='\033[0;32m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
NC='\033[0m'

# --- 1. CEK UPDATE SCRIPT DARI GITHUB OTOMATIS ---
TEMP_SCRIPT="/tmp/nxc1_latest.sh"
curl -s -L "https://raw.githubusercontent.com/nxcode123/nx_code/main/nxc1.sh" -o "$TEMP_SCRIPT"

if [ -s "$TEMP_SCRIPT" ]; then
    LOCAL_HASH=$(md5sum "$0" | awk '{print $1}')
    ONLINE_HASH=$(md5sum "$TEMP_SCRIPT" | awk '{print $1}')

    if [ "$LOCAL_HASH" != "$ONLINE_HASH" ]; then
        echo -e "${GREEN}[+] Memperbarui nxc1.sh ke versi terbaru...${NC}"
        cp "$TEMP_SCRIPT" "$0"
        chmod +x "$0"
        rm -f "$TEMP_SCRIPT"
        exec "$0"
    fi
    rm -f "$TEMP_SCRIPT"
fi

# --- 2. TAMPILKAN LOGO NXC & STATUS SISTEM ---
clear
echo -e "${PURPLE}"
echo " _  _ _  _  ____ ____ ____  _ "
echo " |\ |  \/   |    |  | |___  | "
echo " | \| _/\_  |    |__| |     | "
echo -e "${NC}"
echo -e "${CYAN}========================================${NC}"
echo -e " Status : ${GREEN}Online & Siap Digunakan${NC}"
echo -e " Waktu  : $(date)"
echo -e " Host   : Proot Ubuntu"
echo -e "${CYAN}========================================${NC}"
echo ""

# --- 3. UPDATE & UPGRADE UBUNTU FULL OTOMATIS ---
echo -e "${CYAN}[*] Memeriksa pembaruan sistem Ubuntu...${NC}"
apt update -y && apt upgrade -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold"

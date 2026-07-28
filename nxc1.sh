#!/bin/bash

GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}[*] Memeriksa pembaruan script nxc1.sh dari GitHub...${NC}"

# Simpan temporary file untuk cek versi terbaru dari GitHub
TEMP_SCRIPT="/tmp/nxc1_latest.sh"
curl -s -L "https://raw.githubusercontent.com/nxcode123/nx_code/main/nxc1.sh" -o "$TEMP_SCRIPT"

if [ -s "$TEMP_SCRIPT" ]; then
    # Bandingkan file lokal dengan yang ada di GitHub menggunakan checksum (md5)
    LOCAL_HASH=$(md5sum "$0" | awk '{print $1}')
    ONLINE_HASH=$(md5sum "$TEMP_SCRIPT" | awk '{print $1}')

    if [ "$LOCAL_HASH" != "$ONLINE_HASH" ]; then
        echo -e "${GREEN}[+] Pembaruan ditemukan! Memperbarui nxc1.sh...${NC}"
        cp "$TEMP_SCRIPT" "$0"
        chmod +x "$0"
        echo -e "${GREEN}[+] Script berhasil diperbarui. Memuat ulang...${NC}"
        rm -f "$TEMP_SCRIPT"
        exec "$0"
    else
        echo -e "${GREEN}[+] Script sudah menggunakan versi terbaru.${NC}"
    fi
    rm -f "$TEMP_SCRIPT"
else
    echo -e "${RED}[!] Gagal memeriksa pembaruan (Cek koneksi internet).${NC}"
fi

# Update & Upgrade Ubuntu Full Otomatis
echo -e "${GREEN}[+] Menjalankan Update & Upgrade Ubuntu...${NC}"
apt update -y && apt upgrade -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold"

echo -e "${CYAN}[*] Sistem siap digunakan!${NC}"

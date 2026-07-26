#!/data/data/com.termux/files/usr/bin/bash

#===================================
# Nama file: installer.sh
# Repository: nxcode123/nx_code
# Version: v0.0.4
#===================================

set -e

REPO_URL="https://raw.githubusercontent.com/nxcode123/nx_code/main/installer.sh"
TEMP_FILE="/tmp/installer_latest.sh"

echo "[*] Memeriksa dan memastikan git terinstal..."
if ! command -v git &> /dev/null; then
    pkg install git -y
fi

echo "[*] Memeriksa pembaruan dari repository GitHub..."

if command -v curl &> /dev/null; then
    curl -s -o "$TEMP_FILE" "$REPO_URL"
elif command -v wget &> /dev/null; then
    wget -q -O "$TEMP_FILE" "$REPO_URL"
fi

if [ -f "$TEMP_FILE" ]; then
    if ! cmp -s "$0" "$TEMP_FILE"; then
        echo "[!] Ditemukan pembaruan baru untuk script ini di GitHub!"
        read -p "[?] Apakah Anda ingin mengupdate script ini sebelum melanjutkan? (y/n): " choice
        case "$choice" in 
          y|Y )
            echo "[*] Mengupdate script..."
            cp "$TEMP_FILE" "$0"
            chmod +x "$0"
            echo "[*] Script berhasil diupdate! Silakan jalankan ulang script."
            rm -f "$TEMP_FILE"
            exit 0
            ;;
          * )
            echo "[*] Melanjutkan dengan versi saat ini..."
            ;;
        esac
    else
        echo "[*] Script sudah menggunakan versi terbaru."
    fi
    rm -f "$TEMP_FILE"
fi

echo "[*] Memulai proses instalasi Ubuntu di Termux secara otomatis..."

# 1. Koneksikan storage (Termux Setup Storage)
echo "[*] Menghubungkan penyimpanan internal..."
termux-setup-storage -y || true

# 2. Update dan upgrade package Termux (Non-interaktif)
echo "[*] Melakukan update dan upgrade sistem Termux..."
export DEBIAN_FRONTEND=noninteractive
apt-get update -y && apt-get -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" upgrade

# 3. Install proot-distro
echo "[*] Menginstal proot-distro..."
pkg install proot-distro -y

# 4. Install distro Ubuntu
echo "[*] Menginstal distro Ubuntu..."
proot-distro install ubuntu

echo "[*] Instalasi selesai! Anda dapat menjalankan Ubuntu menggunakan perintah: proot-distro login ubuntu"

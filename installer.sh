#!/data/data/com.termux/files/usr/bin/bash

#===================================
# Nama file: installer.sh
# Repository: nxcode123/nx_code
# Version: v0.0.2
#===================================

set -e

echo "[*] Memulai proses instalasi Ubuntu di Termux secara otomatis..."

# 1. Koneksikan storage (Termux Setup Storage)
echo "[*] Menghubungkan penyimpanan internal..."
termux-setup-storage -y || true

# 2. Update dan upgrade package Termux (Non-interaktif untuk menghindari prompt konfigurasi)
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

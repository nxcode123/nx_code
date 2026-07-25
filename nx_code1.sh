#!/bin/bash

# Pastikan script berhenti jika terjadi error
set -e

echo "=========================================="
echo "    [TERMUX] Setup Awal & X11 Server     "
echo "=========================================="

# 1. Melakukan update dan upgrade otomatis di Termux
echo -e "\n[1/5] Melakukan Update & Upgrade Termux..."
pkg update -y && pkg upgrade -y

# 2. Menginstall repositori X11 dan Termux-X11
echo -e "\n[2/5] Menginstall X11 Repository & Termux-X11..."
pkg install x11-repo -y
pkg install termux-x11-nightly -y

# 3. Menginstall proot-distro otomatis
echo -e "\n[3/5] Memeriksa dan Menginstall proot-distro..."
if ! command -v proot-distro &> /dev/null; then
    pkg install proot-distro -y
else
    echo "proot-distro sudah terinstall."
fi

# 4. Menginstall proot-distro Ubuntu otomatis
echo -e "\n[4/5] Memeriksa dan Menginstall Ubuntu..."
if [ ! -d "$PREFIX/var/lib/proot-distro/installed-rootfs/ubuntu" ]; then
    proot-distro install ubuntu
else
    echo "Ubuntu sudah terinstall."
fi

# 5. Menyalin dan menanam nx_code2.sh menjadi perintah permanen (nxmenu) di Ubuntu
echo -e "\n[5/5] Menanam Menu Interaktif ke dalam Ubuntu..."
if [ -f "nx_code2.sh" ]; then
    # Salin ke root ubuntu terlebih dahulu
    cp nx_code2.sh "$PREFIX/var/lib/proot-distro/installed-rootfs/ubuntu/root/nx_code2.sh"
    
    # Pindahkan ke /usr/local/bin/nxmenu dan berikan izin eksekusi di dalam Ubuntu
    proot-distro login ubuntu -- bash -c "mv /root/nx_code2.sh /usr/local/bin/nxmenu && chmod +x /usr/local/bin/nxmenu"
    
    echo "Menu berhasil ditanam! Anda sekarang bisa menggunakan perintah 'nxmenu' di dalam Ubuntu."
else
    echo "PERINGATAN: File nx_code2.sh tidak ditemukan di direktori saat ini."
    echo "Pastikan file nx_code2.sh sudah ada di repository GitHub / folder Termux."
fi

echo "=========================================="
echo " Setup Termux Selesai! "
echo "=========================================="

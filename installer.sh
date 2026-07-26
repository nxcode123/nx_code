#!/bin/bash

# --- 1. SCRIPT UTAMA UNTUK MENGUBAH TAMPILAN, LOGO & PERINTAH MENU ---
cat << 'EOF' > ~/.bashrc
# --- Konfigurasi CLI Ubuntu nxcode123 ---

# Fungsi untuk Cek Update Otomatis dari GitHub setiap Termux/PRoot dibuka
auto_update_cli() {
    curl -s https://raw.githubusercontent.com/nxcode123/nx_code/main/update.sh > ~/.update_cache.sh
    if [ -s ~/.update_cache.sh ]; then
        bash ~/.update_cache.sh --silent
        rm ~/.update_cache.sh
    fi
}

# Jalankan cek update otomatis (kecuali mode silent)
if [ "$1" != "--silent" ]; then
    auto_update_cli
fi

# Fungsi untuk menampilkan Logo saja saat startup atau clear
a#!/data/data/com.termux/files/usr/bin/bash

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
show_logo() {
    clear
    echo -e "\e[1;36m"
    echo "  _  _       _                       ___ ___ ___  "
    echo " | \| |_  _ | |_____ ___ ___   ___   |_  ) _ \   \ "
    echo " | .^ | || || / / -_) _ Y -_) / -_)   / /| (_) | | |"
    echo " |_|\_|\_, ||_|_\___\_,_\___| \___|  /___|\___/|___/ "
    echo "       |__/                                          "
    echo -e "\e[0m"
    echo -e "\e[1;32m[*] Status: Ubuntu PRoot Connected & Synced from GitHub\e[0m"
    echo "-----------------------------------------------------"
}

# Fungsi untuk menampilkan Menu saat diketik 'menu'
menu() {
    show_logo
    echo -e "\e[1;33m[+] Menu\e[0m"
    echo ""
    echo -e "\e[1;32m[1]\e[0m Update"
    echo ""
    read -p "Pilih : " menu_choice

    if [ "$menu_choice" = "1" ]; then
        echo -e "\n\e[1;34m[*] Menjalankan update tema...\e[0m"
        bash <(curl -s https://raw.githubusercontent.com/nxcode123/nx_code/main/update.sh)
    fi
}

# Jalankan logo saat pertama kali dibuka
show_logo

# Desain Prompt (PS1)
PS1='\[\e[1;32m\]nxcode@ubuntu\[\e[0m\]:\[\e[1;34m\]\w\[\e[0m\]\$ '

# Alias Kustom: Mengganti fungsi 'clear' agar hanya menampilkan logo
alias clear='show_logo'
alias cls='show_logo'

# Alias untuk update manual
alias update-theme='bash <(curl -s https://raw.githubusercontent.com/nxcode123/nx_code/main/update.sh)'
# --- Akhir Konfigurasi ---
EOF

# Jika tidak dijalankan dalam mode silent, langsung muat ulang bashrc
if [ "$1" != "--silent" ]; then
    echo "✅ Tampilan CLI berhasil diperbarui dari GitHub!"
    source ~/.bashrc
fi

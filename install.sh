#!/bin/bash

echo "🚀 Memulai instalasi awal CLI Ubuntu untuk nxcode123..."

# 1. Update package manager termux/ubuntu dan install alat yang dibutuhkan
echo "📦 Menginstal dependensi dasar (curl, git)..."
apt update && apt upgrade -y
apt install curl git proot-distro -y

# 2. Pastikan Ubuntu PRoot terpasang (jika belum ada)
if [ ! -d "$PREFIX/var/lib/proot-distro/installed-rootfs/ubuntu" ]; then
    echo "🐧 Menginstal distribusi Ubuntu PRoot..."
    proot-distro install ubuntu
fi

# 3. Mengunduh file update.sh utama dari repository Anda ke dalam sistem
echo "📥 Mengunduh konfigurasi tampilan dari GitHub..."
curl -s https://raw.githubusercontent.com/nxcode123/nx_code/main/update.sh -o ~/.update_theme.sh

# 4. Jalankan skrip update untuk menerapkan tema dan logo ke ~/.bashrc
if [ -f ~/.update_theme.sh ]; then
    bash ~/.update_theme.sh
    rm ~/.update_theme.sh
fi

echo "✨ Instalasi selesai! Silakan restart Termux atau masuk ulang ke Ubuntu."

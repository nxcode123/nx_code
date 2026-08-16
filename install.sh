#!/data/data/com.termux/files/usr/bin/bash
# ==============================================================================
# PROJECT     : NX_CODE
# FILE        : install.sh
# DESCRIPTION : One-line Automatic Installer for Termux
# VERSION     : 1.3.1
# ==============================================================================

CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

clear
echo -e "${CYAN}======================================================${NC}"
echo -e "${GREEN}  🚀 Memulai Instalasi Otomatis NX_CODE untuk Termux   ${NC}"
echo -e "${CYAN}======================================================${NC}\n"

# 1. Guard: Pastikan berjalan di Termux
if [ ! -d "/data/data/com.termux" ]; then
    echo -e "${RED}[!] Error: Skrip ini dirancang khusus untuk dijalankan di Termux Android!${NC}"
    exit 1
fi

# 2. Hubungkan Storage Android
if [ ! -d "$HOME/storage" ]; then
    echo -e "${CYAN}[*] Menghubungkan penyimpanan internal Android...${NC}"
    termux-setup-storage
fi

# 3. Update package manager & install dependensi
echo -e "${CYAN}[*] Memperbarui repositori dan memasang dependensi (curl, git, proot-distro)...${NC}"
export DEBIAN_FRONTEND=noninteractive
pkg update -y >/dev/null 2>&1
pkg install curl git proot-distro -y >/dev/null 2>&1

# 4. Pastikan Ubuntu PRoot terpasang
UBUNTU_ROOT="$PREFIX/var/lib/proot-distro/installed-rootfs/ubuntu"
if [ ! -d "$UBUNTU_ROOT" ]; then
    echo -e "${CYAN}[*] Mengunduh dan memasang distribusi Ubuntu PRoot...${NC}"
    proot-distro install ubuntu
else
    echo -e "${GREEN}[✔] Sistem Ubuntu PRoot sudah terpasang.${NC}"
fi

# 5. Jalankan skrip setup utama nx_code.sh dari GitHub
echo -e "${CYAN}[*] Mengunduh konfigurasi utama NX_CODE dari GitHub...${NC}"
SETUP_FILE="$HOME/nx_code.sh"
GITHUB_URL="https://raw.githubusercontent.com/nxcode123/nx_code/main/nx_code.sh"

if curl -fsSL --max-time 15 "$GITHUB_URL" -o "$SETUP_FILE"; then
    chmod +x "$SETUP_FILE"
    echo -e "${GREEN}[✔] Menjalankan proses inisialisasi lingkungan...${NC}\n"
    bash "$SETUP_FILE"
else
    echo -e "${RED}[!] Gagal mengunduh nx_code.sh dari GitHub. Menjalankan fallback lokal...${NC}"
    if [ -f "./nx_code.sh" ]; then
        bash "./nx_code.sh"
    fi
fi

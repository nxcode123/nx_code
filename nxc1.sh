#!/bin/bash

# ==============================================================================
# PROJECT: NXC - TERMUX-UBUNTU
# DESCRIPTION: Automated Termux-to-Ubuntu Proot Bridge with Auto-Update & UI
# VERSION: 1.1.0
# ==============================================================================

SCRIPT_VERSION="1.1.0"

# Warna ANSI untuk estetika cyberpunk / futuristic
CYAN='\033[1;36m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
RED='\033[1;31m'
PURPLE='\033[1;35m'
DARK_GRAY='\033[38;5;238m'
NC='\033[0m' # No Color

export DEBIAN_FRONTEND=noninteractive

while true; do
    clear
    echo -e "${GREEN}NXC - TERMUX-UBUNTU // CONTROL [v${SCRIPT_VERSION}]${NC}"
    echo -e "${DARK_GRAY}----------------------------------------${NC}"
    echo -e "${YELLOW} [1]${NC} System Status & Resource Info"
    echo -e "${YELLOW} [2]${NC} Update & Upgrade Ubuntu Packages"
    echo -e "${YELLOW} [3]${NC} Buka Bash Shell Biasa (CLI)"
    echo -e "${YELLOW} [4]${NC} Refresh / Update Menu Script"
    echo -e "${YELLOW} [0]${NC} Keluar / Exit ke Termux Host"
    echo -e "${DARK_GRAY}----------------------------------------${NC}"
    read -p "Pilih opsi [0-4]: " choice

    case $choice in
        1)
            clear
            echo -e "${GREEN}[*] Memeriksa status sistem...${NC}"
            neofetch 2>/dev/null || uname -a
            echo ""
            free -h
            echo ""
            df -h
            echo ""
            read -p "Tekan [Enter] untuk kembali ke menu..."
            ;;
        2)
            clear
            echo -e "${GREEN}[*] Mengupdate repositori Ubuntu...${NC}"
            apt update && apt upgrade -y
            read -p "Tekan [Enter] untuk kembali ke menu..."
            ;;
        3)
            echo -e "${GREEN}[*] Masuk ke Bash Shell Ubuntu. Ketik 'exit' untuk kembali ke menu.${NC}"
            bash
            ;;
        4)
            clear
            echo -e "${CYAN}[*] Menghubungkan ke Server Satelit (GitHub)...${NC}"
            echo -e "${YELLOW}[*] Mengunduh pembaruan script...${NC}"

            # URL GitHub dari script menu Anda
            GITHUB_URL="https://raw.githubusercontent.com/nxcode123/nx_code/main/nxc1.sh"

            if curl -s -L "$GITHUB_URL" -o "$HOME/nxc1.sh"; then
                chmod +x "$HOME/nxc1.sh"
                echo -e "${GREEN}[✔] Neural Link disinkronkan! Script berhasil diperbarui.${NC}"
                echo -e "${GREEN}[*] Memuat ulang antarmuka...${NC}"
                sleep 1.5
                exec bash "$HOME/nxc1.sh" # Perintah ini akan langsung me-restart script
            else
                echo -e "${RED}[✖] Gagal terhubung ke GitHub! Periksa koneksi internet Anda.${NC}"
                read -p "Tekan [Enter] untuk kembali ke menu..."
            fi
            ;;
        0)
            echo -e "${RED}[*] Memutus Neural Link... Kembali ke Termux.${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}[!] Opsi tidak valid!${NC}"
            sleep 1
            ;;
    esac
done

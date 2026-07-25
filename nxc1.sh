#!/bin/bash

# ==============================================================================
# PROJECT: NXC - TERMUX-UBUNTU
# DESCRIPTION: Ubuntu Control Menu (Fully Synchronized with nxc_lib.sh)
# VERSION: 1.1.3
# ==============================================================================

SCRIPT_VERSION="1.1.3"
MENU_PATH="/root/nxc1.sh"
GITHUB_URL="https://raw.githubusercontent.com/nxcode123/nx_code/main/nxc1.sh"
export LOG_FILE="/root/nxc_menu.log"

# Load Shared Library dari rootfs Ubuntu
if [ -f "/root/nxc_lib.sh" ]; then
    source "/root/nxc_lib.sh"
else
    # Fallback warna & fungsi jika library tidak ditemukan
    CYBER_BLUE='\033[38;5;39m'
    TOXIC_GREEN='\033[38;5;46m'
    CORRUPT_RED='\033[38;5;196m'
    YELLOW='\033[1;33m'
    LIGHT_GRAY='\033[38;5;250m'
    DARK_GRAY='\033[38;5;240m'
    WHITE='\033[1;37m'
    NC='\033[0m'
    show_banner() { clear; echo -e "==> ${1} (v${2})\n"; }
fi

export DEBIAN_FRONTEND=noninteractive

while true; do
    clear
    # Menggunakan fungsi banner terpusat dari nxc_lib.sh
    if command -v show_banner &> /dev/null; then
        show_banner "UBUNTU CONTROL PANEL" "$SCRIPT_VERSION"
    else
        echo -e "${CYBER_BLUE}==>${WHITE} NXC - UBUNTU CONTROL ${DARK_GRAY}(v${SCRIPT_VERSION})${NC}\n"
    fi
    
    echo -e "${YELLOW} [1]${NC} Cek Status Sistem & Resource"
    echo -e "${YELLOW} [2]${NC} Update & Upgrade Paket Ubuntu"
    echo -e "${YELLOW} [3]${NC} Buka Bash Shell Ubuntu (CLI)"
    echo -e "${YELLOW} [4]${NC} Perbarui Menu Script (Refresh)"
    echo -e "${YELLOW} [0]${NC} Keluar ke Termux Host"
    echo -e "${DARK_GRAY}----------------------------------------${NC}"
    read -p "Pilih opsi [0-4]: " choice

    case $choice in
        1)
            clear
            echo -e "${CYBER_BLUE}[*] Memeriksa status sistem...${NC}"
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
            echo -e "${CYBER_BLUE}[*] Mengupdate repositori Ubuntu...${NC}"
            apt update && apt upgrade -y
            read -p "Tekan [Enter] untuk kembali ke menu..."
            ;;
        3)
            echo -e "${TOXIC_GREEN}[*] Masuk ke Bash Shell. Ketik 'exit' untuk kembali ke menu.${NC}"
            bash
            ;;
        4)
            clear
            echo -e "${CYBER_BLUE}[*] Menghubungkan ke server GitHub...${NC}"
            echo -e "${YELLOW}[*] Mengunduh pembaruan script menu...${NC}"

            # Menggunakan fungsi aman download_and_validate dari nxc_lib.sh
            if command -v download_and_validate &> /dev/null; then
                if download_and_validate "$GITHUB_URL" "$MENU_PATH" 3 10; then
                    echo -e "${TOXIC_GREEN}[✔] Script menu berhasil divalidasi dan diperbarui!${NC}"
                    sleep 1.5
                    exec bash "$MENU_PATH"
                else
                    echo -e "${CORRUPT_RED}[✖] Gagal mengunduh atau validasi syntax gagal!${NC}"
                    read -p "Tekan [Enter] untuk kembali ke menu..."
                fi
            else
                # Fallback manual jika library gagal dimuat
                if curl -s -L "$GITHUB_URL" -o "$MENU_PATH"; then
                    chmod +x "$MENU_PATH"
                    echo -e "${TOXIC_GREEN}[✔] Script menu berhasil diperbarui!${NC}"
                    sleep 1.5
                    exec bash "$MENU_PATH"
                else
                    echo -e "${CORRUPT_RED}[✖] Gagal terhubung ke GitHub! Periksa koneksi internet.${NC}"
                    read -p "Tekan [Enter] untuk kembali ke menu..."
                fi
            fi
            ;;
        0)
            echo -e "${CORRUPT_RED}[*] Keluar dari Ubuntu... Kembali ke Termux.${NC}"
            exit 0
            ;;
        *)
            echo -e "${CORRUPT_RED}[!] Opsi tidak valid!${NC}"
            sleep 1
            ;;
    esac
done

#!/bin/bash

# Warna ANSI untuk estetika cyberpunk / futuristic
CYAN='\033[1;36m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
RED='\033[1;31m'
PURPLE='\033[1;35m'
NC='\033[0m' # No Color

while true; do
    clear
    echo -e "${CYAN}==================================================${NC}"
    echo -e "${PURPLE}       N X C - U B U N T U   C O N T R O L         ${NC}"
    echo -e "${CYAN}==================================================${NC}"
    echo -e "${YELLOW} [1]${NC} System Status & Resource Info"
    echo -e "${YELLOW} [2]${NC} Update & Upgrade Ubuntu Packages"
    echo -e "${YELLOW} [3]${NC} Buka Bash Shell Biasa (CLI)"
    echo -e "${YELLOW} [0]${NC} Keluar / Exit ke Termux Host"
    echo -e "${CYAN}==================================================${NC}"
    read -p "Pilih opsi [0-3]: " choice

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

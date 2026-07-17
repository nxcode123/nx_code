#!/bin/bash
# ==============================================================================
# MODUL TOOLS – Dev Tools Installer (otomatis install Ubuntu jika perlu)
# ==============================================================================

install_dev_tools() {
    if ! install_ubuntu_if_needed; then
        echo -e "${ERROR} Ubuntu tidak tersedia."
        return 1
    fi

    while true; do
        echo -e "\n${PURPLE}------------------------------------------------------"
        echo -e "${WHITE}DEV-TOOLS INSTALLER"
        echo -e " ${PURPLE}[1]${NC} All (git, python, nodejs, build-essential, curl, wget, vim)"
        echo -e " ${PURPLE}[2]${NC} Git"
        echo -e " ${PURPLE}[3]${NC} Python3+pip"
        echo -e " ${PURPLE}[4]${NC} Node.js+npm"
        echo -e " ${PURPLE}[5]${NC} Build-essential"
        echo -e " ${PURPLE}[6]${NC} Kembali"
        echo -ne "${CYAN}[?] Pilihan: ${NC}"
        read choice
        local pkgs=""
        case "$choice" in
            1) pkgs="git python3 python3-pip nodejs npm build-essential curl wget vim nano" ;;
            2) pkgs="git" ;;
            3) pkgs="python3 python3-pip" ;;
            4) pkgs="nodejs npm" ;;
            5) pkgs="build-essential" ;;
            6) break ;;
            *) echo -e "${ERROR} Pilihan tidak valid."; continue ;;
        esac
        echo -e "${PROCESS} Menginstall $pkgs ..."
        proot-distro login ubuntu -- bash -c "apt update && apt install -y $pkgs"
        echo -e "${SUCCESS} Selesai."
    done
}

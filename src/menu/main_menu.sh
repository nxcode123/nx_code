#!/bin/bash
# ==============================================================================
# MENU UTAMA NX_CODE
# ==============================================================================

show_main_menu() {
    animate_logo
    echo -e "${NEON_PINK}======================================================"
    echo -e "${WHITE}           NX_CODE CORE v${VERSION}                    ${NC}"
    echo -e "${NEON_PINK}======================================================"
    echo -e " ${PURPLE}[1]${NC} Ubuntu CLI"
    echo -e " ${PURPLE}[2]${NC} Ubuntu GUI (XFCE4)"
    echo -e " ${PURPLE}[3]${NC} Kill GUI"
    echo -e " ${PURPLE}[4]${NC} Dev-Tools Installer"
    echo -e " ${PURPLE}[5]${NC} Backup Manager"
    echo -e " ${PURPLE}[6]${NC} Update Script"
    echo -e " ${PURPLE}[7]${NC} System Info"
    echo -e " ${PURPLE}[8]${NC} Exit"
    echo -e "${NEON_PINK}======================================================"
    echo -ne "${CYAN}[?] Pilih: ${NC}"
    read choice

    case "$choice" in
        1) ubuntu_cli; sleep 1; show_main_menu ;;
        2) launch_gui; sleep 1; show_main_menu ;;
        3) kill_gui; sleep 1; show_main_menu ;;
        4) install_dev_tools; sleep 1; show_main_menu ;;
        5) manage_backup_menu; sleep 1; show_main_menu ;;
        6) auto_update --force; sleep 1; show_main_menu ;;
        7) show_system_info; echo -e "\n${PURPLE}Tekan Enter...${NC}"; read; show_main_menu ;;
        8) echo -e "\n${NEON_GREEN}Goodbye!${NC}"; exit 0 ;;
        *) echo -e "${ERROR} Pilihan tidak valid."; sleep 1; show_main_menu ;;
    esac
}

show_system_info() {
    echo -e "\n${PURPLE}------------------------------------------------------"
    echo -e "${WHITE}SYSTEM INFO"
    echo -e "${PURPLE}------------------------------------------------------"
    echo -e "${CYAN}OS:${NC} $(uname -a)"
    echo -e "${CYAN}Kernel:${NC} $(uname -r)"
    echo -e "${CYAN}Arch:${NC} $(uname -m)"
    echo -e "${CYAN}Storage:${NC}"
    df -h /data /sdcard 2>/dev/null | awk '{print "  " $0}'
    echo -e "${CYAN}Packages:${NC} $(dpkg -l 2>/dev/null | grep "^ii" | wc -l)"
    echo -e "${CYAN}Version:${NC} ${NEON_PINK}${VERSION}${NC}"
    echo -e "${PURPLE}------------------------------------------------------"
}

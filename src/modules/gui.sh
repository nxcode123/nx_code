#!/bin/bash
# ==============================================================================
# MODUL GUI – Auto-install XFCE4, Termux:X11, dan jalankan GUI
# ==============================================================================

is_xfce4_installed() {
    proot-distro login ubuntu -- bash -c "command -v startxfce4" >/dev/null 2>&1
}

install_xfce4_if_needed() {
    if is_xfce4_installed; then
        return 0
    fi

    echo -e "${PROCESS} ${CYAN}XFCE4 belum terinstall. Menginstall sekarang...${NC}"
    echo -e "${PURPLE}Proses ini memakan waktu (~100-200 MB).${NC}"

    if ! install_ubuntu_if_needed; then
        echo -e "${ERROR} Ubuntu tidak tersedia."
        return 1
    fi

    # Install Termux:X11 jika belum
    if ! command -v termux-x11 >/dev/null; then
        pkg install x11-repo termux-x11-nightly -y
    fi

    proot-distro login ubuntu -- bash -c "apt update && apt install -y xfce4 xfce4-goodies dbus-x11 x11-xserver-utils"
    if is_xfce4_installed; then
        echo -e "${SUCCESS} XFCE4 berhasil diinstall."
        log_info "XFCE4 installed"
        return 0
    else
        echo -e "${ERROR} Gagal install XFCE4."
        log_error "XFCE4 installation failed"
        return 1
    fi
}

choose_resolution() {
    GUI_CANCELLED=0
    echo -e "\n${PURPLE}------------------------------------------------------"
    echo -e "${WHITE}Pilih resolusi GUI:"
    echo -e " ${PURPLE}[1]${NC} Custom"
    echo -e " ${PURPLE}[2]${NC} Native"
    echo -e " ${PURPLE}[3]${NC} 720x1440"
    echo -e " ${PURPLE}[4]${NC} 1080x1920"
    echo -e " ${PURPLE}[5]${NC} Batal"
    echo -ne "${CYAN}[?] Pilihan: ${NC}"
    read res_choice
    case "$res_choice" in
        1) echo -ne "Masukkan WIDTHxHEIGHT: "; read custom_res
           [[ "$custom_res" =~ ^([0-9]+)x([0-9]+)$ ]] && { RES_W="${BASH_REMATCH[1]}"; RES_H="${BASH_REMATCH[2]}"; } || { RES_W="720"; RES_H="1440"; } ;;
        2) RES_W=""; RES_H="" ;;
        3) RES_W="720"; RES_H="1440" ;;
        4) RES_W="1080"; RES_H="1920" ;;
        5) GUI_CANCELLED=1 ;;
        *) RES_W="720"; RES_H="1440" ;;
    esac
}

write_gui_startup_script() {
    proot-distro login ubuntu -- bash -c "cat > /root/.nx_startup.sh" << EOF
#!/bin/bash
export DISPLAY=:2
sleep 2
OUT=\$(xrandr | grep " connected" | head -n1 | awk '{print \$1}')
if [ -n "$RES_W" ]; then
    MODELINE=\$(cvt $RES_W $RES_H 60 2>/dev/null | grep Modeline)
    if [ -n "\$MODELINE" ]; then
        MODE_NAME=\$(echo "\$MODELINE" | awk '{print \$2}' | tr -d '"')
        MODE_PARAMS=\$(echo "\$MODELINE" | cut -d' ' -f3-)
        xrandr --newmode "\$MODE_NAME" \$MODE_PARAMS 2>/dev/null
        xrandr --addmode "\$OUT" "\$MODE_NAME" 2>/dev/null
        xrandr --output "\$OUT" --mode "\$MODE_NAME" 2>/dev/null
    fi
fi
dbus-launch --exit-with-session startxfce4
EOF
    proot-distro login ubuntu -- bash -c "chmod +x /root/.nx_startup.sh"
}

launch_gui() {
    if ! install_xfce4_if_needed; then
        echo -e "${ERROR} Tidak bisa melanjutkan tanpa XFCE4."
        return 1
    fi
    choose_resolution
    [ $GUI_CANCELLED -eq 1 ] && return 0
    write_gui_startup_script
    pkill -f "termux-x11 :2" 2>/dev/null; sleep 1
    echo -e "${PROCESS} Menjalankan X11 server..."
    setsid termux-x11 :2 -xstartup "proot-distro login ubuntu --shared-tmp $(storage_bind_args) -- bash /root/.nx_startup.sh" >/dev/null 2>&1 &
    local pid=$!
    sleep 2
    kill -0 "$pid" 2>/dev/null || { echo -e "${ERROR} Gagal start X11."; return 1; }
    am start --user 0 -n com.termux.x11/com.termux.x11.MainActivity >/dev/null 2>&1
    echo -e "${NEON_GREEN}[➔] GUI running. Tutup aplikasi Termux:X11 untuk kembali."
    tail --pid=$pid -f /dev/null 2>/dev/null
    echo -e "\n${NEON_GREEN}[➔] GUI ditutup."
}

kill_gui() {
    echo -e "${PROCESS} Mematikan GUI..."
    pkill -f "termux-x11" && echo -e "${SUCCESS} Termux-X11 dimatikan."
    proot-distro login ubuntu -- bash -c "pkill -f 'xfce4|dbus-launch'" 2>/dev/null
}

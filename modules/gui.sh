# ==============================================================================
# [MODULE] GUI MANAGEMENT & XFCE4 LAUNCHER
# ==============================================================================

choose_resolution() {
    GUI_CANCELLED=0
    echo -e "\n${PURPLE}──────────────────────────────────────────────────────${NC}"
    echo -e "${WHITE}Pilih Resolusi Tampilan GUI:${NC}"
    echo -e " ${PURPLE}[1]${NC} ${WHITE}Custom Resolution${NC}"
    echo -e " ${PURPLE}[2]${NC} ${WHITE}Native Display${NC}"
    echo -e " ${PURPLE}[3]${NC} ${WHITE}Kembali${NC}"
    echo -e "${PURPLE}──────────────────────────────────────────────────────${NC}"
    echo -ne "${CYAN}[?] Pilihan ➔ ${NC}"
    read res_choice

    case "$res_choice" in
        1)
            echo -ne "${CYAN}[?] Masukkan resolusi (WIDTHxHEIGHT): ${NC}"
            read custom_res
            if [[ "$custom_res" =~ ^([0-9]+)x([0-9]+)$ ]]; then
                RES_W="${BASH_REMATCH[1]}"; RES_H="${BASH_REMATCH[2]}"
            else
                RES_W="720"; RES_H="1440"
            fi
            ;;
        2) RES_W=""; RES_H="" ;;
        3) GUI_CANCELLED=1 ;;
        *) RES_W="720"; RES_H="1440" ;;
    esac
}

write_gui_startup_script() {
    proot-distro login ubuntu -- bash -c "cat > /usr/local/bin/nx-gui-startup.sh" << EOF
#!/bin/bash
export DISPLAY=:2
export ELECTRON_DISABLE_SANDBOX=true
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
    proot-distro login ubuntu -- bash -c "chmod 755 /usr/local/bin/nx-gui-startup.sh"
}

launch_ubuntu_gui() {
    if ! is_ubuntu_installed || ! is_termux_x11_installed; then
        echo -e "\n${NEON_PINK}[ERR] Ubuntu OS atau Termux:X11 belum terinstal sempurna.${NC}"
        return 1
    fi

    if ! is_xfce4_installed; then
        execute_task "Instalasi XFCE4" proot-distro login ubuntu -- bash -c "DEBIAN_FRONTEND=noninteractive apt update && DEBIAN_FRONTEND=noninteractive apt upgrade -y && DEBIAN_FRONTEND=noninteractive apt install xfce4 xfce4-goodies dbus-x11 x11-xserver-utils sudo tzdata -y"
        if ! is_xfce4_installed; then return 1; fi
    fi

    if ! proot-distro login ubuntu -- bash -c "[ -f /usr/share/xfce4/backdrops/xubuntu-wallpaper.png ]" >/dev/null 2>&1; then
        proot-distro login ubuntu -- bash -c "mkdir -p /usr/share/xfce4/backdrops && echo 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=' | base64 -d > /usr/share/xfce4/backdrops/xubuntu-wallpaper.png" 2>/dev/null
    fi

    if ! is_nonroot_user_setup; then
        execute_task "Konfigurasi User" setup_nonroot_user
    fi

    choose_resolution
    [ "$GUI_CANCELLED" -eq 1 ] && return 0

    write_gui_startup_script
    pkill -f "termux-x11" >/dev/null 2>&1
    sleep 1

    local launch_user="--user $NX_USER"
    ! is_nonroot_user_setup && launch_user=""

    cat > "$HOME/.nx_x11_launch.sh" << WRAPEOF
#!/data/data/com.termux/files/usr/bin/bash
proot-distro login ubuntu --shared-tmp $launch_user -- bash /usr/local/bin/nx-gui-startup.sh
WRAPEOF
    chmod +x "$HOME/.nx_x11_launch.sh"

    termux-x11 :2 -xstartup "bash $HOME/.nx_x11_launch.sh" >/dev/null 2>&1 &
    X11_PID=$!
    sleep 2

    am start --user 0 -n com.termux.x11/com.termux.x11.MainActivity >/dev/null 2>&1
    show_live_progress "GUI Session Active" "$X11_PID" "/dev/null"
    wait "$X11_PID" 2>/dev/null
}

kill_ubuntu_gui() {
    echo -e "\n${PROCESS} ${CYAN}Menghentikan sesi GUI...${NC}"
    pkill -f "termux-x11" >/dev/null 2>&1
    proot-distro login ubuntu -- bash -c "pkill -f 'xfce4|dbus-launch|Xwayland'" >/dev/null 2>&1
    sleep 1
    echo -e "${SUCCESS} ${WHITE}Sesi GUI dihentikan.${NC}"
}

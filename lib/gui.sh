#!/data/data/com.termux/files/usr/bin/bash
# ==============================================================================
# lib/gui.sh — GUI & Audio Management
# Dimuat oleh: nx_code.sh
# Dependensi: lib/config.sh, lib/ui.sh
# ==============================================================================

# --- System Checkers ---
is_termux_x11_installed() { command -v termux-x11 >/dev/null 2>&1; }
is_storage_setup()        { [ -d "$HOME/storage/shared" ]; }
is_mc_installed()         { command -v mc >/dev/null 2>&1; }
is_ubuntu_installed()     { ubuntu_login -- true >/dev/null 2>&1; }
is_xfce4_installed()      { ubuntu_login -- bash -c "command -v startxfce4" >/dev/null 2>&1; }
is_nonroot_user_setup()   { ubuntu_login -- bash -c "id $NX_USER" >/dev/null 2>&1; }

# ------------------------------------------------------------------------------
# ensure_storage_setup
#   Minta izin Shared Storage jika belum disetup
# ------------------------------------------------------------------------------
ensure_storage_setup() {
    if ! is_storage_setup; then
        echo -e "\n${NEON_PINK}[SYS]${NC} ${WHITE}Meminta izin akses Shared Storage...${NC}"
        echo -e "${PURPLE}      Perhatikan layar perangkat Anda dan pilih 'Allow / Izinkan'.${NC}"
        termux-setup-storage
        sleep 2
    fi
}

# ------------------------------------------------------------------------------
# ubuntu_login [args...]
#   Wrapper proot-distro login ubuntu dengan bind storage otomatis
# ------------------------------------------------------------------------------
ubuntu_login() {
    local bind_args=()
    if is_storage_setup; then
        bind_args=(--bind "$HOME/storage/shared:/storage/shared")
    fi
    proot-distro login ubuntu "${bind_args[@]}" "$@"
}

# --- Audio ---
start_pulseaudio() {
    if command -v pulseaudio >/dev/null 2>&1; then
        pkill -f "pulseaudio" >/dev/null 2>&1 || true
        sleep 0.3
        pulseaudio --start \
            --load="module-native-protocol-tcp auth-ip-acl=127.0.0.1 auth-anonymous=1" \
            --exit-idle-time=-1 >/dev/null 2>&1 || true
    fi
}

stop_pulseaudio() {
    pkill -f "pulseaudio" >/dev/null 2>&1 || true
}

# ------------------------------------------------------------------------------
# setup_nonroot_user
#   Buat user non-root di Ubuntu + konfigurasi PulseAudio, ALSA, env global
# ------------------------------------------------------------------------------
setup_nonroot_user() {
    ubuntu_login -- bash -c "
        if ! id $NX_USER >/dev/null 2>&1; then
            useradd -m -s /bin/bash $NX_USER 2>/dev/null
        fi
        usermod -aG sudo,audio,video $NX_USER 2>/dev/null || true
        echo '$NX_USER ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/$NX_USER
        chmod 0440 /etc/sudoers.d/$NX_USER
        mkdir -p /storage/shared && chmod -R 777 /storage

        # Banner helper di dalam Ubuntu
        cat > /usr/local/bin/nx-menu << 'EOF_NX_UBUNTU'
#!/bin/bash
echo -e \"\033[1;95m╔══════════════════════════════════════════════════════╗\033[0m\"
echo -e \"\033[1;36m              NX_CODE - UBUNTU ENVIRONMENT             \033[0m\"
echo -e \"\033[1;95m╚══════════════════════════════════════════════════════╝\033[0m\"
echo -e \"\033[1;33m[!] Anda saat ini berada di dalam terminal Ubuntu CLI.\033[0m\"
echo -e \"\033[0;36m[➔] Ketik \033[1;32mexit\033[0;36m lalu jalankan \033[1;36mnx-menu\033[0;36m di Termux.\n\033[0m\"
EOF_NX_UBUNTU
        chmod 755 /usr/local/bin/nx-menu

        # PulseAudio client config (cegah autospawn + hubungkan ke Termux)
        mkdir -p /etc/pulse
        cat > /etc/pulse/client.conf << 'EOF_PULSE_CLIENT'
default-server = 127.0.0.1
autospawn = no
EOF_PULSE_CLIENT
        chmod 644 /etc/pulse/client.conf 2>/dev/null

        # ALSA → PulseAudio bridge
        cat > /etc/asound.conf << 'EOF_ASOUND'
pcm.!default {
    type pulse
    fallback \"sysdefault\"
}
ctl.!default {
    type pulse
    fallback \"sysdefault\"
}
EOF_ASOUND
        chmod 644 /etc/asound.conf 2>/dev/null

        # Script uji audio
        cat > /usr/local/bin/nx-audio-test << 'EOF_AUDIO_TEST'
#!/bin/bash
echo -e \"\033[0;36m[➔] Menguji koneksi audio PulseAudio ke Termux...\033[0m\"
export PULSE_SERVER=127.0.0.1
if command -v pactl >/dev/null 2>&1; then
    if pactl info >/dev/null 2>&1; then
        echo -e \"\033[1;32m[✔] Server PulseAudio terdeteksi dan terhubung!\033[0m\"
        echo -e \"\033[0;35m    Server String : \033[1;37m\$(pactl info 2>/dev/null | grep 'Server String' | cut -d: -f2-)\033[0m\"
        echo -e \"\033[0;35m    Default Sink  : \033[1;37m\$(pactl info 2>/dev/null | grep 'Default Sink' | cut -d: -f2-)\033[0m\"
        if command -v paplay >/dev/null 2>&1 && [ -f /usr/share/sounds/freedesktop/stereo/complete.oga ]; then
            echo -e \"\033[0;36m[➔] Memutar suara uji coba (paplay)...\033[0m\"
            paplay /usr/share/sounds/freedesktop/stereo/complete.oga 2>/dev/null || true
        elif command -v speaker-test >/dev/null 2>&1; then
            echo -e \"\033[0;36m[➔] Memutar nada uji coba 1 detik...\033[0m\"
            speaker-test -t sine -f 440 -l 1 >/dev/null 2>&1 || true
        fi
        echo -e \"\033[1;32m[✔] Pengujian audio selesai.\033[0m\"
    else
        echo -e \"\033[1;91m[✘] Tidak dapat terhubung ke PulseAudio server (127.0.0.1:4713).\033[0m\"
        echo -e \"\033[1;33m    Pastikan PulseAudio aktif di Termux dengan menjalankan nx-menu.\033[0m\"
    fi
else
    echo -e \"\033[1;33m[!] pulseaudio-utils belum terinstal. Jalankan: sudo apt install pulseaudio-utils\033[0m\"
fi
EOF_AUDIO_TEST
        chmod 755 /usr/local/bin/nx-audio-test

        # Environment global PRoot (Electron sandbox, audio, AT-SPI)
        cat > /etc/profile.d/nx_environment.sh << 'EOF_ENV'
export ELECTRON_DISABLE_SANDBOX=1
export PULSE_SERVER=127.0.0.1
export NO_AT_BRIDGE=1
export DISPLAY=:2
export GDK_BACKEND=x11
export XDG_CURRENT_DESKTOP=XFCE
export XDG_SESSION_TYPE=x11
EOF_ENV
        chmod 644 /etc/profile.d/nx_environment.sh

        grep -q ELECTRON_DISABLE_SANDBOX /etc/environment 2>/dev/null || echo 'ELECTRON_DISABLE_SANDBOX=1' >> /etc/environment
        grep -q PULSE_SERVER /etc/environment 2>/dev/null        || echo 'PULSE_SERVER=127.0.0.1' >> /etc/environment
        grep -q NO_AT_BRIDGE /etc/environment 2>/dev/null        || echo 'NO_AT_BRIDGE=1' >> /etc/environment
    "
}

# ------------------------------------------------------------------------------
# choose_resolution
#   Dialog pilih resolusi GUI; set RES_W, RES_H, GUI_CANCELLED
# ------------------------------------------------------------------------------
choose_resolution() {
    GUI_CANCELLED=0
    echo -e "\n${PURPLE}──────────────────────────────────────────────────────${NC}"
    echo -e "${WHITE}Pilih Resolusi Tampilan GUI:${NC}"
    echo -e " ${PURPLE}[1]${NC} ${WHITE}Custom Resolution (Lebar x Tinggi)${NC}"
    echo -e " ${PURPLE}[2]${NC} ${WHITE}Native Display (Otomatis menyesuaikan layar)${NC}"
    echo -e " ${PURPLE}[3]${NC} ${WHITE}Kembali ke Menu Utama${NC}"
    echo -e "${PURPLE}──────────────────────────────────────────────────────${NC}"
    echo -ne "${CYAN}[?] Pilihan ➔ ${NC}"
    read -r res_choice

    case "$res_choice" in
        1)
            echo -ne "${CYAN}[?] Masukkan resolusi (WIDTHxHEIGHT, mis. 720x1440): ${NC}"
            read -r custom_res
            if [[ "$custom_res" =~ ^([0-9]+)x([0-9]+)$ ]]; then
                RES_W="${BASH_REMATCH[1]}"
                RES_H="${BASH_REMATCH[2]}"
            else
                echo -e "${NEON_PINK}[!] Format tidak valid. Menggunakan default 720x1440.${NC}"
                RES_W="720"; RES_H="1440"
            fi
            ;;
        2) RES_W=""; RES_H="" ;;
        3) GUI_CANCELLED=1 ;;
        *) RES_W="720"; RES_H="1440" ;;
    esac
}

# ------------------------------------------------------------------------------
# write_gui_startup_script
#   Tulis /usr/local/bin/nx-gui-startup.sh ke dalam Ubuntu
# ------------------------------------------------------------------------------
write_gui_startup_script() {
    ubuntu_login -- bash -c "cat > /usr/local/bin/nx-gui-startup.sh" <<EOF
#!/bin/bash
export DISPLAY=:2
export PULSE_SERVER=127.0.0.1
export ELECTRON_DISABLE_SANDBOX=1
export NO_AT_BRIDGE=1
export GDK_BACKEND=x11
export XDG_CURRENT_DESKTOP="XFCE"
export XDG_SESSION_TYPE="x11"
export XDG_SESSION_DESKTOP="xfce"

export XDG_RUNTIME_DIR="/tmp/runtime-\$USER"
mkdir -p "\$XDG_RUNTIME_DIR" 2>/dev/null
chmod 700 "\$XDG_RUNTIME_DIR" 2>/dev/null

sleep 1
OUT=\$(xrandr 2>/dev/null | grep " connected" | head -n1 | awk '{print \$1}')
if [ -n "$RES_W" ] && [ -n "$RES_H" ] && [ -n "\$OUT" ]; then
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
    ubuntu_login -- bash -c "chmod 755 /usr/local/bin/nx-gui-startup.sh"
}

# ------------------------------------------------------------------------------
# launch_ubuntu_gui
#   Install XFCE4 jika perlu, lalu jalankan sesi GUI via Termux:X11
# ------------------------------------------------------------------------------
launch_ubuntu_gui() {
    if ! is_ubuntu_installed || ! is_termux_x11_installed; then
        echo -e "\n${NEON_PINK}[ERR] Ubuntu OS atau Termux:X11 belum terinstal sempurna.${NC}"
        return 1
    fi

    ensure_storage_setup

    if ! is_xfce4_installed; then
        echo -e "\n${PURPLE}[SYS] XFCE4 belum terdeteksi. Memulai instalasi...${NC}"
        execute_task "Instalasi XFCE4" ubuntu_login -- bash -c \
            "DEBIAN_FRONTEND=noninteractive apt update && \
             DEBIAN_FRONTEND=noninteractive apt upgrade -y && \
             DEBIAN_FRONTEND=noninteractive apt install xfce4 xfce4-goodies \
             dbus-x11 x11-xserver-utils sudo tzdata pulseaudio-utils pavucontrol \
             libasound2-plugins alsa-utils sound-theme-freedesktop mc -y"

        if ! is_xfce4_installed; then
            echo -e "${NEON_PINK}[ERR] Instalasi XFCE4 gagal. Periksa koneksi internet.${NC}"
            return 1
        fi
    fi

    # Pastikan wallpaper placeholder ada
    if ! ubuntu_login -- bash -c "[ -f /usr/share/xfce4/backdrops/xubuntu-wallpaper.png ]" >/dev/null 2>&1; then
        ubuntu_login -- bash -c \
            "mkdir -p /usr/share/xfce4/backdrops && \
             echo 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=' \
             | base64 -d > /usr/share/xfce4/backdrops/xubuntu-wallpaper.png" 2>/dev/null
    fi

    if ! is_nonroot_user_setup; then
        execute_task "Konfigurasi User" setup_nonroot_user
    fi

    choose_resolution
    [ "$GUI_CANCELLED" -eq 1 ] && { echo -e "\n${NEON_GREEN}[➔] Sesi dibatalkan.${NC}"; return 0; }

    write_gui_startup_script
    pkill -f "termux-x11" >/dev/null 2>&1
    sleep 1
    start_pulseaudio

    echo -e "\n${PROCESS} ${CYAN}Menyalakan X11 Display Server & Audio Bridge...${NC}"

    local launch_user="--user $NX_USER"
    ! is_nonroot_user_setup && launch_user=""

    local storage_bind=""
    is_storage_setup && storage_bind="--bind $HOME/storage/shared:/storage/shared"

    cat > "$HOME/.nx_x11_launch.sh" <<WRAPEOF
#!/data/data/com.termux/files/usr/bin/bash
export PULSE_SERVER=127.0.0.1
export XDG_RUNTIME_DIR="\${TMPDIR:-/data/data/com.termux/files/usr/tmp}"
proot-distro login ubuntu --shared-tmp $storage_bind $launch_user -- bash /usr/local/bin/nx-gui-startup.sh
WRAPEOF
    chmod +x "$HOME/.nx_x11_launch.sh"

    termux-x11 :2 -xstartup "bash $HOME/.nx_x11_launch.sh" >/dev/null 2>&1 &
    local X11_PID=$!
    sleep 2

    if ! kill -0 "$X11_PID" 2>/dev/null; then
        echo -e "${NEON_PINK}[ERR] Gagal menginisialisasi server X11.${NC}"
        return 1
    fi

    am start --user 0 -n com.termux.x11/com.termux.x11.MainActivity >/dev/null 2>&1
    echo -e "${PROCESS} ${CYAN}Membuka aplikasi Termux:X11 secara otomatis...${NC}\n"

    local tmp_monitor
    tmp_monitor=$(mktemp)
    (
        while kill -0 "$X11_PID" 2>/dev/null; do sleep 1; done
    ) >"$tmp_monitor" 2>&1 &
    local mon_pid=$!

    show_live_progress_loop "GUI Desktop Session" "$mon_pid"
    wait "$X11_PID" 2>/dev/null
    rm -f "$tmp_monitor"
    echo -e "\n${NEON_GREEN}[➔] Sesi GUI telah ditutup.${NC}"
}

# ------------------------------------------------------------------------------
# kill_ubuntu_gui
#   Hentikan semua proses GUI & Audio yang aktif
# ------------------------------------------------------------------------------
kill_ubuntu_gui() {
    echo -e "\n${PROCESS} ${CYAN}Menghentikan seluruh proses GUI & Audio yang aktif...${NC}"
    local found=0
    pkill -f "termux-x11" >/dev/null 2>&1 && found=1
    ubuntu_login -- bash -c "pkill -f 'xfce4|dbus-launch|Xwayland'" >/dev/null 2>&1 && found=1
    stop_pulseaudio
    sleep 1
    if [ "$found" -eq 1 ]; then
        echo -e "${SUCCESS} ${WHITE}Sesi GUI berhasil dihentikan sepenuhnya.${NC}"
    else
        echo -e "${NEON_PINK}[i]${NC} ${WHITE}Tidak ada sesi GUI yang sedang berjalan.${NC}"
    fi
}

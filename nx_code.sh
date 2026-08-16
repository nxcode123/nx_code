#!/data/data/com.termux/files/usr/bin/bash

# ==============================================================================
# [1] KONFIGURASI GLOBAL & OPTIMASI JARINGAN
# ==============================================================================
NX_CODE_REPO_RAW_URL="https://raw.githubusercontent.com/nxcode123/nx_code/main/nx_code.sh"
NX_THEMES_MANIFEST_URL="https://raw.githubusercontent.com/nxcode123/nx_code/main/themes/theme.list"
NX_THEMES_BASE_URL="https://raw.githubusercontent.com/nxcode123/nx_code/main/themes"
NX_VERSION="v1.3.0"
NX_USER="nxuser"

NX_CURL_OPTS="-fsSL --connect-timeout 5 --max-time 15 --retry 2"

THEME_DIR="$HOME/.nx_code/themes"
CONFIG_FILE="$HOME/.nx_code/config"

# Pulihkan kursor & warna terminal saat skrip dihentikan / selesai
cleanup_terminal() {
    echo -ne "\033[?25h\033[0m"
}
trap cleanup_terminal EXIT INT TERM

apply_theme() {
    local theme="${1:-cyberpunk}"
    local theme_file="$THEME_DIR/${theme}.sh"
    local local_repo_theme="./themes/${theme}.sh"

    mkdir -p "$THEME_DIR" 2>/dev/null

    # 1. Salin dari repositori lokal jika tersedia
    if [ ! -s "$theme_file" ] && [ -s "$local_repo_theme" ]; then
        cp "$local_repo_theme" "$theme_file" 2>/dev/null
    fi

    # 2. Unduh dari GitHub jika belum ada di lokal
    if [ ! -s "$theme_file" ]; then
        curl $NX_CURL_OPTS "$NX_THEMES_BASE_URL/${theme}.sh" -o "$theme_file" 2>/dev/null
    fi

    # 3. Source modul tema jika ada
    if [ -s "$theme_file" ]; then
        source "$theme_file" 2>/dev/null
    else
        # Fallback default warna jika file belum ada / offline
        CYAN='\033[0;36m'
        NEON_GREEN='\033[1;32m'
        NEON_PINK='\033[1;95m'
        PURPLE='\033[0;35m'
        WHITE='\033[1;37m'
        NC='\033[0m'
    fi

    SUCCESS="${NEON_GREEN}[✔]${NC}"
    PROCESS="${CYAN}[➔]${NC}"
    ACTIVE_THEME="$theme"
}

setup_nx_menu_command() {
    local bin_dir="${PREFIX:-/data/data/com.termux/files/usr}/bin"
    if [ -d "$bin_dir" ] && [ -w "$bin_dir" ]; then
        cat << 'EOF_NX' > "$bin_dir/nx-menu"
#!/data/data/com.termux/files/usr/bin/bash
TARGET="$HOME/nx_code.sh"
if [ ! -s "$TARGET" ] && [ -s "./nx_code.sh" ]; then
    TARGET="$(realpath ./nx_code.sh 2>/dev/null || echo "./nx_code.sh")"
fi
if [ ! -s "$TARGET" ]; then
    echo -e "\033[0;36m[➔] Mempersiapkan file NX_CODE...\033[0m"
    curl -fsSL --connect-timeout 5 https://raw.githubusercontent.com/nxcode123/nx_code/main/nx_code.sh -o "$HOME/nx_code.sh" 2>/dev/null
    chmod +x "$HOME/nx_code.sh" 2>/dev/null
    TARGET="$HOME/nx_code.sh"
fi
exec bash "$TARGET" --menu "$@"
EOF_NX
        chmod +x "$bin_dir/nx-menu" 2>/dev/null
        ln -sf "$bin_dir/nx-menu" "$bin_dir/nx" 2>/dev/null || cp "$bin_dir/nx-menu" "$bin_dir/nx" 2>/dev/null
        chmod +x "$bin_dir/nx" 2>/dev/null
    fi
}

init_theme_system() {
    mkdir -p "$THEME_DIR" 2>/dev/null

    # Salin semua tema dari repositori lokal jika tersedia
    if [ -d "./themes" ]; then
        cp -r ./themes/* "$THEME_DIR/" 2>/dev/null || true
    fi

    ACTIVE_THEME="cyberpunk"
    [ -f "$CONFIG_FILE" ] && source "$CONFIG_FILE" 2>/dev/null

    apply_theme "$ACTIVE_THEME"
}

init_theme_system

# ==============================================================================
# [2] CORE UTILITIES (ELEGANT UI & FLICKER-FREE LIVE PROGRESS)
# ==============================================================================
animate_logo() {
    command clear
    echo -e "${NEON_PINK}╔══════════════════════════════════════════════════════╗${NC}"
    local lines=(
        "  _   _ __  __        ____ ___  ____  _____ "
        " | \ | |\ \/ /       / ___/ _ \|  _ \| ____|"
        " |  \| | \  /  _____ | |  | | | | | | |  _|  "
        " | |\  | /  \ |_____ | |__| |_| | |_| | |___ "
        " |_| \_|/_/\_\       \____\___/|____/|_____| TERMINAL"
    )
    for line in "${lines[@]}"; do
        printf "${PURPLE}%s${NC}\r" "$line"
        sleep 0.02
        printf "${CYAN}%s${NC}\n" "$line"
    done
    echo -e "${NEON_PINK}╠══════════════════════════════════════════════════════╣${NC}"
    echo -e "${WHITE} STATUS: ${NEON_GREEN}ONLINE${WHITE}  │  THEME: ${NEON_PINK}${ACTIVE_THEME^^}${WHITE}  │  VER: ${CYAN}${NX_VERSION}${NC}"
    echo -e "${NEON_PINK}╚══════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# Progress bar akurat dengan pelacakan exit-code yang tepat
execute_task() {
    local msg="$1"
    shift
    local tmp_log
    tmp_log=$(mktemp)
    local spinner=( "⠋" "⠙" "⠹" "⠸" "⠼" "⠴" "⠦" "⠧" "⠇" "⠏" )
    local i=0
    local start_time
    start_time=$(date +%s)

    ( "$@" ) > "$tmp_log" 2>&1 &
    local pid=$!

    echo -ne "\033[?25l"
    while kill -0 "$pid" 2>/dev/null; do
        local current_time
        current_time=$(date +%s)
        local elapsed=$((current_time - start_time))

        local last_line=""
        if [ -f "$tmp_log" ]; then
            last_line=$(tail -n 1 "$tmp_log" 2>/dev/null | sed -r "s/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[mGK]//g" | tr -d '\n\r' | cut -c 1-24)
        fi

        printf "\r\033[2K${NEON_PINK}%s${NC} ${WHITE}%-18s${NC} ${CYAN}│${NC} ${PURPLE}%-24s${NC} ${CYAN}(%ds)${NC}" \
            "${spinner[$i]}" "$msg" "$last_line" "$elapsed"

        i=$(( (i + 1) % ${#spinner[@]} ))
        sleep 0.1
    done

    wait "$pid"
    local exit_code=$?
    local end_time
    end_time=$(date +%s)
    local elapsed=$((end_time - start_time))

    echo -ne "\033[?25h"
    if [ $exit_code -eq 0 ]; then
        printf "\r\033[2K${SUCCESS} ${WHITE}%-18s${NC} ${CYAN}│${NC} ${NEON_GREEN}COMPLETED${NC}                       ${CYAN}(%ds)${NC}\n" \
            "$msg" "$elapsed"
    else
        printf "\r\033[2K${NEON_PINK}[✘]${NC} ${WHITE}%-18s${NC} ${CYAN}│${NC} ${NEON_PINK}FAILED (Code: %d)${NC}                 ${CYAN}(%ds)${NC}\n" \
            "$msg" "$exit_code" "$elapsed"
        if [ -f "$tmp_log" ] && [ -s "$tmp_log" ]; then
            local err_preview
            err_preview=$(tail -n 2 "$tmp_log" | tr '\n' ' ' | cut -c 1-75)
            [ -n "$err_preview" ] && echo -e "${PURPLE}     ↳ Detail: ${WHITE}${err_preview}${NC}"
        fi
    fi

    rm -f "$tmp_log"
    return $exit_code
}

# ==============================================================================
# [3] AUDIO & SYSTEM CHECKERS
# ==============================================================================
is_termux_x11_installed() { command -v termux-x11 >/dev/null 2>&1; }
is_storage_setup() { [ -d "$HOME/storage/shared" ]; }
is_mc_installed() { command -v mc >/dev/null 2>&1; }

ensure_storage_setup() {
    if ! is_storage_setup; then
        echo -e "\n${NEON_PINK}[SYS]${NC} ${WHITE}Meminta izin akses Shared Storage...${NC}"
        echo -e "${PURPLE}      Perhatikan layar perangkat Anda dan pilih 'Allow / Izinkan'.${NC}"
        termux-setup-storage
        sleep 2
    fi
}

# Wrapper: semua akses ke Ubuntu lewat sini, agar folder storage HP
# (/storage/shared) otomatis ikut terhubung (bind-mount) ke dalam Ubuntu.
ubuntu_login() {
    local bind_args=()
    if is_storage_setup; then
        bind_args=(--bind "$HOME/storage/shared:/storage/shared")
    fi
    proot-distro login ubuntu "${bind_args[@]}" "$@"
}

is_ubuntu_installed() { ubuntu_login -- true >/dev/null 2>&1; }
is_xfce4_installed() { ubuntu_login -- bash -c "command -v startxfce4" >/dev/null 2>&1; }
is_nonroot_user_setup() { ubuntu_login -- bash -c "id $NX_USER" >/dev/null 2>&1; }

start_pulseaudio() {
    if command -v pulseaudio >/dev/null 2>&1; then
        pkill -f "pulseaudio" >/dev/null 2>&1 || true
        sleep 0.3
        pulseaudio --start --load="module-native-protocol-tcp auth-ip-acl=127.0.0.1 auth-anonymous=1" --exit-idle-time=-1 >/dev/null 2>&1 || true
    fi
}

stop_pulseaudio() {
    pkill -f "pulseaudio" >/dev/null 2>&1 || true
}

# ==============================================================================
# [4] GUI MANAGEMENT & SETTINGS
# ==============================================================================
setup_nonroot_user() {
    ubuntu_login -- bash -c "
        if ! id $NX_USER >/dev/null 2>&1; then
            useradd -m -s /bin/bash $NX_USER 2>/dev/null
        fi
        usermod -aG sudo,audio,video $NX_USER 2>/dev/null || true
        echo '$NX_USER ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/$NX_USER
        chmod 0440 /etc/sudoers.d/$NX_USER
        mkdir -p /storage/shared && chmod -R 777 /storage

        # Pasang bantuan nx-menu di dalam lingkungan Ubuntu
        cat > /usr/local/bin/nx-menu << 'EOF_NX_UBUNTU'
#!/bin/bash
echo -e \"\033[1;95m╔══════════════════════════════════════════════════════╗\033[0m\"
echo -e \"\033[1;36m              NX_CODE - UBUNTU ENVIRONMENT             \033[0m\"
echo -e \"\033[1;95m╚══════════════════════════════════════════════════════╝\033[0m\"
echo -e \"\033[1;33m[!] Anda saat ini sedang berada di dalam terminal Ubuntu CLI.\033[0m\"
echo -e \"\033[0;36m[➔] Untuk kembali ke Termux dan membuka Control Center:\033[0m\"
echo -e \"    Ketik \033[1;32mexit\033[0m lalu jalankan \033[1;36mnx-menu\033[0m di Termux.\n\"
EOF_NX_UBUNTU
        chmod 755 /usr/local/bin/nx-menu

        # Konfigurasi PulseAudio client (cegah autospawn server di PRoot & hubungkan ke Termux)
        mkdir -p /etc/pulse
        cat > /etc/pulse/client.conf << 'EOF_PULSE_CLIENT'
default-server = 127.0.0.1
autospawn = no
EOF_PULSE_CLIENT
        chmod 644 /etc/pulse/client.conf 2>/dev/null

        # Konfigurasi ALSA to PulseAudio bridge
        cat > /etc/asound.conf << 'EOF_ASOUND'
pcm.!default {
    type pulse
    fallback "sysdefault"
}

ctl.!default {
    type pulse
    fallback "sysdefault"
}
EOF_ASOUND
        chmod 644 /etc/asound.conf 2>/dev/null

        # Script test audio untuk kemudahan pengujian dari terminal Ubuntu
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
            echo -e \"\033[0;36m[➔] Memutar nada uji coba 1 detik (speaker-test)...\033[0m\"
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

        # Konfigurasi Lingkungan Global PRoot (Fix Electron Sandbox, Audio, & AT-SPI D-Bus)
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
        grep -q PULSE_SERVER /etc/environment 2>/dev/null || echo 'PULSE_SERVER=127.0.0.1' >> /etc/environment
        grep -q NO_AT_BRIDGE /etc/environment 2>/dev/null || echo 'NO_AT_BRIDGE=1' >> /etc/environment
    "
}

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
            echo -ne "${CYAN}[?] Masukkan resolusi (WIDTHxHEIGHT, mis. 720x1440 atau 1080x2400): ${NC}"
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

write_gui_startup_script() {
    ubuntu_login -- bash -c "cat > /usr/local/bin/nx-gui-startup.sh" << EOF
#!/bin/bash
export DISPLAY=:2
export PULSE_SERVER=127.0.0.1
export ELECTRON_DISABLE_SANDBOX=1
export NO_AT_BRIDGE=1
export GDK_BACKEND=x11
export XDG_CURRENT_DESKTOP="XFCE"
export XDG_SESSION_TYPE="x11"
export XDG_SESSION_DESKTOP="xfce"

# Inisialisasi runtime dir untuk dbus/pulseaudio
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

launch_ubuntu_gui() {
    if ! is_ubuntu_installed || ! is_termux_x11_installed; then
        echo -e "\n${NEON_PINK}[ERR] Ubuntu OS atau Termux:X11 belum terinstal sempurna.${NC}"
        return 1
    fi

    ensure_storage_setup

    if ! is_xfce4_installed; then
        echo -e "\n${PURPLE}[SYS] XFCE4 belum terdeteksi. Memulai instalasi lingkungan desktop...${NC}"
        execute_task "Instalasi XFCE4" ubuntu_login -- bash -c "DEBIAN_FRONTEND=noninteractive apt update && DEBIAN_FRONTEND=noninteractive apt upgrade -y && DEBIAN_FRONTEND=noninteractive apt install xfce4 xfce4-goodies dbus-x11 x11-xserver-utils sudo tzdata pulseaudio-utils pavucontrol libasound2-plugins alsa-utils sound-theme-freedesktop mc -y"

        if ! is_xfce4_installed; then
            echo -e "${NEON_PINK}[ERR] Instalasi XFCE4 gagal. Periksa koneksi internet.${NC}"
            return 1
        fi
    fi

    if ! ubuntu_login -- bash -c "[ -f /usr/share/xfce4/backdrops/xubuntu-wallpaper.png ]" >/dev/null 2>&1; then
        ubuntu_login -- bash -c "mkdir -p /usr/share/xfce4/backdrops && echo 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=' | base64 -d > /usr/share/xfce4/backdrops/xubuntu-wallpaper.png" 2>/dev/null
    fi

    if ! is_nonroot_user_setup; then
        execute_task "Konfigurasi User" setup_nonroot_user
    fi

    choose_resolution
    [ "$GUI_CANCELLED" -eq 1 ] && { echo -e "\n${NEON_GREEN}[➔] Sesi dibatalkan.${NC}"; return 0; }

    write_gui_startup_script
    pkill -f "termux-x11" >/dev/null 2>&1
    sleep 1

    # Nyalakan sound server pulseaudio
    start_pulseaudio

    echo -e "\n${PROCESS} ${CYAN}Menyalakan X11 Display Server & Audio Bridge...${NC}"
    local launch_user="--user $NX_USER"
    ! is_nonroot_user_setup && launch_user=""

    local storage_bind=""
    is_storage_setup && storage_bind="--bind $HOME/storage/shared:/storage/shared"

    cat > "$HOME/.nx_x11_launch.sh" << WRAPEOF
#!/data/data/com.termux/files/usr/bin/bash
export PULSE_SERVER=127.0.0.1
export XDG_RUNTIME_DIR="\${TMPDIR:-/data/data/com.termux/files/usr/tmp}"
proot-distro login ubuntu --shared-tmp $storage_bind $launch_user -- bash /usr/local/bin/nx-gui-startup.sh
WRAPEOF
    chmod +x "$HOME/.nx_x11_launch.sh"

    termux-x11 :2 -xstartup "bash $HOME/.nx_x11_launch.sh" >/dev/null 2>&1 &
    X11_PID=$!
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
        while kill -0 "$X11_PID" 2>/dev/null; do
            sleep 1
        done
    ) > "$tmp_monitor" 2>&1 &
    local mon_pid=$!

    show_live_progress_loop "GUI Desktop Session" "$mon_pid"
    wait "$X11_PID" 2>/dev/null
    rm -f "$tmp_monitor"
    echo -e "\n${NEON_GREEN}[➔] Sesi GUI telah ditutup.${NC}"
}

show_live_progress_loop() {
    local msg="$1"
    local pid="$2"
    local spinner=( "⠋" "⠙" "⠹" "⠸" "⠼" "⠴" "⠦" "⠧" "⠇" "⠏" )
    local i=0
    local start_time
    start_time=$(date +%s)

    echo -ne "\033[?25l"
    while kill -0 "$pid" 2>/dev/null; do
        local current_time
        current_time=$(date +%s)
        local elapsed=$((current_time - start_time))
        printf "\r\033[2K${NEON_PINK}%s${NC} ${WHITE}%-20s${NC} ${CYAN}│${NC} ${NEON_GREEN}ACTIVE${NC} ${CYAN}(%ds)${NC}" \
            "${spinner[$i]}" "$msg" "$elapsed"
        i=$(( (i + 1) % ${#spinner[@]} ))
        sleep 0.2
    done
    echo -ne "\033[?25h"
}

kill_ubuntu_gui() {
    echo -e "\n${PROCESS} ${CYAN}Menghentikan seluruh proses GUI & Audio yang aktif...${NC}"
    local found=0
    if pkill -f "termux-x11" >/dev/null 2>&1; then found=1; fi
    if ubuntu_login -- bash -c "pkill -f 'xfce4|dbus-launch|Xwayland'" >/dev/null 2>&1; then found=1; fi
    stop_pulseaudio
    sleep 1
    if [ "$found" -eq 1 ]; then
        echo -e "${SUCCESS} ${WHITE}Sesi GUI berhasil dihentikan sepenuhnya.${NC}"
    else
        echo -e "${NEON_PINK}[i]${NC} ${WHITE}Tidak ada sesi GUI yang sedang berjalan.${NC}"
    fi
}

change_theme_menu() {
    while true; do
        local t_names=()
        local t_descs=()
        local seen_names=" "

        # 1. Muat daftar tema dari manifest theme.list (lokal / download)
        local manifest="$THEME_DIR/theme.list"
        if [ ! -s "$manifest" ] && [ -s "./themes/theme.list" ]; then
            cp "./themes/theme.list" "$manifest" 2>/dev/null
        fi
        if [ ! -s "$manifest" ]; then
            curl $NX_CURL_OPTS "$NX_THEMES_MANIFEST_URL" -o "$manifest" 2>/dev/null
        fi

        if [ -s "$manifest" ]; then
            while IFS='|' read -r t_id t_desc || [ -n "$t_id" ]; do
                [[ -z "$t_id" || "$t_id" =~ ^[[:space:]]*# ]] && continue
                t_id=$(echo "$t_id" | tr -d '\r' | xargs)
                t_desc=$(echo "$t_desc" | tr -d '\r' | xargs)
                if [ -n "$t_id" ]; then
                    t_names+=("$t_id")
                    t_descs+=("${t_desc:-$t_id Theme}")
                    seen_names="${seen_names}${t_id} "
                fi
            done < "$manifest"
        fi

        # 2. Pindai tema kustom tambahan di direktori tema
        for f in "$THEME_DIR"/*.sh ./themes/*.sh; do
            [ -f "$f" ] || continue
            local base_name
            base_name=$(basename "$f" .sh)
            [[ "$base_name" == "*" ]] && continue
            if [[ "$seen_names" != *" $base_name "* ]]; then
                t_names+=("$base_name")
                t_descs+=("${base_name^} (Custom Theme)")
                seen_names="${seen_names}${base_name} "
            fi
        done

        # 3. Fallback jika tidak ada manifes sama sekali
        if [ ${#t_names[@]} -eq 0 ]; then
            t_names=("cyberpunk" "matrix" "dracula" "synthwave" "ocean" "sunset" "emerald" "bloodmoon" "monokai" "arctic" "gold")
            t_descs=("Cyberpunk Neon Theme" "Matrix Green Hacker" "Dracula Dark Pro" "Synthwave 84 Neon" "Oceanic Deep Blue" "Sunset Orange" "Emerald Forest" "Blood Moon Crimson" "Monokai Pro" "Arctic Frost Ice" "Cyber Gold Luxury")
        fi

        animate_logo
        echo -e "${PURPLE}──────────────────────────────────────────────────────${NC}"
        echo -e "${WHITE}PILIH TEMA INTERFACE (NX THEME SYSTEM - MODULAR)${NC}"
        echo -e "${PURPLE}──────────────────────────────────────────────────────${NC}"

        for i in "${!t_names[@]}"; do
            local name="${t_names[$i]}"
            local desc="${t_descs[$i]}"
            local marker=" "
            [ "$ACTIVE_THEME" == "$name" ] && marker="[✔]"
            printf " ${PURPLE}[%2d]${NC} ${WHITE}%-12s${NC} ${CYAN}│ %-22s${NC} ${NEON_GREEN}%s${NC}\n" "$((i+1))" "$name" "$desc" "$marker"
        done
        echo -e " ${PURPLE}[ 0]${NC} ${WHITE}Kembali ke Menu Utama${NC}"
        echo -e "${PURPLE}──────────────────────────────────────────────────────${NC}"
        echo -ne "${CYAN}[?] Pilihan ➔ ${NC}"
        read -r t_choice

        if [ "$t_choice" == "0" ]; then
            break
        fi

        local idx=$((t_choice - 1))
        if [ "$idx" -ge 0 ] && [ "$idx" -lt "${#t_names[@]}" ]; then
            local chosen="${t_names[$idx]}"
            apply_theme "$chosen"

            mkdir -p "$THEME_DIR" 2>/dev/null
            echo "ACTIVE_THEME=\"$ACTIVE_THEME\"" > "$CONFIG_FILE"

            echo -e "\n${SUCCESS} ${WHITE}Tema aktif diubah ke: ${NEON_PINK}$chosen${NC}"
            sleep 1
        else
            echo -e "\n${NEON_PINK}[!] Pilihan tidak valid.${NC}"
            sleep 1
        fi
    done
}


# ==============================================================================
# [5] SYSTEM MANAGEMENT
# ==============================================================================
run_auto_cleaner() {
    local last_clean_file="$HOME/.nx_code_last_clean"
    local today
    today=$(date +%Y%m%d)
    local last_clean=""
    [ -f "$last_clean_file" ] && last_clean=$(cat "$last_clean_file" 2>/dev/null)

    if [ "$today" != "$last_clean" ]; then
        if command -v pkg >/dev/null 2>&1; then
            execute_task "System Storage Clean" bash -c "pkg clean -y && [ -n \"$TMPDIR\" ] && rm -rf \"$TMPDIR\"/*"
        fi
        echo "$today" > "$last_clean_file"
    fi
}

check_for_update() {
    echo -e "\n${PROCESS} ${CYAN}Memeriksa pembaruan dari repository NX_CODE...${NC}"
    local tmp_file="$HOME/.nx_code_update_tmp.sh"

    if ! curl $NX_CURL_OPTS "$NX_CODE_REPO_RAW_URL" -o "$tmp_file" 2>/dev/null || [ ! -s "$tmp_file" ]; then
        echo -e "${NEON_PINK}[ERR] Gagal mengambil pembaruan. Periksa koneksi internet.${NC}"
        rm -f "$tmp_file"; return 1
    fi

    local target_script="$HOME/nx_code.sh"
    if [ -f "./nx_code.sh" ] && [ ! -f "$HOME/nx_code.sh" ]; then
        target_script="./nx_code.sh"
    fi

    if diff -q "$tmp_file" "$target_script" >/dev/null 2>&1; then
        echo -e "${SUCCESS} ${WHITE}Sistem sudah menggunakan versi terbaru (${NX_VERSION}).${NC}"
        rm -f "$tmp_file"; return 0
    fi

    echo -e "${SUCCESS} ${WHITE}Pembaruan ditemukan! Menerapkan patch sistem...${NC}"
    mv "$tmp_file" "$target_script"
    sed -i 's/\xc2\xa0/ /g' "$target_script" 2>/dev/null
    chmod +x "$target_script"
    sleep 1
    exec bash "$target_script" --menu
}

copy_self_to_home() {
    local dest="$HOME/nx_code.sh"
    local src
    src=$(realpath "${BASH_SOURCE[0]:-$0}" 2>/dev/null)

    # 1. Jika sumber adalah file lokal biasa dan berbeda dari dest
    if [ -n "$src" ] && [ -f "$src" ] && [[ "$src" != /dev/fd/* ]] && [[ "$src" != /proc/* ]] && [ "$src" != "$dest" ]; then
        cp "$src" "$dest" 2>/dev/null
        sed -i 's/\xc2\xa0/ /g' "$dest" 2>/dev/null
        chmod +x "$dest" 2>/dev/null
        setup_nx_menu_command
        return 0
    fi

    # 2. Jika file sudah ada di dest dan berukuran valid
    if [ -f "$dest" ] && [ -s "$dest" ]; then
        chmod +x "$dest" 2>/dev/null
        setup_nx_menu_command
        return 0
    fi

    # 3. Jika file di direktori saat ini ada
    if [ -f "./nx_code.sh" ] && [ -s "./nx_code.sh" ]; then
        cp "./nx_code.sh" "$dest" 2>/dev/null
        sed -i 's/\xc2\xa0/ /g' "$dest" 2>/dev/null
        chmod +x "$dest" 2>/dev/null
        setup_nx_menu_command
        return 0
    fi

    # 4. Jika dijalankan via pipe / remote stream, unduh langsung
    echo -e "\n${PROCESS} ${CYAN}Menyimpan salinan skrip NX_CODE ke $dest...${NC}"
    if curl $NX_CURL_OPTS "$NX_CODE_REPO_RAW_URL" -o "$dest" 2>/dev/null && [ -s "$dest" ]; then
        sed -i 's/\xc2\xa0/ /g' "$dest" 2>/dev/null
        chmod +x "$dest" 2>/dev/null
        setup_nx_menu_command
        return 0
    fi

    return 1
}

# ==============================================================================
# [6] ROUTING & MENU
# ==============================================================================
launch_midnight_commander() {
    while true; do
        animate_logo
        echo -e "${NEON_PINK}──────────────────────────────────────────────────────${NC}"
        echo -e "${WHITE}          MIDNIGHT COMMANDER (FILE MANAGER)           ${NC}"
        echo -e "${NEON_PINK}──────────────────────────────────────────────────────${NC}"
        echo -e " ${PURPLE}[1]${NC} ${WHITE}Buka MC di Termux (Akses Direktori Termux & SDCard)${NC}"
        echo -e " ${PURPLE}[2]${NC} ${WHITE}Buka MC di Ubuntu OS (Root / User Environment)${NC}"
        echo -e " ${PURPLE}[3]${NC} ${WHITE}Install / Perbarui Paket MC (Termux & Ubuntu)${NC}"
        echo -e "${NEON_PINK}──────────────────────────────────────────────────────${NC}"
        echo -e " ${PURPLE}[0]${NC} ${WHITE}Kembali ke Menu Utama${NC}"
        echo -e "${NEON_PINK}──────────────────────────────────────────────────────${NC}"
        echo -ne "${CYAN}[?] Pilihan ➔ ${NC}"
        read -r mc_choice

        case "$mc_choice" in
            1)
                if ! command -v mc >/dev/null 2>&1; then
                    echo -e "\n${PURPLE}[SYS] Midnight Commander belum terinstal di Termux.${NC}"
                    execute_task "Instalasi MC Termux" pkg install mc -y -o Dpkg::Options::="--force-confold"
                fi
                if command -v mc >/dev/null 2>&1; then
                    echo -e "\n${PROCESS} ${CYAN}Membuka Midnight Commander (Termux)...${NC}"
                    sleep 0.5
                    mc
                else
                    echo -e "\n${NEON_PINK}[ERR] Gagal memasang Midnight Commander di Termux.${NC}"
                    sleep 1.5
                fi
                ;;
            2)
                if ! is_ubuntu_installed; then
                    echo -e "\n${NEON_PINK}[ERR] Ubuntu OS belum terinstal.${NC}"
                    sleep 1.5
                    continue
                fi
                local has_ubuntu_mc
                has_ubuntu_mc=$(ubuntu_login -- bash -c "command -v mc" 2>/dev/null || true)
                if [ -z "$has_ubuntu_mc" ]; then
                    echo -e "\n${PURPLE}[SYS] Midnight Commander belum terinstal di Ubuntu.${NC}"
                    execute_task "Instalasi MC Ubuntu" ubuntu_login -- bash -c "DEBIAN_FRONTEND=noninteractive apt update && DEBIAN_FRONTEND=noninteractive apt install mc -y"
                fi
                echo -e "\n${PROCESS} ${CYAN}Membuka Midnight Commander (Ubuntu)...${NC}"
                sleep 0.5
                local mc_user="--user $NX_USER"
                ! is_nonroot_user_setup && mc_user=""
                ubuntu_login $mc_user -- mc
                ;;
            3)
                echo -e "\n${PROCESS} ${CYAN}Memperbarui & memasang Midnight Commander...${NC}"
                execute_task "Update MC di Termux" pkg install mc -y -o Dpkg::Options::="--force-confold"
                if is_ubuntu_installed; then
                    execute_task "Update MC di Ubuntu" ubuntu_login -- bash -c "DEBIAN_FRONTEND=noninteractive apt update && DEBIAN_FRONTEND=noninteractive apt install mc -y"
                fi
                echo -e "${SUCCESS} ${WHITE}Pemasangan / Pembaruan MC selesai.${NC}"
                sleep 1.5
                ;;
            0)
                break
                ;;
            *)
                echo -e "\n${NEON_PINK}[!] Pilihan tidak valid, silakan coba lagi.${NC}"
                sleep 1
                ;;
        esac
    done
}

show_shortcut_menu() {
    while true; do
        animate_logo
        echo -e "${NEON_PINK}──────────────────────────────────────────────────────${NC}"
        echo -e "${WHITE}               NX_CODE CONTROL CENTER                 ${NC}"
        echo -e "${NEON_PINK}──────────────────────────────────────────────────────${NC}"
        echo -e " ${PURPLE}[1]${NC} ${WHITE}Ubuntu CLI Core (Terminal Linux)${NC}"
        echo -e " ${PURPLE}[2]${NC} ${WHITE}Ubuntu GUI (XFCE4 + Audio via Termux:X11)${NC}"
        echo -e " ${PURPLE}[3]${NC} ${WHITE}Kill Active GUI & Audio Session${NC}"
        echo -e " ${PURPLE}[4]${NC} ${WHITE}Midnight Commander (MC File Manager)${NC}"
        echo -e " ${PURPLE}[5]${NC} ${WHITE}Ganti Tema Interface${NC}"
        echo -e " ${PURPLE}[6]${NC} ${WHITE}Check for System Updates${NC}"
        echo -e "${NEON_PINK}──────────────────────────────────────────────────────${NC}"
        echo -e " ${PURPLE}[0]${NC} ${WHITE}Exit to Terminal${NC}"
        echo -e "${NEON_PINK}──────────────────────────────────────────────────────${NC}"
        echo -ne "${CYAN}[?] Select Option ➔ ${NC}"
        read -r pilihan

        case "$pilihan" in
            1)
                echo -e "\n${PROCESS} ${CYAN}Memuat lingkungan Ubuntu CLI & Audio Bridge...${NC}"
                start_pulseaudio
                ensure_storage_setup
                sleep 0.5
                if is_ubuntu_installed; then
                    local cli_user="--user $NX_USER"
                    ! is_nonroot_user_setup && cli_user=""
                    ubuntu_login $cli_user
                else
                    echo -e "${NEON_PINK}[ERR] Ubuntu OS belum terinstal.${NC}"
                    sleep 1.5
                fi
                ;;
            2) launch_ubuntu_gui; sleep 1 ;;
            3) kill_ubuntu_gui; sleep 1 ;;
            4) launch_midnight_commander; sleep 1 ;;
            5) change_theme_menu ;;
            6) check_for_update; sleep 1 ;;
            0)
                echo -e "\n${NEON_GREEN}[➔] Keluar ke terminal reguler.${NC}\n"
                break
                ;;
            *)
                echo -e "\n${NEON_PINK}[!] Pilihan tidak valid, silakan coba lagi.${NC}"
                sleep 1
                ;;
        esac
    done
}

# Argument Routing
case "$1" in
    --logo-only) animate_logo; exit 0 ;;
    --menu|-m|menu) show_shortcut_menu; exit 0 ;;
    --mc|mc) launch_midnight_commander; exit 0 ;;
    --ui-only)
        animate_logo

        echo -ne "${CYAN}[SYS] Syncing database...... ${NC}"
        echo -e "${NEON_GREEN}[✔] Clear${NC}"

        echo -ne "${CYAN}[SYS] Ubuntu Integrity...... ${NC}"
        is_ubuntu_installed && echo -e "${NEON_GREEN}[✔] Ready${NC}" || echo -e "${NEON_PINK}[X] Missing${NC}"

        echo -ne "${CYAN}[SYS] Storage Access........ ${NC}"
        if is_storage_setup; then
            echo -e "${NEON_GREEN}[✔] Ready${NC}"
        else
            echo -e "${NEON_PINK}[X] Storage Not Linked${NC}"
        fi

        echo -ne "${CYAN}[SYS] Midnight Commander... ${NC}"
        command -v mc >/dev/null 2>&1 && echo -e "${NEON_GREEN}[✔] Ready${NC}" || echo -e "${NEON_PINK}[X] Missing${NC}"

        run_auto_cleaner
        echo -e "\n${PURPLE}Ketik ${CYAN}nx-menu${PURPLE} untuk membuka control center.${NC}\n"
        exit 0
        ;;
    --help|-h)
        echo "NX_CODE - Hypervisor GUI & CLI Control"
        echo "Penggunaan: nx-menu [opsi]"
        echo "  --menu, -m      Buka NX_CODE Control Center (Default)"
        echo "  --mc            Buka Midnight Commander File Manager"
        echo "  --ui-only       Tampilkan ringkasan status sistem"
        echo "  --logo-only     Tampilkan logo banner saja"
        echo "  --help, -h      Tampilkan pesan bantuan ini"
        exit 0
        ;;
esac

# ==============================================================================
# [7] INSTALLATION MODE (BOOTSTRAPPER)
# ==============================================================================
command -v termux-wake-lock >/dev/null 2>&1 && termux-wake-lock
animate_logo

ensure_storage_setup

execute_task "Updating Repos" pkg update -y -o Dpkg::Options::="--force-confold"
execute_task "Upgrading Core" pkg upgrade -y -o Dpkg::Options::="--force-confold"
execute_task "Deploy Hypervisor" pkg install proot-distro pulseaudio coreutils mc -y -o Dpkg::Options::="--force-confold"
execute_task "Add X11 Repo" pkg install x11-repo -y -o Dpkg::Options::="--force-confold"
execute_task "Deploy X11 Server" pkg install termux-x11-nightly -y -o Dpkg::Options::="--force-confold"

if ! is_ubuntu_installed; then
    echo -e "\n${PROCESS} ${CYAN}Mengunduh Ubuntu Core OS secara live...${NC}"
    proot-distro remove ubuntu > /dev/null 2>&1 || true
    echo -e "${PURPLE}[!] Mohon tunggu hingga proses unduhan selesai.${NC}"
    echo -e "${CYAN}──────────────────────────────────────────────────────${NC}"
    proot-distro install ubuntu
    echo -e "${CYAN}──────────────────────────────────────────────────────${NC}"
fi

# Pastikan konfigurasi non-root & lingkungan global terpasang
if is_ubuntu_installed; then
    execute_task "Setup PRoot Config" setup_nonroot_user
fi

echo ""
is_ubuntu_installed && echo -e "${SUCCESS} ${WHITE}Ubuntu Core OS            :${NC} ${NEON_GREEN}Installed${NC}" || echo -e "${NEON_PINK}[X]${NC} ${WHITE}Ubuntu Core OS            :${NC} ${NEON_PINK}Failed${NC}"
is_termux_x11_installed && echo -e "${SUCCESS} ${WHITE}Termux-X11 Display Server:${NC} ${NEON_GREEN}Installed${NC}" || echo -e "${NEON_PINK}[X]${NC} ${WHITE}Termux-X11 Display Server:${NC} ${NEON_PINK}Failed${NC}"
command -v pulseaudio >/dev/null 2>&1 && echo -e "${SUCCESS} ${WHITE}PulseAudio Sound Server   :${NC} ${NEON_GREEN}Installed${NC}" || echo -e "${NEON_PINK}[X]${NC} ${WHITE}PulseAudio Sound Server   :${NC} ${NEON_PINK}Failed${NC}"
command -v mc >/dev/null 2>&1 && echo -e "${SUCCESS} ${WHITE}Midnight Commander (MC)   :${NC} ${NEON_GREEN}Installed${NC}" || echo -e "${NEON_PINK}[X]${NC} ${WHITE}Midnight Commander (MC)   :${NC} ${NEON_PINK}Failed${NC}"
echo ""

if ! copy_self_to_home; then
    echo -e "${NEON_PINK}[!] Skrip berjalan via remote stream. Disimpan lokal di $HOME/nx_code.sh${NC}"
fi

if ! grep -q "NX_CODE ENVIRONMENT" "$HOME/.bashrc" 2>/dev/null; then
    sed -i '/# --- NX_CODE ENVIRONMENT ---/,/# ---------------------------/d' "$HOME/.bashrc" 2>/dev/null

    cat << 'EOF' >> "$HOME/.bashrc"

# --- NX_CODE ENVIRONMENT ---
[ -f "$HOME/nx_code.sh" ] && bash "$HOME/nx_code.sh" --ui-only
alias ls='ls --color=auto --group-directories-first'
alias ll='ls -la --color=auto --group-directories-first'
alias nx-menu='bash $HOME/nx_code.sh --menu'
alias nx='bash $HOME/nx_code.sh --menu'
alias nx-mc='bash $HOME/nx_code.sh --mc'
PS1="\[\033[1;95m\][═\[\033[0;36m\]NX_CODE\[\033[1;95m\]═] \[\033[1;32m\]⚡ \[\033[0m\]"

clear() { command clear; [ -f "$HOME/nx_code.sh" ] && bash "$HOME/nx_code.sh" --logo-only; }

rm() {
    if [ $# -eq 0 ]; then
        echo -e "\033[1;95m[!] ALERT: NO TARGET SPECIFIED.\033[0m"
        return 1
    fi
    command rm "$@"
}

command_not_found_handle() {
    if [ "$1" = "nx-menu" ] || [ "$1" = "nx" ] || [ "$1" = "menu" ]; then
        if [ -x "${PREFIX:-/data/data/com.termux/files/usr}/bin/nx-menu" ]; then
            exec "${PREFIX:-/data/data/com.termux/files/usr}/bin/nx-menu"
        elif [ -f "$HOME/nx_code.sh" ]; then
            exec bash "$HOME/nx_code.sh" --menu
        fi
    fi
    echo -e "\033[1;95m[!] ALERT: UNAUTHORIZED COMMAND '$1' DETECTED.\033[0m"
    return 127
}
# ---------------------------
EOF
    echo -e "${SUCCESS} ${WHITE}Auto-Startup Profile     :${NC} ${NEON_GREEN}Injected Successfully${NC}"
else
    setup_nx_menu_command
    echo -e "${SUCCESS} ${WHITE}Auto-Startup Profile     :${NC} ${CYAN}Already Configured${NC}"
fi

command -v termux-wake-unlock >/dev/null 2>&1 && termux-wake-unlock

echo -e "\n${NEON_GREEN}[Complete]${NC}"
echo -e "${NEON_PINK}======================================================${NC}"
echo -e "${NEON_GREEN}           SYSTEM INITIALIZED. NX_CODE ACTIVE.         ${NC}"
echo -e "${NEON_PINK}======================================================${NC}"

echo -e " ${PURPLE}[1]${NC} ${WHITE}Masuk ke Menu Utama (nx-menu)${NC}"
echo -e " ${PURPLE}[2]${NC} ${WHITE}Buka Midnight Commander (MC)${NC}"
echo -e " ${PURPLE}[3]${NC} ${WHITE}Buka Sesi Terminal Baru${NC}"
echo -e " ${PURPLE}[0]${NC} ${WHITE}Exit${NC}"
echo -ne "${CYAN}[?] Pilihan ➔ ${NC}"
read -r final_choice

case "$final_choice" in
    1) show_shortcut_menu; exit 0 ;;
    2) launch_midnight_commander; exit 0 ;;
    3) exec bash ;;
    *) exit 0 ;;
esac

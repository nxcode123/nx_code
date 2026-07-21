#!/data/data/com.termux/files/usr/bin/bash

# --- KONFIGURASI UPDATE
NX_CODE_REPO_RAW_URL="https://raw.githubusercontent.com/nxcode123/nx_code/main/nx_code.sh"
NX_CODE_VERSION="v1.0.10"

# --- KONFIGURASI APP STORE
NX_APPS_MANIFEST_URL="https://raw.githubusercontent.com/nxcode123/nx_code_app/main/apps.list"
NX_APPS_SCRIPTS_BASE_URL="https://raw.githubusercontent.com/nxcode123/nx_code_app/main/scripts"

# --- KONFIGURASI TEMA WARNA ---
NX_THEME_FILE="$HOME/.nx_code_theme"
NX_AVAILABLE_THEMES=(cyberpunk matrix dracula ocean sunset mono)

# --- KONFIGURASI USER NON-ROOT UNTUK SESI GUI ---
NX_USER="nxuser"

# --- LOG ERROR ---
NX_LOG="$HOME/.nx_code_error.log"

# --- MODE NON-INTERAKTIF ---
export DEBIAN_FRONTEND=noninteractive
export DEBCONF_NONINTERACTIVE_SEEN=true

# File log sementara untuk progress bar
NX_STEP_LOG="${TMPDIR:-/tmp}/.nx_step.log"

# ==============================================================================
# HELPER: TEMA WARNA (CLASSY EDITION)
# ==============================================================================
load_theme() {
    local theme="cyberpunk"
    if [ -f "$NX_THEME_FILE" ]; then
        theme=$(cat "$NX_THEME_FILE" 2>/dev/null)
    fi

    DIM='\033[2m'
    BOLD='\033[1m'
    
    case "$theme" in
        matrix)
            CYAN='\033[0;32m'; NEON_GREEN='\033[1;92m'; NEON_PINK='\033[1;32m'
            PURPLE='\033[2;32m'; WHITE='\033[1;37m' ;;
        dracula)
            CYAN='\033[0;36m'; NEON_GREEN='\033[1;92m'; NEON_PINK='\033[1;35m'
            PURPLE='\033[0;35m'; WHITE='\033[1;37m' ;;
        ocean)
            CYAN='\033[0;34m'; NEON_GREEN='\033[1;36m'; NEON_PINK='\033[1;34m'
            PURPLE='\033[0;36m'; WHITE='\033[1;37m' ;;
        sunset)
            CYAN='\033[0;33m'; NEON_GREEN='\033[1;33m'; NEON_PINK='\033[1;31m'
            PURPLE='\033[0;31m'; WHITE='\033[1;37m' ;;
        mono)
            CYAN='\033[0;37m'; NEON_GREEN='\033[1;37m'; NEON_PINK='\033[1;37m'
            PURPLE='\033[2;37m'; WHITE='\033[1;37m' ;;
        *)
            theme="cyberpunk"
            CYAN='\033[0;36m'; NEON_GREEN='\033[1;32m'; NEON_PINK='\033[1;95m'
            PURPLE='\033[0;35m'; WHITE='\033[1;37m' ;;
    esac

    NX_CURRENT_THEME="$theme"
    NC='\033[0m'
    SUCCESS="${NEON_GREEN}●${NC}"
    PROCESS="${CYAN}❯${NC}"
}
load_theme

# ==============================================================================
# HELPER: OUTPUT MESSAGE (Gaya Minimalis)
# ==============================================================================
say_ok()    { echo -e "  ${SUCCESS} ${WHITE}$1${NC}"; }
say_proc()  { echo -e "\n  ${PROCESS} ${CYAN}$1${NC}"; }
say_err()   { echo -e "\n  ${NEON_PINK}✖ $1${NC}"; }
say_warn()  { echo -e "  ${NEON_PINK}▲ $1${NC}"; }
say_hint()  { echo -e "    ${DIM}↳ $1${NC}"; }
hr()        { echo -e "  ${DIM}──────────────────────────────────────────────────────${NC}"; }

# --- HELPER: BARIS MENU BER-BOX MODERN ---
print_menu_item() {
    printf "  ${PURPLE}│${NC}  ${NEON_PINK}[%-2s]${NC} ${WHITE}%-42s${NC} ${PURPLE}│${NC}\n" "$1" "$2"
}

log_section() {
    echo "" >> "$NX_LOG"
    echo "===== $(date '+%Y-%m-%d %H:%M:%S') | $1 =====" >> "$NX_LOG"
}

# ==============================================================================
# HELPER: EKSEKUSI DI DALAM UBUNTU
# ==============================================================================
ux() { proot-distro login ubuntu -- bash -c "$1"; }
ux_quiet() { proot-distro login ubuntu -- bash -c "$1" >/dev/null 2>&1; }
ux_ok() { proot-distro login ubuntu -- bash -c "$1" >/dev/null 2>&1; }

is_ubuntu_installed()      { proot-distro login ubuntu -- true >/dev/null 2>&1; }
is_termux_x11_installed()  { command -v termux-x11 >/dev/null 2>&1; }
is_xfce4_installed()       { ux_quiet "command -v startxfce4"; }
is_nonroot_user_setup()    { ux_quiet "id $NX_USER"; }
is_storage_setup()         { [ -d "$HOME/storage/shared" ]; }
is_safe_filename()         { [[ "$1" =~ ^[A-Za-z0-9._-]+$ ]]; }

setup_nonroot_user() {
    ux "
        useradd -m -s /bin/bash $NX_USER 2>/dev/null
        echo '$NX_USER ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/$NX_USER
        chmod 0440 /etc/sudoers.d/$NX_USER
        mkdir -p /storage
        chmod 755 /storage
        grep -q ELECTRON_DISABLE_SANDBOX /etc/environment 2>/dev/null || echo 'ELECTRON_DISABLE_SANDBOX=true' >> /etc/environment
    "
}

# --- FUNGSI PROGRESS: ELEGAN & BEBAS ERROR AWK ---
show_futuristic_progress() {
    local message="$1"
    local pid=$2
    local logfile="${3:-}"
    local total="${4:-0}"
    local label="$message"

    echo -ne "\033[?25l"
    while kill -0 "$pid" 2>/dev/null; do
        local cols=${COLUMNS:-50}
        [ "$cols" -lt 40 ] && cols=40

        local activity="$label"
        local done_count=0
        if [ -n "$logfile" ] && [ -s "$logfile" ]; then
            local candidate
            candidate=$(tail -n 1 "$logfile" 2>/dev/null | tr -cd '[:print:]')
            [ -n "$candidate" ] && activity="$candidate"
            if [ "$total" -gt 0 ]; then
                done_count=$(grep -Ec '^(Unpacking|Setting up|Preparing to unpack)' "$logfile" 2>/dev/null)
            fi
        fi

        if [ "$total" -gt 0 ]; then
            local percent=$(( done_count * 100 / total ))
            [ "$percent" -gt 100 ] && percent=100
            local bar_w=15
            [ "$cols" -lt 40 ] && bar_w=10
            local filled=$(( percent * bar_w / 100 ))
            local bar=""
            for ((j=0; j<filled; j++)); do bar="${bar}■"; done
            for ((j=filled; j<bar_w; j++)); do bar="${bar}□"; done
            printf "\r\033[K  ${DIM}╰─${NC} ${CYAN}[%s]${NC} ${NEON_GREEN}%3d%%${NC} ${DIM}│${NC} %s" "$bar" "$percent" "${activity:0:15}"
        else
            local budget=$(( cols - 10 ))
            [ "$budget" -lt 5 ] && budget=5
            activity="${activity:0:$budget}"
            printf "\r\033[K  ${DIM}╰─${NC} ${CYAN}↻${NC} %s" "$activity"
        fi

        sleep 0.15
    done

    printf "\r\033[K  ${SUCCESS} %s\n" "$label"
    echo -ne "\033[?25h"
}

# --- ANIMASI BOOTING ELEGAN ---
cyber_boot_sequence() {
    clear
    local boot_logs=(
        "Allocating memory spaces..."
        "Bypassing local encryption..."
        "Establishing secure tunnels..."
        "Preparing deployment vectors..."
    )
    echo -e "\n  ${BOLD}${WHITE}INITIATING SETUP PROTOCOL${NC}\n"
    sleep 0.3
    for log in "${boot_logs[@]}"; do
        echo -e "  ${DIM}│${NC} ${CYAN}${log}${NC}"
        sleep 0.3
    done
    echo -e "  ${SUCCESS} ${NEON_GREEN}SYSTEM READY.${NC}\n"
    sleep 0.5
}

# --- ANIMASI BOOTING LOGO (MODERN MINIMALIST) ---
animate_logo() {
    command clear
    local w=52
    echo -e "\n  ${PURPLE}╭$(printf '─%.0s' $(seq 1 $((w-2))))╮${NC}"
    local lines=(
        '    _   _ __  __  ____ ___  ____  _____ '
        '   | \ | |\ \/ / / ___/ _ \|  _ \| ____|'
        '   |  \| | \  / | |  | | | | | | |  _|  '
        '   | |\  | /  \ | |__| |_| | |_| | |___ '
        '   |_| \_|/_/\_\ \____\___/|____/|_____|'
    )
    for line in "${lines[@]}"; do
        printf "  ${PURPLE}│${NC} ${BOLD}${CYAN}%-48s${NC} ${PURPLE}│${NC}\n" "$line"
    done
    printf "  ${PURPLE}│${NC} ${DIM}%-48s${NC} ${PURPLE}│${NC}\n" "               WORKSPACE TERMINAL"
    echo -e "  ${PURPLE}├$(printf '─%.0s' $(seq 1 $((w-2))))┤${NC}"
    printf "  ${PURPLE}│${NC} ${WHITE}ST: ${NEON_GREEN}%-6s${WHITE} THM: ${NEON_PINK}%-9s${WHITE} VER: ${CYAN}%-11s${NC} ${PURPLE}│${NC}\n" "ONLINE" "${NX_CURRENT_THEME^^}" "$NX_CODE_VERSION"
    echo -e "  ${PURPLE}╰$(printf '─%.0s' $(seq 1 $((w-2))))╯${NC}\n"
}

# --- FUNGSI PILIH RESOLUSI LAYAR GUI ---
choose_resolution() {
    local res_choice custom_res

    hr
    echo -e "  ${WHITE}Pilih Resolusi Layar GUI:${NC}"
    echo -e "  ${PURPLE}[1]${NC} ${WHITE}Custom resolution${NC}"
    echo -e "  ${PURPLE}[2]${NC} ${WHITE}Native (Rekomendasi)${NC}"
    echo -e "  ${PURPLE}[0]${NC} ${WHITE}Batal & Kembali${NC}"
    hr
    echo -ne "  ${CYAN}Pilihan ❯${NC} "
    read res_choice

    case "$res_choice" in
        1)
            echo -ne "  ${CYAN}Format (WIDTHxHEIGHT, mis. 720x1440) ❯${NC} "
            read custom_res
            if [[ "$custom_res" =~ ^([0-9]+)x([0-9]+)$ ]]; then
                RES_W="${BASH_REMATCH[1]}"
                RES_H="${BASH_REMATCH[2]}"
            else
                say_warn "Format tidak valid. Memakai 720x1440."
                RES_W="720"; RES_H="1440"
            fi
            ;;
        2) RES_W=""; RES_H="" ;;
        0) GUI_CANCELLED=1 ;;
        *)
            say_warn "Pilihan tidak valid, memakai 720x1440."
            RES_W="720"; RES_H="1440"
            ;;
    esac
}

# --- FUNGSI TULIS SCRIPT STARTUP GUI KE DALAM UBUNTU (DENGAN AUDIO BRIDGE) ---
write_gui_startup_script() {
    local target_w="$1"
    local target_h="$2"
    
    proot-distro login ubuntu -- bash -c "cat > /usr/local/bin/nx-gui-startup.sh" << EOF
#!/bin/bash
export DISPLAY=:2
export ELECTRON_DISABLE_SANDBOX=true
export PULSE_SERVER=tcp:127.0.0.1:4713
sleep 2
OUT=\$(xrandr | grep " connected" | head -n1 | awk '{print \$1}')
if [ -n "$target_w" ]; then
    MODELINE=\$(cvt $target_w $target_h 60 2>/dev/null | grep Modeline)
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
    ux_ok "chmod 755 /usr/local/bin/nx-gui-startup.sh"
}

# --- FUNGSI FIX OTOMATIS "--no-sandbox" ---
setup_no_sandbox_fix() {
    ux_ok "mkdir -p /etc/profile.d; echo 'export ELECTRON_DISABLE_SANDBOX=1' > /etc/profile.d/nx_no_sandbox.sh"
    local apps="google-chrome google-chrome-stable chromium chromium-browser"
    local app
    for app in $apps; do
        ux_ok "test -x /usr/bin/$app && ! test -f /usr/local/bin/$app && { printf '#!/bin/bash\nexec /usr/bin/%s --no-sandbox \"\$@\"\n' '$app' > /usr/local/bin/$app; chmod +x /usr/local/bin/$app; }"
    done
}

# --- FUNGSI INISIALISASI AUDIO SERVER (PULSEAUDIO) ---
setup_audio_server() {
    if ! command -v pulseaudio >/dev/null 2>&1; then
        pkg install pulseaudio -y >/dev/null 2>&1
    fi
    if [ -f "$PREFIX/etc/pulse/default.pa" ]; then
        if ! grep -q "module-native-protocol-tcp" "$PREFIX/etc/pulse/default.pa"; then
            echo "load-module module-native-protocol-tcp auth-anonymous=1" >> "$PREFIX/etc/pulse/default.pa"
        fi
    fi
    pulseaudio --start --exit-idle-time=-1 >/dev/null 2>&1
}

# --- FUNGSI LAUNCH GUI UBUNTU ---
launch_ubuntu_gui() {
    local GUI_CANCELLED=0
    local RES_W="720"
    local RES_H="1440"
    local X11_PID

    if ! is_ubuntu_installed; then
        say_err "Ubuntu OS belum diinstal."
        return 1
    fi

    if ! is_termux_x11_installed; then
        say_err "termux-x11 belum terpasang. Jalankan ulang script."
        return 1
    fi

    setup_audio_server

    if ! is_xfce4_installed; then
        say_proc "Instalasi XFCE4 Environment (Satu Kali)..."
        log_section "INSTALL XFCE4"

        : > "$NX_STEP_LOG"
        (ux "apt update" > "$NX_STEP_LOG" 2>&1) &
        show_futuristic_progress "Updating repos" $! "$NX_STEP_LOG"
        cat "$NX_STEP_LOG" >> "$NX_LOG"

        local xfce_total
        xfce_total=$(ux "apt-get -s upgrade; apt-get -s install xfce4 xfce4-goodies dbus-x11 x11-xserver-utils sudo pulseaudio-utils alsa-utils" 2>/dev/null | grep -Ec '^(Inst|Conf)')
        [ -z "$xfce_total" ] && xfce_total=0

        : > "$NX_STEP_LOG"
        (ux "apt upgrade -y && apt install xfce4 xfce4-goodies dbus-x11 x11-xserver-utils sudo pulseaudio-utils alsa-utils -y" > "$NX_STEP_LOG" 2>&1) &
        local xfce_pid=$!
        show_futuristic_progress "Installing Desktop" "$xfce_pid" "$NX_STEP_LOG" "$xfce_total"
        cat "$NX_STEP_LOG" >> "$NX_LOG"
        if ! is_xfce4_installed; then
            say_err "Instalasi XFCE4 gagal. Cek log."
            return 1
        fi
        say_ok "XFCE4 berhasil dipasang."
    fi

    if ! ux_quiet "[ -f /usr/share/xfce4/backdrops/xubuntu-wallpaper.png ]"; then
        ux_ok "mkdir -p /usr/share/xfce4/backdrops && echo 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=' | base64 -d > /usr/share/xfce4/backdrops/xubuntu-wallpaper.png"
    fi

    if ! is_nonroot_user_setup; then
        say_proc "Menyiapkan workspace user '$NX_USER'..."
        setup_nonroot_user
        if is_nonroot_user_setup; then
            say_ok "User '$NX_USER' siap."
        else
            say_warn "Gagal membuat user non-root."
        fi
    fi

    setup_no_sandbox_fix
    choose_resolution
    
    if [ "$GUI_CANCELLED" -eq 1 ]; then
        say_hint "Dibatalkan."
        return 0
    fi
    
    write_gui_startup_script "$RES_W" "$RES_H"

    pkill -f "termux-x11" >/dev/null 2>&1
    sleep 1

    say_proc "Menyalakan Display & Audio Server (:2)..."

    if is_nonroot_user_setup; then
        cat > "$HOME/.nx_x11_launch.sh" << WRAPEOF
#!/data/data/com.termux/files/usr/bin/bash
proot-distro login ubuntu --shared-tmp --user $NX_USER -- bash /usr/local/bin/nx-gui-startup.sh
WRAPEOF
    else
        cat > "$HOME/.nx_x11_launch.sh" << WRAPEOF
#!/data/data/com.termux/files/usr/bin/bash
proot-distro login ubuntu --shared-tmp -- bash /usr/local/bin/nx-gui-startup.sh
WRAPEOF
    fi
    chmod +x "$HOME/.nx_x11_launch.sh"

    log_section "GUI LAUNCH (display :2)"
    termux-x11 :2 -xstartup "bash $HOME/.nx_x11_launch.sh" 2>&1 | tee -a "$NX_LOG" &
    X11_PID=$!

    sleep 2
    if ! kill -0 "$X11_PID" 2>/dev/null; then
        say_err "Gagal menyalakan X11. Cek log error."
        return 1
    fi

    am start --user 0 -n com.termux.x11/com.termux.x11.MainActivity >/dev/null 2>&1
    say_hint "Buka aplikasi 'Termux:X11' di Android."

    show_futuristic_progress "Sesi GUI Aktif..." "$X11_PID"
    wait "$X11_PID" 2>/dev/null
    say_ok "Sesi GUI ditutup."
}

# --- FUNGSI KILL GUI UBUNTU ---
kill_ubuntu_gui() {
    say_proc "Terminating GUI processes..."
    local found=0

    if pkill -f "termux-x11" >/dev/null 2>&1; then found=1; fi
    if ux_ok "pkill -u $NX_USER -f 'xfce4|dbus-launch|Xwayland' 2>/dev/null || pkill -f 'xfce4|dbus-launch|Xwayland'"; then found=1; fi
    if pkill -f "pulseaudio" >/dev/null 2>&1; then found=1; fi

    sleep 1
    if [ "$found" -eq 1 ]; then
        say_ok "Sesi dibersihkan."
    else
        say_hint "Tidak ada sesi aktif."
    fi
}

# --- FUNGSI CEK SESI GUI AKTIF ---
check_gui_session() {
    say_proc "Memeriksa sesi..."
    local x11_procs x11_count xfce_procs
    x11_procs=$(pgrep -af "termux-x11" 2>/dev/null)
    xfce_procs=$(ux "pgrep -af 'xfce4-session|startxfce4|dbus-launch'" 2>/dev/null)

    if [ -z "$x11_procs" ] && [ -z "$xfce_procs" ]; then
        say_ok "Aman. Tidak ada proses GUI."
        return 0
    fi

    echo ""
    if [ -n "$x11_procs" ]; then
        x11_count=$(echo "$x11_procs" | wc -l)
        echo -e "  ${DIM}▶ Termux:X11 (x${x11_count}) aktif.${NC}"
    fi
    if [ -n "$xfce_procs" ]; then
        echo -e "  ${DIM}▶ XFCE4/DBus aktif di Ubuntu.${NC}"
    fi

    echo ""
    echo -ne "  ${CYAN}Bersihkan semua sesi sekarang? (y/n) ❯${NC} "
    read clean_choice
    if [ "$clean_choice" == "y" ] || [ "$clean_choice" == "Y" ]; then
        kill_ubuntu_gui
    fi
}

# --- FUNGSI QUICK DEV-TOOLS INSTALLER ---
quick_devtools_installer() {
    if ! is_ubuntu_installed; then
        say_err "Ubuntu OS belum diinstal."
        return 1
    fi

    while true; do
        hr
        echo -e "  ${WHITE}DEV-TOOLS INSTALLER${NC}"
        echo -e "  ${PURPLE}[1]${NC} ${WHITE}Full Stack${NC} ${DIM}(git, python3, nodejs, gcc, curl...)${NC}"
        echo -e "  ${PURPLE}[2]${NC} ${WHITE}Git Only${NC}"
        echo -e "  ${PURPLE}[3]${NC} ${WHITE}Python3 + pip${NC}"
        echo -e "  ${PURPLE}[4]${NC} ${WHITE}Node.js + npm${NC}"
        echo -e "  ${PURPLE}[5]${NC} ${WHITE}C/C++ Build Tools${NC}"
        echo -e "  ${PURPLE}[0]${NC} ${WHITE}Kembali${NC}"
        hr
        echo -ne "  ${CYAN}Pilihan ❯${NC} "
        read dev_choice

        local pkgs=""
        case "$dev_choice" in
            1) pkgs="git python3 python3-pip nodejs npm build-essential curl wget vim nano" ;;
            2) pkgs="git" ;;
            3) pkgs="python3 python3-pip" ;;
            4) pkgs="nodejs npm" ;;
            5) pkgs="build-essential" ;;
            0) break ;;
            *) say_warn "Pilihan tidak valid."; continue ;;
        esac

        say_proc "Menyiapkan: ${pkgs}..."
        log_section "DEV-TOOLS INSTALL ($pkgs)"

        : > "$NX_STEP_LOG"
        (ux "apt update" > "$NX_STEP_LOG" 2>&1) &
        show_futuristic_progress "Updating package list" $! "$NX_STEP_LOG"
        
        local dev_total
        dev_total=$(ux "apt-get -s install -y $pkgs" 2>/dev/null | grep -Ec '^(Inst|Conf)')
        [ -z "$dev_total" ] && dev_total=0

        : > "$NX_STEP_LOG"
        (ux "apt install -y $pkgs" > "$NX_STEP_LOG" 2>&1) &
        show_futuristic_progress "Installing modules" $! "$NX_STEP_LOG" "$dev_total"
        say_ok "Modul terpasang."
    done
}

# --- FUNGSI CHECK UPDATE MANUAL ---
check_for_update() {
    say_proc "Sinkronisasi ke GitHub..."
    local tmp_file="$HOME/.nx_code_update_tmp.sh"
    rm -f "$tmp_file"

    if ! curl --silent --max-time 15 --retry 2 -fsSL "$NX_CODE_REPO_RAW_URL" -o "$tmp_file"; then
        say_err "Gagal. Cek koneksi internet."
        rm -f "$tmp_file"
        return 1
    fi

    if diff -q "$tmp_file" "$HOME/nx_code.sh" >/dev/null 2>&1; then
        say_ok "Sistem sudah up-to-date."
        rm -f "$tmp_file"
        return 0
    fi

    say_ok "Pembaruan tersedia!"
    echo -ne "  ${CYAN}Unduh dan terapkan pembaruan sekarang? (y/n) ❯${NC} "
    read update_choice

    if [ "$update_choice" == "y" ] || [ "$update_choice" == "Y" ]; then
        mv "$tmp_file" "$HOME/nx_code.sh"
        chmod +x "$HOME/nx_code.sh"
        say_proc "Restarting terminal UI..."
        sleep 1
        exec bash "$HOME/nx_code.sh"
    else
        say_hint "Pembaruan ditunda."
        rm -f "$tmp_file"
    fi
}

# --- FUNGSI LIHAT LOG ERROR ---
view_error_log() {
    while true; do
        hr
        echo -e "  ${WHITE}SYSTEM LOGS${NC}"
        echo -e "  ${PURPLE}[1]${NC} ${WHITE}Lihat log terbaru${NC} ${DIM}(50 baris)${NC}"
        echo -e "  ${PURPLE}[2]${NC} ${WHITE}Bersihkan log${NC}"
        echo -e "  ${PURPLE}[0]${NC} ${WHITE}Kembali${NC}"
        hr
        echo -ne "  ${CYAN}Pilihan ❯${NC} "
        read log_choice

        case "$log_choice" in
            1)
                if [ -s "$NX_LOG" ]; then
                    hr
                    tail -n 50 "$NX_LOG" | sed 's/^/  /'
                    hr
                else
                    say_ok "Log bersih. Tidak ada error."
                fi
                ;;
            2)
                rm -f "$NX_LOG"
                say_ok "Log telah dihapus."
                ;;
            0) break ;;
            *) say_warn "Tidak valid." ;;
        esac
    done
}

# --- FUNGSI GANTI TEMA WARNA ---
select_theme_menu() {
    while true; do
        hr
        echo -e "  ${WHITE}UI THEMES${NC} ${DIM}(Aktif: ${NX_CURRENT_THEME})${NC}"
        hr

        local i=1
        for t in "${NX_AVAILABLE_THEMES[@]}"; do
            if [ "$t" == "$NX_CURRENT_THEME" ]; then
                echo -e "  ${PURPLE}[$i]${NC} ${WHITE}${t}${NC} ${NEON_GREEN}●${NC}"
            else
                echo -e "  ${PURPLE}[$i]${NC} ${DIM}${t}${NC}"
            fi
            i=$((i+1))
        done
        echo -e "  ${PURPLE}[0]${NC} ${WHITE}Simpan & Kembali${NC}"
        hr
        echo -ne "  ${CYAN}Pilihan ❯${NC} "
        read theme_choice

        if [ "$theme_choice" == "0" ]; then break; fi

        local idx=$((theme_choice - 1))
        local chosen="${NX_AVAILABLE_THEMES[$idx]:-}"

        if [ -z "$chosen" ]; then
            say_warn "Pilihan tidak valid."
            continue
        fi

        echo "$chosen" > "$NX_THEME_FILE"
        load_theme
        animate_logo
        say_ok "Tema diaplikasikan."
    done
}

# --- FUNGSI APP STORE ---
app_store_menu() {
    if ! is_ubuntu_installed; then
        say_err "Ubuntu OS belum terinstal."
        return 1
    fi

    say_proc "Menghubungkan ke App Repository..."
    local manifest="$HOME/.nx_apps_manifest.tmp"
    rm -f "$manifest"

    if ! curl --silent --max-time 15 -fsSL "$NX_APPS_MANIFEST_URL" -o "$manifest"; then
        say_err "Koneksi ke App Store gagal."
        return 1
    fi

    sed -i 's/\r$//' "$manifest" 2>/dev/null

    local names=() scripts=()
    while IFS='|' read -r a_name a_script a_rest; do
        [ -z "$a_name" ] && continue
        if [ -n "$a_script" ] && ! is_safe_filename "$a_script"; then continue; fi
        names+=("$a_name")
        scripts+=("$a_script")
    done < "$manifest"
    rm -f "$manifest"

    if [ "${#names[@]}" -eq 0 ]; then
        say_err "Repositori kosong."
        return 1
    fi

    while true; do
        hr
        echo -e "  ${WHITE}SOFTWARE CENTER${NC}"
        for i in "${!names[@]}"; do
            printf "  ${PURPLE}[%d]${NC} ${WHITE}%s${NC}\n" "$((i+1))" "${names[$i]}"
        done
        echo -e "  ${PURPLE}[0]${NC} ${WHITE}Kembali${NC}"
        hr
        echo -ne "  ${CYAN}Pilihan ❯${NC} "
        read app_choice

        if [ "$app_choice" == "0" ]; then break; fi

        local idx=$((app_choice - 1))
        if [ -z "${names[$idx]:-}" ]; then
            say_warn "Tidak valid."
            continue
        fi

        say_proc "Mengunduh ${names[$idx]}..."
        log_section "APP INSTALL: ${names[$idx]}"

        local target_url="$NX_APPS_SCRIPTS_BASE_URL/${scripts[$idx]}"
        local tmp_script="$HOME/.tmp_install_$(basename "${scripts[$idx]}")"

        if curl --silent --max-time 30 -fsSL "$target_url" -o "$tmp_script"; then
            if [ -s "$tmp_script" ]; then
                if ! bash -n "$tmp_script"; then
                    say_err "Syntax error pada script yang diunduh. Batal."
                    rm -f "$tmp_script"
                    continue
                fi

                say_proc "Menjalankan proses instalasi..."
                proot-distro login ubuntu -- bash < "$tmp_script" 2>&1 | tee -a "$NX_LOG"

                if [ "${PIPESTATUS[0]}" -eq 0 ]; then
                    say_ok "${names[$idx]} sukses diinstal."
                else
                    say_err "Gagal. Cek log."
                fi
            else
                say_err "Script kosong / URL mati."
            fi
        else
            say_err "Gagal mengunduh."
        fi
        rm -f "$tmp_script"
    done
}

# --- FUNGSI PANEL MENU SHORTCUT ---
show_shortcut_menu() {
    while true; do
        animate_logo
        local w=52
        echo -e "  ${PURPLE}╭$(printf '─%.0s' $(seq 1 $((w-2))))╮${NC}"
        print_menu_item "1"  "Masuk Ubuntu (CLI)"
        print_menu_item "2"  "Masuk Ubuntu (GUI - XFCE4)"
        print_menu_item "3"  "Matikan Sesi GUI"
        print_menu_item "4"  "Status Background Proses"
        print_menu_item "5"  "Dev-Tools Installer"
        print_menu_item "6"  "System Monitor (HTop)"
        print_menu_item "7"  "System Update"
        print_menu_item "8"  "Diagnostic Logs"
        print_menu_item "9"  "Software Center (App Store)"
        print_menu_item "10" "Pengaturan Tema Visual"
        echo -e "  ${PURPLE}├$(printf '─%.0s' $(seq 1 $((w-2))))┤${NC}"
        print_menu_item "0"  "Tutup Panel"
        echo -e "  ${PURPLE}╰$(printf '─%.0s' $(seq 1 $((w-2))))╯${NC}"
        echo -ne "  ${CYAN}Execute ❯${NC} "
        read pilihan

        case $pilihan in
            1)
                say_proc "Booting Core..."
                sleep 1
                if is_ubuntu_installed; then
                    proot-distro login ubuntu
                else
                    say_err "Ubuntu belum terinstal."
                fi
                sleep 1 ;;
            2) launch_ubuntu_gui; sleep 1 ;;
            3) kill_ubuntu_gui; sleep 1 ;;
            4) check_gui_session; echo -ne "  ${DIM}Tekan Enter...${NC}"; read; ;;
            5) quick_devtools_installer; sleep 1 ;;
            6) htop ;;
            7) check_for_update; sleep 1 ;;
            8) view_error_log; sleep 1 ;;
            9) app_store_menu; sleep 1 ;;
            10) select_theme_menu; sleep 1 ;;
            0) echo -e "\n  ${SUCCESS} Disconnected.\n"; break ;;
            *) echo -e "\n  ${NEON_PINK}✖ Invalid syntax.${NC}"; sleep 1 ;;
        esac
    done
}

# ==============================================================================
# HELPER: FUNGSI CEK UPDATE UNTUK UI
# ==============================================================================
run_ui_update_check() {
    local tmp_chk="$TMPDIR/.nx_up_check.tmp"
    if curl --silent --max-time 5 -fsSL "$NX_CODE_REPO_RAW_URL" -o "$tmp_chk" 2>/dev/null; then
        if diff -q "$tmp_chk" "$HOME/nx_code.sh" >/dev/null 2>&1; then
            echo "up-to-date" > "$TMPDIR/.nx_up_status"
        else
            echo "update-available" > "$TMPDIR/.nx_up_status"
        fi
        rm -f "$tmp_chk"
    else
        echo "offline" > "$TMPDIR/.nx_up_status"
    fi
}

# ==============================================================================
# ENTRY POINTS
# ==============================================================================
if [ "$1" == "--logo-only" ]; then
    animate_logo
    exit 0
fi

if [ "$1" == "--menu" ]; then
    show_shortcut_menu
    exit 0
fi

if [ "$1" == "--ui-only" ]; then
    animate_logo

    ub_status="${DIM}Offline${NC}"
    st_status="${DIM}Unlinked${NC}"
    clean_status="${DIM}Skipped${NC}"
    update_status="${DIM}Checking...${NC}"

    (sleep 0.4) &
    show_futuristic_progress "Scanning Ubuntu Core" $!
    is_ubuntu_installed && ub_status="${NEON_GREEN}Active${NC}"

    (sleep 0.3) &
    show_futuristic_progress "Verifying Storage" $!
    is_storage_setup && st_status="${NEON_GREEN}Linked${NC}"

    LAST_CLEAN_FILE="$HOME/.nx_code_last_clean"
    TODAY=$(date +%Y%m%d)
    LAST_CLEAN=""
    [ -f "$LAST_CLEAN_FILE" ] && LAST_CLEAN=$(cat "$LAST_CLEAN_FILE" 2>/dev/null)

    if [ "$TODAY" != "$LAST_CLEAN" ]; then
        (
            pkg clean -y
            if [ -n "$TMPDIR" ] && [ -d "$TMPDIR" ]; then rm -rf "${TMPDIR:?}"/* 2>/dev/null; fi
        ) > /dev/null 2>&1 &
        show_futuristic_progress "Flushing Cache" $!
        echo "$TODAY" > "$LAST_CLEAN_FILE"
        clean_status="${NEON_GREEN}Cleaned${NC}"
    fi

    # Menjalankan fungsi pengecekan update agar aman dari error deklarasi local
    run_ui_update_check &
    show_futuristic_progress "Check Update" $!

    if [ -f "$TMPDIR/.nx_up_status" ]; then
        local st_res
        st_res=$(cat "$TMPDIR/.nx_up_status")
        if [ "$st_res" == "up-to-date" ]; then
            update_status="${NEON_GREEN}Up-to-Date${NC}"
        elif [ "$st_res" == "update-available" ]; then
            update_status="${NEON_PINK}Update Available${NC}"
        else
            update_status="${DIM}Offline${NC}"
        fi
        rm -f "$TMPDIR/.nx_up_status"
    else
        update_status="${DIM}Skipped${NC}"
    fi

    echo ""
    echo -e "  ${PURPLE}╭──────────────────────────────────────────────────╮${NC}"
    printf "  ${PURPLE}│${NC} %-20s %-39b${PURPLE}│${NC}\n" "System Core"    "$ub_status"
    printf "  ${PURPLE}│${NC} %-20s %-39b${PURPLE}│${NC}\n" "Local Storage"  "$st_status"
    printf "  ${PURPLE}│${NC} %-20s %-39b${PURPLE}│${NC}\n" "Daily Optimizer" "$clean_status"
    printf "  ${PURPLE}│${NC} %-20s %-39b${PURPLE}│${NC}\n" "Check Update"   "$update_status"
    echo -e "  ${PURPLE}╰──────────────────────────────────────────────────╯${NC}"
    echo -e "\n  ${DIM}Ketik${NC} ${CYAN}nx-menu${NC} ${DIM}untuk membuka interface utama.${NC}\n"
    exit 0
fi

# ==============================================================================
# MODE INSTALASI AWAL (SILENT & CLASSY)
# ==============================================================================
cyber_boot_sequence
animate_logo

say_proc "Injecting Base Dependencies..."

: > "$NX_STEP_LOG"
(
    pkg update -y -o Dpkg::Options::="--force-confold" && \
    pkg upgrade -y -o Dpkg::Options::="--force-confold" && \
    pkg install proot-distro htop coreutils x11-repo curl ncurses-utils pulseaudio -y -o Dpkg::Options::="--force-confold"
) > "$NX_STEP_LOG" 2>&1 &
show_futuristic_progress "Configuring Repositories" $! "$NX_STEP_LOG"

: > "$NX_STEP_LOG"
(pkg install termux-x11-nightly -y -o Dpkg::Options::="--force-confold" > "$NX_STEP_LOG" 2>&1) &
show_futuristic_progress "Mounting Display Engines" $! "$NX_STEP_LOG"

if ! is_ubuntu_installed; then
    say_proc "Generating Virtual Environment..."
    proot-distro remove ubuntu > /dev/null 2>&1
    
    : > "$NX_STEP_LOG"
    (proot-distro install ubuntu > "$NX_STEP_LOG" 2>&1) &
    show_futuristic_progress "Downloading Ubuntu Core (Bisa memakan waktu)" $! "$NX_STEP_LOG"
fi

echo ""
if is_ubuntu_installed; then
    say_ok "OS Core        : ${NEON_GREEN}Operational${NC}"
else
    say_err "OS Core        : Failed"
fi

if is_termux_x11_installed; then
    say_ok "Display Server : ${NEON_GREEN}Operational${NC}"
else
    say_err "Display Server : Failed"
fi

copy_self_to_home() {
    local dest="$HOME/nx_code.sh"
    
    if [ ! -f "$0" ] || [ "$0" = "bash" ] || [ "$0" = "-bash" ]; then
        curl --silent --max-time 15 -fsSL "$NX_CODE_REPO_RAW_URL" -o "$dest" 2>/dev/null
        if [ -s "$dest" ]; then
            chmod +x "$dest"
            return 0
        fi
        return 1
    fi

    local src=""
    if [ -n "${BASH_SOURCE[0]}" ] && [ -f "${BASH_SOURCE[0]}" ]; then 
        src=$(realpath "${BASH_SOURCE[0]}" 2>/dev/null)
    elif [ -f "$0" ]; then 
        src=$(realpath "$0" 2>/dev/null); 
    fi

    if [ -n "$src" ] && [ -f "$src" ] && [ "$src" != "$dest" ]; then
        cp "$src" "$dest"
        chmod +x "$dest"
        return 0
    fi
    
    [ -f "$dest" ] && return 0
    return 1
}

if copy_self_to_home; then
    chmod +x "$HOME/nx_code.sh" 2>/dev/null
fi

if grep -q 'command rm -i "\$@"' "$HOME/.bashrc" 2>/dev/null; then
    sed -i 's/command rm -i "\$@"/command rm "\$@"/' "$HOME/.bashrc"
fi

if ! grep -q "NX_CODE ENVIRONMENT" "$HOME/.bashrc" 2>/dev/null; then
    cat << 'EOF' >> "$HOME/.bashrc"

# --- NX_CODE ENVIRONMENT ---
if [ -f "$HOME/nx_code.sh" ]; then bash "$HOME/nx_code.sh" --ui-only; fi

alias ls='ls --color=auto --group-directories-first'
alias ll='ls -la --color=auto --group-directories-first'
alias nx-menu='bash $HOME/nx_code.sh --menu'

PS1="\n\[\033[1;36m\]╭─\[\033[1;32m\]nxuser\[\033[0;37m\]@\[\033[1;35m\]terminal\[\033[0m\] \[\033[2m\]\w\[\033[0m\]\n\[\033[1;36m\]╰─❯ \[\033[0m\]"

clear() {
    command clear
    if [ -f "$HOME/nx_code.sh" ]; then bash "$HOME/nx_code.sh" --logo-only; fi
}

rm() {
    if [ $# -eq 0 ]; then
        echo -e "\033[1;91m✖ Target file not specified.\033[0m"
        return 1
    fi
    command rm "$@"
}
# ---------------------------
EOF
    say_ok "Boot Sequence  : ${NEON_GREEN}Injected${NC}"
fi

(dpkg -l | grep "^ii" > "$TMPDIR/installed_pkgs.txt"; sleep 0.5) 2>/dev/null &
show_futuristic_progress "Validating Subsystems" $!

echo -e "\n  ${SUCCESS} ${NEON_GREEN}INSTALLATION COMPLETE${NC}"
hr

echo -e "  ${WHITE}Terminal memerlukan proses Restart:${NC}"
echo -e "  ${PURPLE}[1]${NC} ${WHITE}Restart Otomatis (Rekomendasi)${NC}"
echo -e "  ${PURPLE}[0]${NC} ${WHITE}Keluar${NC}"
echo -ne "  ${CYAN}Pilihan ❯${NC} "
read final_choice

case "$final_choice" in
    1) exec bash ;;
    0|*) exit 0 ;;
esac

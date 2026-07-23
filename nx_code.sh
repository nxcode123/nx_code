#!/data/data/com.termux/files/usr/bin/bash

# --- KONFIGURASI UPDATE
NX_CODE_REPO_RAW_URL="https://raw.githubusercontent.com/nxcode123/nx_code/main/nx_code.sh"
NX_CODE_VERSION="v1.2.0"

# --- KONFIGURASI TEMA WARNA ---
NX_THEME_FILE="$HOME/.nx_code_theme"
NX_AVAILABLE_THEMES=(cyberpunk matrix dracula ocean sunset mono)

# --- KONFIGURASI USER NON-ROOT UNTUK SESI GUI ---
NX_USER="nxuser"

# --- RESOLUSI DEFAULT ---
NX_DEFAULT_RES_W="720"
NX_DEFAULT_RES_H="1440"

# --- LOG ERROR & TEMP ---
NX_LOG="$HOME/.nx_code_error.log"
NX_TEMP_DIR="$HOME/.tmp"
mkdir -p "$NX_TEMP_DIR"

# --- MODE NON-INTERAKTIF ---
export DEBIAN_FRONTEND=noninteractive
export DEBCONF_NONINTERACTIVE_SEEN=true

# --- PIPEFAIL ---
set -o pipefail

# File log sementara untuk progress bar
NX_STEP_LOG="$NX_TEMP_DIR/.nx_step.log"

# --- TRAP: Pastikan kursor selalu muncul kembali jika script terhenti paksa ---
trap 'echo -ne "\033[?25h"' EXIT

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
# HELPER: OUTPUT MESSAGE & LOGGING
# ==============================================================================
say_ok()    { echo -e "  ${SUCCESS} ${WHITE}$1${NC}"; }
say_proc()  { echo -e "\n  ${PROCESS} ${CYAN}$1${NC}"; }
say_err()   { echo -e "\n  ${NEON_PINK}✖ $1${NC}"; }
say_warn()  { echo -e "  ${NEON_PINK}▲ $1${NC}"; }
say_hint()  { echo -e "    ${DIM}↳ $1${NC}"; }
hr()        { echo -e "  ${DIM}──────────────────────────────────────────────────────${NC}"; }

print_menu_item() {
    printf "  ${PURPLE}│${NC}  ${NEON_PINK}[%-2s]${NC} ${WHITE}%-42s${NC} ${PURPLE}│${NC}\n" "$1" "$2"
}

log_section() {
    rotate_log_if_needed
    echo "" >> "$NX_LOG"
    echo "===== $(date '+%Y-%m-%d %H:%M:%S') | $1 =====" >> "$NX_LOG"
}

rotate_log_if_needed() {
    [ -f "$NX_LOG" ] || return 0
    local max_bytes=$((2 * 1024 * 1024))
    local size
    size=$(wc -c < "$NX_LOG" 2>/dev/null || echo 0)
    if [ "$size" -gt "$max_bytes" ]; then
        tail -n 500 "$NX_LOG" > "$NX_LOG.tmp" 2>/dev/null && mv "$NX_LOG.tmp" "$NX_LOG"
    fi
}

# ==============================================================================
# HELPER: EKSEKUSI DI DALAM UBUNTU
# ==============================================================================
ux() { proot-distro login ubuntu -- env DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true bash -c "$1"; }
ux_quiet() { proot-distro login ubuntu -- env DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true bash -c "$1" >/dev/null 2>>"$NX_LOG"; }
ux_ok() { ux_quiet "$1"; }

run_tracked() {
    local label="$1" logfile="$2" total="$3"
    shift 4

    : > "$logfile"
    ( "$@" > "$logfile" 2>&1 ) &
    local pid=$!
    show_futuristic_progress "$label" "$pid" "$logfile" "$total"
    wait "$pid"
    LAST_JOB_STATUS=$?
    cat "$logfile" >> "$NX_LOG"
    return "$LAST_JOB_STATUS"
}

is_ubuntu_installed()      { proot-distro login ubuntu -- true >/dev/null 2>&1; }
is_termux_x11_installed()  { command -v termux-x11 >/dev/null 2>&1; }
is_xfce4_installed()       { ux_quiet "command -v startxfce4"; }
is_nonroot_user_setup()    { ux_quiet "id $NX_USER"; }
is_storage_setup()         { [ -d "$HOME/storage/shared" ]; }

preseed_debconf_answers() {
    ux_ok "debconf-set-selections <<'PRESEED'
keyboard-configuration  keyboard-configuration/layout           select  English (US)
keyboard-configuration  keyboard-configuration/layoutcode       string  us
keyboard-configuration  keyboard-configuration/variant          select  English (US)
keyboard-configuration  keyboard-configuration/model            select  Generic 105-key (Intl) PC
keyboard-configuration  keyboard-configuration/altgr            select  The default for the keyboard layout
keyboard-configuration  keyboard-configuration/unsupported_layout boolean true
keyboard-configuration  keyboard-configuration/unsupported_config_layout boolean true
tzdata                  tzdata/Areas                            select  Etc
tzdata                  tzdata/Zones/Etc                        select  UTC
PRESEED"
}

setup_nonroot_user() {
    ux "
        if ! id $NX_USER >/dev/null 2>&1; then
            useradd -m -s /bin/bash $NX_USER 2>/dev/null
        fi
        echo '$NX_USER ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/$NX_USER
        chmod 0440 /etc/sudoers.d/$NX_USER
        mkdir -p /storage
        chmod 755 /storage
        grep -q ELECTRON_DISABLE_SANDBOX /etc/environment 2>/dev/null || echo 'ELECTRON_DISABLE_SANDBOX=true' >> /etc/environment
    "
}

show_futuristic_progress() {
    local message="$1"
    local pid=$2
    local logfile="${3:-}"
    local total="${4:-0}"
    local label="$message"

    local spin_chars='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    local spin_i=0

    echo -ne "\033[?25l"
    while kill -0 "$pid" 2>/dev/null; do
        local cols=${COLUMNS:-50}
        [ "$cols" -lt 40 ] && cols=40

        local activity="$label"
        local done_count=0
        if [ -n "$logfile" ] && [ -s "$logfile" ]; then
            local candidate
            candidate=$(tail -n 1 "$logfile" 2>/dev/null | sed -E 's/\x1B\[[0-9;?]*[a-zA-Z//=?]*//g; s/\x1B\([B012]//g' | tr -cd '[:print:]')
            [ -n "$candidate" ] && activity="$candidate"
            if [ "$total" -gt 0 ]; then
                done_count=$(grep -Ec '^(Unpacking|Setting up|Preparing to unpack)' "$logfile" 2>/dev/null)
            fi
        fi

        local char="${spin_chars:spin_i:1}"
        spin_i=$(( (spin_i + 1) % ${#spin_chars} ))

        if [ "$total" -gt 0 ]; then
            local percent=$(( done_count * 100 / total ))
            [ "$percent" -gt 100 ] && percent=100
            local bar_w=12
            [ "$cols" -lt 40 ] && bar_w=8
            local filled=$(( percent * bar_w / 100 ))
            local bar=""
            for ((j=0; j<filled; j++)); do bar="${bar}■"; done
            for ((j=filled; j<bar_w; j++)); do bar="${bar}□"; done

            local max_len=$(( cols - 35 ))
            [ "$max_len" -lt 10 ] && max_len=10
            activity="${activity:0:$max_len}"

            printf "\r\033[K  ${DIM}╰─${NC} ${CYAN}[%s]${NC} ${NEON_GREEN}%3d%%${NC} ${DIM}│${NC} ${CYAN}%s${NC} %s" "$bar" "$percent" "$char" "$activity"
        else
            local budget=$(( cols - 15 ))
            [ "$budget" -lt 5 ] && budget=5
            activity="${activity:0:$budget}"
            printf "\r\033[K  ${DIM}╰─${NC} ${CYAN}%s${NC} %s" "$char" "$activity"
        fi

        sleep 0.1
    done

    printf "\r\033[K  ${SUCCESS} %s\n" "$label"
    echo -ne "\033[?25h"
}

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

choose_resolution() {
    local res_choice custom_res

    hr
    echo -e "  ${WHITE}Pilih Resolusi Layar GUI:${NC}"
    echo -e "  ${PURPLE}[1]${NC} ${WHITE}Custom resolution${NC}"
    echo -e "  ${PURPLE}[2]${NC} ${WHITE}Native (Rekomendasi)${NC}"
    echo -e "  ${PURPLE}[0]${NC} ${WHITE}Batal & Kembali${NC}"
    hr
    echo -ne "  ${CYAN}Pilihan ❯${NC} "
    read -r res_choice

    case "$res_choice" in
        1)
            echo -ne "  ${CYAN}Format (WIDTHxHEIGHT, mis. ${NX_DEFAULT_RES_W}x${NX_DEFAULT_RES_H}) ❯${NC} "
            read -r custom_res
            if [[ "$custom_res" =~ ^([0-9]+)x([0-9]+)$ ]]; then
                local w="${BASH_REMATCH[1]}"
                local h="${BASH_REMATCH[2]}"
                if [ "$w" -ge 400 ] && [ "$w" -le 7680 ] && [ "$h" -ge 400 ] && [ "$h" -le 4320 ]; then
                    RES_W="$w"
                    RES_H="$h"
                else
                    say_warn "Resolusi di luar batas wajar. Memakai ${NX_DEFAULT_RES_W}x${NX_DEFAULT_RES_H}."
                    RES_W="$NX_DEFAULT_RES_W"; RES_H="$NX_DEFAULT_RES_H"
                fi
            else
                say_warn "Format tidak valid. Memakai ${NX_DEFAULT_RES_W}x${NX_DEFAULT_RES_H}."
                RES_W="$NX_DEFAULT_RES_W"; RES_H="$NX_DEFAULT_RES_H"
            fi
            ;;
        2) RES_W=""; RES_H="" ;;
        0) GUI_CANCELLED=1 ;;
        *)
            say_warn "Pilihan tidak valid, memakai ${NX_DEFAULT_RES_W}x${NX_DEFAULT_RES_H}."
            RES_W="$NX_DEFAULT_RES_W"; RES_H="$NX_DEFAULT_RES_H"
            ;;
    esac
}

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
    if ! command -v cvt >/dev/null 2>&1; then
        echo "[nx-gui] PERINGATAN: 'cvt' tidak ditemukan." >&2
    else
        MODELINE=\$(cvt $target_w $target_h 60 2>/dev/null | grep Modeline)
        if [ -n "\$MODELINE" ]; then
            MODE_NAME=\$(echo "\$MODELINE" | awk '{print \$2}' | tr -d '"')
            MODE_PARAMS=\$(echo "\$MODELINE" | cut -d' ' -f3-)
            xrandr --newmode "\$MODE_NAME" \$MODE_PARAMS 2>/dev/null
            xrandr --addmode "\$OUT" "\$MODE_NAME" 2>/dev/null
            xrandr --output "\$OUT" --mode "\$MODE_NAME" 2>/dev/null
        fi
    fi
fi
dbus-launch --exit-with-session startxfce4
EOF
    ux_ok "chmod 755 /usr/local/bin/nx-gui-startup.sh"
}

setup_no_sandbox_fix() {
    ux_ok "mkdir -p /etc/profile.d; echo 'export ELECTRON_DISABLE_SANDBOX=1' > /etc/profile.d/nx_no_sandbox.sh"
    local apps="google-chrome google-chrome-stable chromium chromium-browser"
    for app in $apps; do
        ux_ok "test -x /usr/bin/$app && ! test -f /usr/local/bin/$app && { printf '#!/bin/bash\nexec /usr/bin/%s --no-sandbox \"\$@\"\n' '$app' > /usr/local/bin/$app; chmod +x /usr/local/bin/$app; }"
    done
}

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

launch_ubuntu_gui() {
    GUI_CANCELLED=0
    RES_W="$NX_DEFAULT_RES_W"
    RES_H="$NX_DEFAULT_RES_H"
    local X11_PID

    if ! is_ubuntu_installed; then
        say_err "Ubuntu OS belum diinstal."
        return 1
    fi

    if ! is_termux_x11_installed; then
        say_err "termux-x11 belum terpasang."
        return 1
    fi

    setup_audio_server

    if ! is_xfce4_installed; then
        say_proc "Instalasi XFCE4 Environment (Satu Kali)..."
        log_section "INSTALL XFCE4"
        preseed_debconf_answers

        run_tracked "Updating repos" "$NX_STEP_LOG" 0 -- ux "apt-get update -y"
        if [ "$LAST_JOB_STATUS" -ne 0 ]; then
            say_err "Gagal update repo Ubuntu."
            return 1
        fi

        local xfce_total
        xfce_total=$(ux "apt-get -s upgrade; apt-get -s install xfce4 xfce4-goodies dbus-x11 x11-xserver-utils xserver-xorg-core sudo pulseaudio-utils alsa-utils" 2>/dev/null | grep -Ec '^(Inst|Conf)')
        [ -z "$xfce_total" ] && xfce_total=0

        run_tracked "Installing Desktop" "$NX_STEP_LOG" "$xfce_total" -- \
            ux "apt-get upgrade -y && apt-get install xfce4 xfce4-goodies dbus-x11 x11-xserver-utils xserver-xorg-core sudo pulseaudio-utils alsa-utils -y"

        if [ "$LAST_JOB_STATUS" -ne 0 ]; then
            say_err "Instalasi XFCE4 gagal."
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
    termux-x11 :2 -xstartup "bash $HOME/.nx_x11_launch.sh" >> "$NX_LOG" 2>&1 &
    X11_PID=$!

    sleep 2
    if ! kill -0 "$X11_PID" 2>/dev/null; then
        say_err "Gagal menyalakan X11."
        return 1
    fi

    am start --user 0 -n com.termux.x11/com.termux.x11.MainActivity >/dev/null 2>&1
    say_hint "Buka aplikasi 'Termux:X11' di Android."

    local session_pid=""
    for _ in 1 2 3 4 5 6 7 8 9 10; do
        session_pid=$(ux "pgrep -f xfce4-session 2>/dev/null | head -n1" 2>/dev/null)
        [ -n "$session_pid" ] && break
        sleep 1
    done
    {
        echo "X11_PID=$X11_PID"
        echo "SESSION_PID=$session_pid"
    } > "$NX_TEMP_DIR/.nx_gui_state"

    show_futuristic_progress "Sesi GUI Aktif..." "$X11_PID"
    wait "$X11_PID" 2>/dev/null
    rm -f "$NX_TEMP_DIR/.nx_gui_state"
    say_ok "Sesi GUI ditutup."
}

kill_ubuntu_gui() {
    say_proc "Terminating GUI processes..."
    local found=0

    if [ -f "$NX_TEMP_DIR/.nx_gui_state" ]; then
        # shellcheck disable=SC1091
        source "$NX_TEMP_DIR/.nx_gui_state" 2>/dev/null
        
        if [ -n "${SESSION_PID:-}" ]; then
            ux_ok "kill $SESSION_PID 2>/dev/null"
            found=1
        fi
        
        if [ -n "${X11_PID:-}" ] && kill -0 "$X11_PID" 2>/dev/null; then
            kill "$X11_PID" 2>/dev/null
            found=1
        fi
        
        rm -f "$NX_TEMP_DIR/.nx_gui_state"
        sleep 2
    fi

    if pgrep -f "termux-x11" >/dev/null 2>&1 || ux_quiet "pgrep -f 'xfce4-session|dbus-launch|Xwayland'"; then
        pkill -f "termux-x11" >/dev/null 2>&1 && found=1
        ux_ok "pkill -u $NX_USER -f 'xfce4|dbus-launch|Xwayland' 2>/dev/null || pkill -f 'xfce4|dbus-launch|Xwayland'" && found=1
    fi
    pkill -f "pulseaudio" >/dev/null 2>&1 && found=1

    sleep 1
    if [ "$found" -eq 1 ]; then
        say_ok "Sesi dibersihkan."
    else
        say_hint "Tidak ada sesi aktif."
    fi
}

check_gui_session() {
    say_proc "Memeriksa sesi..."
    local x11_procs xfce_procs
    x11_procs=$(pgrep -af "termux-x11" 2>/dev/null)
    xfce_procs=$(ux "pgrep -af 'xfce4-session|startxfce4|dbus-launch'" 2>/dev/null)

    if [ -z "$x11_procs" ] && [ -z "$xfce_procs" ]; then
        say_ok "Aman. Tidak ada proses GUI."
        return 0
    fi

    echo ""
    [ -n "$x11_procs" ] && echo -e "  ${DIM}▶ Termux:X11 aktif.${NC}"
    [ -n "$xfce_procs" ] && echo -e "  ${DIM}▶ XFCE4/DBus aktif di Ubuntu.${NC}"

    echo ""
    echo -ne "  ${CYAN}Bersihkan semua sesi sekarang? (y/n) ❯${NC} "
    read -r clean_choice
    [[ "$clean_choice" =~ ^[yY]$ ]] && kill_ubuntu_gui
}

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
        read -r dev_choice

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
        preseed_debconf_answers

        run_tracked "Updating package list" "$NX_STEP_LOG" 0 -- ux "apt-get update -y"
        if [ "$LAST_JOB_STATUS" -ne 0 ]; then
            say_err "Gagal update repo."
            continue
        fi

        local dev_total
        dev_total=$(ux "apt-get -s install -y $pkgs" 2>/dev/null | grep -Ec '^(Inst|Conf)')
        [ -z "$dev_total" ] && dev_total=0

        run_tracked "Installing modules" "$NX_STEP_LOG" "$dev_total" -- ux "apt-get install -y $pkgs"
        if [ "$LAST_JOB_STATUS" -ne 0 ]; then
            say_err "Instalasi paket gagal."
            continue
        fi
        say_ok "Modul terpasang."
    done
}

check_for_update() {
    say_proc "Memeriksa pembaruan..."
    local tmp_file="$NX_TEMP_DIR/.nx_code_update_tmp.sh"
    rm -f "$tmp_file"

    if ! curl --silent --max-time 15 --retry 2 -fsSL "$NX_CODE_REPO_RAW_URL" -o "$tmp_file"; then
        say_err "Gagal. Cek koneksi internet."
        rm -f "$tmp_file"
        return 1
    fi

    local remote_version
    remote_version=$(grep -m1 '^NX_CODE_VERSION=' "$tmp_file" | cut -d'"' -f2)

    if [ -z "$remote_version" ] || [ "$remote_version" == "$NX_CODE_VERSION" ]; then
        say_ok "Sistem sudah up-to-date ($NX_CODE_VERSION)."
        rm -f "$tmp_file"
        return 0
    fi

    say_ok "Pembaruan tersedia: $remote_version (Saat ini: $NX_CODE_VERSION)"
    echo -ne "  ${CYAN}Unduh dan terapkan pembaruan sekarang? (y/n) ❯${NC} "
    read -r update_choice

    if [[ "$update_choice" =~ ^[yY]$ ]]; then
        if [ ! -s "$tmp_file" ] || ! bash -n "$tmp_file" 2>/dev/null; then
            say_err "File update tidak valid. Pembaruan dibatalkan."
            rm -f "$tmp_file"
            return 1
        fi
        cp "$HOME/nx_code.sh" "$HOME/nx_code.sh.bak" 2>/dev/null
        mv "$tmp_file" "$HOME/nx_code.sh"
        chmod +x "$HOME/nx_code.sh"
        say_ok "Backup disimpan di nx_code.sh.bak"
        say_proc "Restarting terminal UI..."
        sleep 1
        exec bash "$HOME/nx_code.sh"
    else
        say_hint "Pembaruan ditunda."
        rm -f "$tmp_file"
    fi
}

view_error_log() {
    while true; do
        hr
        echo -e "  ${WHITE}SYSTEM LOGS${NC}"
        echo -e "  ${PURPLE}[1]${NC} ${WHITE}Lihat log terbaru${NC} ${DIM}(50 baris)${NC}"
        echo -e "  ${PURPLE}[2]${NC} ${WHITE}Bersihkan log${NC}"
        echo -e "  ${PURPLE}[0]${NC} ${WHITE}Kembali${NC}"
        hr
        echo -ne "  ${CYAN}Pilihan ❯${NC} "
        read -r log_choice

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
        read -r theme_choice

        [ "$theme_choice" == "0" ] && break

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

# ==============================================================================
# SUB-MENU: SESI & TAMPILAN
# ==============================================================================
menu_sesi_tampilan() {
    while true; do
        animate_logo
        local w=52
        echo -e "  ${PURPLE}╭$(printf '─%.0s' $(seq 1 $((w-2))))╮${NC}"
        echo -e "  ${PURPLE}│${NC} ${BOLD}${CYAN}  SUB-MENU: SESI & TAMPILAN                 ${NC} ${PURPLE}│${NC}"
        echo -e "  ${PURPLE}├$(printf '─%.0s' $(seq 1 $((w-2))))┤${NC}"
        print_menu_item "1" "Masuk Ubuntu (CLI)"
        print_menu_item "2" "Masuk Ubuntu (GUI - XFCE4)"
        print_menu_item "3" "Matikan Sesi GUI"
        print_menu_item "4" "Status Background Proses"
        echo -e "  ${PURPLE}├$(printf '─%.0s' $(seq 1 $((w-2))))┤${NC}"
        print_menu_item "0" "Kembali ke Menu Utama"
        echo -e "  ${PURPLE}╰$(printf '─%.0s' $(seq 1 $((w-2))))╯${NC}"
        echo -ne "  ${CYAN}Execute ❯${NC} "
        read -r sub1

        case $sub1 in
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
            4) check_gui_session; echo -ne "  ${DIM}Tekan Enter...${NC}"; read -r; ;;
            0) break ;;
            *) say_warn "Pilihan tidak valid."; sleep 1 ;;
        esac
    done
}

# ==============================================================================
# SUB-MENU: SISTEM & PEMELIHARAAN
# ==============================================================================
menu_sistem_pemeliharaan() {
    while true; do
        animate_logo
        local w=52
        echo -e "  ${PURPLE}╭$(printf '─%.0s' $(seq 1 $((w-2))))╮${NC}"
        echo -e "  ${PURPLE}│${NC} ${BOLD}${CYAN}  SUB-MENU: SISTEM & PEMELIHARAAN           ${NC} ${PURPLE}│${NC}"
        echo -e "  ${PURPLE}├$(printf '─%.0s' $(seq 1 $((w-2))))┤${NC}"
        print_menu_item "1" "Dev-Tools Installer"
        print_menu_item "2" "System Monitor (HTop)"
        print_menu_item "3" "System Update"
        print_menu_item "4" "Diagnostic Logs"
        echo -e "  ${PURPLE}├$(printf '─%.0s' $(seq 1 $((w-2))))┤${NC}"
        print_menu_item "0" "Kembali ke Menu Utama"
        echo -e "  ${PURPLE}╰$(printf '─%.0s' $(seq 1 $((w-2))))╯${NC}"
        echo -ne "  ${CYAN}Execute ❯${NC} "
        read -r sub2

        case $sub2 in
            1) quick_devtools_installer; sleep 1 ;;
            2) 
                if command -v htop >/dev/null 2>&1; then
                    htop
                else
                    say_err "Htop belum terinstal."
                    sleep 1
                fi 
                ;;
            3) check_for_update; sleep 1 ;;
            4) view_error_log; sleep 1 ;;
            0) break ;;
            *) say_warn "Pilihan tidak valid."; sleep 1 ;;
        esac
    done
}

# ==============================================================================
# MENU UTAMA BERJENJANG
# ==============================================================================
show_shortcut_menu() {
    while true; do
        animate_logo
        local w=52
        echo -e "  ${PURPLE}╭$(printf '─%.0s' $(seq 1 $((w-2))))╮${NC}"
        print_menu_item "1" "Sesi & Tampilan (CLI / GUI / Status)"
        print_menu_item "2" "Sistem & Pemeliharaan (Update / Logs)"
        print_menu_item "3" "Personalisasi (Tema Visual)"
        echo -e "  ${PURPLE}├$(printf '─%.0s' $(seq 1 $((w-2))))┤${NC}"
        print_menu_item "0" "Tutup Panel"
        echo -e "  ${PURPLE}╰$(printf '─%.0s' $(seq 1 $((w-2))))╯${NC}"
        echo -ne "  ${CYAN}Execute ❯${NC} "
        read -r pilihan

        case $pilihan in
            1) menu_sesi_tampilan ;;
            2) menu_sistem_pemeliharaan ;;
            3) select_theme_menu; sleep 1 ;;
            0) echo -e "\n  ${SUCCESS} Disconnected.\n"; break ;;
            *) echo -e "\n  ${NEON_PINK}✖ Invalid syntax.${NC}"; sleep 1 ;;
        esac
    done
}

run_ui_update_check() {
    local tmp_chk="$NX_TEMP_DIR/.nx_up_check.tmp"
    if curl --silent --max-time 5 -fsSL "$NX_CODE_REPO_RAW_URL" -o "$tmp_chk" 2>/dev/null; then
        local remote_version
        remote_version=$(grep -m1 '^NX_CODE_VERSION=' "$tmp_chk" | cut -d'"' -f2)
        if [ -n "$remote_version" ] && [ "$remote_version" != "$NX_CODE_VERSION" ]; then
            echo "update-available" > "$NX_TEMP_DIR/.nx_up_status"
        else
            echo "up-to-date" > "$NX_TEMP_DIR/.nx_up_status"
        fi
        rm -f "$tmp_chk"
    else
        echo "offline" > "$NX_TEMP_DIR/.nx_up_status"
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
            rm -rf "$NX_TEMP_DIR"/* 2>/dev/null
        ) > /dev/null 2>&1 &
        show_futuristic_progress "Flushing Cache" $!
        echo "$TODAY" > "$LAST_CLEAN_FILE"
        clean_status="${NEON_GREEN}Cleaned${NC}"
    fi

    run_ui_update_check >/dev/null 2>&1

    if [ -f "$NX_TEMP_DIR/.nx_up_status" ]; then
        st_res=$(cat "$NX_TEMP_DIR/.nx_up_status")
        if [ "$st_res" == "up-to-date" ]; then
            update_status="${NEON_GREEN}Up-to-Date${NC}"
        elif [ "$st_res" == "update-available" ]; then
            update_status="${NEON_PINK}Update Available${NC}"
        else
            update_status="${DIM}Offline${NC}"
        fi
        rm -f "$NX_TEMP_DIR/.nx_up_status"
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
# MODE INSTALASI AWAL
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
        [ -s "$dest" ] && chmod +x "$dest" && return 0
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

copy_self_to_home && chmod +x "$HOME/nx_code.sh" 2>/dev/null

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

(dpkg -l | grep "^ii" > "$NX_TEMP_DIR/installed_pkgs.txt"; sleep 0.5) 2>/dev/null &
show_futuristic_progress "Validating Subsystems" $!

echo -e "\n  ${SUCCESS} ${NEON_GREEN}INSTALLATION COMPLETE${NC}"
hr

echo -e "  ${WHITE}Terminal memerlukan proses Restart:${NC}"
echo -e "  ${PURPLE}[1]${NC} ${WHITE}Restart Otomatis (Rekomendasi)${NC}"
echo -e "  ${PURPLE}[0]${NC} ${WHITE}Keluar${NC}"
echo -ne "  ${CYAN}Pilihan ❯${NC} "
read -r final_choice

case "$final_choice" in
    1) exec bash ;;
    0|*) exit 0 ;;
esac

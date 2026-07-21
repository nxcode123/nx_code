#!/data/data/com.termux/files/usr/bin/bash

# --- KONFIGURASI UPDATE
NX_CODE_REPO_RAW_URL="https://raw.githubusercontent.com/nxcode123/nx_code/main/nx_code.sh"
NX_CODE_VERSION="v1.0.1"

# --- KONFIGURASI APP STORE
NX_APPS_MANIFEST_URL="https://raw.githubusercontent.com/nxcode123/nx_code_app/main/apps.list"
NX_APPS_SCRIPTS_BASE_URL="https://raw.githubusercontent.com/nxcode123/nx_code_app/main/scripts"

# --- KONFIGURASI TEMA WARNA ---
NX_THEME_FILE="$HOME/.nx_code_theme"
NX_AVAILABLE_THEMES=(cyberpunk matrix dracula ocean sunset mono)

# --- KONFIGURASI MODE PROGRESS BAR ---
# live   = bar animasi + cuplikan output terakhir (kalau layar cukup lebar)
# simple = bar animasi saja, tanpa teks output (paling aman di layar sempit)
# log    = tanpa animasi sama sekali, cuma print sekali saat mulai & selesai
NX_PROGRESS_FILE="$HOME/.nx_code_progress_mode"
NX_AVAILABLE_PROGRESS_MODES=(live simple log)

load_progress_mode() {
    NX_PROGRESS_MODE="live"
    if [ -f "$NX_PROGRESS_FILE" ]; then
        local saved
        saved=$(cat "$NX_PROGRESS_FILE" 2>/dev/null)
        for m in "${NX_AVAILABLE_PROGRESS_MODES[@]}"; do
            [ "$saved" == "$m" ] && NX_PROGRESS_MODE="$saved"
        done
    fi
}
load_progress_mode

# --- KONFIGURASI USER NON-ROOT UNTUK SESI GUI ---
NX_USER="nxuser"

# --- LOG ERROR (biar output yang kecepetan lewat bisa dibaca ulang nanti) ---
NX_LOG="$HOME/.nx_code_error.log"

# --- MODE NON-INTERAKTIF UNTUK APT/DEBCONF ---
export DEBIAN_FRONTEND=noninteractive
export DEBCONF_NONINTERACTIVE_SEEN=true

# File log sementara untuk menampilkan potongan output real-time di progress bar
NX_STEP_LOG="${TMPDIR:-/tmp}/.nx_step.log"

# ==============================================================================
# HELPER: TEMA WARNA
# ==============================================================================
load_theme() {
    local theme="cyberpunk"
    if [ -f "$NX_THEME_FILE" ]; then
        theme=$(cat "$NX_THEME_FILE" 2>/dev/null)
    fi

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
    SUCCESS="${NEON_GREEN}[✔]${NC}"
    PROCESS="${CYAN}[➔]${NC}"
}
load_theme

# ==============================================================================
# HELPER: OUTPUT MESSAGE (mengganti pola echo -e berulang di seluruh script)
# ==============================================================================
say_ok()    { echo -e "${SUCCESS} ${WHITE}$1${NC}"; }
say_proc()  { echo -e "\n${PROCESS} ${CYAN}$1${NC}"; }
say_err()   { echo -e "\n${NEON_PINK}[X] $1${NC}"; }
say_warn()  { echo -e "${NEON_PINK}[!] $1${NC}"; }
say_hint()  { echo -e "${PURPLE}$1${NC}"; }
hr()        { echo -e "${PURPLE}------------------------------------------------------${NC}"; }

# --- HELPER: BARIS MENU BER-BOX (dipakai di show_shortcut_menu) ---
print_menu_item() {
    printf "${NEON_PINK}║${NC} ${PURPLE}[%-2s]${NC} ${WHITE}%-46s${NC}${NEON_PINK}║${NC}\n" "$1" "$2"
}

log_section() {
    echo "" >> "$NX_LOG"
    echo "===== $(date '+%Y-%m-%d %H:%M:%S') | $1 =====" >> "$NX_LOG"
}

# ==============================================================================
# HELPER: EKSEKUSI DI DALAM UBUNTU (mengganti "proot-distro login ubuntu -- bash -c" berulang)
# ==============================================================================
# Pakai: ux "perintah shell di dalam ubuntu"
# Pakai: ux_as "$NX_USER" "perintah shell"   -> jalankan sebagai user tertentu
ux() {
    proot-distro login ubuntu -- bash -c "$1"
}

ux_quiet() {
    proot-distro login ubuntu -- bash -c "$1" >/dev/null 2>&1
}

ux_ok() {
    proot-distro login ubuntu -- bash -c "$1" >/dev/null 2>&1
}

# --- FUNGSI CEK STATUS (dipusatkan) ---
is_ubuntu_installed()      { proot-distro login ubuntu -- true >/dev/null 2>&1; }
is_termux_x11_installed()  { command -v termux-x11 >/dev/null 2>&1; }
is_xfce4_installed()       { ux_quiet "command -v startxfce4"; }
is_nonroot_user_setup()    { ux_quiet "id $NX_USER"; }
is_storage_setup()         { [ -d "$HOME/storage/shared" ]; }

# --- VALIDASI INPUT (whitelist nama file: huruf, angka, titik, strip, underscore) ---
# Mencegah path traversal / injection dari data manifest app store yang diambil dari internet.
is_safe_filename() {
    [[ "$1" =~ ^[A-Za-z0-9._-]+$ ]]
}

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

# --- FUNGSI PROGRESS: GAYA NATIVE PROOT-DISTRO ("[*] ..." + bar %) ---
show_futuristic_progress() {
    local message="$1"
    local pid=$2
    local logfile="${3:-}"
    local total="${4:-0}"
    local mode="${NX_PROGRESS_MODE:-live}"
    local label="$message"
    local spinner="|/-\\"
    local ticks=0

    # Mode "log": tanpa animasi sama sekali, cuma cetak sekali di awal & akhir.
    if [ "$mode" == "log" ]; then
        echo -e "${WHITE}[*]${NC} ${label}..."
        wait "$pid" 2>/dev/null
        echo -e "${WHITE}[*]${NC} ${label} ${NEON_GREEN}selesai.${NC}"
        return 0
    fi

    echo -ne "\033[?25l"
    while kill -0 "$pid" 2>/dev/null; do
        local cols
        cols=$(stty size 2>/dev/null | awk '{print $2}')
        [ -z "$cols" ] && cols=40

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

        if [ "$mode" == "live" ] && [ "$total" -gt 0 ]; then
            # BAR PERSENTASE CYBERPUNK
            local percent=$(( done_count * 100 / total ))
            [ "$percent" -gt 100 ] && percent=100
            local bar_w=20
            [ "$cols" -lt 40 ] && bar_w=10
            local filled=$(( percent * bar_w / 100 ))
            local bar=""
            for ((j=0; j<filled; j++)); do bar="${bar}█"; done
            for ((j=filled; j<bar_w; j++)); do bar="${bar}░"; done
            printf "\r\033[K${NEON_PINK}[SYS]${NC} ${CYAN}[%s]${NC} ${NEON_GREEN}%3d%%${NC} | %s" "$bar" "$percent" "${activity:0:15}"
        elif [ "$mode" == "simple" ]; then
            local sp_char="${spinner:$((ticks % 4)):1}"
            printf "\r\033[K${WHITE}[*]${NC} %s %s" "$label" "$sp_char"
        else
            local budget=$(( cols - 6 ))
            [ "$budget" -lt 5 ] && budget=5
            activity="${activity:0:$budget}"
            printf "\r\033[K${WHITE}[*]${NC} %s" "$activity"
        fi

        sleep 0.12
        ((ticks++))
    done

    printf "\r\033[K${WHITE}[*]${NC} %s ${NEON_GREEN}selesai.${NC}\n" "$label"
    echo -ne "\033[?25h"
}

# --- ANIMASI BOOTING CYBERPUNK ---
cyber_boot_sequence() {
    clear
    local boot_logs=(
        "CORE_KERNEL    : INITIATING MEMORY ALLOCATION..."
        "SYS_CHK        : BYPASSING MAINFRAME ENCRYPTION... [OK]"
        "NET_LINK       : ESTABLISHING SECURE TUNNEL... [OK]"
        "INJECTOR       : PREPARING DEPLOYMENT VECTORS..."
    )
    echo -e "${NEON_PINK}>> WAKE_UP_PROTOCOL.SH INITIATED <<${NC}\n"
    sleep 0.5
    for log in "${boot_logs[@]}"; do
        echo -e "${PURPLE}[*] ${CYAN}${log}${NC}"
        sleep 0.4
    done
    echo -e "\n${NEON_GREEN}>> NEURAL LINK ESTABLISHED. SYSTEM WIDE OPEN. <<${NC}"
    sleep 1
}

# --- ANIMASI BOOTING LOGO (UPDATED: border ganda + versi) ---
animate_logo() {
    command clear
    local w=56
    echo -e "${NEON_PINK}╔$(printf '═%.0s' $(seq 1 $((w-2))))╗${NC}"
    local lines=(
        "  _   _ __  __        ____ ___  ____  _____ "
        " | \ | |\ \/ /       / ___/ _ \|  _ \| ____|"
        " |  \| | \  /  _____| |  | | | | | | |  _|  "
        " | |\  | /  \ |_____| |__| |_| | |_| | |___ "
        " |_| \_|/_/\_\       \____\___/|____/|_____| TERMINAL"
    )
    for line in "${lines[@]}"; do
        printf "${PURPLE}%s${NC}\r" "$line"
        sleep 0.04
        printf "${CYAN}%s${NC}\n" "$line"
    done
    echo -e "${NEON_PINK}╠$(printf '═%.0s' $(seq 1 $((w-2))))╣${NC}"
    printf " ${WHITE}STATUS:${NEON_GREEN} %-9s${WHITE}THEME:${NEON_PINK} %-10s${WHITE}VER:${CYAN} %s${NC}\n" \
        "ONLINE" "${NX_CURRENT_THEME^^}" "$NX_CODE_VERSION"
    echo -e "${NEON_PINK}╚$(printf '═%.0s' $(seq 1 $((w-2))))╝${NC}"
    echo ""
}

# --- FUNGSI PILIH RESOLUSI LAYAR GUI ---
choose_resolution() {
    GUI_CANCELLED=0
    hr
    echo -e "${WHITE}Pilih resolusi layar GUI (Pilih resolusi):${NC}"
    echo -e " ${PURPLE}[1]${NC} ${WHITE}Custom resolution${NC}"
    echo -e " ${PURPLE}[2]${NC} ${WHITE}Native${NC}"
    echo -e " ${PURPLE}[3]${NC} ${WHITE}Kembali ke menu utama${NC}"
    hr
    echo -ne "${CYAN}[?] Pilihan:${NC} "
    read res_choice

    case "$res_choice" in
        1)
            echo -ne "${CYAN}[?] Masukkan resolusi (format WIDTHxHEIGHT, mis. 720x1440):${NC} "
            read custom_res
            if [[ "$custom_res" =~ ^([0-9]+)x([0-9]+)$ ]]; then
                RES_W="${BASH_REMATCH[1]}"
                RES_H="${BASH_REMATCH[2]}"
            else
                say_warn "Format tidak valid. Pakai default 720x1440."
                RES_W="720"; RES_H="1440"
            fi
            ;;
        2) RES_W=""; RES_H="" ;;
        3) GUI_CANCELLED=1 ;;
        *)
            say_warn "Pilihan tidak valid, pakai default 720x1440."
            RES_W="720"; RES_H="1440"
            ;;
    esac
}

# --- FUNGSI TULIS SCRIPT STARTUP GUI KE DALAM UBUNTU ---
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

# --- FUNGSI LAUNCH GUI UBUNTU ---
launch_ubuntu_gui() {
    if ! is_ubuntu_installed; then
        say_err "Error: Ubuntu OS belum diinstal."
        return 1
    fi

    if ! is_termux_x11_installed; then
        say_err "Error: termux-x11 belum terpasang. Jalankan ulang installer script."
        return 1
    fi

    if ! is_xfce4_installed; then
        say_proc "XFCE4 belum terpasang di Ubuntu. Menginstal sekarang (sekali saja)..."
        say_hint "[!] Proses ini bisa memakan waktu cukup lama tergantung koneksi."
        log_section "INSTALL XFCE4"

        : > "$NX_STEP_LOG"
        (ux "apt update" > "$NX_STEP_LOG" 2>&1) &
        show_futuristic_progress "Updating package list" $! "$NX_STEP_LOG"
        cat "$NX_STEP_LOG" >> "$NX_LOG"

        # Hitung total paket sungguhan (dry-run) biar bar persentase valid, bukan tebakan
        local xfce_total
        xfce_total=$(ux "apt-get -s upgrade; apt-get -s install xfce4 xfce4-goodies dbus-x11 x11-xserver-utils sudo" 2>/dev/null | grep -Ec '^(Inst|Conf)')
        [ -z "$xfce_total" ] && xfce_total=0

        : > "$NX_STEP_LOG"
        (ux "apt upgrade -y && apt install xfce4 xfce4-goodies dbus-x11 x11-xserver-utils sudo -y" > "$NX_STEP_LOG" 2>&1) &
        local xfce_pid=$!
        show_futuristic_progress "Installing XFCE4" "$xfce_pid" "$NX_STEP_LOG" "$xfce_total"
        cat "$NX_STEP_LOG" >> "$NX_LOG"
        if ! is_xfce4_installed; then
            say_err "Instalasi XFCE4 gagal. Cek log lengkap di menu [8] Log error."
            return 1
        fi
        say_ok "XFCE4 berhasil dipasang di Ubuntu."
    fi

    if ! ux_quiet "[ -f /usr/share/xfce4/backdrops/xubuntu-wallpaper.png ]"; then
        ux_ok "mkdir -p /usr/share/xfce4/backdrops && echo 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=' | base64 -d > /usr/share/xfce4/backdrops/xubuntu-wallpaper.png"
    fi

    if ! is_nonroot_user_setup; then
        say_proc "Menyiapkan user non-root '$NX_USER' (sekali saja)..."
        setup_nonroot_user
        if is_nonroot_user_setup; then
            say_ok "User '$NX_USER' berhasil dibuat."
        else
            say_warn "Gagal membuat user non-root, sesi GUI akan tetap jalan sebagai root."
        fi
    fi

    setup_no_sandbox_fix

    choose_resolution
    if [ "$GUI_CANCELLED" -eq 1 ]; then
        echo -e "\n${NEON_GREEN}[➔] Dibatalkan, kembali ke menu utama.${NC}"
        return 0
    fi
    write_gui_startup_script

    pkill -f "termux-x11" >/dev/null 2>&1
    sleep 1

    say_proc "Menyalakan server X11 (display :2) & masuk ke Ubuntu XFCE4..."

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
        say_err "Gagal menyalakan server X11."
        say_hint "[?] Pastikan aplikasi 'Termux:X11' sudah terinstal dan coba lagi."
        say_hint "[?] Detail lengkap ada di menu [8] Log error."
        return 1
    fi

    am start --user 0 -n com.termux.x11/com.termux.x11.MainActivity >/dev/null 2>&1

    echo -e "${PROCESS} ${CYAN}Buka aplikasi 'Termux:X11' di Android kalau belum otomatis terbuka.${NC}\n"

    show_futuristic_progress "GUI Ubuntu Aktif (Termux:X11)..." "$X11_PID"
    wait "$X11_PID" 2>/dev/null

    echo -e "\n${NEON_GREEN}[➔] Sesi GUI Ubuntu ditutup.${NC}"
}

# --- FUNGSI KILL GUI UBUNTU ---
kill_ubuntu_gui() {
    say_proc "Mematikan sesi GUI Ubuntu (XFCE4 & Termux:X11)..."

    local found=0

    if pkill -f "termux-x11" >/dev/null 2>&1; then
        found=1
    fi

    # Targetkan proses xfce hanya untuk nxuser agar tidak menabrak proses lain
    if ux_ok "pkill -u $NX_USER -f 'xfce4|dbus-launch|Xwayland' 2>/dev/null || pkill -f 'xfce4|dbus-launch|Xwayland'"; then
        found=1
    fi

    sleep 1

    if [ "$found" -eq 1 ]; then
        say_ok "Sesi GUI Ubuntu berhasil dimatikan."
    else
        echo -e "${NEON_PINK}[X]${NC} ${WHITE}Tidak ada sesi GUI yang sedang berjalan.${NC}"
    fi
}

# --- FUNGSI CEK SESI GUI AKTIF ---
check_gui_session() {
    say_proc "Mengecek sesi GUI yang sedang aktif..."
    echo ""

    local x11_procs x11_count xfce_procs

    x11_procs=$(pgrep -af "termux-x11" 2>/dev/null)
    xfce_procs=$(ux "pgrep -af 'xfce4-session|startxfce4|dbus-launch'" 2>/dev/null)

    if [ -z "$x11_procs" ] && [ -z "$xfce_procs" ]; then
        say_ok "Tidak ada sesi GUI yang sedang berjalan. Aman."
        return 0
    fi

    if [ -n "$x11_procs" ]; then
        x11_count=$(echo "$x11_procs" | wc -l)
        echo -e "${WHITE}Proses Termux:X11 aktif di sisi Termux (${x11_count}):${NC}"
        echo -e "${CYAN}${x11_procs}${NC}"
        if [ "$x11_count" -gt 1 ]; then
            say_warn "Terdeteksi lebih dari 1 proses termux-x11. Kemungkinan ada sesi lama yang STALE."
        fi
    else
        say_hint "--> Tidak ada proses termux-x11 aktif di sisi Termux."
    fi

    echo ""

    if [ -n "$xfce_procs" ]; then
        echo -e "${WHITE}Proses XFCE4/DBus aktif di dalam Ubuntu:${NC}"
        echo -e "${CYAN}${xfce_procs}${NC}"
    else
        say_hint "--> Tidak ada proses XFCE4/DBus aktif di dalam Ubuntu."
    fi

    echo ""
    echo -ne "${CYAN}[?] Mau bersihkan semua sesi (termasuk yang stale) sekarang? (y/n):${NC} "
    read clean_choice
    if [ "$clean_choice" == "y" ] || [ "$clean_choice" == "Y" ]; then
        kill_ubuntu_gui
    fi
}

# --- FUNGSI QUICK DEV-TOOLS INSTALLER ---
quick_devtools_installer() {
    if ! is_ubuntu_installed; then
        say_err "Error: Ubuntu OS belum diinstal."
        return 1
    fi

    while true; do
        hr
        echo -e "${WHITE}QUICK DEV-TOOLS INSTALLER (UBUNTU)${NC}"
        echo -e " ${PURPLE}[1]${NC} ${WHITE}Install Semua${NC} ${CYAN}(git, python3, nodejs, build-essential, curl, wget, vim)${NC}"
        echo -e " ${PURPLE}[2]${NC} ${WHITE}Git${NC}"
        echo -e " ${PURPLE}[3]${NC} ${WHITE}Python3 + pip${NC}"
        echo -e " ${PURPLE}[4]${NC} ${WHITE}Node.js + npm${NC}"
        echo -e " ${PURPLE}[5]${NC} ${WHITE}Build-essential${NC} ${CYAN}(gcc, make, dll)${NC}"
        echo -e " ${PURPLE}[6]${NC} ${WHITE}Kembali${NC}"
        hr
        echo -ne "${CYAN}[?] Pilihan:${NC} "
        read dev_choice

        local pkgs=""
        case "$dev_choice" in
            1) pkgs="git python3 python3-pip nodejs npm build-essential curl wget vim nano" ;;
            2) pkgs="git" ;;
            3) pkgs="python3 python3-pip" ;;
            4) pkgs="nodejs npm" ;;
            5) pkgs="build-essential" ;;
            6) break ;;
            *)
                say_warn "Pilihan tidak valid."
                continue
                ;;
        esac

        say_proc "Menginstal: ${pkgs}..."
        log_section "DEV-TOOLS INSTALL ($pkgs)"

        : > "$NX_STEP_LOG"
        (ux "apt update" > "$NX_STEP_LOG" 2>&1) &
        show_futuristic_progress "Updating package list" $! "$NX_STEP_LOG"
        cat "$NX_STEP_LOG" >> "$NX_LOG"

        local dev_total
        dev_total=$(ux "apt-get -s install -y $pkgs" 2>/dev/null | grep -Ec '^(Inst|Conf)')
        [ -z "$dev_total" ] && dev_total=0

        : > "$NX_STEP_LOG"
        (ux "apt install -y $pkgs" > "$NX_STEP_LOG" 2>&1) &
        local dev_pid=$!
        show_futuristic_progress "Installing packages" "$dev_pid" "$NX_STEP_LOG" "$dev_total"
        cat "$NX_STEP_LOG" >> "$NX_LOG"
        say_ok "Selesai menginstal."
    done
}

# --- FUNGSI CHECK UPDATE ---
check_for_update() {
    say_proc "Mengecek update dari GitHub..."

    local tmp_file="$HOME/.nx_code_update_tmp.sh"
    rm -f "$tmp_file"

    if ! curl --max-time 20 --retry 2 --retry-delay 2 -fsSL "$NX_CODE_REPO_RAW_URL" -o "$tmp_file" 2>/dev/null; then
        say_err "Gagal mengambil update. Cek koneksi internet atau URL repo di NX_CODE_REPO_RAW_URL."
        rm -f "$tmp_file"
        return 1
    fi

    if [ ! -s "$tmp_file" ]; then
        say_err "File update kosong/tidak valid. Cek URL repo."
        rm -f "$tmp_file"
        return 1
    fi

    if diff -q "$tmp_file" "$HOME/nx_code.sh" >/dev/null 2>&1; then
        say_ok "Sudah pakai versi terbaru. Tidak ada update."
        rm -f "$tmp_file"
        return 0
    fi

    say_ok "Update ditemukan! Menerapkan..."
    mv "$tmp_file" "$HOME/nx_code.sh"
    chmod +x "$HOME/nx_code.sh"

    sed -i '/# --- NX_CODE ENVIRONMENT ---/,/# ---------------------------/d' "$HOME/.bashrc" 2>/dev/null

    say_proc "Menjalankan ulang installer (reinstall + restart terminal)..."
    sleep 1
    exec bash "$HOME/nx_code.sh"
}

# --- FUNGSI LIHAT LOG ERROR ---
view_error_log() {
    while true; do
        hr
        echo -e "${WHITE}LOG ERROR${NC}"
        echo -e " ${PURPLE}[1]${NC} ${WHITE}Lihat log terbaru (50 baris terakhir)${NC}"
        echo -e " ${PURPLE}[2]${NC} ${WHITE}Lihat semua log${NC}"
        echo -e " ${PURPLE}[3]${NC} ${WHITE}Hapus log${NC}"
        echo -e " ${PURPLE}[4]${NC} ${WHITE}Kembali${NC}"
        hr
        echo -ne "${CYAN}[?] Pilihan:${NC} "
        read log_choice

        case "$log_choice" in
            1)
                if [ -s "$NX_LOG" ]; then
                    hr
                    tail -n 50 "$NX_LOG"
                    hr
                else
                    say_ok "Log masih kosong, belum ada error tercatat."
                fi
                ;;
            2)
                if [ -s "$NX_LOG" ]; then
                    hr
                    cat "$NX_LOG"
                    hr
                    echo -e "${CYAN}[?] Geser/scroll ke atas buat baca dari awal.${NC}"
                else
                    say_ok "Log masih kosong, belum ada error tercatat."
                fi
                ;;
            3)
                rm -f "$NX_LOG"
                say_ok "Log dihapus."
                ;;
            4) break ;;
            *)
                say_warn "Pilihan tidak valid."
                ;;
        esac
    done
}

# --- FUNGSI GANTI TEMA WARNA ---
select_theme_menu() {
    while true; do
        hr
        echo -e "${WHITE}PILIH TEMA WARNA${NC} ${CYAN}(aktif: ${NX_CURRENT_THEME})${NC}"
        hr

        local i=1
        for t in "${NX_AVAILABLE_THEMES[@]}"; do
            if [ "$t" == "$NX_CURRENT_THEME" ]; then
                echo -e " ${PURPLE}[$i]${NC} ${WHITE}${t}${NC} ${NEON_GREEN}[✔ aktif]${NC}"
            else
                echo -e " ${PURPLE}[$i]${NC} ${WHITE}${t}${NC}"
            fi
            i=$((i+1))
        done
        echo -e " ${PURPLE}[0]${NC} ${WHITE}Kembali${NC}"
        hr
        echo -ne "${CYAN}[?] Pilihan:${NC} "
        read theme_choice

        if [ "$theme_choice" == "0" ]; then
            break
        fi

        local idx=$((theme_choice - 1))
        local chosen="${NX_AVAILABLE_THEMES[$idx]:-}"

        if [ -z "$chosen" ]; then
            say_warn "Pilihan tidak valid."
            continue
        fi

        echo "$chosen" > "$NX_THEME_FILE"
        load_theme

        animate_logo
        say_ok "Tema berhasil diganti ke: ${NEON_GREEN}${chosen}${NC}"
    done
}

# --- FUNGSI GANTI MODE PROGRESS BAR ---
select_progress_menu() {
    local labels=(
        "Live (gaya proot-distro: [*] status + bar % asli kalau tersedia)"
        "Simple (spinner saja, tanpa teks aksi — paling stabil)"
        "Log (tanpa animasi, cuma cetak status mulai/selesai — paling aman)"
    )
    while true; do
        hr
        echo -e "${WHITE}MODE PROGRESS BAR${NC} ${CYAN}(aktif: ${NX_PROGRESS_MODE})${NC}"
        hr
        local i=1
        for m in "${NX_AVAILABLE_PROGRESS_MODES[@]}"; do
            if [ "$m" == "$NX_PROGRESS_MODE" ]; then
                echo -e " ${PURPLE}[$i]${NC} ${WHITE}${labels[$((i-1))]}${NC} ${NEON_GREEN}[✔ aktif]${NC}"
            else
                echo -e " ${PURPLE}[$i]${NC} ${WHITE}${labels[$((i-1))]}${NC}"
            fi
            i=$((i+1))
        done
        echo -e " ${PURPLE}[0]${NC} ${WHITE}Kembali${NC}"
        hr
        echo -ne "${CYAN}[?] Pilihan:${NC} "
        read prog_choice

        if [ "$prog_choice" == "0" ]; then
            break
        fi

        local idx=$((prog_choice - 1))
        local chosen="${NX_AVAILABLE_PROGRESS_MODES[$idx]:-}"

        if [ -z "$chosen" ]; then
            say_warn "Pilihan tidak valid."
            continue
        fi

        echo "$chosen" > "$NX_PROGRESS_FILE"
        load_progress_mode
        say_ok "Mode progress diganti ke: ${NEON_GREEN}${chosen}${NC}"
    done
}

# --- FUNGSI APP STORE ---
app_store_menu() {
    if ! is_ubuntu_installed; then
        say_err "Error: Ubuntu OS belum diinstal."
        return 1
    fi

    say_proc "Mengambil daftar app dari repo..."

    local manifest="$HOME/.nx_apps_manifest.tmp"
    rm -f "$manifest"

    if ! curl --max-time 20 --retry 2 --retry-delay 2 -fsSL "$NX_APPS_MANIFEST_URL" -o "$manifest" 2>/dev/null; then
        say_err "Gagal ambil daftar app. Cek koneksi internet atau URL di NX_APPS_MANIFEST_URL."
        rm -f "$manifest"
        return 1
    fi

    if [ ! -s "$manifest" ]; then
        say_err "Daftar app kosong/tidak valid."
        rm -f "$manifest"
        return 1
    fi

    # Bersihkan CRLF (Windows line ending) dari manifest sebelum diparse,
    # supaya field terakhir (nama file .desktop) tidak kebawa '\r' tersembunyi.
    sed -i 's/\r$//' "$manifest" 2>/dev/null

    local names=() scripts=() descs=() desktops=()
    while IFS='|' read -r a_name a_script a_desc a_desktop; do
        [ -z "$a_name" ] && continue

        # Validasi: nama file script & desktop wajib aman (whitelist karakter),
        # menutup celah path traversal / command injection dari manifest eksternal.
        if [ -n "$a_script" ] && ! is_safe_filename "$a_script"; then
            say_warn "Melewati entri '$a_name': nama script tidak valid."
            continue
        fi
        if [ -n "$a_desktop" ] && ! is_safe_filename "$a_desktop"; then
            say_warn "Melewati entri '$a_name': nama file .desktop tidak valid."
            continue
        fi

        names+=("$a_name")
        scripts+=("$a_script")
        descs+=("$a_desc")
        desktops+=("$a_desktop")
    done < "$manifest"
    rm -f "$manifest"

    if [ "${#names[@]}" -eq 0 ]; then
        say_err "Daftar app kosong."
        return 1
    fi

    local installed=()
    local check_cmd=""
    for i in "${!names[@]}"; do
        installed[$i]=0
        if [ -n "${desktops[$i]}" ]; then
            check_cmd+="[ -f /usr/share/applications/${desktops[$i]} ] && echo FOUND_$i; "
        fi
    done
    if [ -n "$check_cmd" ]; then
        local check_result
        check_result=$(ux "$check_cmd" 2>/dev/null)
        for i in "${!names[@]}"; do
            if echo "$check_result" | grep -q "^FOUND_${i}$"; then
                installed[$i]=1
            fi
        done
    fi

    while true; do
        hr
        echo -e "${WHITE}APP STORE${NC}"
        for i in "${!names[@]}"; do
            if [ "${installed[$i]}" -eq 1 ]; then
                printf " ${PURPLE}[%d]${NC} ${WHITE}%s${NC} ${CYAN}- %s${NC} ${NEON_GREEN}[✔ Terinstall]${NC}\n" "$((i+1))" "${names[$i]}" "${descs[$i]}"
            else
                printf " ${PURPLE}[%d]${NC} ${WHITE}%s${NC} ${CYAN}- %s${NC}\n" "$((i+1))" "${names[$i]}" "${descs[$i]}"
            fi
        done
        echo -e " ${PURPLE}[0]${NC} ${WHITE}Kembali${NC}"
        hr
        echo -ne "${CYAN}[?] Pilihan:${NC} "
        read app_choice

        if [ "$app_choice" == "0" ]; then
            break
        fi

        local idx=$((app_choice - 1))
        if [ -z "${names[$idx]:-}" ]; then
            say_warn "Pilihan tidak valid."
            continue
        fi

        say_proc "Menginstal ${names[$idx]}..."
        log_section "APP INSTALL: ${names[$idx]}"

        # Eksekusi yang diunduh ke file temporary, bukan blind curl | bash
        local target_url="$NX_APPS_SCRIPTS_BASE_URL/${scripts[$idx]}"
        local tmp_script="$HOME/.tmp_install_$(basename "${scripts[$idx]}")"

        if curl --max-time 30 --retry 2 --retry-delay 2 -fsSL "$target_url" -o "$tmp_script"; then
            if [ -s "$tmp_script" ]; then
                say_proc "Menjalankan script instalasi..."
                proot-distro login ubuntu -- bash < "$tmp_script" 2>&1 | tee -a "$NX_LOG"

                if [ "${PIPESTATUS[0]}" -eq 0 ]; then
                    say_ok "Selesai instal ${names[$idx]}."
                else
                    say_err "Terjadi error saat instalasi ${names[$idx]}. Cek log!"
                fi
            else
                say_err "Gagal: Script yang diunduh kosong atau URL tidak valid."
            fi
        else
            say_err "Gagal mengunduh script. Cek koneksi internet Anda."
        fi

        rm -f "$tmp_script"

        local d_file="${desktops[$idx]}"
        if [ -n "$d_file" ] && is_nonroot_user_setup; then
            ux_ok "
                if [ -f /usr/share/applications/$d_file ]; then
                    mkdir -p /home/$NX_USER/Desktop
                    cp /usr/share/applications/$d_file /home/$NX_USER/Desktop/
                    chmod +x /home/$NX_USER/Desktop/$d_file
                    chown -R $NX_USER:$NX_USER /home/$NX_USER/Desktop
                    gio set /home/$NX_USER/Desktop/$d_file metadata::trusted true 2>/dev/null || true
                fi
            "
            say_hint "[i] Shortcut ditambahkan ke Desktop (kalau perlu, klik kanan > Allow Launching sekali pertama)."
        fi

        if [ -n "$d_file" ] && ux_quiet "[ -f /usr/share/applications/$d_file ]"; then
            installed[$idx]=1
        fi
    done
}

# --- FUNGSI PANEL MENU SHORTCUT (UPDATED: box seragam) ---
show_shortcut_menu() {
    while true; do
        animate_logo
        local w=56
        echo -e "${NEON_PINK}╔$(printf '═%.0s' $(seq 1 $((w-2))))╗${NC}"
        printf "${NEON_PINK}║${NC}%*s${NEON_PINK}║${NC}\n" $((w-2)) ""
        local title="NX_CODE CORE INTERFACE ${NX_CODE_VERSION}"
        local pad=$(( (w - 2 - ${#title}) / 2 ))
        printf "${NEON_PINK}║${NC}%*s${WHITE}%s${NC}%*s${NEON_PINK}║${NC}\n" "$pad" "" "$title" $((w-2-pad-${#title})) ""
        printf "${NEON_PINK}║${NC}%*s${NEON_PINK}║${NC}\n" $((w-2)) ""
        echo -e "${NEON_PINK}╠$(printf '═%.0s' $(seq 1 $((w-2))))╣${NC}"

        print_menu_item "1"  "Ubuntu CLI"
        print_menu_item "2"  "Ubuntu GUI (XFCE4 via Termux:X11)"
        print_menu_item "3"  "Kill Ubuntu GUI (XFCE4 via Termux:X11)"
        print_menu_item "4"  "Cek sesi xfce yang aktif"
        print_menu_item "5"  "Quick Dev-Tools Installer"
        print_menu_item "6"  "System Monitor (HTop)"
        print_menu_item "7"  "Check update"
        print_menu_item "8"  "Log error"
        print_menu_item "9"  "App"
        print_menu_item "10" "Ganti Tema Warna (aktif: ${NX_CURRENT_THEME})"
        print_menu_item "11" "Ganti Mode Progress (aktif: ${NX_PROGRESS_MODE})"
        echo -e "${NEON_PINK}╠$(printf '═%.0s' $(seq 1 $((w-2))))╣${NC}"
        print_menu_item "0"  "Kembali ke home"
        echo -e "${NEON_PINK}╚$(printf '═%.0s' $(seq 1 $((w-2))))╝${NC}"
        echo -ne "${CYAN}[?] Select Option:${NC} "
        read pilihan

        case $pilihan in
            1)
                say_proc "Launching Ubuntu CLI Core..."
                sleep 1
                if is_ubuntu_installed; then
                    proot-distro login ubuntu
                else
                    say_err "Error: Ubuntu OS belum diinstal. Jalankan ulang script secara manual."
                fi
                sleep 1
                ;;
            2) launch_ubuntu_gui; sleep 1 ;;
            3) kill_ubuntu_gui; sleep 1 ;;
            4) check_gui_session; sleep 1 ;;
            5) quick_devtools_installer; sleep 1 ;;
            6)
                say_proc "Booting HTop System Monitor..."
                sleep 0.5
                htop
                ;;
            7) check_for_update; sleep 1 ;;
            8) view_error_log; sleep 1 ;;
            9) app_store_menu; sleep 1 ;;
            10) select_theme_menu; sleep 1 ;;
            11) select_progress_menu; sleep 1 ;;
            0)
                echo -e "\n${NEON_GREEN}[➔] Returning to home base.${NC}\n"
                break
                ;;
            *)
                echo -e "\n\033[1;95m[!] ALERT: INVALID OPTION SELECTED.\033[0m"
                sleep 1
                ;;
        esac
    done
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

    ub_status="${NEON_PINK}Not Installed${NC}"
    st_status="${NEON_PINK}Not Setup${NC}"
    clean_status="${CYAN}Skipped (already today)${NC}"

    # --- Cek Ubuntu (dengan animasi) ---
    (sleep 0.6) &
    show_futuristic_progress "Checking Ubuntu Core" $!
    is_ubuntu_installed && ub_status="${NEON_GREEN}Ready${NC}"

    # --- Cek Storage (dengan animasi) ---
    (sleep 0.4) &
    show_futuristic_progress "Checking Storage Access" $!
    is_storage_setup && st_status="${NEON_GREEN}Ready${NC}"

    # --- Auto-Cleaner (dengan animasi + progress asli kalau ada) ---
    LAST_CLEAN_FILE="$HOME/.nx_code_last_clean"
    TODAY=$(date +%Y%m%d)
    LAST_CLEAN=""
    [ -f "$LAST_CLEAN_FILE" ] && LAST_CLEAN=$(cat "$LAST_CLEAN_FILE" 2>/dev/null)

    if [ "$TODAY" != "$LAST_CLEAN" ]; then
        (
            pkg clean -y
            if [ -n "$TMPDIR" ] && [ -d "$TMPDIR" ]; then
                rm -rf "${TMPDIR:?}"/* 2>/dev/null
            fi
        ) > /dev/null 2>&1 &
        clean_pid=$!
        show_futuristic_progress "Running Auto-Cleaner" "$clean_pid"
        echo "$TODAY" > "$LAST_CLEAN_FILE"
        clean_status="${NEON_GREEN}Done${NC}"
    fi

    echo ""
    echo -e "${PURPLE}┌──────────────────────────────────────────────────┐${NC}"
    printf "${PURPLE}│${NC} %-20s %-30b${PURPLE}│${NC}\n" "Version"       "${CYAN}${NX_CODE_VERSION}${NC}"
    printf "${PURPLE}│${NC} %-20s %-30b${PURPLE}│${NC}\n" "Ubuntu Core"    "$ub_status"
    printf "${PURPLE}│${NC} %-20s %-30b${PURPLE}│${NC}\n" "Storage Access" "$st_status"
    printf "${PURPLE}│${NC} %-20s %-30b${PURPLE}│${NC}\n" "Auto-Cleaner"   "$clean_status"
    echo -e "${PURPLE}└──────────────────────────────────────────────────┘${NC}"
    echo ""
    echo -e " ${NEON_PINK}[!]${NC} ${WHITE}Ketik ${CYAN}nx-menu${WHITE} untuk akses menu${NC}"
    echo ""
    exit 0
fi

# ==============================================================================
# MODE INSTALASI AWAL (CYBERPUNK OPTIMIZED)
# ==============================================================================
cyber_boot_sequence
animate_logo

echo -e "${WHITE}>> DEPLOYING CORE DEPENDENCIES...${NC}\n"

# OPTIMASI: Menggabungkan update dan instalasi paket Termux dasar dalam satu proses
: > "$NX_STEP_LOG"
(
    pkg update -y -o Dpkg::Options::="--force-confold" && \
    pkg upgrade -y -o Dpkg::Options::="--force-confold" && \
    pkg install proot-distro htop coreutils x11-repo -y -o Dpkg::Options::="--force-confold"
) > "$NX_STEP_LOG" 2>&1 &
show_futuristic_progress "Syncing Global Repos & Injecting Base Nodes" $! "$NX_STEP_LOG"

# Instalasi paket server X11
: > "$NX_STEP_LOG"
(pkg install termux-x11-nightly -y -o Dpkg::Options::="--force-confold" > "$NX_STEP_LOG" 2>&1) &
show_futuristic_progress "Compiling X11 Display Subsystems" $! "$NX_STEP_LOG"

if ! is_ubuntu_installed; then
    say_proc "INITIALIZING OS VIRTUALIZATION..."
    proot-distro remove ubuntu > /dev/null 2>&1
    say_hint "[!] Downloading Ubuntu Core Image. Standby..."
    hr
    proot-distro install ubuntu
    hr
fi

(sleep 1) &
show_futuristic_progress "Verifying Hypervisor Integrity" $!

echo ""
if is_ubuntu_installed; then
    echo -e "${SUCCESS} ${WHITE}Ubuntu Core OS           :${NC} ${NEON_GREEN}Deployed & Online${NC}"
else
    echo -e "${NEON_PINK}[X]${NC} ${WHITE}Ubuntu Core OS           :${NC} ${NEON_PINK}Deployment Failed${NC}"
fi

if is_termux_x11_installed; then
    echo -e "${SUCCESS} ${WHITE}Termux-X11 Display Server:${NC} ${NEON_GREEN}Deployed & Online${NC}"
else
    echo -e "${NEON_PINK}[X]${NC} ${WHITE}Termux-X11 Display Server:${NC} ${NEON_PINK}Deployment Failed${NC}"
fi
echo ""

copy_self_to_home() {
    local dest="$HOME/nx_code.sh"
    local src=""
    if [ -n "$BASH_SOURCE" ] && [ -f "${BASH_SOURCE[0]}" ]; then
        src=$(realpath "${BASH_SOURCE[0]}" 2>/dev/null)
    elif [ -f "$0" ]; then
        src=$(realpath "$0" 2>/dev/null)
    fi
    if [ -n "$src" ] && [ -f "$src" ] && [ "$src" != "$dest" ]; then
        cp "$src" "$dest"
        chmod +x "$dest"
        return 0
    fi
    if [ ! -f "$dest" ]; then return 1; fi
    return 0
}

if copy_self_to_home; then
    chmod +x "$HOME/nx_code.sh" 2>/dev/null
else
    say_warn "WARNING: Source injected via memory stream (pipe). Cannot auto-copy."
fi

if grep -q 'command rm -i "\$@"' "$HOME/.bashrc" 2>/dev/null; then
    sed -i 's/command rm -i "\$@"/command rm "\$@"/' "$HOME/.bashrc"
fi

if ! grep -q "NX_CODE ENVIRONMENT" "$HOME/.bashrc" 2>/dev/null; then
    cat << 'EOF' >> "$HOME/.bashrc"

# --- NX_CODE ENVIRONMENT ---
if [ -f "$HOME/nx_code.sh" ]; then
    bash "$HOME/nx_code.sh" --ui-only
fi

alias ls='ls --color=auto --group-directories-first'
alias ll='ls -la --color=auto --group-directories-first'
alias nx-menu='bash $HOME/nx_code.sh --menu'

PS1="\[\033[1;92m\]┌──(\[\033[1;95m\]NX_CODE\[\033[1;92m\])─[\[\033[0;36m\]\w\[\033[1;92m\]]\n└─> \[\033[0m\]"

clear() {
    command clear
    if [ -f "$HOME/nx_code.sh" ]; then
        bash "$HOME/nx_code.sh" --logo-only
    fi
}

rm() {
    if [ $# -eq 0 ]; then
        echo -e "\033[1;95m[!] ALERT: NO TARGET SPECIFIED FOR PURGE MODULE.\033[0m"
        echo -e "\033[0;35m[?] SYSTEM HINT: Usage -> rm [file_name] or rm -rf [folder_name]\033[0m"
        return 1
    fi
    command rm "$@"
}

command_not_found_handle() {
    local cmd="$1"
    echo -e "\033[1;91m[CRITICAL] UNAUTHORIZED SYNTAX: '${cmd}'\033[0m"
    echo -e "\033[0;36m[SYS] Module missing or corrupted. Verify parameters.\033[0m"
    return 127
}
# ---------------------------
EOF
    say_ok "Auto-Startup Override    : ${NEON_GREEN}Injected Successfully${NC}"
else
    echo -e "${SUCCESS} ${WHITE}Auto-Startup Override    :${NC} ${CYAN}Already Configured${NC}"
fi

(dpkg -l | grep "^ii" > "$TMPDIR/installed_pkgs.txt"; sleep 1) 2>/dev/null &
show_futuristic_progress "Scanning Active Modules" $!

if [ -f "$TMPDIR/installed_pkgs.txt" ]; then
    total_pkgs=$(wc -l < "$TMPDIR/installed_pkgs.txt")
    echo -e "\n${PURPLE}>> DATABASE SCAN YIELD: ${NEON_GREEN}${total_pkgs} MODULES ACTIVE${NC}"
    echo -e "${CYAN}>> EXTRACTING CORE LOADOUT:${NC}"
    awk '{print "    [■] " $2 " (v" $3 ")"}' "$TMPDIR/installed_pkgs.txt" | head -n 4
    echo -e "    ${PURPLE}[■] ...and other background dependencies${NC}"
    rm -f "$TMPDIR/installed_pkgs.txt"
fi

echo -e "\n${NEON_GREEN}[INSTALLATION COMPLETE]${NC}"
echo -e "${NEON_PINK}======================================================${NC}"
echo -e "${NEON_GREEN}       SYSTEM INITIALIZED. WELCOME TO NX_CODE.        ${NC}"
echo -e "${NEON_PINK}======================================================${NC}"

echo -e "${WHITE}REBOOT REQUIRED:${NC}"
echo -e " ${PURPLE}[1]${NC} ${WHITE}Initiate Soft Reboot (Rekomendasi)${NC}"
echo -e " ${PURPLE}[2]${NC} ${WHITE}Exit Terminal${NC}"
echo -ne "${CYAN}[?] Pilihan:${NC} "
read final_choice

case "$final_choice" in
    1) exec bash ;;
    *) exit 0 ;;
esac

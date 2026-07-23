#!/data/data/com.termux/files/usr/bin/bash

# ==============================================================================
# [1] KONFIGURASI GLOBAL & MANIFES TEMA GITHUB
# ==============================================================================
NX_CODE_REPO_RAW_URL="https://raw.githubusercontent.com/nxcode123/nx_code/main/nx_code.sh"
NX_THEMES_MANIFEST_URL="https://raw.githubusercontent.com/nxcode123/nx_code/main/themes/theme.list"
NX_THEMES_BASE_URL="https://raw.githubusercontent.com/nxcode123/nx_code/main/themes"
NX_VERSION="v1.1.3"
NX_USER="nxuser"

THEME_DIR="$HOME/.nx_code/themes"
CONFIG_FILE="$HOME/.nx_code/config"

init_theme_system() {
    mkdir -p "$THEME_DIR"

    # Muat konfigurasi tema & debug aktif (default: cyberpunk, debug off)
    ACTIVE_THEME="cyberpunk"
    DEBUG_MODE="off"
    [ -f "$CONFIG_FILE" ] && source "$CONFIG_FILE"

    # Aktifkan trace bash jika debug mode 'on'
    [ "$DEBUG_MODE" == "on" ] && set -x

    local theme_file="$THEME_DIR/$ACTIVE_THEME.sh"

    # Jika file tema lokal belum ada, coba unduh dari GitHub
    if [ ! -f "$theme_file" ]; then
        curl -fsSL "$NX_THEMES_BASE_URL/$ACTIVE_THEME.sh" -o "$theme_file" 2>/dev/null
    fi

    # Fallback ke cyberpunk jika file kosong/gagal
    if [ ! -s "$theme_file" ]; then
        ACTIVE_THEME="cyberpunk"
        theme_file="$THEME_DIR/cyberpunk.sh"
        if [ ! -f "$theme_file" ]; then
            curl -fsSL "$NX_THEMES_BASE_URL/cyberpunk.sh" -o "$theme_file" 2>/dev/null
        fi
    fi

    # Load file tema
    if [ -f "$theme_file" ]; then
        source "$theme_file"
    else
        CYAN='\033[0;36m'
        NEON_GREEN='\033[1;32m'
        NEON_PINK='\033[1;95m'
        PURPLE='\033[0;35m'
        WHITE='\033[1;37m'
        NC='\033[0m'
    fi

    SUCCESS="${NEON_GREEN}[✔]${NC}"
    PROCESS="${CYAN}[➔]${NC}"
}

init_theme_system

# ==============================================================================
# [2] CORE UTILITIES (UI & LIVE PROGRESS)
# ==============================================================================
animate_logo() {
    command clear
    echo -e "${NEON_PINK}======================================================${NC}"
    local lines=(
        "  _   _ __  __       ____ ___  ____  _____ "
        " | \ | |\ \/ /      / ___/ _ \|  _ \| ____|"
        " |  \| | \  /  _____| |  | | | | | | |  _|  "
        " | |\  | /  \ |_____| |__| |_| | |_| | |___ "
        " |_| \_|/_/\_\       \____\___/|____/|_____| TERMINAL"
    )
    for line in "${lines[@]}"; do
        printf "${PURPLE}%s${NC}\r" "$line"
        sleep 0.04
        printf "${CYAN}%s${NC}\n" "$line"
    done
    echo -e "${PURPLE}------------------------------------------------------${NC}"
    echo -e "${WHITE} STATUS: ${NEON_GREEN}ONLINE${WHITE} | THEME: ${NEON_PINK}${ACTIVE_THEME}${WHITE} | DEBUG: ${NEON_PINK}${DEBUG_MODE^^}${NC}"
    echo -e "${NEON_PINK}======================================================${NC}"
    echo ""
}

show_live_progress() {
    local msg="$1"
    local pid="$2"
    local log_file="$3"
    local spinner=( "⠋" "⠙" "⠹" "⠸" "⠼" "⠴" "⠦" "⠧" "⠇" "⠏" )
    local i=0
    local start_time=$(date +%s)

    echo -ne "\033[?25l"
    while kill -0 "$pid" 2>/dev/null; do
        local current_time=$(date +%s)
        local elapsed=$((current_time - start_time))

        local last_line=""
        if [ -f "$log_file" ]; then
            last_line=$(tail -n 1 "$log_file" 2>/dev/null | sed 's/\x1b\[[0-9;]*m//g' | tr -d '\n\r' | cut -c 1-28)
        fi

        printf "\r\033[2K${PROCESS} ${CYAN}%-20s ${NEON_PINK}%s ${PURPLE}[%s] (%ds)${NC}" "$msg" "${spinner[$i]}" "$last_line" "$elapsed"

        i=$(( (i + 1) % 10 ))
        sleep 0.1
    done

    local end_time=$(date +%s)
    local elapsed=$((end_time - start_time))

    printf "\r\033[2K${SUCCESS} ${WHITE}%-20s ${NEON_GREEN}[DONE] ${PURPLE}(%ds)${NC}\n" "$msg" "$elapsed"
    echo -ne "\033[?25h"
}

execute_task() {
    local msg="$1"
    shift
    local tmp_log=$(mktemp)

    ( "$@" ) > "$tmp_log" 2>&1 &
    local pid=$!

    show_live_progress "$msg" "$pid" "$tmp_log"

    wait "$pid"
    local exit_code=$?
    rm -f "$tmp_log"
    return $exit_code
}

# ==============================================================================
# [3] SYSTEM CHECKERS & AUTO-CONFIG
# ==============================================================================
is_ubuntu_installed() { proot-distro login ubuntu -- true >/dev/null 2>&1; }
is_termux_x11_installed() { command -v termux-x11 >/dev/null 2>&1; }
is_xfce4_installed() { proot-distro login ubuntu -- bash -c "command -v startxfce4" >/dev/null 2>&1; }
is_nonroot_user_setup() { proot-distro login ubuntu -- bash -c "id $NX_USER" >/dev/null 2>&1; }
is_storage_setup() { [ -d "$HOME/storage/shared" ]; }

ensure_storage_setup() {
    if ! is_storage_setup; then
        echo -e "\n${PROCESS} ${CYAN}Konfigurasi Storage otomatis terdeteksi belum aktif...${NC}"
        echo -e "${PURPLE}[!] Perhatikan layar HP Anda dan pilih 'Allow / Izinkan' jika muncul pop-up izin penyimpanan.${NC}"
        termux-setup-storage
        sleep 2
    fi
}

# ==============================================================================
# [4] GUI MANAGEMENT & SETTINGS
# ==============================================================================
setup_nonroot_user() {
    proot-distro login ubuntu -- bash -c "
        useradd -m -s /bin/bash $NX_USER 2>/dev/null
        echo '$NX_USER ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/$NX_USER
        chmod 0440 /etc/sudoers.d/$NX_USER
        mkdir -p /storage && chmod 777 /storage
        grep -q ELECTRON_DISABLE_SANDBOX /etc/environment 2>/dev/null || echo 'ELECTRON_DISABLE_SANDBOX=true' >> /etc/environment
    "
}

choose_resolution() {
    GUI_CANCELLED=0
    echo -e "\n${PURPLE}------------------------------------------------------${NC}"
    echo -e "${WHITE}Pilih resolusi layar GUI:${NC}"
    echo -e " ${PURPLE}[1]${NC} ${WHITE}Custom resolution${NC}"
    echo -e " ${PURPLE}[2]${NC} ${WHITE}Native${NC}"
    echo -e " ${PURPLE}[3]${NC} ${WHITE}Kembali ke menu utama${NC}"
    echo -e "${PURPLE}------------------------------------------------------${NC}"
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
                echo -e "${NEON_PINK}[!] Format tidak valid. Pakai default 720x1440.${NC}"
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
        echo -e "\n${NEON_PINK}[X] Error: OS atau Termux:X11 belum terinstal sempurna.${NC}"
        return 1
    fi

    if ! is_xfce4_installed; then
        echo -e "\n${PURPLE}[!] Proses instalasi Desktop Environment butuh waktu tergantung koneksi...${NC}"
        execute_task "Menginstal XFCE4..." proot-distro login ubuntu -- bash -c "DEBIAN_FRONTEND=noninteractive apt update && DEBIAN_FRONTEND=noninteractive apt upgrade -y && DEBIAN_FRONTEND=noninteractive apt install xfce4 xfce4-goodies dbus-x11 x11-xserver-utils sudo tzdata -y"

        if ! is_xfce4_installed; then
            echo -e "${NEON_PINK}[X] Instalasi gagal. Periksa koneksi internet.${NC}"
            return 1
        fi
    fi

    if ! proot-distro login ubuntu -- bash -c "[ -f /usr/share/xfce4/backdrops/xubuntu-wallpaper.png ]" >/dev/null 2>&1; then
        proot-distro login ubuntu -- bash -c "mkdir -p /usr/share/xfce4/backdrops && echo 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=' | base64 -d > /usr/share/xfce4/backdrops/xubuntu-wallpaper.png" 2>/dev/null
    fi

    if ! is_nonroot_user_setup; then
        execute_task "Konfigurasi User..." setup_nonroot_user
    fi

    choose_resolution
    [ "$GUI_CANCELLED" -eq 1 ] && { echo -e "\n${NEON_GREEN}[➔] Dibatalkan.${NC}"; return 0; }

    write_gui_startup_script
    pkill -f "termux-x11" >/dev/null 2>&1
    sleep 1

    echo -e "\n${PROCESS} ${CYAN}Booting X11 Server & XFCE4...${NC}"
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

    if ! kill -0 "$X11_PID" 2>/dev/null; then
        echo -e "${NEON_PINK}[X] Gagal menyalakan X11 Server.${NC}"
        return 1
    fi

    am start --user 0 -n com.termux.x11/com.termux.x11.MainActivity >/dev/null 2>&1
    echo -e "${PROCESS} ${CYAN}Buka aplikasi Termux:X11 jika tidak muncul otomatis.${NC}\n"

    show_live_progress "GUI Active (Termux:X11)" "$X11_PID" "/dev/null"
    wait "$X11_PID" 2>/dev/null
    echo -e "\n${NEON_GREEN}[➔] Sesi GUI tertutup.${NC}"
}

kill_ubuntu_gui() {
    echo -e "\n${PROCESS} ${CYAN}Terminating GUI Sessions...${NC}"
    local found=0
    if pkill -f "termux-x11" >/dev/null 2>&1; then found=1; fi
    if proot-distro login ubuntu -- bash -c "pkill -f 'xfce4|dbus-launch|Xwayland'" >/dev/null 2>&1; then found=1; fi
    sleep 1
    if [ "$found" -eq 1 ]; then echo -e "${SUCCESS} ${WHITE}Sesi dihentikan.${NC}"; else echo -e "${NEON_PINK}[X]${NC} ${WHITE}Tidak ada sesi berjalan.${NC}"; fi
}

change_theme_menu() {
    local manifest="$HOME/.nx_themes_manifest.tmp"
    rm -f "$manifest"

    if ! curl -fsSL "$NX_THEMES_MANIFEST_URL" -o "$manifest" 2>/dev/null || [ ! -s "$manifest" ]; then
        echo -e "cyberpunk|Cyberpunk Neon\nmatrix|Matrix Green\ndracula|Dracula Dark\nsynthwave|Synthwave 84\nocean|Oceanic Deep\nsunset|Sunset Orange\nemerald|Emerald Forest\nbloodmoon|Blood Moon\nmonokai|Monokai Pro\narctic|Arctic Frost\ngold|Cyber Gold" > "$manifest"
    fi

    local t_names=() t_descs=()
    while IFS='|' read -r t_name t_desc; do
        [ -z "$t_name" ] && continue
        t_names+=("$t_name")
        t_descs+=("${t_desc:-Tema kustom}")
    done < "$manifest"
    rm -f "$manifest"

    while true; do
        animate_logo
        echo -e "${PURPLE}------------------------------------------------------${NC}"
        echo -e "${WHITE}PILIH TEMA INTERFACE (DARI theme.list GITHUB)${NC}"
        echo -e "${PURPLE}------------------------------------------------------${NC}"

        for i in "${!t_names[@]}"; do
            local name="${t_names[$i]}"
            local desc="${t_descs[$i]}"
            local marker=" "
            [ "$ACTIVE_THEME" == "$name" ] && marker="[✔]"
            printf " ${PURPLE}[%d]${NC} ${WHITE}%-12s${NC} ${CYAN}- %s${NC} ${NEON_GREEN}%s${NC}\n" "$((i+1))" "$name" "$desc" "$marker"
        done
        echo -e " ${PURPLE}[0]${NC} ${WHITE}Kembali ke Menu Utama${NC}"
        echo -e "${PURPLE}------------------------------------------------------${NC}"
        echo -ne "${CYAN}[?] Pilih nomor tema:${NC} "
        read t_choice

        if [ "$t_choice" == "0" ]; then
            break
        fi

        local idx=$((t_choice - 1))
        if [ -n "${t_names[$idx]:-}" ]; then
            local chosen="${t_names[$idx]}"
            local theme_file="$THEME_DIR/$chosen.sh"

            if [ ! -f "$theme_file" ]; then
                echo -e "\n${PROCESS} ${CYAN}Mengunduh tema '$chosen.sh' dari GitHub...${NC}"
                curl -fsSL "$NX_THEMES_BASE_URL/$chosen.sh" -o "$theme_file" 2>/dev/null
                sed -i 's/\xc2\xa0/ /g' "$theme_file" 2>/dev/null
            fi

            if [ -f "$theme_file" ] && [ -s "$theme_file" ]; then
                ACTIVE_THEME="$chosen"
                echo "ACTIVE_THEME=\"$ACTIVE_THEME\"" > "$CONFIG_FILE"
                echo "DEBUG_MODE=\"$DEBUG_MODE\"" >> "$CONFIG_FILE"
                echo -e "\n${SUCCESS} ${WHITE}Tema berhasil diubah ke: ${NEON_PINK}$chosen${NC}"
                sleep 1
                source "$theme_file"
            else
                echo -e "\n${NEON_PINK}[!] Gagal mengunduh file tema. Periksa koneksi internet.${NC}"
                sleep 1
            fi
        else
            echo -e "${NEON_PINK}[!] Pilihan tidak valid.${NC}"
            sleep 1
        fi
    done
}

toggle_debug_mode() {
    if [ "$DEBUG_MODE" == "on" ]; then
        DEBUG_MODE="off"
        set +x
        echo -e "\n${NEON_PINK}[!] Debug Mode DIMATIKAN.${NC}"
    else
        DEBUG_MODE="on"
        set -x
        echo -e "\n${NEON_GREEN}[✔] Debug Mode DIHIDUPKAN (Trace aktif).${NC}"
    fi

    # Simpan state ke config file
    echo "ACTIVE_THEME=\"$ACTIVE_THEME\"" > "$CONFIG_FILE"
    echo "DEBUG_MODE=\"$DEBUG_MODE\"" >> "$CONFIG_FILE"
    sleep 1.5
}

# ==============================================================================
# [5] SYSTEM MANAGEMENT
# ==============================================================================
run_auto_cleaner() {
    local last_clean_file="$HOME/.nx_code_last_clean"
    local today=$(date +%Y%m%d)
    local last_clean=""
    [ -f "$last_clean_file" ] && last_clean=$(cat "$last_clean_file" 2>/dev/null)

    if [ "$today" != "$last_clean" ]; then
        execute_task "Auto-Cleaner Storage" bash -c "pkg clean -y && [ -n \"$TMPDIR\" ] && rm -rf \"$TMPDIR\"/*"
        echo "$today" > "$last_clean_file"
    fi
}

check_for_update() {
    echo -e "\n${PROCESS} ${CYAN}Checking GitHub Repository...${NC}"
    local tmp_file="$HOME/.nx_code_update_tmp.sh"

    if ! curl -fsSL "$NX_CODE_REPO_RAW_URL" -o "$tmp_file" 2>/dev/null || [ ! -s "$tmp_file" ]; then
        echo -e "${NEON_PINK}[X] Gagal/File kosong. Periksa koneksi internet.${NC}"
        rm -f "$tmp_file"; return 1
    fi

    if diff -q "$tmp_file" "$HOME/nx_code.sh" >/dev/null 2>&1; then
        echo -e "${SUCCESS} ${WHITE}Sistem sudah mutakhir.${NC}"
        rm -f "$tmp_file"; return 0
    fi

    echo -e "${SUCCESS} ${WHITE}Update dipasang! Merestart sistem...${NC}"
    mv "$tmp_file" "$HOME/nx_code.sh"
    sed -i 's/\xc2\xa0/ /g' "$HOME/nx_code.sh" 2>/dev/null
    chmod +x "$HOME/nx_code.sh"
    sed -i '/# --- NX_CODE ENVIRONMENT ---/,/# ---------------------------/d' "$HOME/.bashrc" 2>/dev/null
    sleep 1
    exec bash "$HOME/nx_code.sh"
}

copy_self_to_home() {
    local dest="$HOME/nx_code.sh"
    local src=$(realpath "${BASH_SOURCE[0]:-$0}" 2>/dev/null)

    if [ -n "$src" ] && [ -f "$src" ] && [ "$src" != "$dest" ]; then
        cp "$src" "$dest"
        sed -i 's/\xc2\xa0/ /g' "$dest" 2>/dev/null
        chmod +x "$dest"
        return 0
    fi
    [ -f "$dest" ] || return 1
}

# ==============================================================================
# [6] ROUTING & MENU
# ==============================================================================
show_shortcut_menu() {
    animate_logo
    echo -e "${NEON_PINK}======================================================${NC}"
    echo -e "${WHITE}             NX_CODE MENU ${NX_VERSION}              ${NC}"
    echo -e "${NEON_PINK}======================================================${NC}"
    echo -e " ${PURPLE}[1]${NC} ${WHITE}Ubuntu CLI${NC}"
    echo -e " ${PURPLE}[2]${NC} ${WHITE}Ubuntu GUI (XFCE4 via Termux:X11)${NC}"
    echo -e " ${PURPLE}[3]${NC} ${WHITE}Kill Ubuntu GUI${NC}"
    echo -e " ${PURPLE}[4]${NC} ${WHITE}Ganti Tema Interface${NC}"
    echo -e " ${PURPLE}[5]${NC} ${WHITE}Check for Updates${NC}"
    echo -e " ${PURPLE}[6]${NC} ${WHITE}Toggle Debug Mode (${NEON_GREEN}${DEBUG_MODE^^}${WHITE})${NC}"
    echo -e "${NEON_PINK}======================================================${NC}"
    echo -e " ${PURPLE}[0]${NC} ${WHITE}Exit Interface${NC}"
    echo -e "${NEON_PINK}======================================================${NC}"
    echo -ne "${CYAN}[?] Select Option:${NC} "
    read pilihan

    case $pilihan in
        1)
            echo -e "\n${PROCESS} ${CYAN}Booting Core OS...${NC}"; sleep 1
            is_ubuntu_installed && proot-distro login ubuntu || echo -e "${NEON_PINK}[X] Error: OS belum terinstal.${NC}"
            ;;
        2) launch_ubuntu_gui; sleep 1; show_shortcut_menu ;;
        3) kill_ubuntu_gui; sleep 1; show_shortcut_menu ;;
        4) change_theme_menu; sleep 1; show_shortcut_menu ;;
        5) check_for_update; sleep 1; show_shortcut_menu ;;
        6) toggle_debug_mode; sleep 1; show_shortcut_menu ;;
        0) echo -e "\n${NEON_GREEN}[➔] System Standby.${NC}\n" ;;
        *) echo -e "\n\033[1;95m[!] ALERT: INVALID DIRECTIVE.\033[0m"; sleep 1; show_shortcut_menu ;;
    esac
}

# Argument Routing
case "$1" in
    --logo-only) animate_logo; exit 0 ;;
    --menu) show_shortcut_menu; exit 0 ;;
    --ui-only)
        animate_logo

        echo -ne "${CYAN}Syncing database...... ${NC}"
        echo -e "${NEON_GREEN}[✔] Clear${NC}"

        echo -ne "${CYAN}Ubuntu Integrity...... ${NC}"
        is_ubuntu_installed && echo -e "${NEON_GREEN}[✔] Ready${NC}" || echo -e "${NEON_PINK}[X] Missing${NC}"

        echo -ne "${CYAN}Storage Access........ ${NC}"
        if is_storage_setup; then
            echo -e "${NEON_GREEN}[✔] Ready${NC}"
        else
            echo -e "${NEON_PINK}[X] Auto-Triggering Setup...${NC}"
            termux-setup-storage
        fi

        run_auto_cleaner
        echo -e "\n${PURPLE}Ketik ${CYAN}nx-menu${PURPLE} untuk mengakses interface kontrol.${NC}\n"
        exit 0
        ;;
esac

# ==============================================================================
# [7] INSTALLATION MODE (BOOTSTRAPPER)
# ==============================================================================
termux-wake-lock
animate_logo

ensure_storage_setup

execute_task "Updating Repos..." pkg update -y -o Dpkg::Options::="--force-confold"
execute_task "Upgrading Core..." pkg upgrade -y -o Dpkg::Options::="--force-confold"
execute_task "Deploy Hypervisor..." pkg install proot-distro coreutils -y -o Dpkg::Options::="--force-confold"
execute_task "Add X11 Repo..." pkg install x11-repo -y -o Dpkg::Options::="--force-confold"
execute_task "Deploy X11 Server..." pkg install termux-x11-nightly -y -o Dpkg::Options::="--force-confold"

if ! is_ubuntu_installed; then
    echo -e "\n${PROCESS} ${CYAN}Mempersiapkan unduhan Ubuntu OS...${NC}"
    proot-distro remove ubuntu > /dev/null 2>&1
    echo -e "${PURPLE}[!] System akan mengunduh Ubuntu secara live. Mohon tunggu...${NC}"
    echo -e "${CYAN}------------------------------------------------------${NC}"
    proot-distro install ubuntu
    echo -e "${CYAN}------------------------------------------------------${NC}"
fi

echo ""
is_ubuntu_installed && echo -e "${SUCCESS} ${WHITE}Ubuntu Core OS            :${NC} ${NEON_GREEN}Installed${NC}" || echo -e "${NEON_PINK}[X]${NC} ${WHITE}Ubuntu Core OS            :${NC} ${NEON_PINK}Failed${NC}"
is_termux_x11_installed && echo -e "${SUCCESS} ${WHITE}Termux-X11 Display Server:${NC} ${NEON_GREEN}Installed${NC}" || echo -e "${NEON_PINK}[X]${NC} ${WHITE}Termux-X11 Display Server:${NC} ${NEON_PINK}Failed${NC}"
echo ""

if ! copy_self_to_home; then
    echo -e "${NEON_PINK}[!] Script dipanggil via pipe. Tolong download script & simpan sebagai nx_code.sh${NC}"
fi

# Injeksi bashrc Profile
if ! grep -q "NX_CODE ENVIRONMENT" "$HOME/.bashrc" 2>/dev/null; then
    sed -i 's/command rm -i "\$@"/command rm "\$@"/' "$HOME/.bashrc" 2>/dev/null

    cat << 'EOF' >> "$HOME/.bashrc"

# --- NX_CODE ENVIRONMENT ---
[ -f "$HOME/nx_code.sh" ] && bash "$HOME/nx_code.sh" --ui-only
alias ls='ls --color=auto --group-directories-first'
alias ll='ls -la --color=auto --group-directories-first'
alias nx-menu='bash $HOME/nx_code.sh --menu'
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
    echo -e "\033[1;95m[!] ALERT: UNAUTHORIZED COMMAND '$1' DETECTED.\033[0m"
    return 127
}
# ---------------------------
EOF
    echo -e "${SUCCESS} ${WHITE}Auto-Startup Profile     :${NC} ${NEON_GREEN}Injected Successfully${NC}"
else
    echo -e "${SUCCESS} ${WHITE}Auto-Startup Profile     :${NC} ${CYAN}Already Configured${NC}"
fi

termux-wake-unlock

echo -e "\n${NEON_GREEN}[Complete]${NC}"
echo -e "${NEON_PINK}======================================================${NC}"
echo -e "${NEON_GREEN}           SYSTEM INITIALIZED. NX_CODE ACTIVE.         ${NC}"
echo -e "${NEON_PINK}======================================================${NC}"

echo -e " ${PURPLE}[1]${NC} ${WHITE}Restart Terminal${NC}"
echo -e " ${PURPLE}[2]${NC} ${WHITE}Exit${NC}"
echo -ne "${CYAN}[?] Pilihan:${NC} "
read final_choice

[ "$final_choice" == "1" ] && exec bash || exit 0

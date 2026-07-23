#!/data/data/com.termux/files/usr/bin/bash

# ==============================================================================
# [1] KONFIGURASI GLOBAL & SISTEM MODULAR GITHUB
# ==============================================================================
NX_CODE_REPO_RAW_URL="https://raw.githubusercontent.com/nxcode123/nx_code/main/nx_code.sh"

# Konfigurasi Tema GitHub
NX_THEMES_MANIFEST_URL="https://raw.githubusercontent.com/nxcode123/nx_code/main/themes/theme.list"
NX_THEMES_BASE_URL="https://raw.githubusercontent.com/nxcode123/nx_code/main/themes"

# Konfigurasi Bahasa GitHub
NX_LANG_MANIFEST_URL="https://raw.githubusercontent.com/nxcode123/nx_code/main/lang/lang.list"
NX_LANG_BASE_URL="https://raw.githubusercontent.com/nxcode123/nx_code/main/lang"

# Konfigurasi Logo GitHub
NX_LOGOS_MANIFEST_URL="https://raw.githubusercontent.com/nxcode123/nx_code/main/logos/logo.list"
NX_LOGOS_BASE_URL="https://raw.githubusercontent.com/nxcode123/nx_code/main/logos"

NX_VERSION="v1.1.7"
NX_USER="nxuser"
NX_CURL_OPTS="-fsSL --connect-timeout 5 --max-time 10 --retry 2"

THEME_DIR="$HOME/.nx_code/themes"
LANG_DIR="$HOME/.nx_code/lang"
LOGOS_DIR="$HOME/.nx_code/logos"
CONFIG_FILE="$HOME/.nx_code/config"

init_system_modules() {
    mkdir -p "$THEME_DIR" "$LANG_DIR" "$LOGOS_DIR"

    # Default konfigurasi
    ACTIVE_THEME="cyberpunk"
    ACTIVE_LANG="id"
    ACTIVE_LOGO="classic"
    DEBUG_MODE="off"
    [ -f "$CONFIG_FILE" ] && source "$CONFIG_FILE"

    [ "$DEBUG_MODE" == "on" ] && set -x

    # 1. Inisialisasi Tema
    local theme_file="$THEME_DIR/$ACTIVE_THEME.sh"
    [ ! -f "$theme_file" ] && curl $NX_CURL_OPTS "$NX_THEMES_BASE_URL/$ACTIVE_THEME.sh" -o "$theme_file" 2>/dev/null
    if [ ! -s "$theme_file" ]; then
        ACTIVE_THEME="cyberpunk"
        theme_file="$THEME_DIR/cyberpunk.sh"
        [ ! -f "$theme_file" ] && curl $NX_CURL_OPTS "$NX_THEMES_BASE_URL/cyberpunk.sh" -o "$theme_file" 2>/dev/null
    fi
    [ -f "$theme_file" ] && source "$theme_file" || {
        CYAN='\033[0;36m'; NEON_GREEN='\033[1;32m'; NEON_PINK='\033[1;95m'; PURPLE='\033[0;35m'; WHITE='\033[1;37m'; NC='\033[0m'
    }

    # 2. Inisialisasi Bahasa
    local lang_file="$LANG_DIR/$ACTIVE_LANG.sh"
    [ ! -f "$lang_file" ] && curl $NX_CURL_OPTS "$NX_LANG_BASE_URL/$ACTIVE_LANG.sh" -o "$lang_file" 2>/dev/null
    if [ ! -s "$lang_file" ]; then
        ACTIVE_LANG="id"
        lang_file="$LANG_DIR/id.sh"
        [ ! -f "$lang_file" ] && curl $NX_CURL_OPTS "$NX_LANG_BASE_URL/id.sh" -o "$lang_file" 2>/dev/null
    fi
    [ -f "$lang_file" ] && source "$lang_file"

    # 3. Inisialisasi Logo ASCII
    local logo_file="$LOGOS_DIR/$ACTIVE_LOGO.sh"
    [ ! -f "$logo_file" ] && curl $NX_CURL_OPTS "$NX_LOGOS_BASE_URL/$ACTIVE_LOGO.sh" -o "$logo_file" 2>/dev/null
    if [ ! -s "$logo_file" ]; then
        ACTIVE_LOGO="classic"
        logo_file="$LOGOS_DIR/classic.sh"
        [ ! -f "$logo_file" ] && curl $NX_CURL_OPTS "$NX_LOGOS_BASE_URL/classic.sh" -o "$logo_file" 2>/dev/null
    fi
    if [ -f "$logo_file" ]; then
        source "$logo_file"
    else
        LOGO_LINES=(
            "  _   _ __  __       ____ ___  ____  _____ "
            " | \ | |\ \/ /      / ___/ _ \|  _ \| ____|"
            " |  \| | \  /  _____| |  | | | | | | |  _|  "
            " | |\  | /  \ |_____| |__| |_| | |_| | |___ "
            " |_| \_|/_/\_\       \____\___/|____/|_____| TERMINAL"
        )
    fi

    SUCCESS="${NEON_GREEN}[✔]${NC}"
    PROCESS="${CYAN}[➔]${NC}"
}

init_system_modules

save_config() {
    echo "ACTIVE_THEME=\"$ACTIVE_THEME\"" > "$CONFIG_FILE"
    echo "ACTIVE_LANG=\"$ACTIVE_LANG\"" >> "$CONFIG_FILE"
    echo "ACTIVE_LOGO=\"$ACTIVE_LOGO\"" >> "$CONFIG_FILE"
    echo "DEBUG_MODE=\"$DEBUG_MODE\"" >> "$CONFIG_FILE"
}

# ==============================================================================
# [2] CORE UTILITIES (ELEGANT UI & LIVE PROGRESS)
# ==============================================================================
animate_logo() {
    command clear
    echo -e "${NEON_PINK}╔══════════════════════════════════════════════════════╗${NC}"
    for line in "${LOGO_LINES[@]}"; do
        printf "${PURPLE}%s${NC}\r" "$line"
        sleep 0.02
        printf "${CYAN}%s${NC}\n" "$line"
    done
    echo -e "${NEON_PINK}╠══════════════════════════════════════════════════════╣${NC}"
    echo -e "${WHITE} STATUS: ${NEON_GREEN}ONLINE${WHITE} │ THEME: ${NEON_PINK}${ACTIVE_THEME^^}${WHITE} │ LOGO: ${CYAN}${ACTIVE_LOGO^^}${NC}"
    echo -e "${NEON_PINK}╚══════════════════════════════════════════════════════╝${NC}"
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
        [ -f "$log_file" ] && last_line=$(tail -n 1 "$log_file" 2>/dev/null | sed 's/\x1b\[[0-9;]*m//g' | tr -d '\n\r' | cut -c 1-22)

        printf "\r\033[2K${NEON_PINK}%s${NC} ${WHITE}%-18s${NC} ${CYAN}│${NC} ${PURPLE}%-22s${NC} ${CYAN}(%ds)${NC}" \
            "${spinner[$i]}" "$msg" "$last_line" "$elapsed"

        i=$(( (i + 1) % ${#spinner[@]} ))
        sleep 0.1
    done

    local end_time=$(date +%s)
    local elapsed=$((end_time - start_time))

    printf "\r\033[2K${SUCCESS} ${WHITE}%-18s${NC} ${CYAN}│${NC} ${NEON_GREEN}COMPLETED${NC}                       ${CYAN}(%ds)${NC}\n" \
        "$msg" "$elapsed"
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
# [3] SYSTEM CHECKERS & CONFIGURATION
# ==============================================================================
is_ubuntu_installed() { proot-distro login ubuntu -- true >/dev/null 2>&1; }
is_termux_x11_installed() { command -v termux-x11 >/dev/null 2>&1; }
is_xfce4_installed() { proot-distro login ubuntu -- bash -c "command -v startxfce4" >/dev/null 2>&1; }
is_nonroot_user_setup() { proot-distro login ubuntu -- bash -c "id $NX_USER" >/dev/null 2>&1; }
is_storage_setup() { [ -d "$HOME/storage/shared" ]; }

ensure_storage_setup() {
    if ! is_storage_setup; then
        echo -e "\n${NEON_PINK}[SYS]${NC} ${WHITE}Meminta izin akses Shared Storage...${NC}"
        termux-setup-storage
        sleep 2
    fi
}

# ==============================================================================
# [4] GUI MANAGEMENT, THEMES, LANGUAGES & LOGOS SWITCHER
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

change_theme_menu() {
    local manifest="$HOME/.nx_themes_manifest.tmp"
    rm -f "$manifest"
    if ! curl $NX_CURL_OPTS "$NX_THEMES_MANIFEST_URL" -o "$manifest" 2>/dev/null || [ ! -s "$manifest" ]; then
        echo -e "cyberpunk|Cyberpunk Neon\nmatrix|Matrix Green\ndracula|Dracula Dark\nsynthwave|Synthwave 84\nocean|Oceanic Deep" > "$manifest"
    fi

    local t_names=() t_descs=()
    while IFS='|' read -r t_name t_desc; do
        [ -z "$t_name" ] && continue
        t_names+=("$t_name"); t_descs+=("${t_desc:-Custom}")
    done < "$manifest"
    rm -f "$manifest"

    while true; do
        animate_logo
        echo -e "${PURPLE}──────────────────────────────────────────────────────${NC}"
        echo -e "${WHITE}PILIH TEMA INTERFACE${NC}"
        echo -e "${PURPLE}──────────────────────────────────────────────────────${NC}"
        for i in "${!t_names[@]}"; do
            local marker=" "; [ "$ACTIVE_THEME" == "${t_names[$i]}" ] && marker="[✔]"
            printf " ${PURPLE}[%d]${NC} ${WHITE}%-12s${NC} ${CYAN}│ %s${NC} ${NEON_GREEN}%s${NC}\n" "$((i+1))" "${t_names[$i]}" "${t_descs[$i]}" "$marker"
        done
        echo -e " ${PURPLE}[0]${NC} ${WHITE}Kembali${NC}"
        echo -e "${PURPLE}──────────────────────────────────────────────────────${NC}"
        echo -ne "${CYAN}[?] Pilihan ➔ ${NC}"; read t_choice
        [ "$t_choice" == "0" ] && break

        local idx=$((t_choice - 1))
        if [ -n "${t_names[$idx]:-}" ]; then
            ACTIVE_THEME="${t_names[$idx]}"
            local theme_file="$THEME_DIR/$ACTIVE_THEME.sh"
            [ ! -f "$theme_file" ] && curl $NX_CURL_OPTS "$NX_THEMES_BASE_URL/$ACTIVE_THEME.sh" -o "$theme_file" 2>/dev/null
            sed -i 's/\xc2\xa0/ /g' "$theme_file" 2>/dev/null
            save_config
            source "$theme_file"
            echo -e "\n${SUCCESS} ${WHITE}Tema diubah ke: ${NEON_PINK}$ACTIVE_THEME${NC}"; sleep 1
        fi
    done
}

change_language_menu() {
    local manifest="$HOME/.nx_lang_manifest.tmp"
    rm -f "$manifest"
    if ! curl $NX_CURL_OPTS "$NX_LANG_MANIFEST_URL" -o "$manifest" 2>/dev/null || [ ! -s "$manifest" ]; then
        echo -e "id|Bahasa Indonesia\nen|English" > "$manifest"
    fi

    local l_codes=() l_names=()
    while IFS='|' read -r l_code l_name; do
        [ -z "$l_code" ] && continue
        l_codes+=("$l_code"); l_names+=("${l_name:-Language}")
    done < "$manifest"
    rm -f "$manifest"

    while true; do
        animate_logo
        echo -e "${PURPLE}──────────────────────────────────────────────────────${NC}"
        echo -e "${WHITE}PILIH BAHASA / LANGUAGE${NC}"
        echo -e "${PURPLE}──────────────────────────────────────────────────────${NC}"
        for i in "${!l_codes[@]}"; do
            local marker=" "; [ "$ACTIVE_LANG" == "${l_codes[$i]}" ] && marker="[✔]"
            printf " ${PURPLE}[%d]${NC} ${WHITE}%-6s${NC} ${CYAN}│ %s${NC} ${NEON_GREEN}%s${NC}\n" "$((i+1))" "${l_codes[$i]}" "${l_names[$i]}" "$marker"
        done
        echo -e " ${PURPLE}[0]${NC} ${WHITE}Kembali${NC}"
        echo -e "${PURPLE}──────────────────────────────────────────────────────${NC}"
        echo -ne "${CYAN}[?] Pilihan ➔ ${NC}"; read l_choice
        [ "$l_choice" == "0" ] && break

        local idx=$((l_choice - 1))
        if [ -n "${l_codes[$idx]:-}" ]; then
            ACTIVE_LANG="${l_codes[$idx]}"
            local lang_file="$LANG_DIR/$ACTIVE_LANG.sh"
            [ ! -f "$lang_file" ] && curl $NX_CURL_OPTS "$NX_LANG_BASE_URL/$ACTIVE_LANG.sh" -o "$lang_file" 2>/dev/null
            sed -i 's/\xc2\xa0/ /g' "$lang_file" 2>/dev/null
            save_config
            source "$lang_file"
            echo -e "\n${SUCCESS} ${WHITE}Bahasa diubah ke: ${NEON_PINK}$ACTIVE_LANG${NC}"; sleep 1
        fi
    done
}

change_logo_menu() {
    local manifest="$HOME/.nx_logo_manifest.tmp"
    rm -f "$manifest"
    if ! curl $NX_CURL_OPTS "$NX_LOGOS_MANIFEST_URL" -o "$manifest" 2>/dev/null || [ ! -s "$manifest" ]; then
        echo -e "classic|Classic Terminal Logo\nmatrix|Matrix Green Logo\ncyber|Cyberpunk Minimal Logo" > "$manifest"
    fi

    local l_names=() l_descs=()
    while IFS='|' read -r l_name l_desc; do
        [ -z "$l_name" ] && continue
        l_names+=("$l_name"); l_descs+=("${l_desc:-Custom Logo}")
    done < "$manifest"
    rm -f "$manifest"

    while true; do
        animate_logo
        echo -e "${PURPLE}──────────────────────────────────────────────────────${NC}"
        echo -e "${WHITE}PILIH LOGO & ASCII ART${NC}"
        echo -e "${PURPLE}──────────────────────────────────────────────────────${NC}"
        for i in "${!l_names[@]}"; do
            local marker=" "; [ "$ACTIVE_LOGO" == "${l_names[$i]}" ] && marker="[✔]"
            printf " ${PURPLE}[%d]${NC} ${WHITE}%-12s${NC} ${CYAN}│ %s${NC} ${NEON_GREEN}%s${NC}\n" "$((i+1))" "${l_names[$i]}" "${l_descs[$i]}" "$marker"
        done
        echo -e " ${PURPLE}[0]${NC} ${WHITE}Kembali${NC}"
        echo -e "${PURPLE}──────────────────────────────────────────────────────${NC}"
        echo -ne "${CYAN}[?] Pilihan ➔ ${NC}"; read lg_choice
        [ "$lg_choice" == "0" ] && break

        local idx=$((lg_choice - 1))
        if [ -n "${l_names[$idx]:-}" ]; then
            ACTIVE_LOGO="${l_names[$idx]}"
            local logo_file="$LOGOS_DIR/$ACTIVE_LOGO.sh"
            [ ! -f "$logo_file" ] && curl $NX_CURL_OPTS "$NX_LOGOS_BASE_URL/$ACTIVE_LOGO.sh" -o "$logo_file" 2>/dev/null
            sed -i 's/\xc2\xa0/ /g' "$logo_file" 2>/dev/null
            save_config
            source "$logo_file"
            echo -e "\n${SUCCESS} ${WHITE}Logo diubah ke: ${NEON_PINK}$ACTIVE_LOGO${NC}"; sleep 1
        fi
    done
}

toggle_debug_mode() {
    if [ "$DEBUG_MODE" == "on" ]; then
        DEBUG_MODE="off"; set +x
        echo -e "\n${NEON_PINK}[SYS] Debug dimatikan.${NC}"
    else
        DEBUG_MODE="on"; set -x
        echo -e "\n${NEON_GREEN}[SYS] Debug diaktifkan.${NC}"
    fi
    save_config; sleep 1.5
}

# ==============================================================================
# [5] SYSTEM MANAGEMENT
# ==============================================================================
run_auto_cleaner() {
    local last_clean_file="$HOME/.nx_code_last_clean"
    local today=$(date +%Y%m%d)
    local last_clean=""; [ -f "$last_clean_file" ] && last_clean=$(cat "$last_clean_file" 2>/dev/null)
    if [ "$today" != "$last_clean" ]; then
        execute_task "System Cleaner" bash -c "pkg clean -y && [ -n \"$TMPDIR\" ] && rm -rf \"$TMPDIR\"/*"
        echo "$today" > "$last_clean_file"
    fi
}

check_for_update() {
    echo -e "\n${PROCESS} ${CYAN}Memeriksa pembaruan...${NC}"
    local tmp_file="$HOME/.nx_code_update_tmp.sh"
    if ! curl $NX_CURL_OPTS "$NX_CODE_REPO_RAW_URL" -o "$tmp_file" 2>/dev/null || [ ! -s "$tmp_file" ]; then
        echo -e "${NEON_PINK}[ERR] Gagal memeriksa update.${NC}"; rm -f "$tmp_file"; return 1
    fi
    if diff -q "$tmp_file" "$HOME/nx_code.sh" >/dev/null 2>&1; then
        echo -e "${SUCCESS} ${WHITE}Sistem sudah versi terbaru.${NC}"; rm -f "$tmp_file"; return 0
    fi
    mv "$tmp_file" "$HOME/nx_code.sh"; sed -i 's/\xc2\xa0/ /g' "$HOME/nx_code.sh" 2>/dev/null; chmod +x "$HOME/nx_code.sh"
    sed -i '/# --- NX_CODE ENVIRONMENT ---/,/# ---------------------------/d' "$HOME/.bashrc" 2>/dev/null
    exec bash "$HOME/nx_code.sh"
}

copy_self_to_home() {
    local dest="$HOME/nx_code.sh"
    local src=$(realpath "${BASH_SOURCE[0]:-$0}" 2>/dev/null)
    if [ -n "$src" ] && [ -f "$src" ] && [ "$src" != "$dest" ]; then
        cp "$src" "$dest"; sed -i 's/\xc2\xa0/ /g' "$dest" 2>/dev/null; chmod +x "$dest"; return 0
    fi
    [ -f "$dest" ] || return 1
}

# ==============================================================================
# [6] ROUTING & DYNAMIC MENU
# ==============================================================================
show_shortcut_menu() {
    animate_logo
    echo -e "${NEON_PINK}──────────────────────────────────────────────────────${NC}"
    echo -e "${WHITE}               ${TXT_MENU_TITLE}                 ${NC}"
    echo -e "${NEON_PINK}──────────────────────────────────────────────────────${NC}"
    echo -e " ${PURPLE}[1]${NC} ${WHITE}${TXT_MENU_1}${NC}"
    echo -e " ${PURPLE}[2]${NC} ${WHITE}${TXT_MENU_2}${NC}"
    echo -e " ${PURPLE}[3]${NC} ${WHITE}${TXT_MENU_3}${NC}"
    echo -e " ${PURPLE}[4]${NC} ${WHITE}${TXT_MENU_4}${NC}"
    echo -e " ${PURPLE}[5]${NC} ${WHITE}${TXT_MENU_5}${NC}"
    echo -e " ${PURPLE}[6]${NC} ${WHITE}Ganti Logo Art (Logo Switcher)${NC}"
    echo -e " ${PURPLE}[7]${NC} ${WHITE}${TXT_MENU_6}${NC}"
    echo -e " ${PURPLE}[8]${NC} ${WHITE}${TXT_MENU_7} (${NEON_GREEN}${DEBUG_MODE^^}${WHITE})${NC}"
    echo -e "${NEON_PINK}──────────────────────────────────────────────────────${NC}"
    echo -e " ${PURPLE}[0]${NC} ${WHITE}${TXT_MENU_0}${NC}"
    echo -e "${NEON_PINK}──────────────────────────────────────────────────────${NC}"
    echo -ne "${CYAN}[?] ${TXT_SELECT} ➔ ${NC}"
    read pilihan

    case $pilihan in
        1)
            echo -e "\n${PROCESS} ${CYAN}Memuat Ubuntu CLI...${NC}"; sleep 1
            is_ubuntu_installed && proot-distro login ubuntu || echo -e "${NEON_PINK}[ERR] Ubuntu belum terinstal.${NC}"
            ;;
        2) launch_ubuntu_gui; sleep 1; show_shortcut_menu ;;
        3) kill_ubuntu_gui; sleep 1; show_shortcut_menu ;;
        4) change_theme_menu; sleep 1; show_shortcut_menu ;;
        5) change_language_menu; sleep 1; show_shortcut_menu ;;
        6) change_logo_menu; sleep 1; show_shortcut_menu ;;
        7) check_for_update; sleep 1; show_shortcut_menu ;;
        8) toggle_debug_mode; sleep 1; show_shortcut_menu ;;
        0) echo -e "\n${NEON_GREEN}[➔] Keluar.${NC}\n" ;;
        *) echo -e "\n${NEON_PINK}[!] Invalid.${NC}"; sleep 1; show_shortcut_menu ;;
    esac
}

case "$1" in
    --logo-only) animate_logo; exit 0 ;;
    --menu) show_shortcut_menu; exit 0 ;;
    --ui-only)
        animate_logo
        echo -ne "${CYAN}[SYS] Ubuntu Integrity...... ${NC}"
        is_ubuntu_installed && echo -e "${NEON_GREEN}[✔] Ready${NC}" || echo -e "${NEON_PINK}[X] Missing${NC}"
        run_auto_cleaner
        echo -e "\n${PURPLE}Ketik ${CYAN}nx-menu${PURPLE} untuk membuka control center.${NC}\n"
        exit 0
        ;;
esac

# ==============================================================================
# [7] INSTALLATION BOOTSTRAPPER
# ==============================================================================
termux-wake-lock
animate_logo
ensure_storage_setup

execute_task "Updating Repos" pkg update -y -o Dpkg::Options::="--force-confold"
execute_task "Upgrading Core" pkg upgrade -y -o Dpkg::Options::="--force-confold"
execute_task "Deploy Hypervisor" pkg install proot-distro coreutils -y -o Dpkg::Options::="--force-confold"
execute_task "Add X11 Repo" pkg install x11-repo -y -o Dpkg::Options::="--force-confold"
execute_task "Deploy X11 Server" pkg install termux-x11-nightly -y -o Dpkg::Options::="--force-confold"

if ! is_ubuntu_installed; then
    echo -e "\n${PROCESS} ${CYAN}Mengunduh Ubuntu OS...${NC}"
    proot-distro remove ubuntu > /dev/null 2>&1
    proot-distro install ubuntu
fi

copy_self_to_home

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
rm() { [ $# -eq 0 ] && { echo -e "\033[1;95m[!] NO TARGET.\033[0m"; return 1; }; command rm "$@"; }
command_not_found_handle() { echo -e "\033[1;95m[!] UNKNOWN '$1'.\033[0m"; return 127; }
# ---------------------------
EOF
fi

termux-wake-unlock
echo -e "\n${NEON_GREEN}[Complete] System Initialized.${NC}"
read -p "Restart terminal? [1=Yes / 2=No]: " final_choice
[ "$final_choice" == "1" ] && exec bash || exit 0

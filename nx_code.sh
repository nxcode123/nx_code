#!/data/data/com.termux/files/usr/bin/bash

# ==============================================================================
# [1] KONFIGURASI GLOBAL & SISTEM MODULAR GITHUB
# ==============================================================================
NX_CODE_REPO_RAW_URL="https://raw.githubusercontent.com/nxcode123/nx_code/main/nx_code.sh"

NX_THEMES_MANIFEST_URL="https://raw.githubusercontent.com/nxcode123/nx_code/main/themes/theme.list"
NX_THEMES_BASE_URL="https://raw.githubusercontent.com/nxcode123/nx_code/main/themes"

NX_LANG_MANIFEST_URL="https://raw.githubusercontent.com/nxcode123/nx_code/main/lang/lang.list"
NX_LANG_BASE_URL="https://raw.githubusercontent.com/nxcode123/nx_code/main/lang"

NX_LOGOS_MANIFEST_URL="https://raw.githubusercontent.com/nxcode123/nx_code/main/logos/logo.list"
NX_LOGOS_BASE_URL="https://raw.githubusercontent.com/nxcode123/nx_code/main/logos"

NX_LIB_URL="https://raw.githubusercontent.com/nxcode123/nx_code/main/lib/utils.sh"
NX_GUI_URL="https://raw.githubusercontent.com/nxcode123/nx_code/main/modules/gui.sh"

NX_VERSION="v1.1.9"
NX_USER="nxuser"
NX_CURL_OPTS="-fsSL --connect-timeout 5 --max-time 10 --retry 2"

THEME_DIR="$HOME/.nx_code/themes"
LANG_DIR="$HOME/.nx_code/lang"
LOGOS_DIR="$HOME/.nx_code/logos"
LIB_DIR="$HOME/.nx_code/lib"
GUI_DIR="$HOME/.nx_code/modules"
CONFIG_FILE="$HOME/.nx_code/config"

init_system_modules() {
    mkdir -p "$THEME_DIR" "$LANG_DIR" "$LOGOS_DIR" "$LIB_DIR" "$GUI_DIR"

    ACTIVE_THEME="cyberpunk"
    ACTIVE_LANG="id"
    ACTIVE_LOGO="classic"
    DEBUG_MODE="off"
    [ -f "$CONFIG_FILE" ] && source "$CONFIG_FILE"

    [ "$DEBUG_MODE" == "on" ] && set -x

    # 0a. Inisialisasi Library Fungsi Pendukung (utils.sh)
    local utils_file="$LIB_DIR/utils.sh"
    [ ! -f "$utils_file" ] && curl $NX_CURL_OPTS "$NX_LIB_URL" -o "$utils_file" 2>/dev/null
    sed -i 's/\xc2\xa0/ /g' "$utils_file" 2>/dev/null
    [ -f "$utils_file" ] && source "$utils_file"

    # 0b. Inisialisasi Modul GUI (gui.sh)
    local gui_file="$GUI_DIR/gui.sh"
    [ ! -f "$gui_file" ] && curl $NX_CURL_OPTS "$NX_GUI_URL" -o "$gui_file" 2>/dev/null
    sed -i 's/\xc2\xa0/ /g' "$gui_file" 2>/dev/null
    [ -f "$gui_file" ] && source "$gui_file"

    # 1. Inisialisasi Tema
    local theme_file="$THEME_DIR/$ACTIVE_THEME.sh"
    [ ! -f "$theme_file" ] && curl $NX_CURL_OPTS "$NX_THEMES_BASE_URL/$ACTIVE_THEME.sh" -o "$theme_file" 2>/dev/null
    if [ ! -s "$theme_file" ]; then
        ACTIVE_THEME="cyberpunk"
        theme_file="$THEME_DIR/cyberpunk.sh"
        [ ! -f "$theme_file" ] && curl $NX_CURL_OPTS "$NX_THEMES_BASE_URL/cyberpunk.sh" -o "$theme_file" 2>/dev/null
    fi
    sed -i 's/\xc2\xa0/ /g' "$theme_file" 2>/dev/null
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
    sed -i 's/\xc2\xa0/ /g' "$lang_file" 2>/dev/null
    [ -f "$lang_file" ] && source "$lang_file"

    # 3. Inisialisasi Logo ASCII
    local logo_file="$LOGOS_DIR/$ACTIVE_LOGO.sh"
    [ ! -f "$logo_file" ] && curl $NX_CURL_OPTS "$NX_LOGOS_BASE_URL/$ACTIVE_LOGO.sh" -o "$logo_file" 2>/dev/null
    if [ ! -s "$logo_file" ]; then
        ACTIVE_LOGO="classic"
        logo_file="$LOGOS_DIR/classic.sh"
        [ ! -f "$logo_file" ] && curl $NX_CURL_OPTS "$NX_LOGOS_BASE_URL/classic.sh" -o "$logo_file" 2>/dev/null
    fi
    sed -i 's/\xc2\xa0/ /g' "$logo_file" 2>/dev/null
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
# [2] CORE UTILITIES (UI RENDERERS)
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

# ==============================================================================
# [3] MENU INTERACTION SWITCHERS
# ==============================================================================
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
# [4] ROUTING & DYNAMIC MENU
# ==============================================================================
show_shortcut_menu() {
    animate_logo
    echo -e "${NEON_PINK}──────────────────────────────────────────────────────${NC}"
    echo -e "${WHITE}               ${TXT_MENU_TITLE:-NX_CODE MENU}                 ${NC}"
    echo -e "${NEON_PINK}──────────────────────────────────────────────────────${NC}"
    echo -e " ${PURPLE}[1]${NC} ${WHITE}${TXT_MENU_1:-Ubuntu CLI Core}${NC}"
    echo -e " ${PURPLE}[2]${NC} ${WHITE}${TXT_MENU_2:-Ubuntu GUI}${NC}"
    echo -e " ${PURPLE}[3]${NC} ${WHITE}${TXT_MENU_3:-Kill GUI}${NC}"
    echo -e " ${PURPLE}[4]${NC} ${WHITE}${TXT_MENU_4:-Change Theme}${NC}"
    echo -e " ${PURPLE}[5]${NC} ${WHITE}${TXT_MENU_5:-Change Language}${NC}"
    echo -e " ${PURPLE}[6]${NC} ${WHITE}Ganti Logo Art (Logo Switcher)${NC}"
    echo -e " ${PURPLE}[7]${NC} ${WHITE}${TXT_MENU_6:-Check Updates}${NC}"
    echo -e " ${PURPLE}[8]${NC} ${WHITE}${TXT_MENU_7:-Debug Mode} (${NEON_GREEN}${DEBUG_MODE^^}${WHITE})${NC}"
    echo -e "${NEON_PINK}──────────────────────────────────────────────────────${NC}"
    echo -e " ${PURPLE}[0]${NC} ${WHITE}${TXT_MENU_0:-Exit}${NC}"
    echo -e "${NEON_PINK}──────────────────────────────────────────────────────${NC}"
    echo -ne "${CYAN}[?] ${TXT_SELECT:-Pilih} ➔ ${NC}"
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
        echo -e "${CYAN}[SYS] System Ready & Modular Linked.${NC}"
        run_auto_cleaner
        echo -e "\n${PURPLE}Ketik ${CYAN}nx-menu${PURPLE} untuk membuka control center.${NC}\n"
        exit 0
        ;;
esac

# ==============================================================================
# [5] INSTALLATION BOOTSTRAPPER
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

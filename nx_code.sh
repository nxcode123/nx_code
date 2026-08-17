#!/data/data/com.termux/files/usr/bin/bash
# ==============================================================================
# nx_code.sh — NX_CODE Entrypoint (Bootstrapper + Lib Loader + Routing)
# Repository  : https://github.com/nxcode123/nx_code
# Versi       : v1.3.0
# ==============================================================================

# --- Konfigurasi awal minimal (sebelum lib dimuat) ---
NX_CURL_OPTS="-fsSL --connect-timeout 5 --max-time 15 --retry 2"
NX_LIB_BASE_URL="https://raw.githubusercontent.com/nxcode123/nx_code/main/lib"
NX_LIB_DIR="$HOME/.nx_code/lib"

# ==============================================================================
# _load_lib <nama>
#   Muat modul lib dengan prioritas: repo lokal → cache → GitHub
# ==============================================================================
_load_lib() {
    local name="$1"
    local lib_file="$NX_LIB_DIR/${name}.sh"

    # 1. Salin dari repo lokal jika tersedia (pengembangan)
    if [ ! -s "$lib_file" ] && [ -s "./lib/${name}.sh" ]; then
        mkdir -p "$NX_LIB_DIR" 2>/dev/null
        cp "./lib/${name}.sh" "$lib_file" 2>/dev/null
    fi

    # 2. Download dari GitHub jika cache kosong
    if [ ! -s "$lib_file" ]; then
        mkdir -p "$NX_LIB_DIR" 2>/dev/null
        curl $NX_CURL_OPTS "$NX_LIB_BASE_URL/${name}.sh" -o "$lib_file" 2>/dev/null
    fi

    # 3. Source modul
    if [ -s "$lib_file" ]; then
        # shellcheck source=/dev/null
        source "$lib_file"
    else
        echo -e "\033[1;91m[ERR] Gagal memuat modul: ${name}.sh\033[0m" >&2
        exit 1
    fi
}

# Muat semua modul secara berurutan (urutan penting: config dulu)
mkdir -p "$NX_LIB_DIR" 2>/dev/null
for _lib in config ui gui system menu; do
    _load_lib "$_lib"
done

# Inisialisasi tema setelah config.sh dimuat
init_theme_system

# ==============================================================================
# Argument Routing
# ==============================================================================
case "$1" in
    --logo-only)
        animate_logo
        exit 0
        ;;
    --menu|-m|menu)
        show_shortcut_menu
        exit 0
        ;;
    --mc|mc)
        launch_midnight_commander
        exit 0
        ;;
    --ui-only)
        animate_logo

        echo -ne "${CYAN}[SYS] Syncing database...... ${NC}"
        echo -e "${NEON_GREEN}[✔] Clear${NC}"

        echo -ne "${CYAN}[SYS] Ubuntu Integrity...... ${NC}"
        is_ubuntu_installed \
            && echo -e "${NEON_GREEN}[✔] Ready${NC}" \
            || echo -e "${NEON_PINK}[X] Missing${NC}"

        echo -ne "${CYAN}[SYS] Storage Access........ ${NC}"
        if is_storage_setup; then
            echo -e "${NEON_GREEN}[✔] Ready${NC}"
        else
            echo -e "${NEON_PINK}[X] Storage Not Linked${NC}"
        fi

        echo -ne "${CYAN}[SYS] Midnight Commander... ${NC}"
        command -v mc >/dev/null 2>&1 \
            && echo -e "${NEON_GREEN}[✔] Ready${NC}" \
            || echo -e "${NEON_PINK}[X] Missing${NC}"

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
# [INSTALLER] Mode Bootstrapper — Berjalan jika tidak ada argumen
# ==============================================================================
command -v termux-wake-lock >/dev/null 2>&1 && termux-wake-lock
animate_logo

ensure_storage_setup

execute_task "Updating Repos"    pkg update  -y -o Dpkg::Options::="--force-confold"
execute_task "Upgrading Core"    pkg upgrade -y -o Dpkg::Options::="--force-confold"
execute_task "Deploy Hypervisor" pkg install proot-distro pulseaudio coreutils mc -y \
    -o Dpkg::Options::="--force-confold"
execute_task "Add X11 Repo"      pkg install x11-repo -y \
    -o Dpkg::Options::="--force-confold"
execute_task "Deploy X11 Server" pkg install termux-x11-nightly -y \
    -o Dpkg::Options::="--force-confold"

if ! is_ubuntu_installed; then
    echo -e "\n${PROCESS} ${CYAN}Mengunduh Ubuntu Core OS secara live...${NC}"
    proot-distro remove ubuntu >/dev/null 2>&1 || true
    echo -e "${PURPLE}[!] Mohon tunggu hingga proses unduhan selesai.${NC}"
    echo -e "${CYAN}──────────────────────────────────────────────────────${NC}"
    proot-distro install ubuntu
    echo -e "${CYAN}──────────────────────────────────────────────────────${NC}"
fi

if is_ubuntu_installed; then
    execute_task "Setup PRoot Config" setup_nonroot_user
fi

echo ""
is_ubuntu_installed \
    && echo -e "${SUCCESS} ${WHITE}Ubuntu Core OS            :${NC} ${NEON_GREEN}Installed${NC}" \
    || echo -e "${NEON_PINK}[X]${NC} ${WHITE}Ubuntu Core OS            :${NC} ${NEON_PINK}Failed${NC}"
is_termux_x11_installed \
    && echo -e "${SUCCESS} ${WHITE}Termux-X11 Display Server:${NC} ${NEON_GREEN}Installed${NC}" \
    || echo -e "${NEON_PINK}[X]${NC} ${WHITE}Termux-X11 Display Server:${NC} ${NEON_PINK}Failed${NC}"
command -v pulseaudio >/dev/null 2>&1 \
    && echo -e "${SUCCESS} ${WHITE}PulseAudio Sound Server   :${NC} ${NEON_GREEN}Installed${NC}" \
    || echo -e "${NEON_PINK}[X]${NC} ${WHITE}PulseAudio Sound Server   :${NC} ${NEON_PINK}Failed${NC}"
command -v mc >/dev/null 2>&1 \
    && echo -e "${SUCCESS} ${WHITE}Midnight Commander (MC)   :${NC} ${NEON_GREEN}Installed${NC}" \
    || echo -e "${NEON_PINK}[X]${NC} ${WHITE}Midnight Commander (MC)   :${NC} ${NEON_PINK}Failed${NC}"
echo ""

if ! copy_self_to_home; then
    echo -e "${NEON_PINK}[!] Skrip berjalan via remote stream. Disimpan lokal di $HOME/nx_code.sh${NC}"
fi

# Tulis / refresh environment di .bashrc
sed -i '/# --- NX_CODE ENVIRONMENT ---/,/# ---------------------------/d' "$HOME/.bashrc" 2>/dev/null

cat << 'EOF' >> "$HOME/.bashrc"

# --- NX_CODE ENVIRONMENT ---
[ -f "$HOME/nx_code.sh" ] && bash "$HOME/nx_code.sh" --ui-only
alias ls='ls --color=auto --group-directories-first'
alias ll='ls -la --color=auto --group-directories-first'
alias nx-menu='bash $HOME/nx_code.sh --menu'
alias nx='bash $HOME/nx_code.sh --menu'
alias nx-mc='bash $HOME/nx_code.sh --mc'
PS1="\[\033[1;95m\]🄽🅇🄲•\[\033[0m\] "

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

setup_nx_menu_command
echo -e "${SUCCESS} ${WHITE}Auto-Startup Profile     :${NC} ${NEON_GREEN}Refreshed${NC}"

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

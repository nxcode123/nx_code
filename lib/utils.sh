# ==============================================================================
# [LIB] UTILITIES & CORE FUNCTIONS
# ==============================================================================

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

setup_nonroot_user() {
    proot-distro login ubuntu -- bash -c "
        useradd -m -s /bin/bash $NX_USER 2>/dev/null
        echo '$NX_USER ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/$NX_USER
        chmod 0440 /etc/sudoers.d/$NX_USER
        mkdir -p /storage && chmod 777 /storage
        grep -q ELECTRON_DISABLE_SANDBOX /etc/environment 2>/dev/null || echo 'ELECTRON_DISABLE_SANDBOX=true' >> /etc/environment
    "
}

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
    echo -e "\n${PROCESS} ${CYAN}Memeriksa pembaruan sistem...${NC}"
    local tmp_file="$HOME/.nx_code_update_tmp.sh"

    if ! curl $NX_CURL_OPTS "$NX_CODE_REPO_RAW_URL" -o "$tmp_file" 2>/dev/null || [ ! -s "$tmp_file" ]; then
        echo -e "${NEON_PINK}[ERR] Gagal memeriksa update. Periksa koneksi internet.${NC}"
        rm -f "$tmp_file"; return 1
    fi

    if diff -q "$tmp_file" "$HOME/nx_code.sh" >/dev/null 2>&1; then
        echo -e "${SUCCESS} ${WHITE}Sistem sudah menggunakan versi terbaru.${NC}"
        rm -f "$tmp_file"; return 0
    fi

    echo -e "${SUCCESS} ${WHITE}Pembaruan ditemukan! Menerapkan patch...${NC}"
    mv "$tmp_file" "$HOME/nx_code.sh"
    sed -i 's/\xc2\xa0/ /g' "$HOME/nx_code.sh" 2>/dev/null
    chmod +x "$HOME/nx_code.sh"

    echo -e "${SUCCESS} ${WHITE}Merestart sistem secara otomatis...${NC}"
    sleep 1.5
    exec bash "$HOME/nx_code.sh" --menu
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

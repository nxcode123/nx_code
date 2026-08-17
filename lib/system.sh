#!/data/data/com.termux/files/usr/bin/bash
# ==============================================================================
# lib/system.sh — System Management (Updater, Cleaner, Self-Copy)
# Dimuat oleh: nx_code.sh
# Dependensi: lib/config.sh, lib/ui.sh
# ==============================================================================

# ------------------------------------------------------------------------------
# run_auto_cleaner
#   Bersihkan cache paket sekali sehari
# ------------------------------------------------------------------------------
run_auto_cleaner() {
    local last_clean_file="$HOME/.nx_code_last_clean"
    local today
    today=$(date +%Y%m%d)
    local last_clean=""
    [ -f "$last_clean_file" ] && last_clean=$(cat "$last_clean_file" 2>/dev/null)

    if [ "$today" != "$last_clean" ]; then
        if command -v pkg >/dev/null 2>&1; then
            execute_task "System Storage Clean" bash -c \
                "pkg clean -y && [ -n \"$TMPDIR\" ] && rm -rf \"$TMPDIR\"/*"
        fi
        echo "$today" > "$last_clean_file"
    fi
}

# ------------------------------------------------------------------------------
# check_for_update
#   Bandingkan skrip lokal dengan versi GitHub, terapkan jika ada update
# ------------------------------------------------------------------------------
check_for_update() {
    echo -e "\n${PROCESS} ${CYAN}Memeriksa pembaruan dari repository NX_CODE...${NC}"
    local tmp_file="$HOME/.nx_code_update_tmp.sh"

    if ! curl $NX_CURL_OPTS "$NX_CODE_REPO_RAW_URL" -o "$tmp_file" 2>/dev/null \
        || [ ! -s "$tmp_file" ]; then
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

    # Update lib sekaligus
    _update_libs

    sleep 1
    exec bash "$target_script" --menu
}

# ------------------------------------------------------------------------------
# _update_libs (internal)
#   Paksa re-download semua file lib dari GitHub
# ------------------------------------------------------------------------------
_update_libs() {
    mkdir -p "$NX_LIB_DIR" 2>/dev/null
    for _lib in config ui gui system menu; do
        curl $NX_CURL_OPTS "$NX_LIB_BASE_URL/${_lib}.sh" \
            -o "$NX_LIB_DIR/${_lib}.sh" 2>/dev/null || true
    done
}

# ------------------------------------------------------------------------------
# copy_self_to_home
#   Salin nx_code.sh ke $HOME agar bisa diakses via nx-menu
# ------------------------------------------------------------------------------
copy_self_to_home() {
    local dest="$HOME/nx_code.sh"
    local src
    src=$(realpath "${BASH_SOURCE[0]:-$0}" 2>/dev/null)

    # 1. File lokal berbeda dari dest
    if [ -n "$src" ] && [ -f "$src" ] \
        && [[ "$src" != /dev/fd/* ]] && [[ "$src" != /proc/* ]] \
        && [ "$src" != "$dest" ]; then
        cp "$src" "$dest" 2>/dev/null
        _sanitize_script "$dest"
        setup_nx_menu_command
        return 0
    fi

    # 2. Dest sudah ada dan valid
    if [ -f "$dest" ] && [ -s "$dest" ]; then
        chmod +x "$dest" 2>/dev/null
        setup_nx_menu_command
        return 0
    fi

    # 3. File ada di direktori saat ini
    if [ -f "./nx_code.sh" ] && [ -s "./nx_code.sh" ]; then
        cp "./nx_code.sh" "$dest" 2>/dev/null
        _sanitize_script "$dest"
        setup_nx_menu_command
        return 0
    fi

    # 4. Remote stream — download langsung
    echo -e "\n${PROCESS} ${CYAN}Menyimpan salinan skrip NX_CODE ke $dest...${NC}"
    if curl $NX_CURL_OPTS "$NX_CODE_REPO_RAW_URL" -o "$dest" 2>/dev/null \
        && [ -s "$dest" ]; then
        _sanitize_script "$dest"
        setup_nx_menu_command
        return 0
    fi

    return 1
}

# ------------------------------------------------------------------------------
# _sanitize_script <file> (internal)
#   Bersihkan karakter non-breaking space & set executable
# ------------------------------------------------------------------------------
_sanitize_script() {
    local file="$1"
    sed -i 's/\xc2\xa0/ /g' "$file" 2>/dev/null
    chmod +x "$file" 2>/dev/null
}

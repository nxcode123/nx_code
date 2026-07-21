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

    # Bersihkan karakter carriage return (\r) jika ada
    sed -i 's/\r$//' "$manifest" 2>/dev/null

    local names=() scripts=()
    
    # Membaca format baru: Nama_Aplikasi|nama_script.sh
    while IFS='|' read -r a_name a_script a_rest; do
        [ -z "$a_name" ] && continue

        if [ -n "$a_script" ] && ! is_safe_filename "$a_script"; then
            say_warn "Melewati entri '$a_name': nama script tidak valid."
            continue
        fi

        names+=("$a_name")
        scripts+=("$a_script")
    done < "$manifest"
    rm -f "$manifest"

    if [ "${#names[@]}" -eq 0 ]; then
        say_err "Daftar app kosong."
        return 1
    fi

    while true; do
        hr
        echo -e "${WHITE}APP STORE${NC}"
        for i in "${!names[@]}"; do
            printf " ${PURPLE}[%d]${NC} ${WHITE}%s${NC}\n" "$((i+1))" "${names[$i]}"
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

        local target_url="$NX_APPS_SCRIPTS_BASE_URL/${scripts[$idx]}"
        local tmp_script="$HOME/.tmp_install_$(basename "${scripts[$idx]}")"

        if curl --max-time 30 --retry 2 --retry-delay 2 -fsSL "$target_url" -o "$tmp_script"; then
            if [ -s "$tmp_script" ]; then
                
                # --- LAYER KEAMANAN: Dry-run Syntax Check ---
                if ! bash -n "$tmp_script"; then
                    say_err "Instalasi Dibatalkan: Ditemukan syntax error. Script mungkin terpotong saat diunduh."
                    rm -f "$tmp_script"
                    continue
                fi

                say_proc "Menjalankan instalasi..."
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
    done
}

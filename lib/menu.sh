#!/data/data/com.termux/files/usr/bin/bash
# ==============================================================================
# lib/menu.sh — Menu Interaktif & Setup Command nx-menu
# Dimuat oleh: nx_code.sh
# Dependensi: lib/config.sh, lib/ui.sh, lib/gui.sh, lib/system.sh
# ==============================================================================

# ------------------------------------------------------------------------------
# setup_nx_menu_command
#   Buat perintah `nx-menu` & symlink `nx` di $PREFIX/bin
# ------------------------------------------------------------------------------
setup_nx_menu_command() {
    local bin_dir="${PREFIX:-/data/data/com.termux/files/usr}/bin"
    [ -d "$bin_dir" ] && [ -w "$bin_dir" ] || return 0

    cat << 'EOF_NX' > "$bin_dir/nx-menu"
#!/data/data/com.termux/files/usr/bin/bash
TARGET="$HOME/nx_code.sh"
if [ ! -s "$TARGET" ] && [ -s "./nx_code.sh" ]; then
    TARGET="$(realpath ./nx_code.sh 2>/dev/null || echo "./nx_code.sh")"
fi
if [ ! -s "$TARGET" ]; then
    echo -e "\033[0;36m[➔] Mempersiapkan file NX_CODE...\033[0m"
    curl -fsSL --connect-timeout 5 \
        https://raw.githubusercontent.com/nxcode123/nx_code/main/nx_code.sh \
        -o "$HOME/nx_code.sh" 2>/dev/null
    chmod +x "$HOME/nx_code.sh" 2>/dev/null
    TARGET="$HOME/nx_code.sh"
fi
exec bash "$TARGET" --menu "$@"
EOF_NX
    chmod +x "$bin_dir/nx-menu" 2>/dev/null
    ln -sf "$bin_dir/nx-menu" "$bin_dir/nx" 2>/dev/null \
        || cp "$bin_dir/nx-menu" "$bin_dir/nx" 2>/dev/null
    chmod +x "$bin_dir/nx" 2>/dev/null
}

# ------------------------------------------------------------------------------
# change_theme_menu
#   Menu interaktif pemilihan tema (baca manifest + scan direktori)
# ------------------------------------------------------------------------------
change_theme_menu() {
    while true; do
        local t_names=() t_descs=() seen_names=" "

        # 1. Muat manifest (lokal → cache → download)
        local manifest="$THEME_DIR/theme.list"
        if [ ! -s "$manifest" ] && [ -s "./themes/theme.list" ]; then
            cp "./themes/theme.list" "$manifest" 2>/dev/null
        fi
        [ ! -s "$manifest" ] && curl $NX_CURL_OPTS "$NX_THEMES_MANIFEST_URL" -o "$manifest" 2>/dev/null

        if [ -s "$manifest" ]; then
            while IFS='|' read -r t_id t_desc || [ -n "$t_id" ]; do
                [[ -z "$t_id" || "$t_id" =~ ^[[:space:]]*# ]] && continue
                t_id=$(echo "$t_id" | tr -d '\r' | xargs)
                t_desc=$(echo "$t_desc" | tr -d '\r' | xargs)
                if [ -n "$t_id" ]; then
                    t_names+=("$t_id")
                    t_descs+=("${t_desc:-$t_id Theme}")
                    seen_names="${seen_names}${t_id} "
                fi
            done < "$manifest"
        fi

        # 2. Scan tema kustom tambahan di direktori tema
        for f in "$THEME_DIR"/*.sh ./themes/*.sh; do
            [ -f "$f" ] || continue
            local base_name
            base_name=$(basename "$f" .sh)
            [[ "$base_name" == "*" ]] && continue
            if [[ "$seen_names" != *" $base_name "* ]]; then
                t_names+=("$base_name")
                t_descs+=("${base_name^} (Custom Theme)")
                seen_names="${seen_names}${base_name} "
            fi
        done

        # 3. Fallback jika tidak ada manifest
        if [ ${#t_names[@]} -eq 0 ]; then
            t_names=("cyberpunk" "matrix" "dracula" "synthwave" "ocean"
                     "sunset" "emerald" "bloodmoon" "monokai" "arctic" "gold")
            t_descs=("Cyberpunk Neon Theme" "Matrix Green Hacker" "Dracula Dark Pro"
                     "Synthwave 84 Neon" "Oceanic Deep Blue" "Sunset Orange"
                     "Emerald Forest" "Blood Moon Crimson" "Monokai Pro"
                     "Arctic Frost Ice" "Cyber Gold Luxury")
        fi

        animate_logo
        echo -e "${PURPLE}──────────────────────────────────────────────────────${NC}"
        echo -e "${WHITE}PILIH TEMA INTERFACE (NX THEME SYSTEM - MODULAR)${NC}"
        echo -e "${PURPLE}──────────────────────────────────────────────────────${NC}"

        for i in "${!t_names[@]}"; do
            local marker=" "
            [ "$ACTIVE_THEME" == "${t_names[$i]}" ] && marker="[✔]"
            printf " ${PURPLE}[%2d]${NC} ${WHITE}%-12s${NC} ${CYAN}│ %-22s${NC} ${NEON_GREEN}%s${NC}\n" \
                "$((i+1))" "${t_names[$i]}" "${t_descs[$i]}" "$marker"
        done
        echo -e " ${PURPLE}[ 0]${NC} ${WHITE}Kembali ke Menu Utama${NC}"
        echo -e "${PURPLE}──────────────────────────────────────────────────────${NC}"
        echo -ne "${CYAN}[?] Pilihan ➔ ${NC}"
        read -r t_choice

        [ "$t_choice" == "0" ] && break

        local idx=$((t_choice - 1))
        if [ "$idx" -ge 0 ] && [ "$idx" -lt "${#t_names[@]}" ]; then
            local chosen="${t_names[$idx]}"
            apply_theme "$chosen"
            mkdir -p "$THEME_DIR" 2>/dev/null
            echo "ACTIVE_THEME=\"$ACTIVE_THEME\"" > "$CONFIG_FILE"
            echo -e "\n${SUCCESS} ${WHITE}Tema aktif diubah ke: ${NEON_PINK}$chosen${NC}"
            sleep 1
        else
            echo -e "\n${NEON_PINK}[!] Pilihan tidak valid.${NC}"
            sleep 1
        fi
    done
}

# ------------------------------------------------------------------------------
# launch_midnight_commander
#   Sub-menu Midnight Commander (Termux & Ubuntu)
# ------------------------------------------------------------------------------
launch_midnight_commander() {
    while true; do
        animate_logo
        echo -e "${NEON_PINK}──────────────────────────────────────────────────────${NC}"
        echo -e "${WHITE}          MIDNIGHT COMMANDER (FILE MANAGER)           ${NC}"
        echo -e "${NEON_PINK}──────────────────────────────────────────────────────${NC}"
        echo -e " ${PURPLE}[1]${NC} ${WHITE}Buka MC di Termux (Akses Direktori Termux & SDCard)${NC}"
        echo -e " ${PURPLE}[2]${NC} ${WHITE}Buka MC di Ubuntu OS (Root / User Environment)${NC}"
        echo -e " ${PURPLE}[3]${NC} ${WHITE}Install / Perbarui Paket MC (Termux & Ubuntu)${NC}"
        echo -e "${NEON_PINK}──────────────────────────────────────────────────────${NC}"
        echo -e " ${PURPLE}[0]${NC} ${WHITE}Kembali ke Menu Utama${NC}"
        echo -e "${NEON_PINK}──────────────────────────────────────────────────────${NC}"
        echo -ne "${CYAN}[?] Pilihan ➔ ${NC}"
        read -r mc_choice

        case "$mc_choice" in
            1)
                if ! command -v mc >/dev/null 2>&1; then
                    echo -e "\n${PURPLE}[SYS] Midnight Commander belum terinstal di Termux.${NC}"
                    execute_task "Instalasi MC Termux" pkg install mc -y \
                        -o Dpkg::Options::="--force-confold"
                fi
                if command -v mc >/dev/null 2>&1; then
                    echo -e "\n${PROCESS} ${CYAN}Membuka Midnight Commander (Termux)...${NC}"
                    sleep 0.5; mc
                else
                    echo -e "\n${NEON_PINK}[ERR] Gagal memasang Midnight Commander di Termux.${NC}"
                    sleep 1.5
                fi
                ;;
            2)
                if ! is_ubuntu_installed; then
                    echo -e "\n${NEON_PINK}[ERR] Ubuntu OS belum terinstal.${NC}"
                    sleep 1.5; continue
                fi
                local has_ubuntu_mc
                has_ubuntu_mc=$(ubuntu_login -- bash -c "command -v mc" 2>/dev/null || true)
                if [ -z "$has_ubuntu_mc" ]; then
                    echo -e "\n${PURPLE}[SYS] Midnight Commander belum terinstal di Ubuntu.${NC}"
                    execute_task "Instalasi MC Ubuntu" ubuntu_login -- bash -c \
                        "DEBIAN_FRONTEND=noninteractive apt update && \
                         DEBIAN_FRONTEND=noninteractive apt install mc -y"
                fi
                echo -e "\n${PROCESS} ${CYAN}Membuka Midnight Commander (Ubuntu)...${NC}"
                sleep 0.5
                local mc_user="--user $NX_USER"
                ! is_nonroot_user_setup && mc_user=""
                ubuntu_login $mc_user -- mc
                ;;
            3)
                echo -e "\n${PROCESS} ${CYAN}Memperbarui & memasang Midnight Commander...${NC}"
                execute_task "Update MC di Termux" pkg install mc -y \
                    -o Dpkg::Options::="--force-confold"
                if is_ubuntu_installed; then
                    execute_task "Update MC di Ubuntu" ubuntu_login -- bash -c \
                        "DEBIAN_FRONTEND=noninteractive apt update && \
                         DEBIAN_FRONTEND=noninteractive apt install mc -y"
                fi
                echo -e "${SUCCESS} ${WHITE}Pemasangan / Pembaruan MC selesai.${NC}"
                sleep 1.5
                ;;
            0) break ;;
            *)
                echo -e "\n${NEON_PINK}[!] Pilihan tidak valid, silakan coba lagi.${NC}"
                sleep 1
                ;;
        esac
    done
}

# ------------------------------------------------------------------------------
# show_shortcut_menu
#   Menu utama NX_CODE Control Center
# ------------------------------------------------------------------------------
show_shortcut_menu() {
    while true; do
        animate_logo
        echo -e "${NEON_PINK}──────────────────────────────────────────────────────${NC}"
        echo -e "${WHITE}               NX_CODE CONTROL CENTER                 ${NC}"
        echo -e "${NEON_PINK}──────────────────────────────────────────────────────${NC}"
        echo -e " ${PURPLE}[1]${NC} ${WHITE}Ubuntu CLI Core (Terminal Linux)${NC}"
        echo -e " ${PURPLE}[2]${NC} ${WHITE}Ubuntu GUI (XFCE4 + Audio via Termux:X11)${NC}"
        echo -e " ${PURPLE}[3]${NC} ${WHITE}Kill Active GUI & Audio Session${NC}"
        echo -e " ${PURPLE}[4]${NC} ${WHITE}Midnight Commander (MC File Manager)${NC}"
        echo -e " ${PURPLE}[5]${NC} ${WHITE}Ganti Tema Interface${NC}"
        echo -e " ${PURPLE}[6]${NC} ${WHITE}Check for System Updates${NC}"
        echo -e "${NEON_PINK}──────────────────────────────────────────────────────${NC}"
        echo -e " ${PURPLE}[0]${NC} ${WHITE}Exit to Terminal${NC}"
        echo -e "${NEON_PINK}──────────────────────────────────────────────────────${NC}"
        echo -ne "${CYAN}[?] Select Option ➔ ${NC}"
        read -r pilihan

        case "$pilihan" in
            1)
                echo -e "\n${PROCESS} ${CYAN}Memuat lingkungan Ubuntu CLI & Audio Bridge...${NC}"
                start_pulseaudio
                ensure_storage_setup
                sleep 0.5
                if is_ubuntu_installed; then
                    local cli_user="--user $NX_USER"
                    ! is_nonroot_user_setup && cli_user=""
                    ubuntu_login $cli_user
                else
                    echo -e "${NEON_PINK}[ERR] Ubuntu OS belum terinstal.${NC}"
                    sleep 1.5
                fi
                ;;
            2) launch_ubuntu_gui; sleep 1 ;;
            3) kill_ubuntu_gui; sleep 1 ;;
            4) launch_midnight_commander; sleep 1 ;;
            5) change_theme_menu ;;
            6) check_for_update; sleep 1 ;;
            0)
                echo -e "\n${NEON_GREEN}[➔] Keluar ke terminal reguler.${NC}\n"
                break
                ;;
            *)
                echo -e "\n${NEON_PINK}[!] Pilihan tidak valid, silakan coba lagi.${NC}"
                sleep 1
                ;;
        esac
    done
}

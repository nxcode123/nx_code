#!/usr/bin/env bash
# ==============================================================================
# PROJECT     : NX_CODE
# FILE        : nxc1.sh
# DESCRIPTION : Core Interactive Dashboard & Menu for Ubuntu PRoot
# VERSION     : 1.3.1
# ==============================================================================

# Deteksi direktori script & load library jika ada
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
THEMES_DIR="$SCRIPT_DIR/themes"
THEME_CONFIG="$HOME/.nx_theme"

# Muat library pendukung
if [ -f "$SCRIPT_DIR/nxc_lib.sh" ]; then
    # shellcheck disable=SC1091
    source "$SCRIPT_DIR/nxc_lib.sh"
fi

# Fallback Palette Warna
CYAN="${CYAN:-\033[0;36m}"
GREEN="${GREEN:-\033[0;32m}"
NEON_GREEN="${NEON_GREEN:-\033[1;32m}"
NEON_PINK="${NEON_PINK:-\033[1;35m}"
PURPLE="${PURPLE:-\033[0;35m}"
YELLOW="${YELLOW:-\033[1;33m}"
RED="${RED:-\033[0;31m}"
WHITE="${WHITE:-\033[1;37m}"
NC="${NC:-\033[0m}"

# Muat tema aktif jika tersimpan
if [ -f "$THEME_CONFIG" ]; then
    ACTIVE_THEME="$(cat "$THEME_CONFIG" 2>/dev/null)"
    if [ -f "$THEMES_DIR/${ACTIVE_THEME}.sh" ]; then
        # shellcheck disable=SC1090
        source "$THEMES_DIR/${ACTIVE_THEME}.sh"
    fi
fi

# ==============================================================================
# 1. FUNGSI PENGECEKAN UPDATE DARI GITHUB
# ==============================================================================
check_script_update() {
    local interactive="${1:-false}"
    local temp_script="/tmp/nxc1_latest.sh"
    local github_url="https://raw.githubusercontent.com/nxcode123/nx_code/main/nxc1.sh"
    
    if [ "$interactive" = "true" ]; then
        echo -e "${CYAN}[*] Memeriksa pembaruan ke GitHub (nxcode123/nx_code)...${NC}"
    fi

    if curl -fsSL --max-time 4 "$github_url" -o "$temp_script" 2>/dev/null; then
        if [ -s "$temp_script" ] && bash -n "$temp_script" 2>/dev/null; then
            local current_script="$SCRIPT_DIR/nxc1.sh"
            local local_hash=""
            local online_hash=""

            if [ -f "$current_script" ]; then
                local_hash="$(md5sum "$current_script" 2>/dev/null | awk '{print $1}')"
                online_hash="$(md5sum "$temp_script" 2>/dev/null | awk '{print $1}')"
            fi

            if [ -n "$local_hash" ] && [ -n "$online_hash" ] && [ "$local_hash" != "$online_hash" ]; then
                echo -e "${YELLOW}[!] Pembaruan baru untuk nxc1.sh tersedia di GitHub!${NC}"
                read -r -p "Perbarui script sekarang? [y/N]: " choice
                case "$choice" in
                    y|Y)
                        cp "$temp_script" "$current_script"
                        chmod +x "$current_script"
                        rm -f "$temp_script"
                        
                        # Unduh juga library terbaru jika ada
                        curl -fsSL --max-time 4 "https://raw.githubusercontent.com/nxcode123/nx_code/main/nxc_lib.sh" -o "$SCRIPT_DIR/nxc_lib.sh" 2>/dev/null || true
                        chmod +x "$SCRIPT_DIR/nxc_lib.sh" 2>/dev/null || true
                        
                        echo -e "${GREEN}[✔] Script berhasil diperbarui. Memuat ulang...${NC}"
                        sleep 1
                        exec bash "$current_script"
                        ;;
                    *)
                        echo -e "${CYAN}[*] Pembaruan dilewati.${NC}"
                        ;;
                esac
            elif [ "$interactive" = "true" ]; then
                echo -e "${GREEN}[✔] Script Anda sudah versi terbaru.${NC}"
            fi
        fi
        rm -f "$temp_script"
    elif [ "$interactive" = "true" ]; then
        echo -e "${RED}[!] Gagal terhubung ke GitHub atau timeout.${NC}"
    fi
}

# ==============================================================================
# 2. TAMPILAN BANNER & HEADER
# ==============================================================================
render_header() {
    clear
    echo -e "${PURPLE}"
    echo "  _  _ _  _  ____ ____ ____  _ "
    echo "  |\ |  \/   |    |  | |___  | "
    echo "  | \| _/\_  |    |__| |     | "
    echo -e "${NC}"
    echo -e "${CYAN}======================================================${NC}"
    echo -e " ${WHITE}Status :${NC} ${GREEN}Online & Siap Digunakan${NC}"
    echo -e " ${WHITE}Waktu  :${NC} $(date '+%A, %d %B %Y - %H:%M:%S')"
    echo -e " ${WHITE}Host   :${NC} Proot Ubuntu Linux (${USER:-root})"
    if [ -f "$THEME_CONFIG" ]; then
        echo -e " ${WHITE}Tema   :${NC} ${NEON_PINK}$(cat "$THEME_CONFIG")${NC}"
    fi
    echo -e "${CYAN}======================================================${NC}\n"
}

# ==============================================================================
# 3. GANTI TEMA
# ==============================================================================
select_theme() {
    clear
    echo -e "${CYAN}======================================================${NC}"
    echo -e "${NEON_GREEN}          🎨 PILIH SKEMA WARNA TEMA NX_CODE          ${NC}"
    echo -e "${CYAN}======================================================${NC}\n"

    local list_file="$THEMES_DIR/theme.list"
    if [ ! -f "$list_file" ]; then
        echo -e "${YELLOW}[!] Berkas theme.list belum ada di folder themes.${NC}"
        read -r -p "Tekan [Enter] untuk kembali..." _
        return
    fi

    local themes=()
    local labels=()
    local index=1

    while IFS='|' read -r code label || [ -n "$code" ]; do
        [ -z "$code" ] && continue
        # abaikan komentar
        [[ "$code" =~ ^# ]] && continue
        themes+=("$code")
        labels+=("$label")
        printf "  ${CYAN}[%d]${NC} %-20s ${DARK_GRAY}(%s)${NC}\n" "$index" "$label" "$code"
        index=$((index + 1))
    done < "$list_file"

    echo ""
    echo -e "  ${RED}[0] Batal / Kembali ke Menu${NC}\n"
    read -r -p "Pilih nomor tema [0-$((index-1))]: " choice

    if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "${#themes[@]}" ]; then
        local chosen_idx=$((choice - 1))
        local selected_code="${themes[$chosen_idx]}"
        
        echo "$selected_code" > "$THEME_CONFIG"
        if [ -f "$THEMES_DIR/${selected_code}.sh" ]; then
            # shellcheck disable=SC1090
            source "$THEMES_DIR/${selected_code}.sh"
        fi
        echo -e "\n${GREEN}[✔] Tema berhasil diubah ke: ${labels[$chosen_idx]}!${NC}"
        sleep 1
    fi
}

# ==============================================================================
# 4. STATUS SISTEM
# ==============================================================================
show_sysinfo() {
    clear
    echo -e "${CYAN}======================================================${NC}"
    echo -e "${NEON_GREEN}              📊 INFORMASI SISTEM UBUNTU              ${NC}"
    echo -e "${CYAN}======================================================${NC}\n"

    echo -e "${WHITE}• Arsitektur CPU  :${NC} $(uname -m)"
    echo -e "${WHITE}• Kernel Host     :${NC} $(uname -r)"
    echo -e "${WHITE}• Distribusi      :${NC} $(cat /etc/issue.net 2>/dev/null || cat /etc/issue 2>/dev/null || echo "Ubuntu Linux")"
    echo -e "${WHITE}• Penggunaan Disk :${NC}"
    df -h / | awk 'NR==1 || NR==2 {print "    " $0}'
    echo ""
    echo -e "${WHITE}• Penggunaan Memori (RAM):${NC}"
    free -h 2>/dev/null | awk 'NR<=2 {print "    " $0}' || echo "    (Tidak didukung di PRoot environment)"
    echo ""
    echo -e "${CYAN}======================================================${NC}"
    read -r -p "Tekan [Enter] untuk kembali ke menu..." _
}

# ==============================================================================
# 5. UPDATE PAKET SISTEM SECARA MANUAL
# ==============================================================================
update_packages() {
    clear
    echo -e "${CYAN}======================================================${NC}"
    echo -e "${NEON_GREEN}          📦 PEMBARUAN REPOSITORI & PAKET UBUNTU       ${NC}"
    echo -e "${CYAN}======================================================${NC}\n"

    echo -e "${YELLOW}[*] Menjalankan apt update & upgrade...${NC}"
    export DEBIAN_FRONTEND=noninteractive
    apt update && apt upgrade -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold"
    
    echo -e "\n${GREEN}[✔] Pembaruan paket sistem selesai.${NC}"
    read -r -p "Tekan [Enter] untuk kembali ke menu..." _
}

# Periksa update script diam-diam saat pertama kali dibuka
check_script_update "false"

# ==============================================================================
# LOOP MENU UTAMA
# ==============================================================================
while true; do
    render_header

    echo -e " ${NEON_PINK}[1]${NC} Masuk ke Terminal (Bash Shell)"
    echo -e " ${NEON_PINK}[2]${NC} Tampilkan Info & Status Sistem"
    echo -e " ${NEON_PINK}[3]${NC} Update & Upgrade Paket Ubuntu"
    echo -e " ${NEON_PINK}[4]${NC} Cek Pembaruan Script (GitHub Sync)"
    echo -e " ${NEON_PINK}[5]${NC} Ganti Skema Warna Tema"
    echo -e " ${RED}[0]${NC} Keluar dari Lingkungan Ubuntu\n"

    read -r -p " Pilih opsi menu [0-5]: " menu_choice

    case "$menu_choice" in
        1)
            clear
            echo -e "${GREEN}[*] Masuk ke terminal Ubuntu. Ketik 'menu' kapan saja untuk kembali.${NC}\n"
            break
            ;;
        2)
            show_sysinfo
            ;;
        3)
            update_packages
            ;;
        4)
            check_script_update "true"
            read -r -p "Tekan [Enter] untuk kembali ke menu..." _
            ;;
        5)
            select_theme
            ;;
        0)
            echo -e "\n${CYAN}[*] Keluar dari Ubuntu PRoot. Sampai jumpa!${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}[!] Pilihan tidak valid.${NC}"
            sleep 1
            ;;
    esac
done

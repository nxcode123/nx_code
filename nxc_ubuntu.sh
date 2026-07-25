#!/data/data/com.termux/files/usr/bin/bash

# ==============================================================================
# Source file: nxc_ubuntu.sh
# PROJECT: NXC - TERMUX-UBUNTU
# DESCRIPTION: Automated Termux-to-Ubuntu Proot Bridge with Auto-Update & UI
# VERSION: 1.2.3
# CHANGELOG v1.2.3:
#   - Fungsi UI dipindah ke nxc_lib.sh bersama.
#   - Penambahan jeda (sleep) agar teks pemeriksaan pembaruan sempat terlihat.
# ==============================================================================

SCRIPT_VERSION="1.2.3"
NXC_LIB_URL="https://raw.githubusercontent.com/nxcode123/nx_code/main/nxc_lib.sh"
NXC_LIB_LOCAL="$HOME/nxc_lib.sh"

export DEBIAN_FRONTEND=noninteractive
export APT_LISTCHANGES_FRONTEND=none
LOG_FILE="$HOME/nxc_setup.log"

# Inisialisasi file log baru
> "$LOG_FILE"

# Trap pengaman untuk mengembalikan kursor jika skrip dihentikan paksa (Ctrl+C)
trap 'printf "\033[?25h"; echo -e "\033[0m"; exit' INT TERM EXIT

# Guard: Memastikan skrip dijalankan di lingkungan Termux
if [ ! -d "/data/data/com.termux" ]; then
    echo "[!] Error: Skrip ini dirancang khusus untuk dijalankan di lingkungan Termux!"
    exit 1
fi

# ------------------------------------------------------------------
# Pastikan nxc_lib.sh tersedia lalu source
# ------------------------------------------------------------------
fetch_lib() {
    if command -v curl &> /dev/null; then
        curl -sf -L --max-time 10 "$NXC_LIB_URL" -o "$NXC_LIB_LOCAL.tmp"
    elif command -v wget &> /dev/null; then
        wget -q -T 10 "$NXC_LIB_URL" -O "$NXC_LIB_LOCAL.tmp"
    else
        return 1
    fi
}

if [ ! -f "$NXC_LIB_LOCAL" ]; then
    echo "[*] Mengunduh nxc_lib.sh (library UI bersama)..."
    if fetch_lib && [ -s "$NXC_LIB_LOCAL.tmp" ] && bash -n "$NXC_LIB_LOCAL.tmp" 2>/dev/null; then
        mv "$NXC_LIB_LOCAL.tmp" "$NXC_LIB_LOCAL"
    else
        rm -f "$NXC_LIB_LOCAL.tmp"
        echo "[!] Gagal mengunduh nxc_lib.sh. Cek koneksi internet lalu jalankan ulang skrip."
        exit 1
    fi
fi

# shellcheck source=/dev/null
source "$NXC_LIB_LOCAL"

show_banner "TERMUX-UBUNTU" "$SCRIPT_VERSION"

echo -e "${DARK_GRAY}[INIT] Memuat protokol keamanan sistem...${NC}"
sleep 1 2>/dev/null

# 1. Hushlogin setup
echo -e "${NEON_CYAN}[*] ${WHITE}Memotong protokol sambutan default (Hushlogin)...${NC}"
touch "$HOME/.hushlogin"
sleep 0.5 2>/dev/null

# 2. Storage Setup dengan Logika Smart Skip
if [ ! -d "$HOME/storage" ]; then
    run_with_spinner "Menghubungkan Neural Storage (Penyimpanan HP)" "termux-setup-storage"
else
    echo -e "${NEON_CYAN}[*] ${WHITE}Neural Storage (Penyimpanan HP) ${NEON_GREEN}[✔ ALREADY SECURED]${NC}"
fi

# 3. Membersihkan Apt Locks, Status Macet, dan Cache Lama
echo -e "${NEON_CYAN}[*] ${WHITE}Membersihkan cache dan memperbaiki status sistem...${NC}"
rm -f "$PREFIX/var/lib/dpkg/lock*" "$PREFIX/var/cache/apt/archives/lock*" > /dev/null 2>&1
dpkg --configure -a > /dev/null 2>&1
apt-get clean > /dev/null 2>&1

# 4. Update & Upgrade Termux dengan Fallback Aman
run_with_spinner "Menyinkronkan repositori global Termux" "pkg update -y || apt-get update -y"
run_with_progress_bar "Mengoptimalkan dan mengupgrade kernel inti" 20 "apt-get upgrade -y -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold'"

# 5. Cek & Install Modul Pendukung (Proot-distro & Curl)
if ! command -v proot-distro &> /dev/null || ! command -v curl &> /dev/null; then
    run_with_spinner "Menyinkronkan ulang database paket (Anti-404)" "apt-get update -y"
    run_with_progress_bar "Mengunduh modul pendukung Matrix (Proot & Curl)" 15 "pkg install proot-distro curl -y"
else
    echo -e "${NEON_CYAN}[*] ${WHITE}Modul Proot & Curl ${NEON_GREEN}[✔ ALREADY SECURED]${NC}"
fi

# 6. Install Ubuntu Rootfs via Proot-Distro dengan Smart Skip & Auto-Repair
UBUNTU_ROOT="$PREFIX/var/lib/proot-distro/installed-rootfs/ubuntu"
if [ ! -d "$UBUNTU_ROOT" ] || [ ! -f "$UBUNTU_ROOT/etc/os-release" ]; then
    if [ -d "$UBUNTU_ROOT" ]; then
        rm -rf "$UBUNTU_ROOT"
    fi
    run_with_progress_bar "Mengunduh inti OS Ubuntu Core (Harap tunggu)" 40 "proot-distro install ubuntu"
else
    echo -e "${NEON_CYAN}[*] ${WHITE}Inti OS Ubuntu ${NEON_GREEN}[✔ ALREADY SECURED]${NC}"
fi

# 7. Unduh nxc1.sh (menu Ubuntu) + salin nxc_lib.sh ke dalam rootfs Ubuntu
mkdir -p "$UBUNTU_ROOT/root"
run_with_spinner "Mengunduh skrip Menu (nxc1.sh) dari GitHub" \
    "download_and_validate 'https://raw.githubusercontent.com/nxcode123/nx_code/main/nxc1.sh' '$UBUNTU_ROOT/root/nxc1.sh'"
cp -f "$NXC_LIB_LOCAL" "$UBUNTU_ROOT/root/nxc_lib.sh"

echo -e "${NEON_CYAN}[*] ${WHITE}Meregenerasi ulang profil konfigurasi sistem (.bashrc)...${NC}"

# ===================================================================
# 8. BASHRC TERMUX (Ditambahkan sleep agar teks sempat terbaca)
# ===================================================================
cat << EOF_BASHRC > "$HOME/.bashrc"
if [[ \$- == *i* ]] && [ "\$TERMUX_CATCH" != "true" ]; then
    export DEBIAN_FRONTEND=noninteractive

    LOCAL_FILE="\$HOME/nxc_ubuntu.sh"
    TMP_FILE="\$PREFIX/tmp/nxc_ubuntu_new.sh"
    GITHUB_URL="https://raw.githubusercontent.com/nxcode123/nx_code/main/nxc_ubuntu.sh"

    if [ -f "$NXC_LIB_LOCAL" ]; then
        source "$NXC_LIB_LOCAL"
    fi

    echo -e "\033[1;36m[*] Memeriksa pembaruan sistem...\033[0m"

    if command -v download_and_validate &> /dev/null; then
        if [ -f "\$LOCAL_FILE" ]; then
            if download_and_validate "\$GITHUB_URL" "\$TMP_FILE" 1 3 2>/dev/null && ! cmp -s "\$LOCAL_FILE" "\$TMP_FILE"; then
                echo -e "\033[1;33m[!] Ditemukan versi baru dari nxc_ubuntu.sh di GitHub!\033[0m"
                read -p "Apakah Anda ingin mengupdate dan menjalankan ulang setup? [y/N]: " confirm
                if [[ "\$confirm" =~ ^[Yy]\$ ]]; then
                    mv "\$TMP_FILE" "\$LOCAL_FILE"
                    chmod +x "\$LOCAL_FILE"
                    exec bash "\$LOCAL_FILE"
                else
                    rm -f "\$TMP_FILE"
                fi
            else
                rm -f "\$TMP_FILE"
                sleep 1
            fi
        else
            download_and_validate "\$GITHUB_URL" "\$LOCAL_FILE" 1 3 2>/dev/null
            sleep 1
        fi
    fi

    exec proot-distro login ubuntu
fi
EOF_BASHRC

# ===================================================================
# 9. BASHRC UBUNTU
# ===================================================================
cat << 'EOF_UBUNTU_BASHRC' > "$UBUNTU_ROOT/root/.bashrc"
alias menu='bash /root/nxc1.sh'

if [[ $- == *i* ]] && [ -f "/root/nxc1.sh" ]; then
    bash "/root/nxc1.sh"
fi
EOF_UBUNTU_BASHRC

sleep 1 2>/dev/null
printf "\033[?25h"

echo -e "\n${NEON_GREEN}[✔] NXC - TERMUX-UBUNTU (v${SCRIPT_VERSION}) DEPLOYMENT BERHASIL!${NC}"

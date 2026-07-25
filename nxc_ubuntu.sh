#!/data/data/com.termux/files/usr/bin/bash

# ==============================================================================
# PROJECT: NXC - TERMUX-UBUNTU
# DESCRIPTION: Automated Termux-to-Ubuntu Proot Bridge with Auto-Update & UI
# VERSION: 1.3.0
# Source file: nxc_ubuntu.sh
# CHANGELOG v1.3.0: 
# - Ultimate Optimization: Integrasi penuh auto-repair proot-distro[span_1](start_span)[span_1](end_span)
# - Otomatisasi global binary 'menu' di dalam Ubuntu
# - Mode silent update tanpa batas harian (cocok untuk developer)
# ==============================================================================

SCRIPT_VERSION="1.3.0"
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

echo -e "${DARK_GRAY}[INIT] Menyiapkan lingkungan awal Termux...${NC}"
sleep 1 2>/dev/null

# 1. Hushlogin setup
echo -e "${CYBER_BLUE}[*]${WHITE} Menyembunyikan teks sambutan awal (hushlogin)...${NC}"
touch "$HOME/.hushlogin"
sleep 0.5 2>/dev/null

# 2. Storage Setup dengan Logika Smart Skip
if [ ! -d "$HOME/storage" ]; then
    run_with_spinner "Meminta izin akses penyimpanan HP" "termux-setup-storage"
else
    echo -e "${CYBER_BLUE}[*]${WHITE} Akses penyimpanan HP ${TOXIC_GREEN}[✔ TERSEDIA]${NC}"
fi

# 3. Membersihkan Apt Locks, Status Macet, dan Cache Lama
echo -e "${CYBER_BLUE}[*]${WHITE} Membersihkan cache dan memperbaiki error paket dpkg...${NC}"
rm -f "$PREFIX/var/lib/dpkg/lock*" "$PREFIX/var/cache/apt/archives/lock*" > /dev/null 2>&1
dpkg --configure -a > /dev/null 2>&1
apt-get clean > /dev/null 2>&1

# 4. Update & Upgrade Termux dengan Fallback Aman
run_with_spinner "Memperbarui repositori paket Termux" "pkg update -y || apt-get update -y"
run_with_progress_bar "Meningkatkan paket dasar Termux" 20 "apt-get upgrade -y -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold'"

# 5. Cek & Install Modul Pendukung (Proot-distro & Curl)
if ! command -v proot-distro &> /dev/null || ! command -v curl &> /dev/null; then
    run_with_spinner "Menyegarkan database paket terbaru" "apt-get update -y"
    run_with_progress_bar "Menginstal modul pendukung (Proot & Curl)" 15 "pkg install proot-distro curl -y"
else
    echo -e "${CYBER_BLUE}[*]${WHITE} Modul Proot & Curl ${TOXIC_GREEN}[✔ TERSEDIA]${NC}"
fi

# 6. Install Ubuntu Rootfs via Proot-Distro (Smart Skip & Auto-Repair)
UBUNTU_ROOT="$PREFIX/var/lib/proot-distro/installed-rootfs/ubuntu"
if [ ! -d "$UBUNTU_ROOT" ] || [ ! -f "$UBUNTU_ROOT/etc/os-release" ]; then
    if [ -d "$UBUNTU_ROOT" ] || proot-distro list | grep -q "ubuntu.*installed"; then
        echo -e "${DARK_GRAY}[*] Membersihkan file instalasi Ubuntu yang rusak...${NC}"
        # Menggunakan proot-distro remove untuk mencegah error container exists[span_2](start_span)[span_2](end_span)
        proot-distro remove ubuntu > /dev/null 2>&1
        chmod -R 777 "$UBUNTU_ROOT" 2>/dev/null
        rm -rf "$UBUNTU_ROOT" 2>/dev/null
    fi
    run_with_progress_bar "Menginstal sistem operasi Ubuntu" 40 "proot-distro install ubuntu"
else
    echo -e "${CYBER_BLUE}[*]${WHITE} Sistem operasi Ubuntu ${TOXIC_GREEN}[✔ TERSEDIA]${NC}"
fi

# 7. Otomatisasi Total: Unduh nxc1.sh & Buat Binary Global 'menu' di Ubuntu
mkdir -p "$UBUNTU_ROOT/root"
mkdir -p "$UBUNTU_ROOT/usr/local/bin"

run_with_spinner "Mengunduh file skrip menu (nxc1.sh)" \
    "curl -sL 'https://raw.githubusercontent.com/nxcode123/nx_code/main/nxc1.sh' -o '$UBUNTU_ROOT/root/nxc1.sh' && chmod +x '$UBUNTU_ROOT/root/nxc1.sh'"

cp -f "$NXC_LIB_LOCAL" "$UBUNTU_ROOT/root/nxc_lib.sh"

# Membuat perintah global 'menu' di dalam direktori sistem Ubuntu
cat << 'EOF_MENU' > "$UBUNTU_ROOT/usr/local/bin/menu"
#!/bin/bash
if [ -f "/root/nxc1.sh" ]; then
    bash "/root/nxc1.sh"
else
    echo -e "\033[1;31m[!] Error: File /root/nxc1.sh tidak ditemukan.\033[0m"
fi
EOF_MENU
chmod +x "$UBUNTU_ROOT/usr/local/bin/menu"

echo -e "${CYBER_BLUE}[*]${WHITE} Menerapkan konfigurasi otomatis (.bashrc)...${NC}"

# ===================================================================
# 8. BASHRC TERMUX (Developer Mode: Check Every Time & Silent)
# ===================================================================
cat << 'EOF_BASHRC' > "$HOME/.bashrc"
if [[ $- == *i* ]] && [ "$TERMUX_CATCH" != "true" ]; then
    LOCAL_FILE="$HOME/nxc_ubuntu.sh"
    TMP_FILE="$PREFIX/tmp/nxc_ubuntu_new.sh"
    GITHUB_URL="https://raw.githubusercontent.com/nxcode123/nx_code/main/nxc_ubuntu.sh"
    NXC_LIB_LOCAL="$HOME/nxc_lib.sh"

    if [ -f "$NXC_LIB_LOCAL" ]; then
        source "$NXC_LIB_LOCAL"
    fi

    if command -v download_and_validate &> /dev/null; then
        if [ -f "$LOCAL_FILE" ]; then
            if download_and_validate "$GITHUB_URL" "$TMP_FILE" 1 3 2>/dev/null; then
                if ! cmp -s "$LOCAL_FILE" "$TMP_FILE"; then
                    echo -e "\033[1;33m[!] Ditemukan versi baru dari nxc_ubuntu.sh di GitHub!\033[0m"
                    read -p "Apakah Anda ingin mengupdate dan menjalankan ulang setup? [y/N]: " confirm
                    if [[ "$confirm" =~ ^[Yy]$ ]]; then
                        mv "$TMP_FILE" "$LOCAL_FILE"
                        chmod +x "$LOCAL_FILE"
                        exec bash "$LOCAL_FILE"
                    else
                        rm -f "$TMP_FILE"
                    fi
                else
                    rm -f "$TMP_FILE"
                fi
            else
                rm -f "$TMP_FILE"
            fi
        else
            if download_and_validate "$GITHUB_URL" "$LOCAL_FILE" 1 3 2>/dev/null; then
                chmod +x "$LOCAL_FILE"
            fi
        fi
    fi

    exec proot-distro login ubuntu
fi
EOF_BASHRC

# ===================================================================
# 9. BASHRC UBUNTU AUTO-START
# ===================================================================
cat << 'EOF_UBUNTU_BASHRC' > "$UBUNTU_ROOT/root/.bashrc"
if [[ $- == *i* ]] && [ -f "/root/nxc1.sh" ]; then
    bash "/root/nxc1.sh"
fi
EOF_UBUNTU_BASHRC

sleep 1 2>/dev/null
printf "\033[?25h"

echo -e "\n${TOXIC_GREEN}[✔] SETUP TERMUX-UBUNTU SELESAI!${NC}"

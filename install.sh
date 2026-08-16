#!/data/data/com.termux/files/usr/bin/bash
# ==============================================================================
# NX_CODE - Instant Bootstrap Installer
# ==============================================================================

set -e

NX_REPO_RAW_URL="https://raw.githubusercontent.com/nxcode123/nx_code/main/nx_code.sh"
LOCAL_SCRIPT="$HOME/nx_code.sh"

echo -e "\033[1;95m======================================================\033[0m"
echo -e "\033[1;36m       🚀 NX_CODE BOOTSTRAP INSTALLER                \033[0m"
echo -e "\033[1;95m======================================================\033[0m"

# 1. Update paket & instal dependensi awal
echo -e "\n\033[0;36m[➔] Mempersiapkan dependensi Termux (curl, git, proot-distro)...\033[0m"
pkg update -y -o Dpkg::Options::="--force-confold" || true
pkg install -y -o Dpkg::Options::="--force-confold" curl git proot-distro pulseaudio coreutils

# 2. Download / salin nx_code.sh ke direktori HOME
echo -e "\n\033[0;36m[➔] Mengunduh skrip inti NX_CODE...\033[0m"
if [ -f "./nx_code.sh" ]; then
    cp "./nx_code.sh" "$LOCAL_SCRIPT"
else
    curl -fsSL --connect-timeout 10 --max-time 30 "$NX_REPO_RAW_URL" -o "$LOCAL_SCRIPT"
fi

chmod +x "$LOCAL_SCRIPT"

# 3. Jalankan nx_code.sh untuk memulai inisialisasi lingkungan
echo -e "\n\033[1;32m[✔] Skrip inti berhasil disiapkan. Menjalankan konfigurasi sistem...\033[0m\n"
exec bash "$LOCAL_SCRIPT" "$@"

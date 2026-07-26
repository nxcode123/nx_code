#!/data/data/com.termux/files/usr/bin/bash

#===================================
# Nama file: installer.sh
# Repository: nxcode123/nx_code
# Version: v0.0.6
#===================================

set -e

REPO_URL="https://raw.githubusercontent.com/nxcode123/nx_code/main/installer.sh"
INSTALL_DIR="$HOME/.local/bin"
TARGET_FILE="$INSTALL_DIR/installer.sh"
ALIAS_FILE="$INSTALL_DIR/update-installer"

# Fungsi untuk memeriksa update
check_update() {
    local force_check=$1
    local temp_file="/tmp/installer_latest.sh"
    
    echo "[*] Memeriksa pembaruan dari repository GitHub..."
    
    if command -v curl &> /dev/null; then
        curl -s -o "$temp_file" "$REPO_URL"
    elif command -v wget &> /dev/null; then
        wget -q -O "$temp_file" "$REPO_URL"
    fi

    if [ -f "$temp_file" ]; then
        if ! cmp -s "$0" "$temp_file"; then
            echo "[!] Ditemukan pembaruan baru untuk script ini di GitHub!"
            read -p "[?] Apakah Anda ingin memperbarui script sekarang? (y/n): " choice
            case "$choice" in 
              y|Y )
                echo "[*] Mengupdate script..."
                mkdir -p "$INSTALL_DIR"
                cp "$temp_file" "$TARGET_FILE"
                chmod +x "$TARGET_FILE"
                ln -sf "$TARGET_FILE" "$ALIAS_FILE"
                echo "[*] Script berhasil diperbarui!"
                rm -f "$temp_file"
                return 0
                ;;
              * )
                echo "[*] Melewati pembaruan."
                ;;
            esac
        else
            if [ "$force_check" = "true" ]; then
                echo "[*] Script sudah menggunakan versi terbaru."
            fi
        fi
        rm -f "$temp_file"
    fi
}

# Jika dijalankan dengan argumen 'check', jalankan pemeriksaan update
if [ "$1" = "check" ]; then
    check_update true
    exit 0
fi

# Pengecekan otomatis saat script utama dijalankan
check_update false

echo "[*] Menyiapkan lingkungan dan integrasi otomatis..."

# 1. Pastikan direktori biner lokal ada dan terdaftar di PATH
mkdir -p "$INSTALL_DIR"
if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
fi

# 2. Salin file ke direktori sistem lokal agar perintah update-installer aktif
cp "$0" "$TARGET_FILE"
chmod +x "$TARGET_FILE"
ln -sf "$TARGET_FILE" "$ALIAS_FILE"

# 3. Otomatis pasang pemicu cek update ke ~/.bashrc tanpa perlu repot manual
BASHRC_LINE='if [ -f "$HOME/.local/bin/installer.sh" ]; then bash "$HOME/.local/bin/installer.sh" check; fi'
if ! grep -q "installer.sh check" ~/.bashrc; then
    echo "$BASHRC_LINE" >> ~/.bashrc
    echo "[*] Fitur cek update otomatis saat Termux dibuka telah diaktifkan."
fi

echo "[*] Memulai proses instalasi Ubuntu di Termux secara otomatis..."

# 4. Koneksikan storage (Termux Setup Storage)
echo "[*] Menghubungkan penyimpanan internal..."
termux-setup-storage -y || true

# 5. Update dan upgrade package Termux (Non-interaktif)
echo "[*] Melakukan update dan upgrade sistem Termux..."
export DEBIAN_FRONTEND=noninteractive
apt-get update -y && apt-get -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" upgrade

# 6. Install proot-distro
echo "[*] Menginstal proot-distro..."
pkg install proot-distro -y

# 7. Install distro Ubuntu
echo "[*] Menginstal distro Ubuntu..."
proot-distro install ubuntu

echo "[*] Instalasi selesai! Anda dapat menjalankan Ubuntu menggunakan perintah: proot-distro login ubuntu"

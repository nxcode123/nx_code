#!/data/data/com.termux/files/usr/bin/bash

#===================================
# Nama file: installer.sh
# Repository: nxcode123/nx_code
# Version: v0.0.8
#===================================

set -e

REPO_URL="https://raw.githubusercontent.com/nxcode123/nx_code/main/installer.sh"
INSTALL_DIR="$HOME/.local/bin"
TARGET_FILE="$INSTALL_DIR/installer.sh"
ALIAS_FILE="$INSTALL_DIR/update-installer"
BASHRC_LINE='if [ -f "$HOME/.local/bin/installer.sh" ]; then bash "$HOME/.local/bin/installer.sh" check; fi'

# Fungsi untuk memeriksa update
check_update() {
    local force_check=$1
    local temp_file="/tmp/installer_latest.sh"
    
    echo "check update ...."
    
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
                
                if grep -q "installer.sh check" ~/.bashrc; then
                    grep -v "installer.sh check" ~/.bashrc > ~/.bashrc.tmp && mv ~/.bashrc.tmp ~/.bashrc
                fi
                echo "$BASHRC_LINE" >> ~/.bashrc
                
                echo "[*] Script berhasil diperbarui!"
                rm -f "$temp_file"
                return 0
                ;;
              * )
                echo "[*] Melewati pembaruan."
                ;;
            esac
        else
            echo "up to date"
        fi
        rm -f "$temp_file"
    fi
}

if [ "$1" = "check" ]; then
    check_update true
    exit 0
fi

check_update false

echo "[*] Menyiapkan lingkungan dan integrasi otomatis..."

mkdir -p "$INSTALL_DIR"
if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
fi

cp "$0" "$TARGET_FILE"
chmod +x "$TARGET_FILE"
ln -sf "$TARGET_FILE" "$ALIAS_FILE"

if grep -q "installer.sh check" ~/.bashrc; then
    grep -v "installer.sh check" ~/.bashrc > ~/.bashrc.tmp && mv ~/.bashrc.tmp ~/.bashrc
fi
echo "$BASHRC_LINE" >> ~/.bashrc

echo "[*] Memulai proses instalasi Ubuntu di Termux secara otomatis..."

echo "[*] Menghubungkan penyimpanan internal..."
termux-setup-storage -y || true

echo "[*] Melakukan update dan upgrade sistem Termux..."
export DEBIAN_FRONTEND=noninteractive
apt-get update -y && apt-get -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" upgrade

echo "[*] Menginstal proot-distro..."
pkg install proot-distro -y

echo "[*] Menginstal distro Ubuntu..."
proot-distro install ubuntu

echo "[*] Instalasi selesai! Anda dapat menjalankan Ubuntu menggunakan perintah: proot-distro login ubuntu"

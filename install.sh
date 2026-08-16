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
echo -e "\n\033[0;36m[➔] Mempersiapkan dependensi Termux (curl, git, proot-distro, pulseaudio)...\033[0m"
pkg update -y -o Dpkg::Options::="--force-confold" || true
pkg install -y -o Dpkg::Options::="--force-confold" curl git proot-distro pulseaudio coreutils

# 2. Download / salin nx_code.sh & direktori themes ke direktori HOME
echo -e "\n\033[0;36m[➔] Menyiapkan modul tema dan skrip inti NX_CODE...\033[0m"
mkdir -p "$HOME/.nx_code/themes" 2>/dev/null || true
if [ -d "./themes" ]; then
    cp -r ./themes/* "$HOME/.nx_code/themes/" 2>/dev/null || true
fi

if [ -f "./nx_code.sh" ]; then
    cp "./nx_code.sh" "$LOCAL_SCRIPT"
else
    curl -fsSL --connect-timeout 10 --max-time 30 "$NX_REPO_RAW_URL" -o "$LOCAL_SCRIPT"
fi

chmod +x "$LOCAL_SCRIPT"

# 3. Pasang executable global nx-menu
BIN_DIR="${PREFIX:-/data/data/com.termux/files/usr}/bin"
if [ -d "$BIN_DIR" ]; then
    cat << 'EOF' > "$BIN_DIR/nx-menu"
#!/data/data/com.termux/files/usr/bin/bash
TARGET="$HOME/nx_code.sh"
if [ ! -s "$TARGET" ] && [ -s "./nx_code.sh" ]; then
    TARGET="$(realpath ./nx_code.sh 2>/dev/null || echo "./nx_code.sh")"
fi
if [ ! -s "$TARGET" ]; then
    curl -fsSL --connect-timeout 5 https://raw.githubusercontent.com/nxcode123/nx_code/main/nx_code.sh -o "$HOME/nx_code.sh" 2>/dev/null
    chmod +x "$HOME/nx_code.sh" 2>/dev/null
    TARGET="$HOME/nx_code.sh"
fi
exec bash "$TARGET" --menu "$@"
EOF
    chmod +x "$BIN_DIR/nx-menu" 2>/dev/null
    ln -sf "$BIN_DIR/nx-menu" "$BIN_DIR/nx" 2>/dev/null || cp "$BIN_DIR/nx-menu" "$BIN_DIR/nx" 2>/dev/null
    chmod +x "$BIN_DIR/nx" 2>/dev/null
fi

# 4. Jalankan nx_code.sh untuk memulai inisialisasi lingkungan
echo -e "\n\033[1;32m[✔] Skrip inti berhasil disiapkan. Menjalankan konfigurasi sistem...\033[0m\n"
exec bash "$LOCAL_SCRIPT" "$@"

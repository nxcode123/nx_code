#!/data/data/com.termux/files/usr/bin/bash
# ==============================================================================
# PROJECT     : NX_CODE
# FILE        : nxc.sh
# DESCRIPTION : Fast Lightweight Termux-Ubuntu Bridge & Installer
# VERSION     : 1.3.1
# ==============================================================================

CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Guard: Memastikan script berjalan di Termux
if [ ! -d "/data/data/com.termux" ]; then
    echo -e "${RED}[!] Error: Skrip ini dirancang khusus untuk dijalankan di lingkungan Termux!${NC}"
    exit 1
fi

echo -e "${CYAN}==============================================${NC}"
echo -e "${GREEN} [*] NX_CODE: Termux-Ubuntu Automated Setup${NC}"
echo -e "${CYAN}==============================================${NC}\n"

# 1. Hubungkan Penyimpanan Android
echo -e "${CYAN}[1/5]${NC} Menghubungkan penyimpanan internal..."
if [ ! -d "$HOME/storage" ]; then
    termux-setup-storage
fi

# 2. Update & Pasang Dependensi Inti
echo -e "${CYAN}[2/5]${NC} Memeriksa dependensi Termux (git, curl, proot-distro)..."
export DEBIAN_FRONTEND=noninteractive
pkg update -y >/dev/null 2>&1
for pkg in git curl proot-distro; do
    if ! command -v "$pkg" &>/dev/null; then
        echo -e "      ${YELLOW}Menginstal $pkg...${NC}"
        pkg install "$pkg" -y >/dev/null 2>&1
    fi
done

# 3. Pasang Distribusi Ubuntu jika belum ada
echo -e "${CYAN}[3/5]${NC} Memeriksa sistem Ubuntu PRoot..."
UBUNTU_ROOT="$PREFIX/var/lib/proot-distro/installed-rootfs/ubuntu"
if [ ! -d "$UBUNTU_ROOT" ]; then
    echo -e "      ${YELLOW}Menginstal Ubuntu (proses awal)...${NC}"
    proot-distro install ubuntu
else
    echo -e "      ${GREEN}[✔] Ubuntu rootfs sudah terpasang.${NC}"
fi

# 4. Sinkronisasi Skrip dan Direktori Menu ke Ubuntu
echo -e "${CYAN}[4/5]${NC} Menyiapkan modul dan antarmuka NX_CODE di dalam Ubuntu..."
mkdir -p "$UBUNTU_ROOT/root/themes"

# Unduh nxc1.sh, nxc_lib.sh, dan themes
BASE_URL="https://raw.githubusercontent.com/nxcode123/nx_code/main"
curl -fsSL "$BASE_URL/nxc1.sh" -o "$UBUNTU_ROOT/root/nxc1.sh" 2>/dev/null || true
curl -fsSL "$BASE_URL/nxc_lib.sh" -o "$UBUNTU_ROOT/root/nxc_lib.sh" 2>/dev/null || true
curl -fsSL "$BASE_URL/themes/theme.list" -o "$UBUNTU_ROOT/root/themes/theme.list" 2>/dev/null || true
curl -fsSL "$BASE_URL/themes/cyberpunk.sh" -o "$UBUNTU_ROOT/root/themes/cyberpunk.sh" 2>/dev/null || true

# Salin berkas lokal jika instalasi dijalankan dari folder lokal
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/nxc1.sh" ]; then
    cp "$SCRIPT_DIR/nxc1.sh" "$UBUNTU_ROOT/root/nxc1.sh"
fi
if [ -f "$SCRIPT_DIR/nxc_lib.sh" ]; then
    cp "$SCRIPT_DIR/nxc_lib.sh" "$UBUNTU_ROOT/root/nxc_lib.sh"
fi
if [ -d "$SCRIPT_DIR/themes" ]; then
    cp -r "$SCRIPT_DIR/themes/"* "$UBUNTU_ROOT/root/themes/" 2>/dev/null || true
fi

chmod +x "$UBUNTU_ROOT/root/nxc1.sh" 2>/dev/null || true
chmod +x "$UBUNTU_ROOT/root/nxc_lib.sh" 2>/dev/null || true

# 5. Konfigurasi .bashrc Ubuntu & Termux
echo -e "${CYAN}[5/5]${NC} Mengonfigurasi pintasan (.bashrc)..."
UBUNTU_BASHRC="$UBUNTU_ROOT/root/.bashrc"
if [ -f "$UBUNTU_BASHRC" ]; then
    if ! grep -q "alias menu=" "$UBUNTU_BASHRC"; then
        echo -e "\n# Alias pintasan menu NX_CODE\nalias menu='bash /root/nxc1.sh'\nalias nx-menu='bash /root/nxc1.sh'" >> "$UBUNTU_BASHRC"
    fi
    if ! grep -q "bash /root/nxc1.sh" "$UBUNTU_BASHRC"; then
        echo -e "if [ -f \"/root/nxc1.sh\" ]; then bash /root/nxc1.sh; fi" >> "$UBUNTU_BASHRC"
    fi
fi

# Konfigurasi Termux .bashrc
TERMUX_BASHRC="$HOME/.bashrc"
touch "$HOME/.hushlogin"
if ! grep -q "proot-distro login ubuntu" "$TERMUX_BASHRC"; then
    cat << 'EOF' >> "$TERMUX_BASHRC"

# Masuk otomatis ke Ubuntu PRoot jika bukan sub-session
if [ -z "$PROOT_DISTRO_EDITION" ] && [ "$TERMUX_CATCH" != "true" ]; then
    exec proot-distro login ubuntu
fi
EOF
fi

echo -e "\n${GREEN}[✔] Instalasi dan konfigurasi berhasil diselesaikan!${NC}"
echo -e "${YELLOW}Ketik 'menu' di dalam Ubuntu kapan saja untuk membuka pusat kendali.${NC}\n"

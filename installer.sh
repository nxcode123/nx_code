#!/data/data/com.termux/files/usr/bin/bash
# ==============================================================================
# NX_CODE INSTALLER v3.0.0 – Fully Automatic Modular Edition
# ==============================================================================

# --- Konfigurasi GitHub (GANTI DENGAN USERNAME KAMU) ---
GITHUB_USER="nxcode123"
GITHUB_REPO="nx_code"
GITHUB_BRANCH="main"
BASE_URL="https://raw.githubusercontent.com/$GITHUB_USER/$GITHUB_REPO/$GITHUB_BRANCH"

# Daftar file yang akan didownload
FILES=(
    "main.sh"
    "README.md"
    "CHANGELOG.md"
    "LICENSE"
    "src/core/config.sh"
    "src/core/utils.sh"
    "src/core/security.sh"
    "src/modules/ubuntu.sh"
    "src/modules/gui.sh"
    "src/modules/tools.sh"
    "src/modules/backup.sh"
    "src/modules/update.sh"
    "src/menu/main_menu.sh"
)

# --- Warna ---
CYAN='\033[0;36m'
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
PURPLE='\033[0;35m'
WHITE='\033[1;37m'
NC='\033[0m'

SUCCESS="${GREEN}[✔]${NC}"
ERROR="${RED}[✘]${NC}"
PROCESS="${CYAN}[➔]${NC}"
WARNING="${YELLOW}[⚠]${NC}"

# --- Fungsi ---
download_file() {
    local file="$1"
    local dest="$HOME/.nx_code/$file"
    local dir=$(dirname "$dest")
    mkdir -p "$dir"
    echo -ne "${PROCESS} ${CYAN}Downloading $file...${NC}"
    if curl -sL "$BASE_URL/$file" -o "$dest"; then
        chmod +x "$dest" 2>/dev/null
        echo -e " ${GREEN}[OK]${NC}"
        return 0
    else
        echo -e " ${RED}[FAIL]${NC}"
        return 1
    fi
}

setup_symlink() {
    ln -sf "$HOME/.nx_code/main.sh" "$HOME/nx_code.sh"
    chmod +x "$HOME/.nx_code/main.sh"
    chmod +x "$HOME/.nx_code/src/"*/*.sh 2>/dev/null
}

setup_bashrc() {
    echo -e "\n${PROCESS} ${CYAN}Configuring .bashrc...${NC}"
    if grep -q "NX_CODE" "$HOME/.bashrc" 2>/dev/null; then
        echo -e "${SUCCESS} Already configured."
        return 0
    fi
    cat >> "$HOME/.bashrc" << 'EOF'

# --- NX_CODE ENVIRONMENT ---
export NX_CODE_HOME="$HOME/.nx_code"
alias nx="bash \$NX_CODE_HOME/main.sh"
alias nx-menu="nx"
alias nx-update="bash \$NX_CODE_HOME/src/modules/update.sh"
alias nx-info="bash \$NX_CODE_HOME/src/modules/info.sh 2>/dev/null || echo 'Info module not found'"
PS1="\[\033[1;95m\][═\[\033[0;36m\]NX\[\033[1;95m\]═] \[\033[1;32m\]⚡ \[\033[0m\]"
EOF
    echo -e "${SUCCESS} .bashrc updated."
}

show_finish() {
    echo -e "\n${PURPLE}======================================================"
    echo -e "${GREEN}          NX_CODE INSTALLATION COMPLETE! 🎉"
    echo -e "${PURPLE}======================================================"
    echo -e "${WHITE}  Location: ${CYAN}~/.nx_code/${NC}"
    echo -e "${WHITE}  Version:  ${CYAN}$(grep -m1 'VERSION=' ~/.nx_code/src/core/config.sh | cut -d'"' -f2)${NC}"
    echo -e "${PURPLE}------------------------------------------------------"
    echo -e "${WHITE}  🚀 Quick start:"
    echo -e "     ${GREEN}nx${NC}          - Buka menu utama"
    echo -e "     ${GREEN}nx-update${NC}   - Update NX_CODE"
    echo -e "${PURPLE}======================================================"
    echo -e "\n${YELLOW}Restart Termux atau jalankan 'exec bash'.${NC}"
}

# --- Main ---
clear
echo -e "${PURPLE}======================================================"
echo -e "${WHITE}      NX_CODE INSTALLER v3.0.0 (Fully Automatic)"
echo -e "${PURPLE}======================================================"

# Cek internet
if ! ping -c 1 8.8.8.8 &>/dev/null; then
    echo -e "${ERROR} No internet."
    exit 1
fi

# Buat direktori
mkdir -p "$HOME/.nx_code"

# Download semua file
failed=0
for file in "${FILES[@]}"; do
    if ! download_file "$file"; then
        ((failed++))
    fi
done

if [ $failed -gt 0 ]; then
    echo -e "${ERROR} $failed file(s) gagal didownload."
    exit 1
fi

# Setup symlink dan bashrc
setup_symlink
setup_bashrc
show_finish

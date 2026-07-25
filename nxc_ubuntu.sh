#!/data/data/com.termux/files/usr/bin/bash

# ==============================================================================
# PROJECT: NXC - TERMUX-UBUNTU
# DESCRIPTION: Automated Termux-to-Ubuntu Proot Bridge with Auto-Update & UI
# VERSION: 1.3.2
# Source file: nxc_ubuntu.sh
# CHANGELOG v1.3.2: 
# - Fix Absolute Path: Menggunakan path absolut penuh untuk mencegah variabel gagal diekspansi
# - Mengoptimalkan fungsi download agar langsung dieksekusi tanpa eval yang rentan error
# =============================================================================

SCRIPT_VERSION="1.3.2"
NXC_LIB_URL="https://raw.githubusercontent.com/nxcode123/nx_code/main/nxc_lib.sh"
NXC_LIB_LOCAL="$HOME/nxc_lib.sh"

export DEBIAN_FRONTEND=noninteractive
export APT_LISTCHANGES_FRONTEND=none
LOG_FILE="$HOME/nxc_setup.log"

> "$LOG_FILE"
trap 'printf "\033[?25h"; echo -e "\033[0m"; exit' INT TERM EXIT

if [ ! -d "/data/data/com.termux" ]; then
    echo "[!] Error: Skrip ini dirancang khusus untuk dijalankan di lingkungan Termux!"
    exit 1
fi

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
    if fetch_lib && [ -s "$NXC_LIB_LOCAL.tmp" ] && bash -n "$NXC_LIB_LOCAL.tmp" 2>/dev/null; then
        mv "$NXC_LIB_LOCAL.tmp" "$NXC_LIB_LOCAL"
    else
        rm -f "$NXC_LIB_LOCAL.tmp"
        exit 1
    fi
fi

source "$NXC_LIB_LOCAL"

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

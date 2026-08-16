#!/data/data/com.termux/files/usr/bin/bash
# ==============================================================================
# PROJECT     : NX_CODE
# FILE        : nx_code.sh
# DESCRIPTION : Automated Termux-to-Ubuntu Proot Bridge with Rich UI & Auto-Update
# VERSION     : 1.3.1
# ==============================================================================

SCRIPT_VERSION="1.3.1"

# ANSI Cyberpunk Color Palette
NEON_GREEN='\033[38;5;46m'
NEON_CYAN='\033[38;5;51m'
NEON_PINK='\033[38;5;198m'
NEON_YELLOW='\033[38;5;226m'
DARK_GRAY='\033[38;5;238m'
WHITE='\033[1;37m'
RED='\033[1;31m'
NC='\033[0m'

export DEBIAN_FRONTEND=noninteractive
export APT_LISTCHANGES_FRONTEND=none
LOG_FILE="$HOME/nxc_setup.log"

# Inisialisasi file log baru
> "$LOG_FILE"

# Trap pengaman untuk mengembalikan kursor saat keluar
trap 'printf "\033[?25h\033[0m"' INT TERM EXIT

# Guard: Memastikan skrip dijalankan di lingkungan Termux
if [ ! -d "/data/data/com.termux" ]; then
    echo -e "${RED}[!] Error: Skrip ini dirancang khusus untuk dijalankan di lingkungan Termux!${NC}"
    exit 1
fi

show_banner() {
    clear
    printf "\033[?25l"
    echo -e "${NEON_CYAN}======================================================${NC}"
    echo -e "${NEON_GREEN}       NXC-UBUNTU // HYPERVISOR PRO [v${SCRIPT_VERSION}]${NC}"
    echo -e "${NEON_CYAN}======================================================${NC}\n"
}

log_msg() {
    echo "[$(date +'%Y-%m-%d %T')] $1" >> "$LOG_FILE"
}

run_with_spinner() {
    local text="$1"
    local cmd="$2"
    
    log_msg "START: $text"
    eval "$cmd" >> "$LOG_FILE" 2>&1 &
    local pid=$!
    
    local spin='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    local i=0
    
    printf "${NEON_CYAN}[*] ${WHITE}%s ${NC}" "$text"
    
    while kill -0 "$pid" 2>/dev/null; do
        printf "\b${NEON_PINK}%s${NC}" "${spin:i:1}"
        i=$(( (i+1) % 10 ))
        read -r -t 0.15 _ 2>/dev/null || sleep 0.15 2>/dev/null || true
    done
    
    wait "$pid"
    local status=$?
    if [ $status -eq 0 ]; then
        printf "\b${NEON_GREEN}[✔ SYNCED]${NC}\n"
        log_msg "SUCCESS: $text"
        return 0
    else
        printf "\b${RED}[✖ FAILED]${NC}\n"
        log_msg "ERROR: $text (Exit code: $status)"
        printf "\033[?25h"
        echo -e "\n${RED}[!] Detail error sistem dari log:${NC}"
        tail -n 10 "$LOG_FILE"
        exit 1
    fi
}

run_with_progress_bar() {
    local text="$1"
    local est_time="$2"
    local cmd="$3"
    
    log_msg "START (Progress): $text"
    echo -e "${NEON_CYAN}[*] ${WHITE}${text}${NC}"
    
    eval "$cmd" >> "$LOG_FILE" 2>&1 &
    local pid=$!
    
    local width=30
    local elapsed=0
    local max_ticks=$(( est_time * 5 ))
    [ "$max_ticks" -le 0 ] && max_ticks=50
    
    while kill -0 "$pid" 2>/dev/null; do
        local percent=$(( (elapsed * 100) / max_ticks ))
        [ "$percent" -ge 98 ] && percent=98
        
        local filled=$(( (percent * width) / 100 ))
        local empty=$(( width - filled ))
        
        local bar=""
        for ((i=0; i<filled; i++)); do bar+="█"; done
        for ((i=0; i<empty; i++)); do bar+="░"; done
        
        printf "\r${DARK_GRAY} ↳ ${NEON_PINK}[${NEON_GREEN}%s${NEON_PINK}] ${NEON_YELLOW}%3d%%${NC} " "$bar" "$percent"
        
        read -r -t 0.2 _ 2>/dev/null || sleep 0.2 2>/dev/null || true
        elapsed=$((elapsed + 1))
    done
    
    wait "$pid"
    local status=$?
    
    local bar=""
    for ((i=0; i<width; i++)); do bar+="█"; done

    if [ $status -eq 0 ]; then
        printf "\r${DARK_GRAY} ↳ ${NEON_PINK}[${NEON_GREEN}%s${NEON_PINK}] ${NEON_GREEN}100%% [✔ SECURED]${NC}\n" "$bar"
        log_msg "SUCCESS (Progress): $text"
        return 0
    else
        printf "\r${DARK_GRAY} ↳ ${NEON_PINK}[${RED}%s${NEON_PINK}] ${RED}ERR%% [✖ FAILED]${NC}\n" "$bar"
        log_msg "ERROR (Progress): $text (Exit code: $status)"
        echo -e "${RED}[!] FATAL ERROR: Silakan cek file nxc_setup.log untuk detailnya.${NC}"
        tail -n 10 "$LOG_FILE"
        printf "\033[?25h"
        exit 1
    fi
}

show_banner

echo -e "${DARK_GRAY}[INIT] Memuat protokol konfigurasi sistem...${NC}"
read -r -t 0.5 _ 2>/dev/null || sleep 0.5 2>/dev/null || true

# 1. Hushlogin setup
touch "$HOME/.hushlogin"

# 2. Storage Setup
if [ ! -d "$HOME/storage" ]; then
    run_with_spinner "Menghubungkan Neural Storage (Penyimpanan HP)" "termux-setup-storage"
fi

# 3. Membersihkan Apt Locks Lama
rm -f "$PREFIX/var/lib/dpkg/lock*" "$PREFIX/var/cache/apt/archives/lock*" > /dev/null 2>&1

# 4. Update & Upgrade Termux dengan Fallback Aman
run_with_spinner "Menyinkronkan repositori Termux" "pkg update -y || apt-get update -y"
run_with_progress_bar "Memasang modul pendukung (Proot-distro, Curl, Git)" 10 "pkg install -y proot-distro curl git"

# 5. Install Ubuntu Rootfs via Proot-Distro
UBUNTU_ROOT="$PREFIX/var/lib/proot-distro/installed-rootfs/ubuntu"
if [ ! -d "$UBUNTU_ROOT" ]; then
    run_with_progress_bar "Mengunduh inti OS Ubuntu Core (Harap tunggu)" 35 "proot-distro install ubuntu"
else
    echo -e "${NEON_CYAN}[*] ${WHITE}Inti OS Ubuntu ${NEON_GREEN}[✔ ALREADY SECURED]${NC}"
fi

# 6. Injeksi Skrip Menu, Library, dan Tema ke Ubuntu Rootfs
run_with_spinner "Menyiapkan modul antarmuka NX_CODE ke dalam Ubuntu" "
    mkdir -p \"$UBUNTU_ROOT/root/themes\"
    BASE_URL='https://raw.githubusercontent.com/nxcode123/nx_code/main'
    curl -fsSL \"\$BASE_URL/nxc1.sh\" -o \"$UBUNTU_ROOT/root/nxc1.sh\" 2>/dev/null || true
    curl -fsSL \"\$BASE_URL/nxc_lib.sh\" -o \"$UBUNTU_ROOT/root/nxc_lib.sh\" 2>/dev/null || true
    curl -fsSL \"\$BASE_URL/themes/theme.list\" -o \"$UBUNTU_ROOT/root/themes/theme.list\" 2>/dev/null || true
    
    # Salin dari repositori lokal jika ada
    SCRIPT_DIR=\"\$(cd \"\$(dirname \"\${BASH_SOURCE[0]}\")\" && pwd)\"
    if [ -f \"\$SCRIPT_DIR/nxc1.sh\" ]; then cp \"\$SCRIPT_DIR/nxc1.sh\" \"$UBUNTU_ROOT/root/nxc1.sh\"; fi
    if [ -f \"\$SCRIPT_DIR/nxc_lib.sh\" ]; then cp \"\$SCRIPT_DIR/nxc_lib.sh\" \"$UBUNTU_ROOT/root/nxc_lib.sh\"; fi
    if [ -d \"\$SCRIPT_DIR/themes\" ]; then cp -r \"\$SCRIPT_DIR/themes/\"* \"$UBUNTU_ROOT/root/themes/\" 2>/dev/null || true; fi
    
    chmod +x \"$UBUNTU_ROOT/root/nxc1.sh\" 2>/dev/null || true
    chmod +x \"$UBUNTU_ROOT/root/nxc_lib.sh\" 2>/dev/null || true
"

echo -e "${NEON_CYAN}[*] ${WHITE}Menulis ulang protokol jembatan utama (.bashrc)...${NC}"

# ===================================================================
# 7. BASHRC TERMUX (Jembatan Auto-Login & Auto-Update nx_code.sh)
# ===================================================================
cat << 'EOF_BASHRC' > "$HOME/.bashrc"
if [ -z "$PROOT_DISTRO_EDITION" ] && [ "$TERMUX_CATCH" != "true" ]; then
    export DEBIAN_FRONTEND=noninteractive
    
    # Pengecekan pembaruan cepat nx_code.sh
    CYAN='\033[1;36m'
    YELLOW='\033[1;33m'
    GREEN='\033[1;32m'
    NC='\033[0m'
    
    LOCAL_FILE="$HOME/nx_code.sh"
    TMP_FILE="$PREFIX/tmp/nx_code_new.sh"
    GITHUB_URL="https://raw.githubusercontent.com/nxcode123/nx_code/main/nx_code.sh"
    
    if curl -fsSL --max-time 3 "$GITHUB_URL" -o "$TMP_FILE" 2>/dev/null; then
        if [ -s "$TMP_FILE" ] && [ -f "$LOCAL_FILE" ]; then
            if ! cmp -s "$LOCAL_FILE" "$TMP_FILE"; then
                echo -e "${YELLOW}[!] Pembaruan baru NX_CODE tersedia di GitHub.${NC}"
                read -r -t 5 -p "Perbarui skrip sekarang? [y/N]: " confirm || confirm="n"
                echo ""
                if [[ "$confirm" =~ ^[Yy]$ ]]; then
                    mv "$TMP_FILE" "$LOCAL_FILE"
                    chmod +x "$LOCAL_FILE"
                    echo -e "${GREEN}[*] Skrip diperbarui. Memuat ulang...${NC}"
                    exec bash "$LOCAL_FILE"
                fi
            fi
        elif [ ! -f "$LOCAL_FILE" ] && [ -s "$TMP_FILE" ]; then
            mv "$TMP_FILE" "$LOCAL_FILE"
            chmod +x "$LOCAL_FILE"
        fi
        rm -f "$TMP_FILE"
    fi

    # Masuk langsung ke lingkungan Ubuntu
    exec proot-distro login ubuntu
fi
EOF_BASHRC

# ===================================================================
# 8. BASHRC UBUNTU (Alias Menu & Auto-run Hook)
# ===================================================================
cat << 'EOF_UBUNTU_BASHRC' > "$UBUNTU_ROOT/root/.bashrc"
# Alias panggilan cepat menu NX_CODE
alias menu='bash /root/nxc1.sh'
alias nx-menu='bash /root/nxc1.sh'

# Jalankan menu utama saat sesi dimulai
if [ -f "/root/nxc1.sh" ]; then
    bash "/root/nxc1.sh"
fi
EOF_UBUNTU_BASHRC

printf "\033[?25h" # Kembalikan kursor

echo -e "\n${NEON_GREEN}======================================================${NC}"
echo -e "${NEON_GREEN} [✔] NXC-UBUNTU (v${SCRIPT_VERSION}) INSTALASI BERHASIL!${NC}"
echo -e "${NEON_GREEN}======================================================${NC}"
echo -e "${NEON_YELLOW} • Ketik 'menu' di dalam Ubuntu untuk membuka antarmuka.${NC}"
echo -e "${NEON_YELLOW} • Silakan restart aplikasi Termux atau login ke Ubuntu.${NC}\n"

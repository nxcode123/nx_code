#!/data/data/com.termux/files/usr/bin/bash

# ==============================================================================
# PROJECT: NXC - TERMUX-UBUNTU
# DESCRIPTION: Automated Termux-to-Ubuntu Proot Bridge with Auto-Update & UI
# VERSION: 1.1.6
# ==============================================================================

SCRIPT_VERSION="1.1.6"

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

# Trap pengaman untuk mengembalikan kursor jika skrip dihentikan paksa (Ctrl+C)
trap 'printf "\033[?25h"; echo -e "${NC}"; exit' INT TERM EXIT

# Guard: Memastikan skrip dijalankan di lingkungan Termux
if [ ! -d "/data/data/com.termux" ]; then
    echo -e "${RED}[!] Error: Skrip ini dirancang khusus untuk dijalankan di lingkungan Termux!${NC}"
    exit 1
fi

show_banner() {
    clear
    printf "\033[?25l"
    echo -e "${NEON_GREEN}NXC - TERMUX-UBUNTU // PRO-EDITION [v${SCRIPT_VERSION}]${NC}"
    echo -e "${DARK_GRAY}----------------------------------------${NC}\n"
}

log_msg() {
    echo "[$(date +'%T')] $1" >> "$LOG_FILE"
}

run_with_spinner() {
    local text="$1"
    local cmd="$2"
    
    log_msg "START: $text"
    eval "$cmd" >> "$LOG_FILE" 2>&1 &
    local pid=$!
    
    local spin='⣾⣽⣻⢿⡿⣟⣯⣷'
    local i=0
    
    printf "${NEON_CYAN}[*] ${WHITE}%s ${NC}" "$text"
    
    while kill -0 "$pid" 2>/dev/null; do
        printf "\b${NEON_PINK}%s${NC}" "${spin:i:1}"
        i=$(( (i+1) % 8 ))
        sleep 0.1 2>/dev/null || read -t 0.1
    done
    
    wait "$pid"
    local status=$?
    if [ $status -eq 0 ]; then
        printf "\b${NEON_GREEN}[✔ SYNCED]${NC}\n"
        log_msg "SUCCESS: $text"
    else
        printf "\b${RED}[✖ FAILED] - Cek nxc_setup.log${NC}\n"
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
    
    local width=35
    local elapsed=0
    local interval=0.2 
    
    while kill -0 "$pid" 2>/dev/null; do
        local percent=$(( (elapsed * 100) / (est_time * 5) ))
        if [ "$percent" -ge 98 ]; then percent=98; fi
        
        local filled=$(( (percent * width) / 100 ))
        local empty=$(( width - filled ))
        
        local bar=""
        for ((i=0; i<filled; i++)); do bar+="█"; done
        for ((i=0; i<empty; i++)); do bar+="░"; done
        
        printf "\r${DARK_GRAY} ↳ ${NEON_PINK}[${NEON_GREEN}%-${width}s${NEON_PINK}] ${NEON_YELLOW}%3d%% ${NC}" "$bar" "$percent"
        
        sleep $interval 2>/dev/null || read -t 0.2
        elapsed=$((elapsed + 1))
    done
    
    wait "$pid"
    local status=$?
    
    if [ $status -eq 0 ]; then
        local bar=""
        for ((i=0; i<width; i++)); do bar+="█"; done
        printf "\r${DARK_GRAY} ↳ ${NEON_PINK}[${NEON_GREEN}%-${width}s${NEON_PINK}] ${NEON_GREEN}100%% [✔ SECURED]${NC}\n" "$bar"
        log_msg "SUCCESS (Progress): $text"
    else
        local bar=""
        for ((i=0; i<width; i++)); do bar+="█"; done
        printf "\r${DARK_GRAY} ↳ ${NEON_PINK}[${RED}%-${width}s${NEON_PINK}] ${RED}ERR%% [✖ FAILED] ${NC}\n" "$bar"
        log_msg "ERROR (Progress): $text (Exit code: $status)"
        echo -e "${RED}[!] FATAL ERROR: Silakan cek file nxc_setup.log untuk detailnya.${NC}"
        tail -n 10 "$LOG_FILE"
        printf "\033[?25h"
        exit 1
    fi
}

show_banner

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

# 6. Install Ubuntu Rootfs via Proot-Distro dengan Self-Healing Korup
UBUNTU_ROOT="$PREFIX/var/lib/proot-distro/installed-rootfs/ubuntu"
if [ ! -d "$UBUNTU_ROOT" ] || [ ! -f "$UBUNTU_ROOT/etc/os-release" ]; then
    if [ -d "$UBUNTU_ROOT" ]; then
        echo -e "${NEON_YELLOW}[!] Mendeteksi direktori Ubuntu korup. Membersihkan sisa data secara otomatis...${NC}"
        rm -rf "$UBUNTU_ROOT"
    fi
    run_with_progress_bar "Mengunduh inti OS Ubuntu Core (Harap tunggu)" 40 "proot-distro install ubuntu"
else
    echo -e "${NEON_CYAN}[*] ${WHITE}Inti OS Ubuntu ${NEON_GREEN}[✔ ALREADY SECURED]${NC}"
fi

# 7. Fungsi Unduh dengan Mekanisme Retry Otomatis
download_menu_script() {
    local url="https://raw.githubusercontent.com/nxcode123/nx_code/main/nxc1.sh"
    local target="$UBUNTU_ROOT/root/nxc1.sh"
    
    mkdir -p "$UBUNTU_ROOT/root"
    
    for attempt in {1..3}; do
        if curl -s -L --max-time 10 "$url" -o "$target"; then
            if [ -s "$target" ]; then
                chmod +x "$target"
                return 0
            fi
        fi
        sleep 1
    done
    return 1
}

run_with_spinner "Mengunduh skrip Menu (nxc1.sh) dari GitHub" "download_menu_script"

echo -e "${NEON_CYAN}[*] ${WHITE}Menulis ulang protokol jembatan utama (.bashrc)...${NC}"

# ===================================================================
# 8. BASHRC TERMUX (Jembatan Auto-Login & Silent Auto-Update nxc_ubuntu.sh)
# ===================================================================
cat << 'EOF_BASHRC' > "$HOME/.bashrc"
if [ -z "$PROOT_DISTRO_EDITION" ] && [ "$TERMUX_CATCH" != "true" ]; then
    export DEBIAN_FRONTEND=noninteractive
    
    # --- PRO-GRADE AUTO-UPDATE NXC_UBUNTU.SH ---
    CYAN='\033[1;36m'
    YELLOW='\033[1;33m'
    GREEN='\033[1;32m'
    NC='\033[0m'
    
    LOCAL_FILE="$HOME/nxc_ubuntu.sh"
    TMP_FILE="$PREFIX/tmp/nxc_ubuntu_new.sh"
    GITHUB_URL="https://raw.githubusercontent.com/nxcode123/nx_code/main/nxc_ubuntu.sh"
    
    echo -e "${CYAN}[*] Memeriksa pembaruan sistem (nxc_ubuntu.sh)...${NC}"
    
    if curl -s -L --max-time 3 "$GITHUB_URL" -o "$TMP_FILE"; then
        if [ -f "$LOCAL_FILE" ]; then
            if ! cmp -s "$LOCAL_FILE" "$TMP_FILE"; then
                echo -e "${YELLOW}[!] Ditemukan versi baru dari nxc_ubuntu.sh di GitHub!${NC}"
                read -p "Apakah Anda ingin mengupdate dan menjalankan ulang setup? [y/N]: " confirm
                if [[ "$confirm" =~ ^[Yy]$ ]]; then
                    echo -e "${GREEN}[*] Mengupdate file sistem...${NC}"
                    mv "$TMP_FILE" "$LOCAL_FILE"
                    chmod +x "$LOCAL_FILE"
                    echo -e "${GREEN}[*] Memulai ulang proses setup...${NC}"
                    sleep 1
                    exec bash "$LOCAL_FILE"
                else
                    echo -e "${CYAN}[*] Pembaruan ditunda.${NC}"
                    rm -f "$TMP_FILE"
                fi
            else
                rm -f "$TMP_FILE"
            fi
        else
            mv "$TMP_FILE" "$LOCAL_FILE"
            chmod +x "$LOCAL_FILE"
        fi
    fi
    # ------------------------------------------

    pkg update -y > /dev/null 2>&1 && apt-get upgrade -y > /dev/null 2>&1
    
    exec proot-distro login ubuntu
fi
EOF_BASHRC

# ===================================================================
# 9. BASHRC UBUNTU (Alias Menu & Auto-run Hook dengan Path Absolut)
# ===================================================================
cat << 'EOF_UBUNTU_BASHRC' > "$UBUNTU_ROOT/root/.bashrc"
# Perintah panggilan cepat (Alias)
alias menu='bash /root/nxc1.sh'

# Skrip berjalan otomatis saat pertama kali masuk
if [ -f "/root/nxc1.sh" ]; then
    bash "/root/nxc1.sh"
fi
EOF_UBUNTU_BASHRC

sleep 1 2>/dev/null
printf "\033[?25h" # Kembalikan kursor

echo -e "\n${NEON_GREEN}[✔] NXC - TERMUX-UBUNTU (v1.1.6) DEPLOYMENT BERHASIL!${NC}"
echo -e "${NEON_YELLOW} [1] Perbaikan path alias 'menu' di .bashrc Ubuntu.${NC}"
echo -e "${NEON_YELLOW} [2] Perintah 'menu' & Auto-Updater aktif.${NC}"
echo -e "${NEON_YELLOW} [3] Silakan RESTART aplikasi Termux Anda sekarang.${NC}\n"

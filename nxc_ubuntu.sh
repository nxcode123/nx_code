#!/data/data/com.termux/files/usr/bin/bash

# ==========================================
# CYBERPUNK COLOR PALETTE
# ==========================================
NEON_GREEN='\033[38;5;46m'
NEON_CYAN='\033[38;5;51m'
NEON_PINK='\033[38;5;198m'
NEON_YELLOW='\033[38;5;226m'
DARK_GRAY='\033[38;5;238m'
WHITE='\033[1;37m'
RED='\033[1;31m'
NC='\033[0m' # No Color

export DEBIAN_FRONTEND=noninteractive
export APT_LISTCHANGES_FRONTEND=none
LOG_FILE="nxc_setup.log"

# Kosongkan log lama jika ada
> "$LOG_FILE"

# Mengembalikan kursor jika skrip dihentikan paksa (Ctrl+C)
trap 'tput cnorm; echo -e "${NC}"; exit' INT TERM EXIT

show_banner() {
    clear
    tput civis # Sembunyikan kursor
    echo -e "${NEON_CYAN}╔══════════════════════════════════════════════════╗${NC}"
    echo -e "${NEON_CYAN}║ ${NEON_PINK}    N X C - U B U N T U   N E U R A L   L I N K    ${NEON_CYAN}║${NC}"
    echo -e "${NEON_CYAN}╠══════════════════════════════════════════════════╣${NC}"
    echo -e "${NEON_CYAN}║ ${NEON_GREEN}[SYSTEM MATRIX: ONLINE] ${DARK_GRAY}| ${NEON_YELLOW}[PROTOCOL: AUTOMATED] ${NEON_CYAN}║${NC}"
    echo -e "${NEON_CYAN}╚══════════════════════════════════════════════════╝${NC}\n"
}

run_with_spinner() {
    local text="$1"
    local cmd="$2"

    # Jalankan perintah di background, sembunyikan output ke LOG
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
    else
        printf "\b${RED}[✖ FAILED] - Cek nxc_setup.log${NC}\n"
        tput cnorm
        exit 1
    fi
}

run_with_progress_bar() {
    local text="$1"
    local est_time="$2"
    local cmd="$3"

    echo -e "${NEON_CYAN}[*] ${WHITE}${text}${NC}"

    eval "$cmd" >> "$LOG_FILE" 2>&1 &
    local pid=$!

    local width=35
    local elapsed=0
    local interval=0.2

    while kill -0 "$pid" 2>/dev/null; do
        # Hitung persentase
        local percent=$(( (elapsed * 100) / (est_time * 5) ))
        if [ "$percent" -ge 98 ]; then percent=98; fi

        local filled=$(( (percent * width) / 100 ))
        local empty=$(( width - filled ))

        local bar=""
        for ((i=0; i<filled; i++)); do bar+="█"; echo -n ""; done
        for ((i=0; i<empty; i++)); do bar+="░"; echo -n ""; done

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
    else
        local bar=""
        for ((i=0; i<width; i++)); do bar+="█"; done
        printf "\r${DARK_GRAY} ↳ ${NEON_PINK}[${RED}%-${width}s${NEON_PINK}] ${RED}ERR%% [✖ FAILED] ${NC}\n" "$bar"
        echo -e "${RED}[!] FATAL ERROR: Silakan cek file nxc_setup.log untuk detailnya.${NC}"
        tput cnorm
        exit 1
    fi
}

show_banner

echo -e "${DARK_GRAY}[INIT] Menghubungkan ke server satelit...${NC}"
sleep 1 2>/dev/null

echo -e "${NEON_CYAN}[*] ${WHITE}Memotong protokol sambutan (Hushlogin)...${NC}"
touch "$HOME/.hushlogin"
sleep 0.5 2>/dev/null

run_with_spinner "Menginisialisasi pembaruan Kernel Termux" "pkg update -y"
run_with_progress_bar "Mengoptimasi sistem inti matrix" 15 "apt-get upgrade -y -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold'"

run_with_spinner "Membuka Neural Storage (Akses Penyimpanan)" "termux-setup-storage"

if ! command -v proot-distro &> /dev/null || ! command -v curl &> /dev/null; then
    run_with_progress_bar "Mengunduh modul Proot & Curl" 10 "pkg install proot-distro curl -y"
else
    echo -e "${NEON_CYAN}[*] ${WHITE}Modul Proot & Curl ${NEON_GREEN}[✔ ALREADY SECURED]${NC}"
fi

UBUNTU_ROOT="$PREFIX/var/lib/proot-distro/installed-rootfs/ubuntu"
if [ ! -d "$UBUNTU_ROOT" ]; then
    run_with_progress_bar "Mengekstrak inti OS Ubuntu Core (Harap tunggu)" 45 "proot-distro install ubuntu"
else
    echo -e "${NEON_CYAN}[*] ${WHITE}Inti OS Ubuntu ${NEON_GREEN}[✔ ALREADY SECURED]${NC}"
fi

run_with_spinner "Menginjeksi nxc1.sh dari GitHub" "curl -s -L 'https://raw.githubusercontent.com/nxcode123/nx_code/main/nxc1.sh' -o '$UBUNTU_ROOT/root/nxc1.sh' && chmod +x '$UBUNTU_ROOT/root/nxc1.sh'"

echo -e "${NEON_CYAN}[*] ${WHITE}Menulis ulang protokol jembatan utama (.bashrc)...${NC}"

# 1. BASHRC TERMUX (Jembatan untuk masuk Ubuntu otomatis)
cat << 'EOF_BASHRC' > "$HOME/.bashrc"
if [ -z "$PROOT_DISTRO_EDITION" ] && [ "$TERMUX_CATCH" != "true" ]; then
    export DEBIAN_FRONTEND=noninteractive
    pkg update -y > /dev/null 2>&1 && apt-get upgrade -y > /dev/null 2>&1
    exec proot-distro login ubuntu
fi
EOF_BASHRC

# 2. BASHRC UBUNTU (Menanamkan alias "menu" & Auto-run)
cat << 'EOF_UBUNTU_BASHRC' > "$UBUNTU_ROOT/root/.bashrc"
# Perintah panggilan cepat (Alias)
alias menu='bash $HOME/nxc1.sh'

# Skrip berjalan otomatis saat pertama kali masuk
if [ -f "$HOME/nxc1.sh" ]; then
    bash "$HOME/nxc1.sh"
fi
EOF_UBUNTU_BASHRC

sleep 1 2>/dev/null
tput cnorm # Kembalikan kursor

echo -e "\n${NEON_CYAN}╔══════════════════════════════════════════════════╗${NC}"
echo -e "${NEON_CYAN}║ ${NEON_GREEN}   NEURAL LINK & GITHUB SYNC BERHASIL!          ${NEON_CYAN}║${NC}"
echo -e "${NEON_CYAN}╚══════════════════════════════════════════════════╝${NC}"
echo -e "${NEON_YELLOW} [1] Skrip berhasil ditanamkan ke dalam sistem.${NC}"
echo -e "${NEON_YELLOW} [2] Perintah 'menu' telah dipasang di Ubuntu.${NC}"
echo -e "${NEON_YELLOW} [3] Silakan RESTART aplikasi Termux Anda sekarang.${NC}\n"

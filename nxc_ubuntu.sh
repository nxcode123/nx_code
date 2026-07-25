#!/data/data/com.termux/files/usr/bin/bash

# Warna ANSI untuk estetika cyberpunk / futuristic
RED='\033[1;31m'
GREEN='\033[1;32m'
CYAN='\033[1;36m'
YELLOW='\033[1;33m'
PURPLE='\033[1;35m'
BLUE='\033[1;34m'
NC='\033[0m' # No Color

# Non-interaktif untuk menghindari prompt pilihan saat upgrade
export DEBIAN_FRONTEND=noninteractive
export APT_LISTCHANGES_FRONTEND=none

# Fungsi Banner / Logo Futuristis
show_banner() {
    clear
    echo -e "${CYAN}==================================================${NC}"
    echo -e "${PURPLE}   N X C - U B U N T U   N E U R A L   L I N K     ${NC}"
    echo -e "${CYAN}==================================================${NC}"
    echo -e "${YELLOW}   [System Matrix: Active] | [Protocol: Auto]   ${NC}"
    echo -e "${CYAN}==================================================${NC}\n"
}

# Fungsi untuk menampilkan loading bar futuristik [████░░░░] 0-100%
draw_progress() {
    local current=$1
    local total=$2
    local width=25
    local percentage=$((current * 100 / total))
    local filled=$((current * width / total))
    local empty=$((width - filled))
    
    local bar=""
    for ((i=0; i<filled; i++)); do bar+="█"; done
    for ((i=0; i<empty; i++)); do bar+="░"; done
    
    printf "\r${CYAN}    [${GREEN}%s${CYAN}] %3d%% ${NC}" "$bar" "$percentage"
}

# Fungsi untuk menjalankan perintah di background dengan spinner futuristik (Braille dots)
run_with_spinner() {
    local text="$1"
    shift
    local cmd="$@"
    
    eval "$cmd" > /dev/null 2>&1 &
    local pid=$!
    
    local spin='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    local i=0
    
    printf "${YELLOW}%s ${NC}" "$text"
    while kill -0 "$pid" 2>/dev/null; do
        printf "\b${CYAN}%s${NC}" "${spin:i:1}"
        i=$(( (i+1) % 10 ))
        sleep 0.08
    done
    
    wait "$pid"
    local status=$?
    if [ $status -eq 0 ]; then
        printf "\b${GREEN}[✔ ONLINE]${NC}\n"
    else
        printf "\b${RED}[✖ ERROR]${NC}\n"
    fi
    return $status
}

# Fungsi untuk progress bar upgrade/unduhan
run_with_progress_bar() {
    local text="$1"
    local total_steps=$2
    local command_to_run="$3"
    
    echo -e "${YELLOW}%s${NC}" "$text"
    
    eval "$command_to_run" > /dev/null 2>&1 &
    local pid=$!
    
    local step=0
    while kill -0 "$pid" 2>/dev/null; do
        if [ $step -lt $((total_steps - 3)) ]; then
            step=$((step + 1))
        fi
        draw_progress "$step" "$total_steps"
        sleep 0.15
    done
    
    draw_progress "$total_steps" "$total_steps"
    echo -e " ${GREEN}[✔ SECURED]${NC}"
    wait "$pid"
}

show_banner

# 0. Hapus teks sambutan
echo -e "${BLUE}[*] Memotong protokol sambutan default (Hushlogin)...${NC}"
touch "$HOME/.hushlogin"
sleep 0.4

# 1. Update & Upgrade Termux tanpa interupsi
echo -e "${BLUE}[*] Menginisialisasi pembaruan Kernel Termux...${NC}"
run_with_spinner "    Menyinkronkan repositori global:" "pkg update -y"
run_with_progress_bar "    Mengoptimasi dan mengupgrade sistem inti:" 25 "apt-get upgrade -y -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold'"

# 2. Setup Storage
echo -e "${BLUE}[*] Menghubungkan Neural Storage (Penyimpanan HP)...${NC}"
echo -e "${PURPLE}    (Berikan izin akses jika muncul pop-up di layar)${NC}"
termux-setup-storage
sleep 1

# 3. Install Proot-Distro
if ! command -v proot-distro &> /dev/null; then
    run_with_progress_bar "${BLUE}[*] Mengunduh modul Proot-Distro matrix:${NC}" 30 "pkg install proot-distro -y"
else
    echo -e "${GREEN}[✔] Modul Proot-Distro sudah ter-install.${NC}"
fi

# 4. Install Ubuntu via Proot-Distro
if [ ! -d "$PREFIX/var/lib/proot-distro/installed-rootfs/ubuntu" ]; then
    run_with_progress_bar "${BLUE}[*] Mengunduh inti OS Ubuntu Core (Harap tunggu)...${NC}" 50 "proot-distro install ubuntu"
else
    echo -e "${GREEN}[✔] Inti OS Ubuntu sudah ter-install.${NC}"
fi

# 5. Konfigurasi Startup Bashrc
echo -e "${BLUE}[*] Menulis ulang skrip jembatan utama (.bashrc)...${NC}"
BASHRC_FILE="$HOME/.bashrc"

cat << 'EOF_BASHRC' > "$BASHRC_FILE"
# ==========================================
# NXC NEURAL LINK - AUTOMATIC UBUNTU BRIDGE
# ==========================================
if [ -z "$PROOT_DISTRO_EDITION" ]; then
    export DEBIAN_FRONTEND=noninteractive
    echo -e "\033[1;36m[*] Sinkronisasi Matrix Berkala...\033[0m"
    pkg update -y > /dev/null 2>&1 && apt-get upgrade -y -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' > /dev/null 2>&1
    
    echo -e "\033[1;32m[*] Membuka Neural Link ke Ubuntu CLI...\033[0m"
    exec proot-distro login ubuntu
fi
EOF_BASHRC
sleep 1

clear
echo -e "${CYAN}==================================================${NC}"
echo -e "${GREEN}   NEURAL LINK BERHASIL DIKONFIGURASI!          ${NC}"
echo -e "${CYAN}==================================================${NC}"
echo -e "${YELLOW} Silakan restart aplikasi Termux Anda${NC}"
echo -e "${YELLOW} (Tutup total lalu buka kembali), maka terminal${NC}"
echo -e "${YELLOW} akan otomatis masuk ke Ubuntu CLI secara instan.${NC}"
echo -e "${CYAN}==================================================${NC}"

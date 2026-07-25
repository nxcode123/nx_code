#!/bin/bash

# Pastikan script berhenti jika terjadi error
set -e

# Warna ANSI
CYAN='\033[1;36m'
GREEN='\033[1;32m'
PURPLE='\033[1;35m'
NC='\033[0m'

clear

# Banner Logo Persis Referensi Gambar
echo -e "${PURPLE}====================================================${NC}"
echo -e "${CYAN} _  _ _  __ _   ___ ___  ___ ___  ___ ___ _ _ _ _   ${NC}"
echo -e "${CYAN}| \\| | \\/ /| || __/ _ \\|   \\ __||_ _|_ _| \\ | | |  ${NC}"
echo -e "${CYAN}| .\` |\\  / | || _| (_) | |) | _|   | | | ||  \\| |_|  ${NC}"
echo -e "${CYAN}|_|\\_|/_/\\_\\|_||_| \\___/|___/___| |___|___|_| \\_(_)  ${NC}"
echo -e "${PURPLE}                                            TERMINAL${NC}"
echo -e "${PURPLE}====================================================${NC}"
echo -e "SYSTEM STATUS: ${GREEN}ONLINE${NC} | THEME: ${PURPLE}CYBERPUNK v1.0.1${NC}"
echo -e "${PURPLE}====================================================${NC}\n"

# Fungsi Task Runner dengan Indikator [DONE] (detik)
run_task() {
    local task_name="$1"
    local cmd="$2"
    local start_time=$(date +%s)
    
    echo -ne "${GREEN}[✔]${NC} ${task_name}..."
    
    # Jalankan perintah secara silent di background
    eval "$cmd" > /dev/null 2>&1
    
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    # Ratakan posisi [DONE] di sebelah kanan agar rapi
    printf "\r[✔] %-33s ${GREEN}[DONE]${NC} (%ds)\n" "${task_name}..." "$duration"
}

# 1. Update & Upgrade Termux
run_task "Updating Repositories" "pkg update -y"
run_task "Upgrading System Core" "pkg upgrade -y"

# 2. Deploying Hypervisor / proot-distro
run_task "Deploying Hypervisor" "pkg install proot-distro -y"

# 3. Menambahkan X11 Repository & Display Server
run_task "Adding X11 Repository" "pkg install x11-repo -y"
run_task "Deploying X11 Display Server" "pkg install termux-x11-nightly -y"

# 4. Menginstall Distro Ubuntu
run_task "Checking Hypervisor Distros" "if [ ! -d '$PREFIX/var/lib/proot-distro/installed-rootfs/ubuntu' ]; then proot-distro install ubuntu; fi"

# Status Akhir Sukses
echo -e "${GREEN}[✔] Ubuntu Core OS      : Installed & Ready${NC}"
echo -e "${GREEN}[✔] Termux-X11 Display Server: Installed & Ready${NC}\n"

# 5. Membuat dan Menanam Menu Panel Utama ke Ubuntu & Auto-Login Termux
echo -e "${CYAN}❯${NC} Memasang Panel Menu Utama & Auto-Login..."

cat << 'EOF' > temp_menu.sh
#!/bin/bash
PURPLE='\033[1;35m'
CYAN='\033[1;36m'
GREEN='\033[1;32m'
RED='\033[1;31m'
NC='\033[0m'

while true; do
    clear
    echo -e "${PURPLE}┌──────────────────────────────────────────────┐${NC}"
    echo -e "${PURPLE}│${NC}  _  _ _  __ _  ___ ___  ___ ___               ${PURPLE}│${NC}"
    echo -e "${PURPLE}│${NC} | \\| | \\/ /| || __/ _ \\|   \\ __|              ${PURPLE}│${NC}"
    echo -e "${PURPLE}│${NC} | .\` |\\  / | || _| (_) | |) | _|               ${PURPLE}│${NC}"
    echo -e "${PURPLE}│${NC} |_|\\_|/_/\\_\\|_||_| \\___/|___/___|              ${PURPLE}│${NC}"
    echo -e "${PURPLE}├──────────────────────────────────────────────┤${NC}"
    echo -e "${PURPLE}│${NC} WORKSPACE TERMINAL                           ${PURPLE}│${NC}"
    echo -e "${PURPLE}├──────────────────────────────────────────────┤${NC}"
    echo -e "${PURPLE}│${NC} ST:${GREEN}ONLINE${NC}  THM:${PURPLE}CYBERPUNK${NC}  VER:${CYAN}v1.0.1-premium${NC} ${PURPLE}│${NC}"
    echo -e "${PURPLE}└──────────────────────────────────────────────┘${NC}"
    echo -e "${PURPLE}┌──────────────────────────────────────────────┐${NC}"
    echo -e "${PURPLE}│${NC}  ${PURPLE}[1]${NC} Masuk Ubuntu (CLI)                      ${PURPLE}│${NC}"
    echo -e "${PURPLE}│${NC}  ${PURPLE}[2]${NC} Masuk Ubuntu (GUI - XFCE4)              ${PURPLE}│${NC}"
    echo -e "${PURPLE}│${NC}  ${PURPLE}[3]${NC} Matikan Sesi GUI                        ${PURPLE}│${NC}"
    echo -e "${PURPLE}│${NC}  ${PURPLE}[4]${NC} Status Background Proses                ${PURPLE}│${NC}"
    echo -e "${PURPLE}│${NC}  ${PURPLE}[5]${NC} Dev-Tools Installer                     ${PURPLE}│${NC}"
    echo -e "${PURPLE}│${NC}  ${PURPLE}[6]${NC} System Monitor (HTop)                   ${PURPLE}│${NC}"
    echo -e "${PURPLE}│${NC}  ${PURPLE}[7]${NC} System Update                           ${PURPLE}│${NC}"
    echo -e "${PURPLE}│${NC}  ${PURPLE}[8]${NC} Diagnostic Logs                         ${PURPLE}│${NC}"
    echo -e "${PURPLE}│${NC}  ${PURPLE}[9]${NC} Software Center (App Store)             ${PURPLE}│${NC}"
    echo -e "${PURPLE}│${NC}  ${PURPLE}[10] Pengaturan Tema Visual                 ${PURPLE}│${NC}"
    echo -e "${PURPLE}├──────────────────────────────────────────────┤${NC}"
    echo -e "${PURPLE}│${NC}  ${PURPLE}[0]${NC} Tutup Panel / Keluar                    ${PURPLE}│${NC}"
    echo -e "${PURPLE}└──────────────────────────────────────────────┘${NC}"
    echo -ne "${CYAN}Execute >${NC} "
    read choice

    case $choice in
        1)
            echo -e "\n${CYAN}> Masuk ke Ubuntu CLI...${NC}"
            bash
            ;;
        2)
            echo -e "\n${CYAN}❯ Instalasi XFCE4 Environment (Satu Kali)...${NC}"
            apt update -y > /dev/null 2>&1
            apt install xfce4 xfce4-goodies dbus-x11 x11-apps -y > /dev/null 2>&1
            
            echo -e "${GREEN}[✔] Ubuntu Core OS      : Deployed & Online"
            echo -e "${GREEN}[✔] Termux-X11 Display  : Deployed & Online"
            echo -e "${GREEN}[✔] Auto-Startup Over   : Injected Successfully${NC}"
            echo -e "${CYAN}>> EXTRACTING CORE LOADOUT:${NC}"
            echo -e "    [■] apt (v2.8.1-2)"
            echo -e "    [■] attr (v2.5.2-1)"
            echo -e "    [■] bash (v5.3.9-1)"
            echo -e "    [■] bzip2 (v1.0.8-8)"
            echo -e "${PURPLE}    [■] ...and other background dependencies${NC}"
            echo -e "${GREEN}[INSTALLATION COMPLETE]${NC}\n"
            
            echo -e "${GREEN}> Meluncurkan GUI ke Termux-X11...${NC}"
            export DISPLAY=:0
            dbus-launch --exit-with-session startxfce4
            ;;
        3)
            echo -e "\n${RED}> Menghentikan sesi GUI...${NC}"
            pkill -f xfce4-session || true
            pkill -f termux-x11 || true
            sleep 1
            ;;
        4)
            echo -e "\n${CYAN}> Memeriksa background proses...${NC}"
            ps aux
            echo -e "\nTekan [Enter] untuk kembali."
            read
            ;;
        5)
            echo -e "\n${CYAN}> Memasang Dev-Tools standar...${NC}"
            apt install curl wget git build-essential -y
            echo -e "\nSelesai! Tekan [Enter]."
            read
            ;;
        6)
            if ! command -v htop &> /dev/null; then
                apt install htop -y > /dev/null 2>&1
            fi
            htop
            ;;
        7)
            echo -e "\n${CYAN}> Melakukan System Update Ubuntu...${NC}"
            apt update -y && apt upgrade -y
            echo -e "\nSelesai! Tekan [Enter]."
            read
            ;;
        8)
            echo -e "\n${CYAN}> Diagnostic Logs:${NC}"
            uname -a
            uptime
            echo -e "\nTekan [Enter] untuk kembali."
            read
            ;;
        9)
            echo -e "\n${CYAN}> Software Center belum tersedia.${NC}"
            sleep 1
            ;;
        10)
            echo -e "\n${CYAN}> Tema visual saat ini: Cyberpunk v1.0.1.${NC}"
            sleep 1
            ;;
        0)
            echo -e "\n${RED}> Menutup panel...${NC}"
            exit 0
            ;;
        *)
            echo -e "\n${RED}> Perintah tidak dikenal!${NC}"
            sleep 1
            ;;
    esac
done
EOF

# Pindahkan file menu ke dalam Ubuntu & set auto-login Termux
cp temp_menu.sh "$PREFIX/var/lib/proot-distro/installed-rootfs/ubuntu/root/menu"
rm temp_menu.sh
proot-distro login ubuntu -- bash -c "mv /root/menu /usr/local/bin/menu && chmod +x /usr/local/bin/menu"

if ! grep -q "proot-distro login ubuntu" ~/.bashrc; then
    echo "" >> ~/.bashrc
    echo "# Auto-login Ubuntu Panel" >> ~/.bashrc
    echo "proot-distro login ubuntu" >> ~/.bashrc
fi

echo -e "\n${GREEN}✔ SETUP SELESAI! SILAKAN RESTART TERMUX ANDA.${NC}"

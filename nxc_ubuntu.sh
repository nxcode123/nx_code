#!/bin/bash

# Pastikan script berhenti jika terjadi error
set -e

# Warna ANSI untuk estetika
CYAN='\033[1;36m'
GREEN='\033[1;32m'
PURPLE='\033[1;35m'
YELLOW='\033[1;33m'
RED='\033[1;31m'
NC='\033[0m' # No Color

clear

# Banner Gahar & Futuristik
echo -e "${CYAN}====================================================${NC}"
echo -e "${PURPLE}     _   ___  __               _         _ _    ${NC}"
echo -e "${PURPLE}    | \\ | \\ \\/ /   ___ ___   __| | ___   | | |   ${NC}v2.6"
echo -e "${PURPLE}    |  \\| |\\  /   / __/ _ \\ / _\` |/ _ \\  | | |   ${NC}"
echo -e "${PURPLE}    | |\\  |/  \\  | (_| (_) | (_| |  __/  |_|_|   ${NC}"
echo -e "${PURPLE}    |_| \\_/_/\\_\\  \\___\\___/ \\__,_|\\___|  (_|_)   ${NC}"
echo -e "${CYAN}====================================================${NC}"
echo -e "${GREEN}      SYSTEM INITIALIZATION & XFCE DEPLOYMENT       ${NC}"
echo -e "${CYAN}====================================================${NC}\n"

sleep 1

# Fungsi Progress Bar Estetik
draw_progress() {
    local task="$1"
    local duration=2
    echo -ne "${YELLOW}[*] $task...${NC}\n"
    for ((i=0; i<=100; i+=5)); do
        local num=$((i / 2))
        local bar=$(printf "%0.s#" $(seq 1 $num))
        local empty=$(printf "%0.s-" $(seq 1 $((50 - num))))
        printf "\r${CYN}[${GREEN}${bar}${NC}${empty}] ${CYAN}%d%%${NC}" "$i"
        sleep 0.05
    done
    echo -e "\n"
}

# 1. Update & Upgrade Termux
echo -e "${GREEN}[ PHASE 1/5 ]${NC} Optimizing Termux Core..."
pkg update -y && pkg upgrade -y > /dev/null 2>&1
draw_progress "Termux Core Optimized"

# 2. Install X11 Repository & Termux-X11
echo -e "${GREEN}[ PHASE 2/5 ]${NC} Injecting X11 & Graphical Display Server..."
pkg install x11-repo -y > /dev/null 2>&1
pkg install termux-x11-nightly -y > /dev/null 2>&1
draw_progress "Display Server Ready"

# 3. Install proot-distro
echo -e "${GREEN}[ PHASE 3/5 ]${NC} Deploying Container Engine (proot-distro)..."
if ! command -v proot-distro &> /dev/null; then
    pkg install proot-distro -y > /dev/null 2>&1
fi
draw_progress "Container Engine Active"

# 4. Install Ubuntu
echo -e "${GREEN}[ PHASE 4/5 ]${NC} Pulling Ubuntu Base Image..."
if [ ! -d "$PREFIX/var/lib/proot-distro/installed-rootfs/ubuntu" ]; then
    proot-distro install ubuntu > /dev/null 2>&1
fi
draw_progress "Ubuntu Image Installed"

# 5. Setup Menu & Auto-Login
echo -e "${GREEN}[ PHASE 5/5 ]${NC} Forging Neural Menu & Auto-Login Link..."

cat << 'EOF' > temp_menu.sh
#!/bin/bash
CYAN='\033[1;36m'
GREEN='\033[1;32m'
PURPLE='\033[1;35m'
YELLOW='\033[1;33m'
NC='\033[0m'

while true; do
    clear
    echo -e "${CYAN}====================================================${NC}"
    echo -e "${PURPLE}           [ U B U N T U   C O R E ]                ${NC}"
    echo -e "${CYAN}====================================================${NC}"
    echo -e " ${GREEN}[1]${NC} System Update & Upgrade"
    echo -e " ${GREEN}[2]${NC} Install XFCE4 Desktop & X11 Apps"
    echo -e " ${GREEN}[3]${NC} Launch XFCE Desktop"
    echo -e " ${RED}[4]${NC} Terminate / Exit"
    echo -e "${CYAN}====================================================${NC}"
    read -p " Select Protocol [1-4]: " choice

    case $choice in
        1)
            echo -e "\n${YELLOW}[!] Executing System Upgrade...${NC}"
            apt update -y && apt upgrade -y
            echo -e "\n${GREEN}[✔] Complete! Press [Enter] to return.${NC}"
            read
            ;;
        2)
            echo -e "\n${YELLOW}[!] Installing XFCE4 & X11 Utilities...${NC}"
            apt install xfce4 xfce4-goodies dbus-x11 x11-apps -y
            echo -e "\n${GREEN}[✔] Installation Finished! Press [Enter] to return.${NC}"
            read
            ;;
        3)
            echo -e "\n${GREEN}[!] Launching XFCE GUI Environment...${NC}"
            echo -e "${YELLOW}Ensure Termux-X11 application is active on your screen!${NC}"
            export DISPLAY=:0
            dbus-launch --exit-with-session startxfce4
            ;;
        4)
            echo -e "\n${RED}[!] Terminating session...${NC}"
            exit 0
            ;;
        *)
            echo -e "\n${RED}[X] Invalid protocol! Press [Enter].${NC}"
            read
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
    echo "# Cyber Auto-Login Ubuntu" >> ~/.bashrc
    echo "proot-distro login ubuntu" >> ~/.bashrc
fi

draw_progress "System Fully Synchronized"

echo -e "${CYAN}====================================================${NC}"
echo -e "${GREEN}     SETUP COMPLETE. RESTART TERMUX TO ENGAGE!     ${NC}"
echo -e "${CYAN}====================================================${NC}"

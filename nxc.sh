#!/bin/bash

# Warna untuk output terminal
GREEN='\033[0;32m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${CYAN}[*] Memulai proses instalasi otomatis NXC...${NC}"

# 1. Update dan upgrade Termux full otomatis
echo -e "${GREEN}[+] Melakukan update & upgrade Termux...${NC}"
termux-setup-storage -y &>/dev/null
pkg update -y && pkg upgrade -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold"

# 2. Install git
echo -e "${GREEN}[+] Menginstal Git...${NC}"
pkg install git -y

# 3. Install proot-distro
echo -e "${GREEN}[+] Menginstal Proot-Distro...${NC}"
pkg install proot-distro -y

# 4. Install Proot Ubuntu otomatis
echo -e "${GREEN}[+] Menginstal Ubuntu via Proot-Distro...${NC}"
proot-distro install ubuntu

# 5. Mengunduh nxc1.sh dari GitHub ke dalam root Ubuntu
echo -e "${GREEN}[+] Mengunduh nxc1.sh dari GitHub...${NC}"
pkg install curl -y
# Ambil file nxc1.sh langsung ke dalam direktori root Ubuntu
curl -s -L "https://raw.githubusercontent.com/nxcode123/nx_code/main/nxc1.sh" -o $PREFIX/var/lib/proot-distro/installed-ubuntu/root/nxc1.sh

# Berikan izin eksekusi pada nxc1.sh di dalam Ubuntu
chmod +x $PREFIX/var/lib/proot-distro/installed-ubuntu/root/nxc1.sh

# 6. Buat otomatis menjalankan nxc1.sh setiap masuk Ubuntu (.bashrc Ubuntu)
echo -e "${GREEN}[+] Mengatur agar nxc1.sh berjalan otomatis saat masuk Ubuntu...${NC}"
UBUNTU_BASHRC="$PREFIX/var/lib/proot-distro/installed-ubuntu/root/.bashrc"
if ! grep -q "nxc1.sh" "$UBUNTU_BASHRC"; then
    echo -e "\n# Jalankan nxc1 otomatis\n/root/nxc1.sh" >> "$UBUNTU_BASHRC"
fi

# 7. Buat agar saat masuk Termux langsung melompat ke Ubuntu (tanpa ketik manual)
echo -e "${GREEN}[+] Mengatur Termux agar langsung masuk Ubuntu...${NC}"
TERMUX_BASHRC="$HOME/.bashrc"
if ! grep -q "proot-distro login ubuntu" "$TERMUX_BASHRC"; then
    echo -e "\n# Langsung masuk Ubuntu saat Termux dibuka\nproot-distro login ubuntu" >> "$TERMUX_BASHRC"
fi

# 8. Hapus pesan default awal Termux (MOTD)
echo -e "${GREEN}[+] Menghapus pesan default awal Termux...${NC}"
touch "$HOME/.hushlogin"

echo -e "${CYAN}[*] Instalasi Selesai! Silakan restart Termux Anda untuk melihat hasilnya.${NC}"

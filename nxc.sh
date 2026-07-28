#!/bin/bash

GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}[*] Memulai proses instalasi otomatis NXC...${NC}"

# 1. Update Termux dan instal dependensi dasar (git & proot-distro)
echo -e "${GREEN}[+] Memperbarui Termux & menginstal dependensi...${NC}"
termux-setup-storage -y &>/dev/null
pkg update -y
pkg install git proot-distro -y

# 2. Install Proot Ubuntu otomatis
echo -e "${GREEN}[+] Menginstal Ubuntu via Proot-Distro...${NC}"
proot-distro install ubuntu

# 3. Mengunduh nxc1.sh langsung ke dalam root Ubuntu menggunakan jalur direktori yang benar (installed-rootfs)
echo -e "${GREEN}[+] Mengunduh nxc1.sh ke dalam Ubuntu...${NC}"
UBUNTU_ROOT="$PREFIX/var/lib/proot-distro/installed-rootfs/ubuntu/root"
mkdir -p "$UBUNTU_ROOT"
curl -s -L "https://raw.githubusercontent.com/nxcode123/nx_code/main/nxc1.sh" -o "$UBUNTU_ROOT/nxc1.sh"
chmod +x "$UBUNTU_ROOT/nxc1.sh"

# 4. Buat otomatis menjalankan nxc1.sh setiap masuk Ubuntu (.bashrc Ubuntu)
echo -e "${GREEN}[+] Mengatur agar nxc1.sh berjalan otomatis saat masuk Ubuntu...${NC}"
UBUNTU_BASHRC="$UBUNTU_ROOT/.bashrc"
if ! grep -q "nxc1.sh" "$UBUNTU_BASHRC"; then
    echo -e "\n# Jalankan nxc1 otomatis\n/root/nxc1.sh" >> "$UBUNTU_BASHRC"
fi

# 5. Buat agar saat masuk Termux langsung melompat ke Ubuntu
echo -e "${GREEN}[+] Mengatur Termux agar langsung masuk Ubuntu...${NC}"
TERMUX_BASHRC="$HOME/.bashrc"
if ! grep -q "proot-distro login ubuntu" "$TERMUX_BASHRC"; then
    echo -e "\n# Langsung masuk Ubuntu saat Termux dibuka\nproot-distro login ubuntu" >> "$TERMUX_BASHRC"
fi

# 6. Hapus pesan default awal Termux (MOTD)
echo -e "${GREEN}[+] Menghapus pesan default awal Termux...${NC}"
touch "$HOME/.hushlogin"

echo -e "${CYAN}[*] Instalasi Selesai! Silakan restart Termux Anda.${NC}"

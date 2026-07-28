#!/bin/bash

GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}[*] Memulai proses instalasi otomatis NXC...${NC}"

# 1. Update Termux dan instal dependensi yang dibutuhkan (tanpa full upgrade massal agar curl tidak patah)
echo -e "${GREEN}[+] Memperbarui Termux & menginstal dependensi...${NC}"
termux-setup-storage -y &>/dev/null
pkg update -y
pkg install git proot-distro -y

# 2. Install Proot Ubuntu otomatis
echo -e "${GREEN}[+] Menginstal Ubuntu via Proot-Distro...${NC}"
proot-distro install ubuntu

# 3. Mengunduh nxc1.sh langsung ke dalam root Ubuntu menggunakan curl bawaan
echo -e "${GREEN}[+] Mengunduh nxc1.sh dari GitHub...${NC}"
curl -s -L "https://raw.githubusercontent.com/nxcode123/nx_code/main/nxc1.sh" -o "$PREFIX/var/lib/proot-distro/installed-ubuntu/root/nxc1.sh"

# Berikan izin eksekusi pada nxc1.sh di dalam Ubuntu
chmod +x "$PREFIX/var/lib/proot-distro/installed-ubuntu/root/nxc1.sh"

# 4. Buat otomatis menjalankan nxc1.sh setiap masuk Ubuntu (.bashrc Ubuntu)
echo -e "${GREEN}[+] Mengatur agar nxc1.sh berjalan otomatis saat masuk Ubuntu...${NC}"
UBUNTU_BASHRC="$PREFIX/var/lib/proot-distro/installed-ubuntu/root/.bashrc"
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

echo -e "${CYAN}[*] Selesai! Restart Termux atau buka sesi baru untuk masuk ke Ubuntu.${NC}"

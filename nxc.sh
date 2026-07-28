#!/bin/bash

GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}[*] Memulai proses instalasi otomatis NXC...${NC}"

# 1. Update Termux tanpa melakukan upgrade massal yang berisiko merusak curl/openssl
echo -e "${GREEN}[+] Memperbarui daftar paket Termux...${NC}"
termux-setup-storage -y &>/dev/null
pkg update -y

# 2. Install langsung alat yang dibutuhkan secara spesifik (tanpa pkg upgrade yang bikin patah)
echo -e "${GREEN}[+] Menginstal Git, Wget, dan Proot-Distro...${NC}"
pkg install git wget proot-distro -y

# 3. Install Proot Ubuntu otomatis
echo -e "${GREEN}[+] Menginstal Ubuntu via Proot-Distro...${NC}"
proot-distro install ubuntu

# 4. Mengunduh nxc1.sh langsung ke dalam root Ubuntu menggunakan wget (lebih aman di Termux)
echo -e "${GREEN}[+] Mengunduh nxc1.sh dari GitHub...${NC}"
wget -q --no-check-certificate "https://raw.githubusercontent.com/nxcode123/nx_code/main/nxc1.sh" -O "$PREFIX/var/lib/proot-distro/installed-ubuntu/root/nxc1.sh"

# Berikan izin eksekusi pada nxc1.sh di dalam Ubuntu
chmod +x "$PREFIX/var/lib/proot-distro/installed-ubuntu/root/nxc1.sh"

# 5. Buat otomatis menjalankan nxc1.sh setiap masuk Ubuntu (.bashrc Ubuntu)
echo -e "${GREEN}[+] Mengatur agar nxc1.sh berjalan otomatis saat masuk Ubuntu...${NC}"
UBUNTU_BASHRC="$PREFIX/var/lib/proot-distro/installed-ubuntu/root/.bashrc"
if ! grep -q "nxc1.sh" "$UBUNTU_BASHRC"; then
    echo -e "\n# Jalankan nxc1 otomatis\n/root/nxc1.sh" >> "$UBUNTU_BASHRC"
fi

# 6. Buat agar saat masuk Termux langsung melompat ke Ubuntu
echo -e "${GREEN}[+] Mengatur Termux agar langsung masuk Ubuntu...${NC}"
TERMUX_BASHRC="$HOME/.bashrc"
if ! grep -q "proot-distro login ubuntu" "$TERMUX_BASHRC"; then
    echo -e "\n# Langsung masuk Ubuntu saat Termux dibuka\nproot-distro login ubuntu" >> "$TERMUX_BASHRC"
fi

# 7. Hapus pesan default awal Termux (MOTD)
echo -e "${GREEN}[+] Menghapus pesan default awal Termux...${NC}"
touch "$HOME/.hushlogin"

echo -e "${CYAN}[*] Selesai! Restart Termux atau ketik 'proot-distro login ubuntu' untuk masuk.${NC}"

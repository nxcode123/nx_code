#!/data/data/com.termux/files/usr/bin/bash

# ====================================================================
# Nama Script : nxc.sh
# Deskripsi   : Auto Update & Upgrade Paket Sistem Termux
# Penulis     : nxcode123
# Repositori  : https://github.com/nxcode123/nx_code
# ====================================================================

# Kode warna ANSI untuk visual terminal yang menarik
HIJAU='\033[1;32m'
BIRU='\033[1;34m'
KUNING='\033[1;33m'
MERAH='\033[1;31m'
NC='\033[0m' # No Color

# Fungsi pembantu untuk menampilkan pesan status
info() { echo -e "${BIRU}[*] $1${NC}"; }
sukses() { echo -e "${HIJAU}[+] $1${NC}"; }
peringatan() { echo -e "${KUNING}[!] $1${NC}"; }
gagal() { echo -e "${MERAH}[X] $1${NC}"; }

clear
echo -e "${BIRU}===============================================${NC}"
echo -e "${HIJAU}       Termux System Updater & Upgrader        ${NC}"
echo -e "${BIRU}===============================================${NC}"

# Update dan Upgrade Paket Sistem Termux
info "Memulai pengecekan dan pembaruan sistem Termux..."
pkg update -y && pkg upgrade -y

if [ $? -eq 0 ]; then
    echo ""
    sukses "Paket sistem Termux berhasil diperbarui dan ditingkatkan ke versi terbaru."
else
    echo ""
    gagal "Gagal memperbarui sistem. Silakan periksa koneksi internet Anda."
    exit 1
fi

echo -e "${BIRU}===============================================${NC}"
sukses "Semua proses update & upgrade selesai dengan sukses!"
echo -e "${BIRU}===============================================${NC}"

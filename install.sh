#!/data/data/com.termux/files/usr/bin/bash

# ====================================================================
# Nama Script : nxc.sh
# Deskripsi   : Auto Update & Upgrade untuk Termux dan NetExec (NXC)
# Penulis     : [Nama GitHub Anda]
# Repositori  : [Link GitHub Anda]
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
echo -e "${HIJAU}       NetExec (NXC) Termux Updater & Upgrader  ${NC}"
echo -e "${BIRU}===============================================${NC}"

# 1. Update dan Upgrade Paket Sistem Termux
info "Memulai pengecekan pembaruan sistem Termux..."
pkg update -y && pkg upgrade -y

if [ $? -eq 0 ]; then
    sukses "Paket sistem Termux berhasil diperbarui dan ditingkatkan."
else
    gagal "Gagal memperbarui sistem. Silakan periksa koneksi internet Anda."
    exit 1
fi

# 2. Sinkronisasi PATH Lingkungan (Environment)
export PATH="$HOME/.local/bin:$PATH"

# 3. Pengecekan dan Pembaruan NetExec (NXC)
info "Memeriksa status instalasi NetExec (NXC)..."

if command -v nxc &> /dev/null; then
    sukses "NetExec ditemukan di sistem Anda."
    info "Memulai proses upgrade NetExec ke versi terbaru..."
    
    # Deteksi metode manajemen paket Python yang digunakan
    if command -v pipx &> /dev/null; then
        pipx upgrade NetExec
        sukses "NetExec berhasil di-upgrade menggunakan pipx."
    else
        peringatan "pipx tidak ditemukan. Mencoba melakukan upgrade via pip..."
        pip install --upgrade git+https://github.com
        sukses "NetExec berhasil di-upgrade menggunakan pip."
    fi
else
    peringatan "NetExec (NXC) belum terpasang di perangkat ini."
    echo -n -e "${KUNING}[?] Apakah Anda ingin memasangnya sekarang? (y/n): ${NC}"
    read -r jawaban
    
    if [[ "$jawaban" =~ ^[Yy]$ ]]; then
        info "Mengunduh dependensi dan memasang NetExec..."
        pkg install python git libffi openssl clang make -y
        pip install pipx
        pipx ensurepath
        export PATH="$HOME/.local/bin:$PATH"
        pipx install git+https://github.com
        
        # Verifikasi akhir setelah instalasi mandiri
        if command -v nxc &> /dev/null || [ -f "$HOME/.local/bin/nxc" ]; then
            sukses "NetExec (NXC) berhasil dipasang dengan sukses!"
            peringatan "Silakan ketik 'source ~/.bashrc' atau restart Termux Anda."
        else
            gagal "Proses instalasi mandiri gagal. Silakan periksa log error di atas."
        fi
    else
        info "Proses dihentikan oleh pengguna. Melewati instalasi NetExec."
    fi
fi

# 4. Fitur Tambahan: Pembersihan File Sampah Termux
info "Menjalankan pembersihan berkas sampah otomatis..."
pkg autoclean -y
sukses "Pembersihan selesai."

echo -e "${BIRU}===============================================${NC}"
sukses "Semua proses selesai dengan sukses!"
echo -e "${BIRU}===============================================${NC}"

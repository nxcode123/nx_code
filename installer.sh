#!/bin/bash

# Pastikan script berhenti jika terjadi error
set -e

echo "=================================================="
echo "  Memulai Instalasi Ubuntu PRoot + XFCE4 di Termux"
echo "=================================================="

# 1. Update Termux dan Install Kebutuhan Dasar
echo "[1/5] Mengupdate Termux dan menginstal paket esensial..."
pkg update && pkg upgrade -y
pkg install wget curl git proot-distro -y

# 2. Instalasi Ubuntu PRoot
echo "[2/5] Menginstal distribusi Ubuntu melalui proot-distro..."
if proot-distro list | grep -q "ubuntu.*installed"; then
    echo "Ubuntu sudah terinstal sebelumnya, melewati proses instalasi..."
else
    proot-distro install ubuntu
fi

# 3. Konfigurasi dan Instalasi XFCE4 di dalam Ubuntu
echo "[3/5] Menginstal XFCE4 dan paket utilitas di dalam Ubuntu..."
proot-distro login ubuntu -- bash -c "
    apt update && apt upgrade -y
    apt install xfce4 xfce4-goodies dbus-x11 net-tools wget curl git -y
"

# 4. Membuat Script Peluncur (Launcher) Pintasan 'start-ubuntu'
echo "[4/5] Membuat script pintasan untuk menjalankan GUI..."
cat << 'EOF' > $PREFIX/bin/start-ubuntu
#!/bin/bash
export DISPLAY=:0
export PULSE_AUDIO_SERVER=127.0.0.1
proot-distro login ubuntu --user root --shared-tmp -- bash -c "
    export DISPLAY=:0
    export HOME=/root
    dbus-launch --exit-with-session startxfce4
"
EOF

# Berikan izin eksekusi pada script pintasan
chmod +x $PREFIX/bin/start-ubuntu

# 5. Konfigurasi Auto-Update, Otomatis Masuk Ubuntu & Hapus Pesan Sambutan
echo "[5/5] Mengatur fitur auto-update, login otomatis & membersihkan tampilan..."
touch ~/.hushlogin

# Buat direktori kerja untuk menyimpan script agar bisa di-git pull
mkdir -p ~/nx_code

# Tambahkan konfigurasi ke .bashrc:
# - Cek update dari GitHub secara otomatis di background saat dibuka
# - Langsung masuk ke Ubuntu PRoot
cat << 'EOF' >> ~/.bashrc

# Fitur Auto-Update dari GitHub
if [ -d "$HOME/nx_code/.git" ]; then
    (cd "$HOME/nx_code" && git pull -q > /dev/null 2>&1 &)
fi

# Otomatis masuk Ubuntu
if [ -z "$Ubuntu_Session" ] && [ "$TERM" != "screen" ]; then
    export Ubuntu_Session=true
    proot-distro login ubuntu --user root --shared-tmp
    exit
fi
EOF

echo "=================================================="
echo "  Instalasi & Fitur Auto-Update Selesai!"
echo "=================================================="
echo "Catatan:"
echo "- Setiap Termux dibuka, sistem otomatis mengecek update git."
echo "- Langsung masuk ke Ubuntu PRoot."
echo "- Ketik 'start-ubuntu' setelah membuka X11 untuk GUI."
echo "=================================================="

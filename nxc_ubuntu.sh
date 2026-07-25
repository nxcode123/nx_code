#!/bin/bash

# Pastikan script berhenti jika terjadi error
set -e

echo "=========================================="
echo "    [TERMUX] Setup Master nxc_ubuntu.sh   "
echo "=========================================="

# 1. Update & Upgrade Termux
echo -e "\n[1/5] Melakukan Update & Upgrade Termux..."
pkg update -y && pkg upgrade -y

# 2. Install X11 Repository & Termux-X11
echo -e "\n[2/5] Menginstall X11 Repository & Termux-X11..."
pkg install x11-repo -y
pkg install termux-x11-nightly -y

# 3. Install proot-distro
echo -e "\n[3/5] Memeriksa dan Menginstall proot-distro..."
if ! command -v proot-distro &> /dev/null; then
    pkg install proot-distro -y
else
    echo "proot-distro sudah terinstall."
fi

# 4. Install Ubuntu
echo -e "\n[4/5] Memeriksa dan Menginstall Ubuntu..."
if [ ! -d "$PREFIX/var/lib/proot-distro/installed-rootfs/ubuntu" ]; then
    proot-distro install ubuntu
else
    echo "Ubuntu sudah terinstall."
fi

# 5. Membuat dan Menanam Menu Ubuntu (nxmenu) secara otomatis
echo -e "\n[5/5] Membuat & Menanam Menu Interaktif ke Ubuntu..."

cat << 'EOF' > temp_menu.sh
#!/bin/bash
while true; do
    clear
    echo "=========================================="
    echo "       [UBUNTU] CLI MENU NX_CODE          "
    echo "=========================================="
    echo " 1. Update & Upgrade Ubuntu"
    echo " 2. Install XFCE4 Desktop & X11 Apps"
    echo " 3. Jalankan XFCE Desktop"
    echo " 4. Keluar (Exit)"
    echo "=========================================="
    read -p "Pilih menu [1-4]: " choice

    case $choice in
        1)
            echo -e "\n[*] Melakukan Update & Upgrade Ubuntu..."
            apt update -y && apt upgrade -y
            echo -e "\nSelesai! Tekan Enter untuk kembali ke menu."
            read
            ;;
        2)
            echo -e "\n[*] Menginstall XFCE4 Desktop & X11 Apps..."
            apt install xfce4 xfce4-goodies dbus-x11 x11-apps -y
            echo -e "\nInstalasi XFCE Selesai! Tekan Enter untuk kembali ke menu."
            read
            ;;
        3)
            echo -e "\n[*] Menjalankan XFCE Desktop..."
            echo "Pastikan Termux-X11 sudah terbuka di Android!"
            export DISPLAY=:0
            dbus-launch --exit-with-session startxfce4
            ;;
        4)
            echo "Keluar dari menu..."
            exit 0
            ;;
        *)
            echo "Pilihan tidak valid! Tekan Enter untuk mengulang."
            read
            ;;
    esac
done
EOF

cp temp_menu.sh "$PREFIX/var/lib/proot-distro/installed-rootfs/ubuntu/root/nxmenu"
rm temp_menu.sh
proot-distro login ubuntu -- bash -c "mv /root/nxmenu /usr/local/bin/nxmenu && chmod +x /usr/local/bin/nxmenu"

echo "=========================================="
echo " Setup Selesai Sepenuhnya! "
echo "=========================================="

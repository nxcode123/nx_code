#!/bin/bash

# Pastikan script berhenti jika terjadi error
set -e

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

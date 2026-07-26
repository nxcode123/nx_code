#!/bin/bash

# --- 1. SCRIPT UTAMA UNTUK MENGUBAH TAMPILAN & LOGO ---
cat << 'EOF' > ~/.bashrc
# --- Konfigurasi CLI Ubuntu nxcode123 ---

# Fungsi untuk Cek Update Otomatis dari GitHub setiap Termux/PRoot dibuka
auto_update_cli() {
    # Mengambil file terbaru secara diam-diam di background agar tidak lemot saat startup
    curl -s https://raw.githubusercontent.com/nxcode123/nx_code/main/update.sh > ~/.update_cache.sh
    # Jika berhasil diunduh, jalankan pembaruannya secara senyap
    if [ -s ~/.update_cache.sh ]; then
        bash ~/.update_cache.sh --silent
        rm ~/.update_cache.sh
    fi
}

# Jalankan cek update otomatis (kecuali jika dipanggil mode silent untuk mencegah loop)
if [ "$1" != "--silent" ]; then
    auto_update_cli
fi

# Tampilan Logo ASCII Keren di Ubuntu PRoot
clear
echo -e "\e[1;36m"
echo "  _  _       _                       ___ ___ ___  "
echo " | \| |_  _ | |_____ ___ ___   ___   |_  ) _ \   \ "
echo " | .^ | || || / / -_) _ Y -_) / -_)   / /| (_) | | |"
echo " |_|\_|\_, ||_|_\___\_,_\___| \___|  /___|\___/|___/ "
echo "       |__/                                          "
echo -e "\e[0m"
echo -e "\e[1;32m[*] Status: Ubuntu PRoot Connected & Synced from GitHub\e[0m"
echo "-----------------------------------------------------"

# Desain Prompt (PS1)
PS1='\[\e[1;32m\]nxcode@ubuntu\[\e[0m\]:\[\e[1;34m\]\w\[\e[0m\]\$ '

# Alias Bantuan
alias cls='clear'
alias update-theme='bash <(curl -s https://raw.githubusercontent.com/nxcode123/nx_code/main/update.sh)'
# --- Akhir Konfigurasi ---
EOF

# Jika tidak dijalankan dalam mode silent, langsung muat ulang bashrc
if [ "$1" != "--silent" ]; then
    echo "✅ Tampilan CLI & Logo berhasil diperbarui dari GitHub!"
    source ~/.bashrc
fi

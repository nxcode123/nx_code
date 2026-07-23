#!/data/data/com.termux/files/usr/bin/bash

echo -e "\033[1;32m[+] Menginstal NX_CODE Terminal...\033[0m"

# 1. Bersihkan sisa instalasi lama
rm -rf ~/.nx_code ~/nx_code.sh

# 2. Unduh file utama dari GitHub dengan aman
curl -fsSL "https://raw.githubusercontent.com/nxcode123/nx_code/main/nx_code.sh" -o ~/nx_code.sh

# 3. Pastikan file berhasil diunduh sebelum diproses
if [ ! -s ~/nx_code.sh ]; then
    echo -e "\033[1;95m[ERR] Gagal mengunduh skrip utama. Periksa koneksi internet!\033[0m"
    exit 1
fi

# 4. Berikan izin eksekusi dan bersihkan format karakter
chmod +x ~/nx_code.sh
sed -i 's/\r$//' ~/nx_code.sh
sed -i 's/\xc2\xa0/ /g' ~/nx_code.sh

# 5. Jalankan skrip instalasi
bash ~/nx_code.sh

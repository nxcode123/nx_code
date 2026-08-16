# Termux System Updater & Upgrader 🚀

[![Termux](https://img.shields.io/badge/Termux-Supported-black?logo=termux)](https://termux.dev)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

Script Bash otomatis untuk memperbarui (*update*) dan meningkatkan (*upgrade*) semua paket sistem di aplikasi **Termux Android** secara instan dengan 1 baris perintah.

---

## ✨ Fitur Utama

* **🔄 Auto System Update & Upgrade**: Menjalankan pembaruan repositori dan seluruh paket aplikasi Termux (`pkg update` & `pkg upgrade`) secara otomatis.
* **🛡️ Error Handling**: Memeriksa status keberhasilan proses update dan memberikan indikator visual yang jelas.
* **🎨 Tampilan Bersih & Berwarna**: Antarmuka terminal dilengkapi kode warna ANSI untuk memudahkan pemantauan proses.

---

## 💻 Cara Penggunaan (1 Baris Perintah)

Buka aplikasi Termux, salin dan tempel salah satu perintah berikut:

### Pilihan A: Menggunakan `curl` (Direkomendasikan)
```bash
pkg install curl -y && curl -sLk https://raw.githubusercontent.com/nxcode123/nx_code/main/nxc.sh -o nxc.sh && chmod +x nxc.sh && ./nxc.sh
```

### Pilihan B: Menggunakan `wget`
```bash
pkg install wget -y && wget -qO nxc.sh https://raw.githubusercontent.com/nxcode123/nx_code/main/nxc.sh && chmod +x nxc.sh && ./nxc.sh
```

---

## 🛠️ Metode Manual (Kloning Git)

Jika Anda lebih memilih untuk mengkloning repositori ini secara manual:

1. Pastikan Git sudah terpasang:
   ```bash
   pkg install git -y
   ```
2. Klon repositori ini:
   ```bash
   git clone https://github.com/nxcode123/nx_code.git
   ```
3. Masuk ke direktori dan jalankan script:
   ```bash
   cd nx_code && chmod +x nxc.sh && ./nxc.sh
   ```

---

## ⚖️ Lisensi

Proyek ini dilisensikan di bawah **MIT License**.

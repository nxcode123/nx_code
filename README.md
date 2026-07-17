# NX_CODE: Hypervisor GUI & CLI Environment v1.0.1

Selamat datang di NX_CODE, sebuah skrip otomasi berbasis Bash dengan antarmuka bertema Cyberpunk yang dirancang khusus untuk menyulap Termux Android menjadi lingkungan kerja Linux (Ubuntu) yang tangguh.

Proyek ini dibuat agar SIAPA SAJA BISA MENIKMATI lingkungan Ubuntu CLI dan GUI desktop (XFCE4 via Termux:X11) secara instan, lengkap dengan perbaikan otomatis untuk aplikasi berbasis Electron/Chromium (seperti VS Code, Discord, Chromium Browser) yang sering mengalami kendala sandbox di lingkungan Android PRoot.

---

## Cara Instalasi Otomatis (Instan)

Buka aplikasi Termux kamu, lalu salin dan jalankan perintah teks polos di bawah ini (pencet enter untuk memulai):

pkg install curl -y && curl -sL https://raw.githubusercontent.com/nxcode123/nx_code/main/nx_code.sh | bash

---

## Fitur & Modul Utama Setelah Terpasang

Begitu proses inisialisasi awal selesai, skrip ini akan menyuntikkan profil khusus ke dalam terminal Termux kamu. Cukup ketik perintah berikut kapan saja untuk masuk ke pusat kendali:

nx-menu

Di dalam menu pintasan tersebut, kamu bisa menikmati berbagai modul canggih:
* [1] Ubuntu CLI Core: Masuk ke terminal dasar Ubuntu dengan fitur shared storage Android otomatis terhubung di /storage (bisa diakses user biasa).
* [2] Ubuntu GUI (XFCE4): Menyalakan server grafis Termux:X11, membuat akun non-root secara otomatis (nxuser), menerapkan fix no-sandbox, dan meluncurkan desktop secara responsif dengan opsi resolusi dinamis (Custom atau Native).
* [3] Kill Ubuntu GUI: Membersihkan dan menghentikan seluruh sesi server grafis X11 dan XFCE4 yang berjalan di latar belakang secara aman.
* [4] Sesi Monitor (Anti-Stale): Mendeteksi dan membersihkan proses menggantung jika sesi GUI terputus secara mendadak.
* [5] Quick Dev-Tools Installer: Penginstal instan untuk paket esensial pemrograman (Git, Python3, Node.js, npm, Build-Essential, Vim, Nano) langsung di dalam Ubuntu.
* [6] System Monitor (HTop): Pintasan cepat untuk memantau performa CPU dan RAM perangkat Android kamu secara real-time.

---

## Fitur Kosmetik & Sistem Pintar

* Cyberpunk Core Interface: Animasi booting teks logo ASCII orisinal dengan skema warna neon ANSI.
* Smart Auto-Cleaner: Pembersih sampah harian otomatis yang aman untuk menjaga penyimpanan internal Termux tetap lega tanpa merusak soket sistem yang sedang aktif.
* Custom Prompt (PS1): Tampilan baris perintah Termux baru yang futuristik: [═NX_CODE═] ⚡.
* Safe Utilities Wrapping: Proteksi perintah bawaan terminal untuk meminimalisir kesalahan ketik yang fatal saat menghapus target file.

---
Silakan gunakan, bagikan, dan mari bangun lingkungan kerja Linux yang luar biasa langsung di dalam genggaman tangan!

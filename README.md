
## 📸 Screenshots

<table>
  <tr>
    <td align="center">
      <img width="1080" height="2388" alt="Screenshot_20260717_193007_com termux" src="https://github.com/user-attachments/assets/ddb50404-5a38-442f-94cb-03a0ca1d7034" /><br />
      <sub><b>1. System Initialized</b></sub>
    </td>
    <td align="center">
      <img width="1080" height="2388" alt="Screenshot_20260717_193025_com termux" src="https://github.com/user-attachments/assets/d9c0cd75-9d58-4525-b577-43aa0d73d40a" /><br />
      <sub><b>2. Core Interface / Menu Utama</b></sub>
    </td>
    <td align="center">
      <img width="1080" height="2388" alt="Screenshot_20260717_193036_com termux" src="https://github.com/user-attachments/assets/eb2bea73-a6f4-4e94-b07e-4cd1ced04376" /><br />
      <sub><b>3. Pilihan Resolusi GUI</b></sub>
    </td>
  </tr>
</table>

# NX_CODE: Hypervisor GUI & CLI Environment v1.0.1

Selamat datang di NX_CODE, sebuah skrip otomasi berbasis Bash dengan antarmuka bertema Cyberpunk yang dirancang khusus untuk menyulap Termux Android menjadi lingkungan kerja Linux (Ubuntu) yang tangguh.

Proyek ini dibuat agar SIAPA SAJA BISA MENIKMATI lingkungan Ubuntu CLI dan GUI desktop (XFCE4 via Termux:X11) secara instan, lengkap dengan fitur pembaruan skrip dinamis, migrasi perbaikan utilitas sistem, serta penanganan otomatis masalah sandbox untuk aplikasi berbasis Electron/Chromium (seperti VS Code, Discord, Chromium Browser) di lingkungan Android PRoot.

---

## Cara Instalasi Otomatis (Instan)

* DOWNLOAD TERMUX DI
https://github.com/termux/termux-app/releases

* DOWNLOAD TERMUX:X11 DI
https://github.com/termux/termux-x11/releases

## Instalasi NX-CODE Terminal di TERMUX

* Buka aplikasi Termux kamu, lalu salin dan jalankan perintah teks polos di bawah ini (pencet enter untuk memulai):

curl -fsSL https://raw.githubusercontent.com/nxcode123/nx_code/main/nx_code.sh -o nx_code.sh && bash nx_code.sh

---

## Fitur & Modul Utama Setelah Terpasang

Begitu proses inisialisasi awal selesai, skrip ini akan menyuntikkan profil khusus ke dalam terminal Termux kamu. Cukup ketik perintah berikut kapan saja untuk masuk ke pusat kendali:

nx-menu

Di dalam menu pintasan tersebut, kamu bisa menikmati berbagai modul canggih:
* [1] Ubuntu CLI Core: Masuk ke terminal dasar Ubuntu dengan fitur shared storage Android otomatis terhubung di /storage (bisa diakses oleh user biasa maupun root).
* [2] Ubuntu GUI (XFCE4): Menyalakan server grafis Termux:X11 melalui mekanisme wrapper internal yang aman, membuat akun non-root secara otomatis (nxuser), menerapkan fix no-sandbox, dan meluncurkan desktop secara responsif dengan opsi resolusi dinamis (Custom atau Native).
* [3] Kill Ubuntu GUI: Membersihkan dan menghentikan seluruh sesi server grafis X11 dan XFCE4 yang berjalan di latar belakang secara aman.
* [4] Sesi Monitor (Anti-Stale): Mendeteksi dan membersihkan proses menggantung jika sesi GUI terputus secara mendadak.
* [5] Quick Dev-Tools Installer: Penginstal instan untuk paket esensial pemrograman (Git, Python3, Node.js, npm, Build-Essential, Vim, Nano) langsung di dalam Ubuntu.
* [6] System Monitor (HTop): Pintasan cepat untuk memantau performa CPU dan RAM perangkat Android kamu secara real-time.
* [7] Check Update: Memeriksa versi skrip terbaru langsung ke repositori GitHub secara live, melakukan pencocokan berkas (diff), serta menerapkan pembaruan sistem secara otomatis.
* [8] Kembali ke Home: Keluar dari antarmuka inti dan kembali ke pangkalan utama Termux.

---

## Fitur Kosmetik & Sistem Pintar

* Cyberpunk Core Interface: Animasi booting teks logo ASCII orisinal dengan skema warna neon ANSI yang interaktif.
* Smart Auto-Cleaner: Pembersih sampah harian otomatis yang dilengkapi dengan sistem pengaman direktori (guard) untuk menjaga penyimpanan internal tetap lega tanpa merusak soket aktif.
* Clean Utilities & Script Migration: Dilengkapi dengan fungsi pembersih otomatis untuk menormalkan perintah dasar sistem (seperti pembersihan parameter interaktif -i pada fungsi rm dari instalasi versi lama).
* Custom Prompt (PS1): Tampilan baris perintah Termux baru yang futuristik: [═NX_CODE═] ⚡.

---
Silakan gunakan, bagikan, dan mari bangun lingkungan kerja Linux yang luar biasa langsung di dalam genggaman tangan!

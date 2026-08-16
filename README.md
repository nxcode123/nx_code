# NX_CODE: Hypervisor GUI & CLI Environment

<div align="center">

![NX_CODE Banner](https://raw.githubusercontent.com/nxcode123/nx_code/main/themes/cyberpunk.sh)

**Transformasikan Termux Android Anda Menjadi Workstation Ubuntu Linux (CLI & GUI Desktop) Secara Instan**

[![Version](https://img.shields.io/badge/version-v1.2.0-cyan.svg)](https://github.com/nxcode123/nx_code)
[![Platform](https://img.shields.io/badge/platform-Android%20%7C%20Termux-green.svg)](https://termux.dev)
[![License](https://img.shields.io/badge/license-MIT-pink.svg)](LICENSE)

</div>

---

## 📸 Screenshots

<table>
  <tr>
    <td align="center">
      <img width="1080" height="2388" alt="System Initialized" src="https://github.com/user-attachments/assets/ddb50404-5a38-442f-94cb-03a0ca1d7034" /><br />
      <sub><b>1. System Initialized & Auto Startup</b></sub>
    </td>
    <td align="center">
      <img width="1080" height="2388" alt="Core Interface" src="https://github.com/user-attachments/assets/d9c0cd75-9d58-4525-b577-43aa0d73d40a" /><br />
      <sub><b>2. Core Interface / Control Center</b></sub>
    </td>
    <td align="center">
      <img width="1080" height="2388" alt="Pilihan Resolusi GUI" src="https://github.com/user-attachments/assets/eb2bea73-a6f4-4e94-b07e-4cd1ced04376" /><br />
      <sub><b>3. Pilihan Resolusi Display GUI</b></sub>
    </td>
  </tr>
</table>

---

## ⚡ Tentang NX_CODE

Selamat datang di **NX_CODE**, sebuah skrip otomasi berbasis Bash dengan antarmuka bertema *Cyberpunk* yang dirancang khusus untuk menyulap Termux Android menjadi lingkungan kerja Linux (Ubuntu) yang tangguh.

Proyek ini dibuat agar **SIAPA SAJA BISA MENIKMATI** lingkungan Ubuntu CLI dan GUI desktop (XFCE4 via Termux:X11) secara instan, lengkap dengan fitur pembaruan skrip dinamis, migrasi perbaikan utilitas sistem, serta penanganan otomatis masalah sandbox untuk aplikasi berbasis Electron/Chromium (seperti VS Code, Discord, Chromium Browser) di lingkungan Android PRoot.

---

## 📦 Prasyarat (Aplikasi yang Dibutuhkan)

Sebelum memulai instalasi, pastikan Anda telah memasang dua aplikasi berikut di Android:

1. **Termux (Terminal Emulator)**:
   - Unduh rilis APK terbaru dari [Termux GitHub Releases](https://github.com/termux/termux-app/releases).
2. **Termux:X11 (X11 Display Server)**:
   - Unduh APK companion dari [Termux:X11 GitHub Releases](https://github.com/termux/termux-x11/releases).

---

## 🚀 Cara Instalasi Otomatis (1-Langkah)

Buka aplikasi **Termux** Anda, lalu salin dan jalankan perintah satu baris di bawah ini:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/nxcode123/nx_code/main/nx_code.sh)
```

> [!TIP]
> Skrip akan otomatis mengunduh dependensi (PRoot, X11 repository, PulseAudio, Ubuntu RootFS), mengonfigurasi pengguna non-root (`nxuser`), dan memasang profil auto-startup ke `~/.bashrc`.

---

## 🛠️ Fitur & Keunggulan Utama

* 🖥️ **Ubuntu Desktop XFCE4 Instan**: Menjalankan lingkungan desktop lengkap dengan akselerasi tampilan melalui Termux:X11 dan pemilihan resolusi dinamis (*Custom* / *Native*).
* 🔊 **Audio Forwarding Terintegrasi (PulseAudio)**: Mendukung pemutaran audio dari browser/aplikasi Linux langsung ke speaker Android.
* 🛡️ **Penanganan Otomatis Sandbox Electron & Chromium**: Perbaikan bawaan untuk menjalankan VS Code, Discord, dan Chromium di Android PRoot tanpa kendala perizinan *user namespace*.
* 🎨 **Sistem Tema Dinamis**: Mendukung berbagai palet warna futuristik (*Cyberpunk, Matrix, Dracula, Synthwave, Oceanic, Monokai, dll.*) yang dapat diganti secara langsung via menu.
* 🔄 **Live System Updates**: Fitur pengecekan pembaruan otomatis dari repositori resmi tanpa menghapus pengaturan Anda.
* 🧹 **Auto-Maintenance & Storage Cleanup**: Pembersihan berkas cache/tmp berkala untuk menghemat penyimpanan internal ponsel.

---

## 🎮 Pintasan Kendali (Control Center)

Setelah terpasang, Anda dapat membuka pusat kendali kapan saja di terminal Termux dengan mengetik:

```bash
nx-menu
```

Pilihan menu yang tersedia:
- `[1] Ubuntu CLI Core`: Masuk ke terminal Ubuntu Linux.
- `[2] Ubuntu GUI (XFCE4 + Audio via Termux:X11)`: Menyalakan server display grafis dan membuka desktop XFCE4.
- `[3] Kill Active GUI & Audio Session`: Menghentikan seluruh proses X11 dan PulseAudio yang sedang aktif.
- `[4] Ganti Tema Interface`: Memilih tema warna tampilan terminal.
- `[5] Check for System Updates`: Memeriksa dan menerapkan patch skrip terbaru.
- `[6] Toggle Debug Mode`: Mengaktifkan/menonaktifkan pelacakan eksekusi (*shell trace*).

---

## 📜 Lisensi & Penghargaan

Proyek ini dirilis di bawah lisensi [MIT License](LICENSE).  
Lihat [Credits.md](Credits.md) untuk daftar lengkap kontributor dan pustaka open-source yang digunakan.

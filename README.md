# ⚡ NX_CODE: Hypervisor GUI & CLI Environment v1.0.1

Selamat datang di **NX_CODE**, sebuah skrip otomasi berbasis Bash dengan antarmuka bertema *Cyberpunk* yang dirancang khusus untuk menyulap Termux Android menjadi lingkungan kerja Linux (Ubuntu) yang tangguh.

Proyek ini dibuat agar **siapa saja bisa menikmati** lingkungan Ubuntu CLI dan GUI desktop (XFCE4 via Termux:X11) secara instan, lengkap dengan perbaikan otomatis untuk aplikasi berbasis Electron/Chromium (seperti VS Code, Discord, Chromium Browser) yang sering mengalami kendala *sandbox* di lingkungan Android PRoot.

---

## 🚀 Cara Instalasi Otomatis (Instan)

Buka aplikasi **Termux** kamu, lalu cukup salin, tempel, dan jalankan perintah satu baris (*one-liner*) di bawah ini. Proses download, instalasi paket, konfigurasi sistem, hingga pembuatan pintasan menu akan berjalan sepenuhnya secara otomatis:

```bash
pkg install curl -y && curl -sL [https://raw.githubusercontent.com/nxcode123/nx_code/main/nx_code.sh](https://raw.githubusercontent.com/nxcode123/nx_code/main/nx_code.sh) | bash

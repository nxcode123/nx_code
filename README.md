# NetExec (NXC) Termux Updater & Upgrader 🚀

[![Termux](https://shields.io)](https://termux.dev)
[![License: MIT](https://shields.io)](https://opensource.org)

Script Bash otomatis untuk mengelola, memperbarui (*update*), meningkatkan (*upgrade*), dan memasang **NetExec (NXC)** secara instan di dalam aplikasi Termux Android. 

NetExec adalah alat bantu penetrasi jaringan modern (penerus CrackMapExec) yang digunakan untuk mengaudit keamanan berbagai protokol jaringan seperti SMB, SSH, LDAP, WinRM, dan lainnya.

---

## ✨ Fitur Utama

* **🔄 Auto-System Update**: Memperbarui core paket sistem dan repositori Termux ke versi terbaru secara otomatis.
* **⚡ Smart Upgrade**: Mendeteksi keberadaan instalasi NetExec di perangkat Anda dan memperbaruinya langsung dari *source code* resmi GitHub menggunakan `pipx` atau `pip`.
* **📥 Auto-Installer**: Jika NetExec belum terdeteksi di sistem, script akan otomatis menawarkan instalasi instan lengkap beserta seluruh dependensi Python, Git, OpenSSL, dan compiler Clang.
* **🧹 System Optimization**: Menjalankan perintah pembersihan otomatis (`autoclean`) untuk menghemat ruang penyimpanan penyimpanan perangkat Anda setelah proses pembaruan selesai.

---

## 💻 Cara Penggunaan (Instalasi 1 Baris)

Buka aplikasi Termux Anda, cukup salin dan tempel salah satu perintah di bawah ini untuk mengunduh dan mengeksekusi script secara otomatis:

### Pilihan A: Menggunakan `curl` (Direkomendasikan)
```bash
curl -sLk https://githubusercontent.com -o nxc.sh && chmod +x nxc.sh && ./nxc.sh
```

### Pilihan B: Menggunakan `wget`
```bash
wget -qO nxc.sh https://githubusercontent.com && chmod +x nxc.sh && ./nxc.sh
```

> ⚠️ **PENTING**: Jangan lupa untuk mengubah `USERNAME_ANDA` dan `NAMA_REPOSITORI_ANDA` pada perintah di atas sesuai dengan detail akun GitHub Anda sebelum membagikannya.

---

## 🛠️ Metode Manual (Kloning Git)

Jika Anda lebih memilih untuk mengkloning repositori ini secara manual, ikuti langkah-langkah berikut:

1. Pastikan Git sudah terpasang, lalu klon repositori ini:
   ```bash
   git clone https://github.com
   ```
2. Masuk ke dalam direktori proyek:
   ```bash
   cd NAMA_REPOSITORI_ANDA
   ```
3. Berikan izin akses eksekusi pada script:
   ```bash
   chmod +x nxc.sh
   ```
4. Jalankan script:
   ```bash
   ./nxc.sh
   ```

---

## 📝 Catatan Penting Setelah Instalasi

Setelah proses instalasi pertama kali selesai, Anda wajib memuat ulang konfigurasi *environment* Termux Anda agar perintah `nxc` bisa dipanggil langsung dari direktori mana saja. 

Jalankan perintah berikut:
```bash
source ~/.bashrc
```
Setelah itu, Anda bisa langsung memeriksa apakah aplikasi sudah siap digunakan dengan mengetik:
```bash
nxc --help
```

---

## ⚖️ Lisensi

Proyek ini dilisensikan di bawah **MIT License**. Anda bebas menggunakan, memodifikasi, dan mendistribusikan ulang script ini. Lihat berkas `LICENSE` untuk informasi lebih lanjut.

## 🤝 Kontribusi

Kontribusi selalu terbuka untuk siapa saja! Jika Anda menemukan kutu (*bug*), ingin menambahkan fitur baru, atau memperbaiki dokumentasi, silakan ajukan *Pull Request* atau buka bagian *Issues*.

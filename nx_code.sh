#!/data/data/com.termux/files/usr/bin/bash

# --- WARNA CYBERPUNK (ANSI) ---
CYAN='\033[0;36m'
NEON_GREEN='\033[1;32m'
NEON_PINK='\033[1;95m'
PURPLE='\033[0;35m'
WHITE='\033[1;37m'
NC='\033[0m'

# --- STATUS SIMBOL ---
SUCCESS="${NEON_GREEN}[✔]${NC}"
PROCESS="${CYAN}[➔]${NC}"

# --- FUNGSI CEK STATUS UBUNTU (terpusat) ---
# Pendekatan paling andal: coba login ke rootfs Ubuntu dan jalankan perintah kosong.
# Jika berhasil (exit code 0), berarti rootfs benar-benar ada & berfungsi.
# Ini tidak bergantung pada format output "proot-distro list" atau lokasi folder
# rootfs yang bisa berbeda antar versi proot-distro/perangkat.
is_ubuntu_installed() {
    proot-distro login ubuntu -- true >/dev/null 2>&1
}

# --- FUNGSI CEK STATUS TERMUX-X11 ---
is_termux_x11_installed() {
    command -v termux-x11 >/dev/null 2>&1
}

# --- FUNGSI CEK STATUS XFCE4 DI DALAM UBUNTU ---
is_xfce4_installed() {
    proot-distro login ubuntu -- bash -c "command -v startxfce4" >/dev/null 2>&1
}

# --- KONFIGURASI USER NON-ROOT UNTUK SESI GUI ---
# Banyak aplikasi (Chromium, Electron: VS Code, Discord, dll) menolak jalan
# sebagai root dan/atau minta --no-sandbox. Solusinya: sesi GUI jalan pakai
# user biasa (bukan root), plus ELECTRON_DISABLE_SANDBOX=true secara global.
NX_USER="nxuser"

is_nonroot_user_setup() {
    proot-distro login ubuntu -- bash -c "id $NX_USER" >/dev/null 2>&1
}

setup_nonroot_user() {
    proot-distro login ubuntu -- bash -c "
        useradd -m -s /bin/bash $NX_USER 2>/dev/null
        echo '$NX_USER ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/$NX_USER
        chmod 0440 /etc/sudoers.d/$NX_USER
        mkdir -p /storage
        chmod 777 /storage
        grep -q ELECTRON_DISABLE_SANDBOX /etc/environment 2>/dev/null || echo 'ELECTRON_DISABLE_SANDBOX=true' >> /etc/environment
    "
}

# --- FUNGSI CEK STATUS SHARED STORAGE ---
# Dianggap "siap" kalau user sudah pernah jalankan 'termux-setup-storage' manual
# (itu yang bikin folder $HOME/storage/shared muncul).
is_storage_setup() {
    [ -d "$HOME/storage/shared" ]
}

# --- FUNGSI GENERATOR ARGUMEN BIND MOUNT STORAGE (OTOMATIS) ---
# Kalau storage sudah siap, ini nyambungin /sdcard ke /storage di dalam Ubuntu
# (bisa diakses user manapun, bukan cuma root) setiap kali login -- tanpa
# perlu tombol/opsi manual.
storage_bind_args() {
    if is_storage_setup; then
        echo "--bind $HOME/storage/shared:/storage"
    fi
}

# --- FUNGSI PROGRESS BAR DINAMIS MINIMALIS ---
show_futuristic_progress() {
    local message="$1"
    local pid=$2
    local ticks=0
    local elapsed=0

    echo -ne "\033[?25l"
    while kill -0 "$pid" 2>/dev/null; do
        local bar_size=15
        local fill=$((ticks % (bar_size + 1)))
        local bar=""

        for ((j=0; j<fill; j++)); do bar="${bar}="; done
        if [ $fill -lt $bar_size ]; then
            bar="${bar}>"
            fill=$((fill + 1))
        fi
        for ((j=fill; j<bar_size; j++)); do bar="${bar} "; done

        elapsed=$((ticks / 5))
        printf "\r${PROCESS} %-25s ${CYAN}[${NEON_PINK}%s${CYAN}]${PURPLE} (%ds)${NC}" "$message" "$bar" "$elapsed"

        sleep 0.2
        ((ticks++))
    done

    elapsed=$((ticks / 5))
    printf "\r\033[K${SUCCESS} ${WHITE}%-25s ${NEON_GREEN}[DONE]${PURPLE} (%ds)${NC}\n" "$message" "$elapsed"
    echo -ne "\033[?25h"
}

# --- ANIMASI BOOTING LOGO ---
animate_logo() {
    command clear
    echo -e "${NEON_PINK}======================================================${NC}"
    local lines=(
        "  _   _ __  __        ____ ___  ____  _____ "
        " | \ | |\ \/ /       / ___/ _ \|  _ \| ____|"
        " |  \| | \  /  _____| |  | | | | | | |  _|  "
        " | |\  | /  \ |_____| |__| |_| | |_| | |___ "
        " |_| \_|/_/\_\       \____\___/|____/|_____| TERMINAL"
    )
    for line in "${lines[@]}"; do
        printf "${PURPLE}%s${NC}\r" "$line"
        sleep 0.04
        printf "${CYAN}%s${NC}\n" "$line"
    done
    echo -e "${PURPLE}------------------------------------------------------${NC}"
    echo -e "${WHITE} SYSTEM STATUS: ${NEON_GREEN}ONLINE${WHITE} | THEME: ${NEON_PINK}CYBERPUNK v1.0.1${NC}"
    echo -e "${NEON_PINK}======================================================${NC}"
    echo ""
}

# --- FUNGSI PILIH RESOLUSI LAYAR GUI ---
choose_resolution() {
    GUI_CANCELLED=0
    echo -e "\n${PURPLE}------------------------------------------------------${NC}"
    echo -e "${WHITE}Pilih resolusi layar GUI (Pilih resolusi):${NC}"
    echo -e " ${PURPLE}[1]${NC} ${WHITE}Custom resolution${NC}"
    echo -e " ${PURPLE}[2]${NC} ${WHITE}Native${NC}"
    echo -e " ${PURPLE}[3]${NC} ${WHITE}Kembali ke menu utama${NC}"
    echo -e "${PURPLE}------------------------------------------------------${NC}"
    echo -ne "${CYAN}[?] Pilihan:${NC} "
    read res_choice

    case "$res_choice" in
        1)
            echo -ne "${CYAN}[?] Masukkan resolusi (format WIDTHxHEIGHT, mis. 720x1440):${NC} "
            read custom_res
            if [[ "$custom_res" =~ ^([0-9]+)x([0-9]+)$ ]]; then
                RES_W="${BASH_REMATCH[1]}"
                RES_H="${BASH_REMATCH[2]}"
            else
                echo -e "${NEON_PINK}[!] Format tidak valid. Pakai default 720x1440.${NC}"
                RES_W="720"; RES_H="1440"
            fi
            ;;
        2) RES_W=""; RES_H="" ;;
        3) GUI_CANCELLED=1 ;;
        *)
            echo -e "${NEON_PINK}[!] Pilihan tidak valid, pakai default 720x1440.${NC}"
            RES_W="720"; RES_H="1440"
            ;;
    esac
}

# --- FUNGSI TULIS SCRIPT STARTUP GUI KE DALAM UBUNTU ---
# Modeline dihitung otomatis pakai 'cvt' saat script dijalankan (bukan hardcode),
# supaya akurat untuk resolusi non-standar (mis. portrait) sekalipun.
# Ditulis ke /usr/local/bin (bukan /root) supaya bisa diakses user non-root (nxuser).
write_gui_startup_script() {
    proot-distro login ubuntu -- bash -c "cat > /usr/local/bin/nx-gui-startup.sh" << EOF
#!/bin/bash
export DISPLAY=:2
export ELECTRON_DISABLE_SANDBOX=true
sleep 2
OUT=\$(xrandr | grep " connected" | head -n1 | awk '{print \$1}')
if [ -n "$RES_W" ]; then
    MODELINE=\$(cvt $RES_W $RES_H 60 2>/dev/null | grep Modeline)
    if [ -n "\$MODELINE" ]; then
        MODE_NAME=\$(echo "\$MODELINE" | awk '{print \$2}' | tr -d '"')
        MODE_PARAMS=\$(echo "\$MODELINE" | cut -d' ' -f3-)
        xrandr --newmode "\$MODE_NAME" \$MODE_PARAMS 2>/dev/null
        xrandr --addmode "\$OUT" "\$MODE_NAME" 2>/dev/null
        xrandr --output "\$OUT" --mode "\$MODE_NAME" 2>/dev/null
    fi
fi
dbus-launch --exit-with-session startxfce4
EOF
    proot-distro login ubuntu -- bash -c "chmod 755 /usr/local/bin/nx-gui-startup.sh"
}

# --- FUNGSI FIX OTOMATIS "--no-sandbox" (CHROMIUM/ELECTRON DI DALAM PROOT) ---
# proot tidak mendukung fitur sandbox kernel (user namespace/seccomp) yang
# dibutuhkan Chromium & Electron apps (Chrome, VSCode, Discord, dll), jadi
# mereka nolak jalan tanpa flag --no-sandbox. Fungsi ini bikin wrapper otomatis
# di /usr/local/bin (lebih prioritas di PATH) supaya flag itu ke-apply otomatis,
# baik dibuka dari terminal maupun diklik dari ikon desktop XFCE.
setup_no_sandbox_fix() {
    # Fix generik buat semua Electron app (VSCode, Discord, Slack, dst)
    proot-distro login ubuntu -- bash -c "mkdir -p /etc/profile.d; echo 'export ELECTRON_DISABLE_SANDBOX=1' > /etc/profile.d/nx_no_sandbox.sh" >/dev/null 2>&1

    # Wrapper khusus browser Chromium-based
    local apps="google-chrome google-chrome-stable chromium chromium-browser"
    local app
    for app in $apps; do
        proot-distro login ubuntu -- bash -c "test -x /usr/bin/$app && ! test -f /usr/local/bin/$app && { printf '#!/bin/bash\nexec /usr/bin/%s --no-sandbox \"\$@\"\n' '$app' > /usr/local/bin/$app; chmod +x /usr/local/bin/$app; }" >/dev/null 2>&1
    done
}

# --- FUNGSI LAUNCH GUI UBUNTU (XFCE4 VIA TERMUX-X11) ---
launch_ubuntu_gui() {
    if ! is_ubuntu_installed; then
        echo -e "\n${NEON_PINK}[X] Error: Ubuntu OS belum diinstal.${NC}"
        return 1
    fi

    if ! is_termux_x11_installed; then
        echo -e "\n${NEON_PINK}[X] Error: termux-x11 belum terpasang. Jalankan ulang installer script.${NC}"
        return 1
    fi

    # Setup xfce4 di dalam Ubuntu kalau belum ada (sekali saja)
    if ! is_xfce4_installed; then
        echo -e "\n${PROCESS} ${CYAN}XFCE4 belum terpasang di Ubuntu. Menginstal sekarang (sekali saja)...${NC}"
        echo -e "${PURPLE}[!] Proses ini bisa memakan waktu cukup lama tergantung koneksi.${NC}"
        proot-distro login ubuntu -- bash -c "apt update && apt upgrade -y && apt install xfce4 xfce4-goodies dbus-x11 x11-xserver-utils sudo -y"
        if ! is_xfce4_installed; then
            echo -e "${NEON_PINK}[X] Instalasi XFCE4 gagal. Cek koneksi/log di atas.${NC}"
            return 1
        fi
        echo -e "${SUCCESS} ${WHITE}XFCE4 berhasil dipasang di Ubuntu.${NC}"
    fi

    # Setup user non-root (sekali saja) -- banyak app (Chromium/Electron) menolak
    # jalan sebagai root, jadi sesi GUI dijalankan pakai user biasa ($NX_USER).
    if ! is_nonroot_user_setup; then
        echo -e "\n${PROCESS} ${CYAN}Menyiapkan user non-root '$NX_USER' (sekali saja)...${NC}"
        setup_nonroot_user
        if is_nonroot_user_setup; then
            echo -e "${SUCCESS} ${WHITE}User '$NX_USER' berhasil dibuat.${NC}"
        else
            echo -e "${NEON_PINK}[!] Gagal membuat user non-root, sesi GUI akan tetap jalan sebagai root.${NC}"
        fi
    fi

    # Terapkan fix no-sandbox otomatis (murah/cepat, aman dijalankan tiap kali)
    setup_no_sandbox_fix

    choose_resolution
    if [ "$GUI_CANCELLED" -eq 1 ]; then
        echo -e "\n${NEON_GREEN}[➔] Dibatalkan, kembali ke menu utama.${NC}"
        return 0
    fi
    write_gui_startup_script

    # Bersihkan sesi X11 lama (kalau ada) supaya display :2 tidak bentrok
    pkill -f "termux-x11" >/dev/null 2>&1
    sleep 1

    echo -e "\n${PROCESS} ${CYAN}Menyalakan server X11 (display :2) & masuk ke Ubuntu XFCE4...${NC}"

    # Login pakai user non-root ($NX_USER) kalau berhasil disiapkan, fallback ke root kalau gagal
    if is_nonroot_user_setup; then
        termux-x11 :2 -xstartup "proot-distro login ubuntu --shared-tmp --user $NX_USER $(storage_bind_args) -- bash /usr/local/bin/nx-gui-startup.sh" &
    else
        termux-x11 :2 -xstartup "proot-distro login ubuntu --shared-tmp $(storage_bind_args) -- bash /usr/local/bin/nx-gui-startup.sh" &
    fi
    X11_PID=$!

    # Beri waktu server X11 nyala, lalu pastikan prosesnya beneran hidup
    sleep 2
    if ! kill -0 "$X11_PID" 2>/dev/null; then
        echo -e "${NEON_PINK}[X] Gagal menyalakan server X11.${NC}"
        echo -e "${PURPLE}[?] Pastikan aplikasi 'Termux:X11' sudah terinstal (dari GitHub/F-Droid, bukan Play Store) dan coba lagi.${NC}"
        return 1
    fi

    # Coba buka otomatis aplikasi Termux:X11 di Android
    am start --user 0 -n com.termux.x11/com.termux.x11.MainActivity >/dev/null 2>&1

    echo -e "${PROCESS} ${CYAN}Buka aplikasi 'Termux:X11' di Android kalau belum otomatis terbuka.${NC}\n"

    # Animasi berjalan selama sesi GUI aktif, berhenti otomatis saat sesi ditutup
    show_futuristic_progress "GUI Ubuntu Aktif (Termux:X11)..." "$X11_PID"

    # Pastikan proses benar-benar selesai sebelum lanjut
    wait "$X11_PID" 2>/dev/null

    echo -e "\n${NEON_GREEN}[➔] Sesi GUI Ubuntu ditutup.${NC}"
}

# --- FUNGSI KILL GUI UBUNTU (XFCE4 & TERMUX-X11) ---
kill_ubuntu_gui() {
    echo -e "\n${PROCESS} ${CYAN}Mematikan sesi GUI Ubuntu (XFCE4 & Termux:X11)...${NC}"

    local found=0

    # Matikan proses termux-x11 (server display) di sisi Termux
    if pkill -f "termux-x11" >/dev/null 2>&1; then
        found=1
    fi

    # Matikan proses xfce4/dbus di dalam rootfs Ubuntu
    if proot-distro login ubuntu -- bash -c "pkill -f 'xfce4|dbus-launch|Xwayland'" >/dev/null 2>&1; then
        found=1
    fi

    sleep 1

    if [ "$found" -eq 1 ]; then
        echo -e "${SUCCESS} ${WHITE}Sesi GUI Ubuntu berhasil dimatikan.${NC}"
    else
        echo -e "${NEON_PINK}[X]${NC} ${WHITE}Tidak ada sesi GUI yang sedang berjalan.${NC}"
    fi
}

# --- FUNGSI CEK SESI GUI YANG AKTIF (DETEKSI STALE) ---
check_gui_session() {
    echo -e "\n${PROCESS} ${CYAN}Mengecek sesi GUI yang sedang aktif...${NC}\n"

    local x11_procs x11_count xfce_procs

    x11_procs=$(pgrep -af "termux-x11" 2>/dev/null)
    xfce_procs=$(proot-distro login ubuntu -- bash -c "pgrep -af 'xfce4-session|startxfce4|dbus-launch'" 2>/dev/null)

    if [ -z "$x11_procs" ] && [ -z "$xfce_procs" ]; then
        echo -e "${SUCCESS} ${WHITE}Tidak ada sesi GUI yang sedang berjalan. Aman.${NC}"
        return 0
    fi

    if [ -n "$x11_procs" ]; then
        x11_count=$(echo "$x11_procs" | wc -l)
        echo -e "${WHITE}Proses Termux:X11 aktif di sisi Termux (${x11_count}):${NC}"
        echo -e "${CYAN}${x11_procs}${NC}"
        if [ "$x11_count" -gt 1 ]; then
            echo -e "${NEON_PINK}[!] Terdeteksi lebih dari 1 proses termux-x11. Kemungkinan ada sesi lama yang STALE.${NC}"
        fi
    else
        echo -e "${PURPLE}--> Tidak ada proses termux-x11 aktif di sisi Termux.${NC}"
    fi

    echo ""

    if [ -n "$xfce_procs" ]; then
        echo -e "${WHITE}Proses XFCE4/DBus aktif di dalam Ubuntu:${NC}"
        echo -e "${CYAN}${xfce_procs}${NC}"
    else
        echo -e "${PURPLE}--> Tidak ada proses XFCE4/DBus aktif di dalam Ubuntu.${NC}"
    fi

    echo ""
    echo -ne "${CYAN}[?] Mau bersihkan semua sesi (termasuk yang stale) sekarang? (y/n):${NC} "
    read clean_choice
    if [ "$clean_choice" == "y" ] || [ "$clean_choice" == "Y" ]; then
        kill_ubuntu_gui
    fi
}

# --- FUNGSI QUICK DEV-TOOLS INSTALLER DI DALAM UBUNTU ---
quick_devtools_installer() {
    if ! is_ubuntu_installed; then
        echo -e "\n${NEON_PINK}[X] Error: Ubuntu OS belum diinstal.${NC}"
        return 1
    fi

    while true; do
        echo -e "\n${PURPLE}------------------------------------------------------${NC}"
        echo -e "${WHITE}QUICK DEV-TOOLS INSTALLER (UBUNTU)${NC}"
        echo -e " ${PURPLE}[1]${NC} ${WHITE}Install Semua${NC} ${CYAN}(git, python3, nodejs, build-essential, curl, wget, vim)${NC}"
        echo -e " ${PURPLE}[2]${NC} ${WHITE}Git${NC}"
        echo -e " ${PURPLE}[3]${NC} ${WHITE}Python3 + pip${NC}"
        echo -e " ${PURPLE}[4]${NC} ${WHITE}Node.js + npm${NC}"
        echo -e " ${PURPLE}[5]${NC} ${WHITE}Build-essential${NC} ${CYAN}(gcc, make, dll)${NC}"
        echo -e " ${PURPLE}[6]${NC} ${WHITE}Kembali${NC}"
        echo -e "${PURPLE}------------------------------------------------------${NC}"
        echo -ne "${CYAN}[?] Pilihan:${NC} "
        read dev_choice

        local pkgs=""
        case "$dev_choice" in
            1) pkgs="git python3 python3-pip nodejs npm build-essential curl wget vim nano" ;;
            2) pkgs="git" ;;
            3) pkgs="python3 python3-pip" ;;
            4) pkgs="nodejs npm" ;;
            5) pkgs="build-essential" ;;
            6) break ;;
            *)
                echo -e "${NEON_PINK}[!] Pilihan tidak valid.${NC}"
                continue
                ;;
        esac

        echo -e "\n${PROCESS} ${CYAN}Menginstal: ${pkgs}...${NC}"
        proot-distro login ubuntu -- bash -c "apt update && apt install -y $pkgs"
        echo -e "${SUCCESS} ${WHITE}Selesai menginstal.${NC}"
    done
}

# --- FUNGSI PANEL MENU SHORTCUT ---
show_shortcut_menu() {
    animate_logo
    echo -e "${NEON_PINK}======================================================${NC}"
    echo -e "${WHITE}           NX_CODE CORE INTERFACE v1.0.1              ${NC}"
    echo -e "${NEON_PINK}======================================================${NC}"
    echo -e " ${PURPLE}[1]${NC} ${WHITE}Ubuntu CLI${NC}"
    echo -e " ${PURPLE}[2]${NC} ${WHITE}Ubuntu GUI (XFCE4 via Termux:X11)${NC}"
    echo -e " ${PURPLE}[3]${NC} ${WHITE}Kill Ubuntu GUI (XFCE4 via Termux:X11)${NC}"
    echo -e " ${PURPLE}[4]${NC} ${WHITE}Cek sesi xfce yang aktif${NC}"
    echo -e " ${PURPLE}[5]${NC} ${WHITE}Quick Dev-Tools Installer${NC}"
    echo -e " ${PURPLE}[6]${NC} ${WHITE}System Monitor (HTop)${NC}"
    echo -e " ${PURPLE}[7]${NC} ${WHITE}Kembali ke home${NC}"
    echo -e "${NEON_PINK}======================================================${NC}"
    echo -ne "${CYAN}[?] Select Option:${NC} "
    read pilihan

    case $pilihan in
        1)
            echo -e "\n${PROCESS} ${CYAN}Launching Ubuntu CLI Core...${NC}"
            sleep 1
            if is_ubuntu_installed; then
                proot-distro login ubuntu $(storage_bind_args)
            else
                echo -e "${NEON_PINK}[X] Error: Ubuntu OS belum diinstal. Jalankan ulang script secara manual.${NC}"
            fi
            ;;
        2)
            launch_ubuntu_gui
            sleep 1
            show_shortcut_menu
            ;;
        3)
            kill_ubuntu_gui
            sleep 1
            show_shortcut_menu
            ;;
        4)
            check_gui_session
            sleep 1
            show_shortcut_menu
            ;;
        5)
            quick_devtools_installer
            sleep 1
            show_shortcut_menu
            ;;
        6)
            echo -e "\n${PROCESS} ${CYAN}Booting HTop System Monitor...${NC}"
            sleep 0.5
            htop
            show_shortcut_menu
            ;;
        7)
            echo -e "\n${NEON_GREEN}[➔] Returning to home base.${NC}\n"
            ;;
        *)
            echo -e "\n\033[1;95m[!] ALERT: INVALID OPTION SELECTED.\033[0m"
            sleep 1
            show_shortcut_menu
            ;;
    esac
}

if [ "$1" == "--logo-only" ]; then
    animate_logo
    exit 0
fi

if [ "$1" == "--menu" ]; then
    show_shortcut_menu
    exit 0
fi

if [ "$1" == "--ui-only" ]; then
    animate_logo

    echo -ne "${CYAN}Syncing database"
    for i in {1..4}; do echo -ne "."; sleep 0.3; done
    echo -e " ${NEON_GREEN}Done!${NC}"

    echo -ne "${CYAN}Ubuntu check"
    for i in {1..5}; do echo -ne "."; sleep 0.3; done

    if is_ubuntu_installed; then
        echo -e " ${NEON_GREEN}[✔] Ubuntu Ready${NC}"
    else
        echo -e " ${NEON_PINK}[X] Ubuntu Not Installed${NC}"
    fi

    echo -ne "${CYAN}Storage check"
    for i in {1..3}; do echo -ne "."; sleep 0.2; done

    if is_storage_setup; then
        echo -e " ${NEON_GREEN}[✔] Storage Ready${NC}"
    else
        echo -e " ${NEON_PINK}[X] Storage Not Setup${NC} ${PURPLE}(jalankan manual: termux-setup-storage)${NC}"
    fi

    # Auto-cleaner: hanya jalan sekali per hari (bukan di setiap sesi terminal)
    # supaya tidak menghapus file sementara yang sedang dipakai proses lain,
    # dan tidak membebani setiap kali buka terminal.
    LAST_CLEAN_FILE="$HOME/.nx_code_last_clean"
    TODAY=$(date +%Y%m%d)
    LAST_CLEAN=""
    [ -f "$LAST_CLEAN_FILE" ] && LAST_CLEAN=$(cat "$LAST_CLEAN_FILE" 2>/dev/null)

    if [ "$TODAY" != "$LAST_CLEAN" ]; then
        (
            pkg clean -y
            # Guard: hanya hapus jika TMPDIR benar-benar terset dan merupakan direktori valid
            if [ -n "$TMPDIR" ] && [ -d "$TMPDIR" ]; then
                rm -rf "${TMPDIR:?}"/* 2>/dev/null
            fi
        ) > /dev/null 2>&1 &
        clean_pid=$!

        echo -ne "${CYAN}Auto-Cleaner Storage Termux"
        for i in {1..7}; do echo -ne "."; sleep 0.2; done
        wait $clean_pid 2>/dev/null
        echo -e " ${NEON_GREEN}[✔] Clean${NC}"
        echo "$TODAY" > "$LAST_CLEAN_FILE"
    fi

    echo -e "${PURPLE}Untuk masuk ke menu ketik ${CYAN}nx-menu${NC}\n"
    exit 0
fi

# ==============================================================================
# MODE INSTALASI AWAL
# ==============================================================================
animate_logo

(pkg update -y -o Dpkg::Options::="--force-confold") > /dev/null 2>&1 &
show_futuristic_progress "Updating Repositories..." $!

(pkg upgrade -y -o Dpkg::Options::="--force-confold") > /dev/null 2>&1 &
show_futuristic_progress "Upgrading System Core..." $!

(pkg install proot-distro htop coreutils -y -o Dpkg::Options::="--force-confold") > /dev/null 2>&1 &
show_futuristic_progress "Deploying Hypervisor..." $!

(pkg install x11-repo -y -o Dpkg::Options::="--force-confold") > /dev/null 2>&1 &
show_futuristic_progress "Adding X11 Repository..." $!

(pkg install termux-x11-nightly -y -o Dpkg::Options::="--force-confold") > /dev/null 2>&1 &
show_futuristic_progress "Deploying X11 Display Server..." $!

# Cek & Install Ubuntu menggunakan fungsi deteksi terpusat
if ! is_ubuntu_installed; then
    echo -e "${PROCESS} ${CYAN}Mempersiapkan unduhan Ubuntu OS...${NC}"
    proot-distro remove ubuntu > /dev/null 2>&1
    echo -e "${PURPLE}[!] System akan mengunduh Ubuntu secara live. Mohon tunggu...${NC}"
    echo "------------------------------------------------------"
    proot-distro install ubuntu
    echo "------------------------------------------------------"
fi

(sleep 1) &
show_futuristic_progress "Checking Hypervisor Distros..." $!

if is_ubuntu_installed; then
    echo -e "${SUCCESS} ${WHITE}Ubuntu Core OS           :${NC} ${NEON_GREEN}Installed & Ready${NC}"
else
    echo -e "${NEON_PINK}[X]${NC} ${WHITE}Ubuntu Core OS           :${NC} ${NEON_PINK}Installation Failed${NC}"
fi

if is_termux_x11_installed; then
    echo -e "${SUCCESS} ${WHITE}Termux-X11 Display Server:${NC} ${NEON_GREEN}Installed & Ready${NC}"
else
    echo -e "${NEON_PINK}[X]${NC} ${WHITE}Termux-X11 Display Server:${NC} ${NEON_PINK}Installation Failed${NC}"
fi
echo ""

(dpkg -l | grep "^ii" > "$TMPDIR/installed_pkgs.txt"; sleep 1) 2>/dev/null &
show_futuristic_progress "Scanning Modules..." $!

if [ -f "$TMPDIR/installed_pkgs.txt" ]; then
    total_pkgs=$(wc -l < "$TMPDIR/installed_pkgs.txt")
    echo -e "${PURPLE}--> Total paket terdeteksi: ${NEON_GREEN}${total_pkgs} paket${NC}"
    echo -e "${CYAN}--> Menampilkan beberapa core modul yang aktif:${NC}"
    awk '{print "    [+] " $2 " (v" $3 ")"}' "$TMPDIR/installed_pkgs.txt" | head -n 5
    rm -f "$TMPDIR/installed_pkgs.txt"
fi
echo ""

# --- SALIN SCRIPT KE LOKASI PERMANEN ---
# Diperbaiki: mendukung eksekusi via `bash <(wget -qO- URL)` atau `wget script.sh && bash script.sh`,
# di mana "$0" bisa berupa "bash" atau path sementara yang tidak valid dengan realpath.
copy_self_to_home() {
    local dest="$HOME/nx_code.sh"
    local src=""

    # Coba dapatkan path script yang sebenarnya jika dijalankan sebagai file biasa
    if [ -n "$BASH_SOURCE" ] && [ -f "${BASH_SOURCE[0]}" ]; then
        src=$(realpath "${BASH_SOURCE[0]}" 2>/dev/null)
    elif [ -f "$0" ]; then
        src=$(realpath "$0" 2>/dev/null)
    fi

    if [ -n "$src" ] && [ -f "$src" ] && [ "$src" != "$dest" ]; then
        cp "$src" "$dest"
        chmod +x "$dest"
        return 0
    fi

    # Fallback: jika dijalankan lewat pipe (curl/wget | bash) dan tidak ada file fisik,
    # dan file tujuan belum ada, beri tahu user secara eksplisit alih-alih gagal diam-diam.
    if [ ! -f "$dest" ]; then
        return 1
    fi
    return 0
}

if copy_self_to_home; then
    chmod +x "$HOME/nx_code.sh" 2>/dev/null
else
    echo -e "${NEON_PINK}[!] PERINGATAN: Script dijalankan lewat pipe (mis. wget -qO- | bash) sehingga tidak bisa disalin otomatis ke \$HOME/nx_code.sh.${NC}"
    echo -e "${PURPLE}    Silakan download file-nya dulu (mis. wget URL -O nx_code.sh) lalu jalankan: bash nx_code.sh${NC}"
fi

if ! grep -q "NX_CODE ENVIRONMENT" "$HOME/.bashrc" 2>/dev/null; then
    cat << 'EOF' >> "$HOME/.bashrc"

# --- NX_CODE ENVIRONMENT ---
if [ -f "$HOME/nx_code.sh" ]; then
    bash "$HOME/nx_code.sh" --ui-only
fi

alias ls='ls --color=auto --group-directories-first'
alias ll='ls -la --color=auto --group-directories-first'
alias nx-menu='bash $HOME/nx_code.sh --menu'

PS1="\[\033[1;95m\][═\[\033[0;36m\]NX_CODE\[\033[1;95m\]═] \[\033[1;32m\]⚡ \[\033[0m\]"

clear() {
    command clear
    if [ -f "$HOME/nx_code.sh" ]; then
        bash "$HOME/nx_code.sh" --logo-only
    fi
}

rm() {
    if [ $# -eq 0 ]; then
        echo -e "\033[1;95m[!] ALERT: NO TARGET SPECIFIED FOR PURGE MODULE.\033[0m"
        echo -e "\033[0;35m[?] SYSTEM HINT: Usage -> rm [file_name] or rm -rf [folder_name]\033[0m"
        return 1
    fi
    command rm -i "$@"
}

command_not_found_handle() {
    local cmd="$1"
    echo -e "\033[1;95m[!] ALERT: UNAUTHORIZED COMMAND '${cmd}' DETECTED.\033[0m"
    echo -e "\033[0;35m[?] SYSTEM HINT: Check your syntax or inject modules first.\033[0m"
    return 127
}
# ---------------------------
EOF
    echo -e "${SUCCESS} ${WHITE}Auto-Startup Profile     :${NC} ${NEON_GREEN}Injected Successfully${NC}"
else
    echo -e "${SUCCESS} ${WHITE}Auto-Startup Profile     :${NC} ${CYAN}Already Configured${NC}"
fi

echo -e "${NEON_PINK}======================================================${NC}"
echo -e "${NEON_GREEN}          SYSTEM INITIALIZED. NX_CODE ACTIVE.          ${NC}"
echo -e "${NEON_PINK}======================================================${NC}"

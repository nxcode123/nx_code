#!/data/data/com.termux/files/usr/bin/bash

# --- KONFIGURASI UPDATE (GANTI SESUAI REPO GITHUB KAMU) ---
# Ganti USERNAME di bawah dengan username GitHub kamu sebelum publish/pakai fitur update.
NX_CODE_REPO_RAW_URL="https://raw.githubusercontent.com/nxcode123/nx_code/main/nx_code.sh"

# --- KONFIGURASI APP STORE (REPO KE-2, GANTI KALAU NAMA REPO BEDA) ---
NX_APPS_MANIFEST_URL="https://raw.githubusercontent.com/nxcode123/nx_code_app/main/apps.list"
NX_APPS_SCRIPTS_BASE_URL="https://raw.githubusercontent.com/nxcode123/nx_code_app/main/scripts"

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

# --- LOG ERROR (biar output yang kecepetan lewat bisa dibaca ulang nanti) ---
NX_LOG="$HOME/.nx_code_error.log"

log_section() {
    echo "" >> "$NX_LOG"
    echo "===== $(date '+%Y-%m-%d %H:%M:%S') | $1 =====" >> "$NX_LOG"
}

# --- FUNGSI CEK STATUS UBUNTU (terpusat) ---
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
        chmod 755 /storage
        grep -q ELECTRON_DISABLE_SANDBOX /etc/environment 2>/dev/null || echo 'ELECTRON_DISABLE_SANDBOX=true' >> /etc/environment
    "
}

# --- FUNGSI CEK STATUS SHARED STORAGE ---
is_storage_setup() {
    [ -d "$HOME/storage/shared" ]
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

# --- FUNGSI FIX OTOMATIS "--no-sandbox" ---
setup_no_sandbox_fix() {
    proot-distro login ubuntu -- bash -c "mkdir -p /etc/profile.d; echo 'export ELECTRON_DISABLE_SANDBOX=1' > /etc/profile.d/nx_no_sandbox.sh" >/dev/null 2>&1
    local apps="google-chrome google-chrome-stable chromium chromium-browser"
    local app
    for app in $apps; do
        proot-distro login ubuntu -- bash -c "test -x /usr/bin/$app && ! test -f /usr/local/bin/$app && { printf '#!/bin/bash\nexec /usr/bin/%s --no-sandbox \"\$@\"\n' '$app' > /usr/local/bin/$app; chmod +x /usr/local/bin/$app; }" >/dev/null 2>&1
    done
}

# --- FUNGSI LAUNCH GUI UBUNTU ---
launch_ubuntu_gui() {
    if ! is_ubuntu_installed; then
        echo -e "\n${NEON_PINK}[X] Error: Ubuntu OS belum diinstal.${NC}"
        return 1
    fi

    if ! is_termux_x11_installed; then
        echo -e "\n${NEON_PINK}[X] Error: termux-x11 belum terpasang. Jalankan ulang installer script.${NC}"
        return 1
    fi

    if ! is_xfce4_installed; then
        echo -e "\n${PROCESS} ${CYAN}XFCE4 belum terpasang di Ubuntu. Menginstal sekarang (sekali saja)...${NC}"
        echo -e "${PURPLE}[!] Proses ini bisa memakan waktu cukup lama tergantung koneksi.${NC}"
        log_section "INSTALL XFCE4"
        proot-distro login ubuntu -- bash -c "apt update && apt upgrade -y && apt install xfce4 xfce4-goodies dbus-x11 x11-xserver-utils sudo -y" 2>&1 | tee -a "$NX_LOG"
        if ! is_xfce4_installed; then
            echo -e "${NEON_PINK}[X] Instalasi XFCE4 gagal. Cek log lengkap di menu [8] Log error.${NC}"
            return 1
        fi
        echo -e "${SUCCESS} ${WHITE}XFCE4 berhasil dipasang di Ubuntu.${NC}"
    fi

    if ! proot-distro login ubuntu -- bash -c "[ -f /usr/share/xfce4/backdrops/xubuntu-wallpaper.png ]" >/dev/null 2>&1; then
        proot-distro login ubuntu -- bash -c "mkdir -p /usr/share/xfce4/backdrops && echo 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=' | base64 -d > /usr/share/xfce4/backdrops/xubuntu-wallpaper.png" 2>/dev/null
    fi

    if ! is_nonroot_user_setup; then
        echo -e "\n${PROCESS} ${CYAN}Menyiapkan user non-root '$NX_USER' (sekali saja)...${NC}"
        setup_nonroot_user
        if is_nonroot_user_setup; then
            echo -e "${SUCCESS} ${WHITE}User '$NX_USER' berhasil dibuat.${NC}"
        else
            echo -e "${NEON_PINK}[!] Gagal membuat user non-root, sesi GUI akan tetap jalan sebagai root.${NC}"
        fi
    fi

    setup_no_sandbox_fix

    choose_resolution
    if [ "$GUI_CANCELLED" -eq 1 ]; then
        echo -e "\n${NEON_GREEN}[➔] Dibatalkan, kembali ke menu utama.${NC}"
        return 0
    fi
    write_gui_startup_script

    pkill -f "termux-x11" >/dev/null 2>&1
    sleep 1

    echo -e "\n${PROCESS} ${CYAN}Menyalakan server X11 (display :2) & masuk ke Ubuntu XFCE4...${NC}"

    if is_nonroot_user_setup; then
        cat > "$HOME/.nx_x11_launch.sh" << WRAPEOF
#!/data/data/com.termux/files/usr/bin/bash
proot-distro login ubuntu --shared-tmp --user $NX_USER -- bash /usr/local/bin/nx-gui-startup.sh
WRAPEOF
    else
        cat > "$HOME/.nx_x11_launch.sh" << WRAPEOF
#!/data/data/com.termux/files/usr/bin/bash
proot-distro login ubuntu --shared-tmp -- bash /usr/local/bin/nx-gui-startup.sh
WRAPEOF
    fi
    chmod +x "$HOME/.nx_x11_launch.sh"

    log_section "GUI LAUNCH (display :2)"
    termux-x11 :2 -xstartup "bash $HOME/.nx_x11_launch.sh" 2>&1 | tee -a "$NX_LOG" &
    X11_PID=$!

    sleep 2
    if ! kill -0 "$X11_PID" 2>/dev/null; then
        echo -e "${NEON_PINK}[X] Gagal menyalakan server X11.${NC}"
        echo -e "${PURPLE}[?] Pastikan aplikasi 'Termux:X11' sudah terinstal dan coba lagi.${NC}"
        echo -e "${PURPLE}[?] Detail lengkap ada di menu [8] Log error.${NC}"
        return 1
    fi

    am start --user 0 -n com.termux.x11/com.termux.x11.MainActivity >/dev/null 2>&1

    echo -e "${PROCESS} ${CYAN}Buka aplikasi 'Termux:X11' di Android kalau belum otomatis terbuka.${NC}\n"

    show_futuristic_progress "GUI Ubuntu Aktif (Termux:X11)..." "$X11_PID"
    wait "$X11_PID" 2>/dev/null

    echo -e "\n${NEON_GREEN}[➔] Sesi GUI Ubuntu ditutup.${NC}"
}

# --- FUNGSI KILL GUI UBUNTU ---
kill_ubuntu_gui() {
    echo -e "\n${PROCESS} ${CYAN}Mematikan sesi GUI Ubuntu (XFCE4 & Termux:X11)...${NC}"

    local found=0

    if pkill -f "termux-x11" >/dev/null 2>&1; then
        found=1
    fi

    # Update: Targetkan proses xfce hanya untuk nxuser agar tidak menabrak proses lain
    if proot-distro login ubuntu -- bash -c "pkill -u $NX_USER -f 'xfce4|dbus-launch|Xwayland' 2>/dev/null || pkill -f 'xfce4|dbus-launch|Xwayland'" >/dev/null 2>&1; then
        found=1
    fi

    sleep 1

    if [ "$found" -eq 1 ]; then
        echo -e "${SUCCESS} ${WHITE}Sesi GUI Ubuntu berhasil dimatikan.${NC}"
    else
        echo -e "${NEON_PINK}[X]${NC} ${WHITE}Tidak ada sesi GUI yang sedang berjalan.${NC}"
    fi
}

# --- FUNGSI CEK SESI GUI AKTIF ---
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

# --- FUNGSI QUICK DEV-TOOLS INSTALLER ---
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
        log_section "DEV-TOOLS INSTALL ($pkgs)"
        proot-distro login ubuntu -- bash -c "apt update && apt install -y $pkgs" 2>&1 | tee -a "$NX_LOG"
        echo -e "${SUCCESS} ${WHITE}Selesai menginstal.${NC}"
    done
}

# --- FUNGSI CHECK UPDATE ---
check_for_update() {
    echo -e "\n${PROCESS} ${CYAN}Mengecek update dari GitHub...${NC}"

    local tmp_file="$HOME/.nx_code_update_tmp.sh"
    rm -f "$tmp_file"

    if ! curl --max-time 20 --retry 2 --retry-delay 2 -fsSL "$NX_CODE_REPO_RAW_URL" -o "$tmp_file" 2>/dev/null; then
        echo -e "${NEON_PINK}[X] Gagal mengambil update. Cek koneksi internet atau URL repo di NX_CODE_REPO_RAW_URL.${NC}"
        rm -f "$tmp_file"
        return 1
    fi

    if [ ! -s "$tmp_file" ]; then
        echo -e "${NEON_PINK}[X] File update kosong/tidak valid. Cek URL repo.${NC}"
        rm -f "$tmp_file"
        return 1
    fi

    if diff -q "$tmp_file" "$HOME/nx_code.sh" >/dev/null 2>&1; then
        echo -e "${SUCCESS} ${WHITE}Sudah pakai versi terbaru. Tidak ada update.${NC}"
        rm -f "$tmp_file"
        return 0
    fi

    echo -e "${SUCCESS} ${WHITE}Update ditemukan! Menerapkan...${NC}"
    mv "$tmp_file" "$HOME/nx_code.sh"
    chmod +x "$HOME/nx_code.sh"

    sed -i '/# --- NX_CODE ENVIRONMENT ---/,/# ---------------------------/d' "$HOME/.bashrc" 2>/dev/null

    echo -e "${PROCESS} ${CYAN}Menjalankan ulang installer (reinstall + restart terminal)...${NC}"
    sleep 1
    exec bash "$HOME/nx_code.sh"
}

# --- FUNGSI LIHAT LOG ERROR ---
view_error_log() {
    while true; do
        echo -e "\n${PURPLE}------------------------------------------------------${NC}"
        echo -e "${WHITE}LOG ERROR${NC}"
        echo -e " ${PURPLE}[1]${NC} ${WHITE}Lihat log terbaru (50 baris terakhir)${NC}"
        echo -e " ${PURPLE}[2]${NC} ${WHITE}Lihat semua log${NC}"
        echo -e " ${PURPLE}[3]${NC} ${WHITE}Hapus log${NC}"
        echo -e " ${PURPLE}[4]${NC} ${WHITE}Kembali${NC}"
        echo -e "${PURPLE}------------------------------------------------------${NC}"
        echo -ne "${CYAN}[?] Pilihan:${NC} "
        read log_choice

        case "$log_choice" in
            1)
                if [ -s "$NX_LOG" ]; then
                    echo -e "\n${PURPLE}------------------------------------------------------${NC}"
                    tail -n 50 "$NX_LOG"
                    echo -e "${PURPLE}------------------------------------------------------${NC}"
                else
                    echo -e "${SUCCESS} ${WHITE}Log masih kosong, belum ada error tercatat.${NC}"
                fi
                ;;
            2)
                if [ -s "$NX_LOG" ]; then
                    echo -e "\n${PURPLE}------------------------------------------------------${NC}"
                    cat "$NX_LOG"
                    echo -e "${PURPLE}------------------------------------------------------${NC}"
                    echo -e "${CYAN}[?] Geser/scroll ke atas buat baca dari awal.${NC}"
                else
                    echo -e "${SUCCESS} ${WHITE}Log masih kosong, belum ada error tercatat.${NC}"
                fi
                ;;
            3)
                rm -f "$NX_LOG"
                echo -e "${SUCCESS} ${WHITE}Log dihapus.${NC}"
                ;;
            4) break ;;
            *)
                echo -e "${NEON_PINK}[!] Pilihan tidak valid.${NC}"
                ;;
        esac
    done
}

# --- FUNGSI APP STORE ---
app_store_menu() {
    if ! is_ubuntu_installed; then
        echo -e "\n${NEON_PINK}[X] Error: Ubuntu OS belum diinstal.${NC}"
        return 1
    fi

    echo -e "\n${PROCESS} ${CYAN}Mengambil daftar app dari repo...${NC}"

    local manifest="$HOME/.nx_apps_manifest.tmp"
    rm -f "$manifest"

    if ! curl --max-time 20 --retry 2 --retry-delay 2 -fsSL "$NX_APPS_MANIFEST_URL" -o "$manifest" 2>/dev/null; then
        echo -e "${NEON_PINK}[X] Gagal ambil daftar app. Cek koneksi internet atau URL di NX_APPS_MANIFEST_URL.${NC}"
        rm -f "$manifest"
        return 1
    fi

    if [ ! -s "$manifest" ]; then
        echo -e "${NEON_PINK}[X] Daftar app kosong/tidak valid.${NC}"
        rm -f "$manifest"
        return 1
    fi

    # Bersihkan CRLF (Windows line ending) dari manifest sebelum diparse,
    # supaya field terakhir (nama file .desktop) tidak kebawa '\r' tersembunyi.
    sed -i 's/\r$//' "$manifest" 2>/dev/null

    local names=() scripts=() descs=() desktops=()
    while IFS='|' read -r a_name a_script a_desc a_desktop; do
        [ -z "$a_name" ] && continue
        names+=("$a_name")
        scripts+=("$a_script")
        descs+=("$a_desc")
        desktops+=("$a_desktop")
    done < "$manifest"
    rm -f "$manifest"

    if [ "${#names[@]}" -eq 0 ]; then
        echo -e "${NEON_PINK}[X] Daftar app kosong.${NC}"
        return 1
    fi

    local installed=()
    local check_cmd=""
    for i in "${!names[@]}"; do
        installed[$i]=0
        if [ -n "${desktops[$i]}" ]; then
            check_cmd+="[ -f /usr/share/applications/${desktops[$i]} ] && echo FOUND_$i; "
        fi
    done
    if [ -n "$check_cmd" ]; then
        local check_result
        check_result=$(proot-distro login ubuntu -- bash -c "$check_cmd" 2>/dev/null)
        for i in "${!names[@]}"; do
            if echo "$check_result" | grep -q "^FOUND_${i}$"; then
                installed[$i]=1
            fi
        done
    fi

    while true; do
        echo -e "\n${PURPLE}------------------------------------------------------${NC}"
        echo -e "${WHITE}APP STORE${NC}"
        for i in "${!names[@]}"; do
            if [ "${installed[$i]}" -eq 1 ]; then
                printf " ${PURPLE}[%d]${NC} ${WHITE}%s${NC} ${CYAN}- %s${NC} ${NEON_GREEN}[✔ Terinstall]${NC}\n" "$((i+1))" "${names[$i]}" "${descs[$i]}"
            else
                printf " ${PURPLE}[%d]${NC} ${WHITE}%s${NC} ${CYAN}- %s${NC}\n" "$((i+1))" "${names[$i]}" "${descs[$i]}"
            fi
        done
        echo -e " ${PURPLE}[0]${NC} ${WHITE}Kembali${NC}"
        echo -e "${PURPLE}------------------------------------------------------${NC}"
        echo -ne "${CYAN}[?] Pilihan:${NC} "
        read app_choice

        if [ "$app_choice" == "0" ]; then
            break
        fi

        local idx=$((app_choice - 1))
        if [ -z "${names[$idx]:-}" ]; then
            echo -e "${NEON_PINK}[!] Pilihan tidak valid.${NC}"
            continue
        fi

        echo -e "\n${PROCESS} ${CYAN}Menginstal ${names[$idx]}...${NC}"
        log_section "APP INSTALL: ${names[$idx]}"

        # Update: Eksekusi yang diunduh ke file temporary, bukan blind curl | bash
        local target_url="$NX_APPS_SCRIPTS_BASE_URL/${scripts[$idx]}"
        local tmp_script="$HOME/.tmp_install_$(basename "${scripts[$idx]}")"

        if curl --max-time 30 --retry 2 --retry-delay 2 -fsSL "$target_url" -o "$tmp_script"; then
            if [ -s "$tmp_script" ]; then
                echo -e "${PROCESS} ${CYAN}Menjalankan script instalasi...${NC}"
                proot-distro login ubuntu -- bash < "$tmp_script" 2>&1 | tee -a "$NX_LOG"

                if [ ${PIPESTATUS[0]} -eq 0 ]; then
                    echo -e "${SUCCESS} ${WHITE}Selesai instal ${names[$idx]}.${NC}"
                else
                    echo -e "${NEON_PINK}[X] Terjadi error saat instalasi ${names[$idx]}. Cek log!${NC}"
                fi
            else
                echo -e "${NEON_PINK}[X] Gagal: Script yang diunduh kosong atau URL tidak valid.${NC}"
            fi
        else
            echo -e "${NEON_PINK}[X] Gagal mengunduh script. Cek koneksi internet Anda.${NC}"
        fi

        rm -f "$tmp_script"

        local d_file="${desktops[$idx]}"
        if [ -n "$d_file" ] && is_nonroot_user_setup; then
            proot-distro login ubuntu -- bash -c "
                if [ -f /usr/share/applications/$d_file ]; then
                    mkdir -p /home/$NX_USER/Desktop
                    cp /usr/share/applications/$d_file /home/$NX_USER/Desktop/
                    chmod +x /home/$NX_USER/Desktop/$d_file
                    chown -R $NX_USER:$NX_USER /home/$NX_USER/Desktop
                    gio set /home/$NX_USER/Desktop/$d_file metadata::trusted true 2>/dev/null || true
                fi
            " >/dev/null 2>&1
            echo -e "${PURPLE}[i] Shortcut ditambahkan ke Desktop (kalau perlu, klik kanan > Allow Launching sekali pertama).${NC}"
        fi

        if [ -n "$d_file" ]; then
            if proot-distro login ubuntu -- bash -c "[ -f /usr/share/applications/$d_file ]" >/dev/null 2>&1; then
                installed[$idx]=1
            fi
        fi
    done
}

# --- FUNGSI PANEL MENU SHORTCUT ---
show_shortcut_menu() {
    while true; do
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
        echo -e " ${PURPLE}[7]${NC} ${WHITE}Check update${NC}"
        echo -e " ${PURPLE}[8]${NC} ${WHITE}Log error${NC}"
        echo -e " ${PURPLE}[9]${NC} ${WHITE}App${NC}"
        echo -e " ${PURPLE}[0]${NC} ${WHITE}Kembali ke home${NC}"
        echo -e "${NEON_PINK}======================================================${NC}"
        echo -ne "${CYAN}[?] Select Option:${NC} "
        read pilihan

        case $pilihan in
            1)
                echo -e "\n${PROCESS} ${CYAN}Launching Ubuntu CLI Core...${NC}"
                sleep 1
                if is_ubuntu_installed; then
                    proot-distro login ubuntu
                else
                    echo -e "${NEON_PINK}[X] Error: Ubuntu OS belum diinstal. Jalankan ulang script secara manual.${NC}"
                fi
                sleep 1
                ;;
            2)
                launch_ubuntu_gui
                sleep 1
                ;;
            3)
                kill_ubuntu_gui
                sleep 1
                ;;
            4)
                check_gui_session
                sleep 1
                ;;
            5)
                quick_devtools_installer
                sleep 1
                ;;
            6)
                echo -e "\n${PROCESS} ${CYAN}Booting HTop System Monitor...${NC}"
                sleep 0.5
                htop
                ;;
            7)
                check_for_update
                sleep 1
                ;;
            8)
                view_error_log
                sleep 1
                ;;
            9)
                app_store_menu
                sleep 1
                ;;
            0)
                echo -e "\n${NEON_GREEN}[➔] Returning to home base.${NC}\n"
                break
                ;;
            *)
                echo -e "\n\033[1;95m[!] ALERT: INVALID OPTION SELECTED.\033[0m"
                sleep 1
                ;;
        esac
    done
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

    LAST_CLEAN_FILE="$HOME/.nx_code_last_clean"
    TODAY=$(date +%Y%m%d)
    LAST_CLEAN=""
    [ -f "$LAST_CLEAN_FILE" ] && LAST_CLEAN=$(cat "$LAST_CLEAN_FILE" 2>/dev/null)

    if [ "$TODAY" != "$LAST_CLEAN" ]; then
        (
            pkg clean -y
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

    echo -e "${NEON_PINK}======================================================${NC}"
    echo ""
    echo -e " ${NEON_PINK}[ ! ]${NC} ${WHITE}ketik ${CYAN}nx-menu${WHITE} untuk akses menu${NC}"
    echo ""
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

copy_self_to_home() {
    local dest="$HOME/nx_code.sh"
    local src=""

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

if grep -q 'command rm -i "\$@"' "$HOME/.bashrc" 2>/dev/null; then
    sed -i 's/command rm -i "\$@"/command rm "\$@"/' "$HOME/.bashrc"
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
    command rm "$@"
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

(dpkg -l | grep "^ii" > "$TMPDIR/installed_pkgs.txt"; sleep 1) 2>/dev/null &
show_futuristic_progress "Scanning Modules..." $!

if [ -f "$TMPDIR/installed_pkgs.txt" ]; then
    total_pkgs=$(wc -l < "$TMPDIR/installed_pkgs.txt")
    echo -e "${PURPLE}--> Total paket terdeteksi: ${NEON_GREEN}${total_pkgs} paket${NC}"
    echo -e "${CYAN}--> Menampilkan beberapa core modul yang aktif:${NC}"
    awk '{print "    [+] " $2 " (v" $3 ")"}' "$TMPDIR/installed_pkgs.txt" | head -n 5
    rm -f "$TMPDIR/installed_pkgs.txt"
fi

echo -e "${NEON_GREEN}[Complete]${NC}"
echo -e "${NEON_PINK}======================================================${NC}"
echo -e "${NEON_GREEN}          SYSTEM INITIALIZED. NX_CODE ACTIVE.          ${NC}"
echo -e "${NEON_PINK}======================================================${NC}"

echo -e "${WHITE}Menu :${NC}"
echo -e " ${PURPLE}[1]${NC} ${WHITE}Restart${NC}"
echo -e " ${PURPLE}[2]${NC} ${WHITE}Exit${NC}"
echo -ne "${CYAN}[?] Pilihan:${NC} "
read final_choice

case "$final_choice" in
    1)
        exec bash
        ;;
    *)
        exit 0
        ;;
esac

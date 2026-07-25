#!/data/data/com.termux/files/usr/bin/bash
# ==============================================================================
# NXC SHARED UI LIBRARY (nxc_lib.sh)
# Dipakai bersama oleh nxc_ubuntu.sh (sisi Termux) dan nxc1.sh (sisi Ubuntu),
# supaya fungsi UI (spinner, progress bar, banner, logger, warna) tidak
# terduplikasi di dua tempat.
#
# CARA PAKAI (di script pemanggil):
#   LOG_FILE="$HOME/namafile.log"      # wajib di-set SEBELUM source
#   source "/path/ke/nxc_lib.sh"
#   > "$LOG_FILE"                       # inisialisasi log (dilakukan pemanggil)
#   show_banner "TERMUX-UBUNTU" "1.2.3" # judul & versi custom per script
#
# File ini HANYA berisi definisi (warna, fungsi). Tidak ada side-effect saat
# di-source (tidak jalankan apa pun sendiri), supaya aman dipakai di kedua sisi.
# ==============================================================================

# ANSI Cyberpunk Color Palette
NEON_GREEN='\033[38;5;46m'
NEON_CYAN='\033[38;5;51m'
NEON_PINK='\033[38;5;198m'
NEON_YELLOW='\033[38;5;226m'
DARK_GRAY='\033[38;5;238m'
WHITE='\033[1;37m'
RED='\033[1;31m'
NC='\033[0m'

# show_banner <title> <version>
show_banner() {
    local title="${1:-NXC}"
    local version="${2:-0.0.0}"
    clear
    printf "\033[?25l"
    echo -e "${NEON_GREEN}[NXC]  ${title}  [v${version}]${NC}"
    echo -e "${DARK_GRAY}----------------------------------------${NC}\n"
}

# log_msg <pesan>
# Membutuhkan variabel LOG_FILE sudah di-set oleh script pemanggil.
log_msg() {
    if [ -z "$LOG_FILE" ]; then
        return 0
    fi
    echo "[$(date +'%T')] $1" >> "$LOG_FILE"
}

# run_with_spinner <label> <command_string>
run_with_spinner() {
    local text="$1"
    local cmd="$2"

    log_msg "START: $text"
    eval "$cmd" >> "${LOG_FILE:-/dev/null}" 2>&1 &
    local pid=$!

    local spin='⣾⣽⣻⢿⡿⣟⣯⣷'
    local i=0

    printf "${NEON_CYAN}[*] ${WHITE}%s ${NC}" "$text"

    while kill -0 "$pid" 2>/dev/null; do
        printf "\b${NEON_PINK}%s${NC}" "${spin:i:1}"
        i=$(( (i+1) % 8 ))
        sleep 0.1 2>/dev/null || read -t 0.1
    done

    wait "$pid"
    local status=$?
    if [ $status -eq 0 ]; then
        printf "\b${NEON_GREEN}[✔ SYNCED]${NC}\n"
        log_msg "SUCCESS: $text"
    else
        printf "\b${RED}[✖ FAILED] - Cek log${NC}\n"
        log_msg "ERROR: $text (Exit code: $status)"
        printf "\033[?25h"
        if [ -n "$LOG_FILE" ] && [ -f "$LOG_FILE" ]; then
            echo -e "\n${RED}[!] Detail error sistem dari log:${NC}"
            tail -n 10 "$LOG_FILE"
        fi
        return $status
    fi
}

# run_with_progress_bar <label> <estimasi_detik> <command_string>
run_with_progress_bar() {
    local text="$1"
    local est_time="$2"
    local cmd="$3"

    log_msg "START (Progress): $text"
    echo -e "${NEON_CYAN}[*] ${WHITE}${text}${NC}"

    eval "$cmd" >> "${LOG_FILE:-/dev/null}" 2>&1 &
    local pid=$!

    local width=35
    local elapsed=0
    local interval=0.2

    while kill -0 "$pid" 2>/dev/null; do
        local percent=$(( (elapsed * 100) / (est_time * 5) ))
        if [ "$percent" -ge 98 ]; then percent=98; fi

        local filled=$(( (percent * width) / 100 ))
        local empty=$(( width - filled ))

        local bar=""
        for ((i=0; i<filled; i++)); do bar+="█"; done
        for ((i=0; i<empty; i++)); do bar+="░"; done

        printf "\r${DARK_GRAY} ↳ ${NEON_PINK}[${NEON_GREEN}%-${width}s${NEON_PINK}] ${NEON_YELLOW}%3d%% ${NC}" "$bar" "$percent"

        sleep $interval 2>/dev/null || read -t 0.2
        elapsed=$((elapsed + 1))
    done

    wait "$pid"
    local status=$?

    if [ $status -eq 0 ]; then
        local bar=""
        for ((i=0; i<width; i++)); do bar+="█"; done
        printf "\r${DARK_GRAY} ↳ ${NEON_PINK}[${NEON_GREEN}%-${width}s${NEON_PINK}] ${NEON_GREEN}100%% [✔ SECURED]${NC}\n" "$bar"
        log_msg "SUCCESS (Progress): $text"
    else
        local bar=""
        for ((i=0; i<width; i++)); do bar+="█"; done
        printf "\r${DARK_GRAY} ↳ ${NEON_PINK}[${RED}%-${width}s${NEON_PINK}] ${RED}ERR%% [✖ FAILED] ${NC}\n" "$bar"
        log_msg "ERROR (Progress): $text (Exit code: $status)"
        echo -e "${RED}[!] FATAL ERROR: Silakan cek log untuk detailnya.${NC}"
        if [ -n "$LOG_FILE" ] && [ -f "$LOG_FILE" ]; then
            tail -n 10 "$LOG_FILE"
        fi
        return $status
    fi
}

# download_and_validate <url> <target_path> [max_attempts=3] [timeout=10]
# Helper umum: download dengan retry, validasi bash -n sebelum dipakai.
# Dipakai baik untuk update nxc_ubuntu.sh, nxc1.sh, maupun nxc_lib.sh sendiri.
download_and_validate() {
    local url="$1"
    local target="$2"
    local attempts="${3:-3}"
    local timeout="${4:-10}"
    local tmp="${target}.tmp"

    mkdir -p "$(dirname "$target")"

    local attempt
    for (( attempt=1; attempt<=attempts; attempt++ )); do
        if curl -sf -L --max-time "$timeout" "$url" -o "$tmp"; then
            if [ -s "$tmp" ] && bash -n "$tmp" 2>/dev/null; then
                mv "$tmp" "$target"
                chmod +x "$target"
                return 0
            fi
        fi
        rm -f "$tmp"
        sleep 1
    done
    return 1
}

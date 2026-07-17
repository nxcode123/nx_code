#!/bin/bash
# ==============================================================================
# KEAMANAN – Validasi, Trap, Sanitasi
# ==============================================================================

# --- Trap untuk cleanup ---
cleanup() {
    echo -e "\n${WARNING} Interrupted by user."
    pkill -f "termux-x11 :2" 2>/dev/null
    echo -ne "\033[?25h"
    exit 0
}
trap cleanup SIGINT SIGTERM

# --- Validasi input (hanya angka) ---
validate_number() {
    [[ "$1" =~ ^[0-9]+$ ]]
}

# --- Validasi input (ya/tidak) ---
confirm() {
    local prompt="$1"
    local answer
    while true; do
        read -p "$prompt (y/n): " answer
        case "$answer" in
            y|Y|yes|Yes) return 0 ;;
            n|N|no|No) return 1 ;;
            *) echo -e "${ERROR} Jawab y atau n." ;;
        esac
    done
}

# --- Sanitasi path ---
sanitize_path() {
    echo "$1" | sed 's/\.\.//g; s/\/\//\//g'
}

# --- Cek internet ---
check_internet() {
    if ping -c 1 -W 2 8.8.8.8 >/dev/null 2>&1; then
        return 0
    else
        echo -e "${ERROR} Tidak ada koneksi internet."
        return 1
    fi
}

#!/bin/bash
# ==============================================================================
# FUNGSI UTILITY – Warna, Logging, Progress, Logo
# ==============================================================================

# --- Warna ---
CYAN='\033[0;36m'
NEON_GREEN='\033[1;32m'
NEON_PINK='\033[1;95m'
PURPLE='\033[0;35m'
WHITE='\033[1;37m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

SUCCESS="${NEON_GREEN}[✔]${NC}"
ERROR="${NEON_PINK}[✘]${NC}"
PROCESS="${CYAN}[➔]${NC}"
WARNING="${YELLOW}[⚠]${NC}"
INFO="${CYAN}[i]${NC}"

# --- Logging ---
log_message() {
    local level="$1"
    local msg="$2"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$level] $msg" >> "$LOG_FILE"
}
log_info() { log_message "INFO" "$1"; }
log_error() { log_message "ERROR" "$1"; }
log_warning() { log_message "WARNING" "$1"; }

# --- Progress Bar ---
show_progress() {
    local message="$1"
    local pid=$2
    local ticks=0
    echo -ne "\033[?25l"
    while kill -0 "$pid" 2>/dev/null; do
        local bar_size=15
        local fill=$((ticks % (bar_size + 1)))
        local bar=""
        for ((j=0; j<fill; j++)); do bar="${bar}="; done
        [ $fill -lt $bar_size ] && bar="${bar}>"
        for ((j=fill+1; j<bar_size; j++)); do bar="${bar} "; done
        printf "\r${PROCESS} %-25s ${CYAN}[${NEON_PINK}%s${CYAN}]${PURPLE} (%ds)${NC}" "$message" "$bar" "$ticks"
        sleep 0.2
        ((ticks++))
    done
    printf "\r\033[K${SUCCESS} %-25s ${NEON_GREEN}[DONE]${NC}\n" "$message"
    echo -ne "\033[?25h"
}

# --- Logo Cyberpunk ---
animate_logo() {
    clear
    echo -e "${NEON_PINK}======================================================"
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
    echo -e "${PURPLE}------------------------------------------------------"
    echo -e "${WHITE} SYSTEM STATUS: ${NEON_GREEN}ONLINE${WHITE} | VERSION: ${NEON_PINK}${VERSION}${NC}"
    echo -e "${NEON_PINK}======================================================"
    echo ""
}

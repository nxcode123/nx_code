#!/data/data/com.termux/files/usr/bin/bash
# ==============================================================================
# Source file : nxc_lib.sh
# THEME       : CLEAN MODERN CLI (Minimalist & Professional)
# ==============================================================================

# 🎨 Palette Warna Clean & Modern
CYBER_BLUE='\033[38;5;39m'
TOXIC_GREEN='\033[38;5;46m'
CORRUPT_RED='\033[38;5;196m'
LIGHT_GRAY='\033[38;5;250m'
DARK_GRAY='\033[38;5;240m'
WHITE='\033[1;37m'
NC='\033[0m'

# ==============================================================================
# show_banner <title> <version>
# ==============================================================================
show_banner() {
    local title="${1:-NXC}"
    local version="${2:-0.0.0}"
    clear
    printf "\033[?25l"
    echo -e "${CYBER_BLUE}==>${WHITE} ${title} ${DARK_GRAY}(v${version})${NC}\n"
}

# ==============================================================================
# log_msg <pesan>
# ==============================================================================
log_msg() {
    if [ -z "$LOG_FILE" ]; then
        return 0
    fi
    echo "[$(date +'%T')] $1" >> "$LOG_FILE"
}

# ==============================================================================
# run_with_spinner <label> <command_string>
# ==============================================================================
run_with_spinner() {
    local text="$1"
    local cmd="$2"

    log_msg "START: $text"
    eval "$cmd" >> "${LOG_FILE:-/dev/null}" 2>&1 &
    local pid=$!

    local spin='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    local i=0

    printf "\033[?25l"

    while kill -0 "$pid" 2>/dev/null; do
        printf "\r${CYBER_BLUE}[%s]${NC} ${LIGHT_GRAY}%s...${NC}" "${spin:i:1}" "$text"
        i=$(( (i+1) % 10 ))
        sleep 0.1 2>/dev/null || read -t 0.1
    done

    wait "$pid"
    local status=$?
    if [ $status -eq 0 ]; then
        printf "\r${TOXIC_GREEN}[✔]${NC} ${WHITE}%s ${NC}\n" "$text"
        log_msg "SUCCESS: $text"
    else
        printf "\r${CORRUPT_RED}[✖]${NC} ${WHITE}%s ${NC}\n" "$text"
        log_msg "ERROR: $text (Exit code: $status)"
        printf "\033[?25h"
        if [ -n "$LOG_FILE" ] && [ -f "$LOG_FILE" ]; then
            echo -e "\n${CORRUPT_RED}[!] Log error:${NC}"
            tail -n 10 "$LOG_FILE"
        fi
        return $status
    fi
}

# ==============================================================================
# run_with_progress_bar <label> <estimasi_detik> <command_string>
# ==============================================================================
run_with_progress_bar() {
    local text="$1"
    local est_time="$2"
    local cmd="$3"

    log_msg "START (Progress): $text"
    echo -e "${CYBER_BLUE}[i]${NC} ${WHITE}${text}${NC}"

    eval "$cmd" >> "${LOG_FILE:-/dev/null}" 2>&1 &
    local pid=$!

    local width=30
    local elapsed=0
    local interval=0.2

    while kill -0 "$pid" 2>/dev/null; do
        local percent=$(( (elapsed * 100) / (est_time * 5) ))
        if [ "$percent" -ge 98 ]; then percent=98; fi

        local filled=$(( (percent * width) / 100 ))
        local empty=$(( width - filled ))

        local bar=""
        for ((i=0; i<filled; i++)); do bar+="="; done
        for ((i=0; i<empty; i++)); do bar+=" "; done

        # Style terminal modern: [====>     ] 45%
        local head=">"
        [ "$filled" -eq 0 ] && head=""
        
        printf "\r    ${CYBER_BLUE}[%-${width}s]${NC} %3d%%" "${bar}${head}" "$percent"

        sleep $interval 2>/dev/null || read -t 0.2
        elapsed=$((elapsed + 1))
    done

    wait "$pid"
    local status=$?

    if [ $status -eq 0 ]; then
        local bar=""
        for ((i=0; i<width; i++)); do bar+="="; done
        printf "\r    ${TOXIC_GREEN}[%s]${NC} 100%%\n" "$bar"
        log_msg "SUCCESS (Progress): $text"
    else
        printf "\r    ${CORRUPT_RED}[GAGAL]${NC}\n"
        log_msg "ERROR (Progress): $text (Exit code: $status)"
        if [ -n "$LOG_FILE" ] && [ -f "$LOG_FILE" ]; then
            tail -n 10 "$LOG_FILE"
        fi
        return $status
    fi
}

# ==============================================================================
# download_and_validate <url> <target_path> [max_attempts=3] [timeout=10]
# ==============================================================================
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

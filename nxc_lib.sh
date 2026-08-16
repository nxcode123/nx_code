#!/usr/bin/env bash
# ==============================================================================
# PROJECT     : NX_CODE
# FILE        : nxc_lib.sh
# DESCRIPTION : Core Shared Library (UI Components, Logging & Helpers)
# VERSION     : 1.3.1
# ==============================================================================

# 🎨 Default Palette Warna (Cyberpunk Neon)
CYBER_BLUE='\033[38;5;39m'
NEON_GREEN='\033[38;5;46m'
NEON_CYAN='\033[38;5;51m'
NEON_PINK='\033[38;5;198m'
NEON_YELLOW='\033[38;5;226m'
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
    local title="${1:-NX_CODE}"
    local version="${2:-1.3.1}"
    clear
    printf "\033[?25l"
    echo -e "${CYBER_BLUE}====================================================${NC}"
    echo -e "${NEON_GREEN} ${title} ${NC}${DARK_GRAY}// PRO-EDITION [v${version}]${NC}"
    echo -e "${CYBER_BLUE}====================================================${NC}\n"
}

# ==============================================================================
# log_msg <pesan>
# ==============================================================================
log_msg() {
    if [ -n "$LOG_FILE" ]; then
        echo "[$(date +'%Y-%m-%d %T')] $1" >> "$LOG_FILE"
    fi
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
    printf "${CYBER_BLUE}[*] ${WHITE}%s ${NC}" "$text"

    while kill -0 "$pid" 2>/dev/null; do
        printf "\b${NEON_PINK}%s${NC}" "${spin:i:1}"
        i=$(( (i+1) % 10 ))
        read -r -t 0.15 _ 2>/dev/null || sleep 0.15 2>/dev/null || true
    done

    wait "$pid"
    local status=$?
    if [ $status -eq 0 ]; then
        printf "\b${NEON_GREEN}[✔ SYNCED]${NC}\n"
        log_msg "SUCCESS: $text"
        return 0
    else
        printf "\b${CORRUPT_RED}[✖ GAGAL]${NC}\n"
        log_msg "ERROR: $text (Exit code: $status)"
        printf "\033[?25h"
        if [ -n "$LOG_FILE" ] && [ -f "$LOG_FILE" ]; then
            echo -e "\n${CORRUPT_RED}[!] Error log detail:${NC}"
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
    echo -e "${CYBER_BLUE}[*] ${WHITE}${text}${NC}"

    eval "$cmd" >> "${LOG_FILE:-/dev/null}" 2>&1 &
    local pid=$!

    local width=30
    local elapsed=0
    local max_ticks=$(( est_time * 5 ))
    [ "$max_ticks" -le 0 ] && max_ticks=50

    while kill -0 "$pid" 2>/dev/null; do
        local percent=$(( (elapsed * 100) / max_ticks ))
        [ "$percent" -ge 98 ] && percent=98

        local filled=$(( (percent * width) / 100 ))
        local empty=$(( width - filled ))

        local bar=""
        for ((i=0; i<filled; i++)); do bar+="█"; done
        for ((i=0; i<empty; i++)); do bar+="░"; done

        printf "\r${DARK_GRAY} ↳ ${NEON_PINK}[${NEON_GREEN}%s${NEON_PINK}] ${NEON_YELLOW}%3d%%${NC} " "$bar" "$percent"

        read -r -t 0.2 _ 2>/dev/null || sleep 0.2 2>/dev/null || true
        elapsed=$((elapsed + 1))
    done

    wait "$pid"
    local status=$?

    local bar=""
    for ((i=0; i<width; i++)); do bar+="█"; done

    if [ $status -eq 0 ]; then
        printf "\r${DARK_GRAY} ↳ ${NEON_PINK}[${NEON_GREEN}%s${NEON_PINK}] ${NEON_GREEN}100%% [✔ SECURED]${NC}\n" "$bar"
        log_msg "SUCCESS (Progress): $text"
        return 0
    else
        printf "\r${DARK_GRAY} ↳ ${NEON_PINK}[${CORRUPT_RED}%s${NEON_PINK}] ${CORRUPT_RED}ERR%% [✖ FAILED]${NC}\n" "$bar"
        log_msg "ERROR (Progress): $text (Exit code: $status)"
        printf "\033[?25h"
        if [ -n "$LOG_FILE" ] && [ -f "$LOG_FILE" ]; then
            echo -e "\n${CORRUPT_RED}[!] Error log detail:${NC}"
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
        if curl -fsSL --max-time "$timeout" "$url" -o "$tmp"; then
            if [ -s "$tmp" ]; then
                # Jika target adalah script shell, pastikan sintaks valid
                if [[ "$target" == *.sh ]] && ! bash -n "$tmp" 2>/dev/null; then
                    rm -f "$tmp"
                    continue
                fi
                mv "$tmp" "$target"
                chmod +x "$target" 2>/dev/null || true
                return 0
            fi
        fi
        rm -f "$tmp"
        sleep 1
    done
    return 1
}

# ==============================================================================
# load_active_theme <themes_dir> <theme_name_or_file>
# ==============================================================================
load_active_theme() {
    local dir="$1"
    local selected="$2"
    local target_file=""

    if [ -f "$selected" ]; then
        target_file="$selected"
    elif [ -f "$dir/${selected}.sh" ]; then
        target_file="$dir/${selected}.sh"
    elif [ -f "$dir/cyberpunk.sh" ]; then
        target_file="$dir/cyberpunk.sh"
    fi

    if [ -n "$target_file" ] && [ -f "$target_file" ]; then
        # shellcheck disable=SC1090
        source "$target_file"
    fi
}

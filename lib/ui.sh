#!/data/data/com.termux/files/usr/bin/bash
# ==============================================================================
# lib/ui.sh — Core UI Utilities (Logo, Progress Bar, Spinner)
# Dimuat oleh: nx_code.sh
# Dependensi: lib/config.sh (variabel warna & NX_VERSION, ACTIVE_THEME)
# ==============================================================================

# ------------------------------------------------------------------------------
# animate_logo
#   Tampilkan banner NX_CODE dengan animasi
# ------------------------------------------------------------------------------
animate_logo() {
    command clear
    echo -e "${NEON_PINK}╔══════════════════════════════════════════════════════╗${NC}"
    local lines=(
        "  _   _ __  __        ____ ___  ____  _____ "
        " | \\ | |\\ \\/ /       / ___/ _ \\|  _ \\| ____|"
        " |  \\| | \\  /  _____ | |  | | | | | | |  _|  "
        " | |\\  | /  \\ |_____ | |__| |_| | |_| | |___ "
        " |_| \\_|/_/\\_\\       \\____\\___/|____/|_____| TERMINAL"
    )
    for line in "${lines[@]}"; do
        printf "${PURPLE}%s${NC}\\r" "$line"
        sleep 0.02
        printf "${CYAN}%s${NC}\\n" "$line"
    done
    echo -e "${NEON_PINK}╠══════════════════════════════════════════════════════╣${NC}"
    echo -e "${WHITE} STATUS: ${NEON_GREEN}ONLINE${WHITE}  │  THEME: ${NEON_PINK}${ACTIVE_THEME^^}${WHITE}  │  VER: ${CYAN}${NX_VERSION}${NC}"
    echo -e "${NEON_PINK}╚══════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# ------------------------------------------------------------------------------
# execute_task <pesan> <perintah...>
#   Jalankan perintah di background dengan spinner & exit-code yang akurat
# ------------------------------------------------------------------------------
execute_task() {
    local msg="$1"
    shift
    local tmp_log
    tmp_log=$(mktemp)
    local spinner=( "⠋" "⠙" "⠹" "⠸" "⠼" "⠴" "⠦" "⠧" "⠇" "⠏" )
    local i=0
    local start_time
    start_time=$(date +%s)

    ( "$@" ) >"$tmp_log" 2>&1 &
    local pid=$!

    echo -ne "\033[?25l"
    while kill -0 "$pid" 2>/dev/null; do
        local current_time elapsed last_line=""
        current_time=$(date +%s)
        elapsed=$((current_time - start_time))

        if [ -f "$tmp_log" ]; then
            last_line=$(tail -n 1 "$tmp_log" 2>/dev/null \
                | sed -r "s/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[mGK]//g" \
                | tr -d '\n\r' | cut -c 1-24)
        fi

        printf "\r\033[2K${NEON_PINK}%s${NC} ${WHITE}%-18s${NC} ${CYAN}│${NC} ${PURPLE}%-24s${NC} ${CYAN}(%ds)${NC}" \
            "${spinner[$i]}" "$msg" "$last_line" "$elapsed"

        i=$(( (i + 1) % ${#spinner[@]} ))
        sleep 0.1
    done

    wait "$pid"
    local exit_code=$?
    local end_time elapsed
    end_time=$(date +%s)
    elapsed=$((end_time - start_time))

    echo -ne "\033[?25h"
    if [ $exit_code -eq 0 ]; then
        printf "\r\033[2K${SUCCESS} ${WHITE}%-18s${NC} ${CYAN}│${NC} ${NEON_GREEN}COMPLETED${NC}                       ${CYAN}(%ds)${NC}\n" \
            "$msg" "$elapsed"
    else
        printf "\r\033[2K${NEON_PINK}[✘]${NC} ${WHITE}%-18s${NC} ${CYAN}│${NC} ${NEON_PINK}FAILED (Code: %d)${NC}                 ${CYAN}(%ds)${NC}\n" \
            "$msg" "$exit_code" "$elapsed"
        if [ -f "$tmp_log" ] && [ -s "$tmp_log" ]; then
            local err_preview
            err_preview=$(tail -n 2 "$tmp_log" | tr '\n' ' ' | cut -c 1-75)
            [ -n "$err_preview" ] && echo -e "${PURPLE}     ↳ Detail: ${WHITE}${err_preview}${NC}"
        fi
    fi

    rm -f "$tmp_log"
    return $exit_code
}

# ------------------------------------------------------------------------------
# show_live_progress_loop <pesan> <pid>
#   Tampilkan spinner live selama proses berjalan
# ------------------------------------------------------------------------------
show_live_progress_loop() {
    local msg="$1"
    local pid="$2"
    local spinner=( "⠋" "⠙" "⠹" "⠸" "⠼" "⠴" "⠦" "⠧" "⠇" "⠏" )
    local i=0
    local start_time
    start_time=$(date +%s)

    echo -ne "\033[?25l"
    while kill -0 "$pid" 2>/dev/null; do
        local current_time elapsed
        current_time=$(date +%s)
        elapsed=$((current_time - start_time))
        printf "\r\033[2K${NEON_PINK}%s${NC} ${WHITE}%-20s${NC} ${CYAN}│${NC} ${NEON_GREEN}ACTIVE${NC} ${CYAN}(%ds)${NC}" \
            "${spinner[$i]}" "$msg" "$elapsed"
        i=$(( (i + 1) % ${#spinner[@]} ))
        sleep 0.2
    done
    echo -ne "\033[?25h"
}

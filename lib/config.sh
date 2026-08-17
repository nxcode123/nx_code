#!/data/data/com.termux/files/usr/bin/bash
# ==============================================================================
# lib/config.sh — Konfigurasi Global & Sistem Tema
# Dimuat oleh: nx_code.sh
# ==============================================================================

# --- URL & Versi ---
NX_CODE_REPO_RAW_URL="https://raw.githubusercontent.com/nxcode123/nx_code/main/nx_code.sh"
NX_THEMES_MANIFEST_URL="https://raw.githubusercontent.com/nxcode123/nx_code/main/themes/theme.list"
NX_THEMES_BASE_URL="https://raw.githubusercontent.com/nxcode123/nx_code/main/themes"
NX_LIB_BASE_URL="https://raw.githubusercontent.com/nxcode123/nx_code/main/lib"
NX_VERSION="v1.3.0"
NX_USER="nxuser"

# --- Opsi Curl ---
NX_CURL_OPTS="-fsSL --connect-timeout 5 --max-time 15 --retry 2"

# --- Path ---
NX_HOME="$HOME/.nx_code"
NX_LIB_DIR="$NX_HOME/lib"
THEME_DIR="$NX_HOME/themes"
CONFIG_FILE="$NX_HOME/config"

# --- Cleanup terminal saat skrip selesai/dihentikan ---
cleanup_terminal() {
    echo -ne "\033[?25h\033[0m"
}
trap cleanup_terminal EXIT INT TERM

# ------------------------------------------------------------------------------
# apply_theme <nama_tema>
#   Muat file tema dari: repo lokal → cache → GitHub
# ------------------------------------------------------------------------------
apply_theme() {
    local theme="${1:-cyberpunk}"
    local theme_file="$THEME_DIR/${theme}.sh"
    local local_repo_theme="./themes/${theme}.sh"

    mkdir -p "$THEME_DIR" 2>/dev/null

    # 1. Salin dari repo lokal jika ada
    if [ ! -s "$theme_file" ] && [ -s "$local_repo_theme" ]; then
        cp "$local_repo_theme" "$theme_file" 2>/dev/null
    fi

    # 2. Download dari GitHub jika belum ada
    if [ ! -s "$theme_file" ]; then
        curl $NX_CURL_OPTS "$NX_THEMES_BASE_URL/${theme}.sh" -o "$theme_file" 2>/dev/null
    fi

    # 3. Source tema atau gunakan fallback warna
    if [ -s "$theme_file" ]; then
        source "$theme_file" 2>/dev/null
    else
        CYAN='\033[0;36m'
        NEON_GREEN='\033[1;32m'
        NEON_PINK='\033[1;95m'
        PURPLE='\033[0;35m'
        WHITE='\033[1;37m'
        NC='\033[0m'
    fi

    SUCCESS="${NEON_GREEN}[✔]${NC}"
    PROCESS="${CYAN}[➔]${NC}"
    ACTIVE_THEME="$theme"
}

# ------------------------------------------------------------------------------
# init_theme_system
#   Inisialisasi sistem tema saat startup
# ------------------------------------------------------------------------------
init_theme_system() {
    mkdir -p "$THEME_DIR" 2>/dev/null

    # Salin semua tema dari repo lokal jika tersedia
    if [ -d "./themes" ]; then
        cp -r ./themes/* "$THEME_DIR/" 2>/dev/null || true
    fi

    ACTIVE_THEME="cyberpunk"
    [ -f "$CONFIG_FILE" ] && source "$CONFIG_FILE" 2>/dev/null

    apply_theme "$ACTIVE_THEME"
}

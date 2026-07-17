#!/data/data/com.termux/files/usr/bin/bash
# ==============================================================================
# NX_CODE MAIN ENTRY POINT
# ==============================================================================

# --- Tentukan lokasi script ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export NX_CODE_HOME="$SCRIPT_DIR"

# --- Load semua modul ---
source "$NX_CODE_HOME/src/core/config.sh"
source "$NX_CODE_HOME/src/core/utils.sh"
source "$NX_CODE_HOME/src/core/security.sh"
source "$NX_CODE_HOME/src/modules/ubuntu.sh"
source "$NX_CODE_HOME/src/modules/gui.sh"
source "$NX_CODE_HOME/src/modules/tools.sh"
source "$NX_CODE_HOME/src/modules/backup.sh"
source "$NX_CODE_HOME/src/modules/update.sh"
source "$NX_CODE_HOME/src/menu/main_menu.sh"

# --- Inisialisasi ---
init_config
init_status_cache
log_info "==================== NX_CODE START ===================="

# --- Auto-Update (jika bukan mode khusus) ---
if [[ "$1" != "--no-update" ]] && [[ "$1" != "--logo-only" ]]; then
    auto_update
fi

# --- Eksekusi berdasarkan argumen ---
case "$1" in
    --logo-only)
        animate_logo
        exit 0
        ;;
    --menu|"")
        show_main_menu
        exit 0
        ;;
    --update)
        auto_update --force
        exit 0
        ;;
    --info)
        show_system_info
        exit 0
        ;;
    *)
        echo -e "${ERROR} Argumen tidak dikenal: $1"
        echo -e "Gunakan: nx [--menu|--update|--info|--logo-only]"
        exit 1
        ;;
esac

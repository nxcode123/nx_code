#!/bin/bash
# ==============================================================================
# MODUL BACKUP – Backup & Restore Konfigurasi
# ==============================================================================

backup_file() {
    local file="$1"
    local backup_name="$(basename "$file").backup.$(date +%s)"
    cp "$file" "$BACKUP_DIR/$backup_name" 2>/dev/null
    echo -e "${SUCCESS} Backup: $backup_name"
}

restore_backup() {
    local file="$1"
    local latest=$(ls -t "$BACKUP_DIR/$(basename "$file")".backup.* 2>/dev/null | head -n1)
    if [ -f "$latest" ]; then
        cp "$latest" "$file"
        echo -e "${SUCCESS} Restore dari $(basename "$latest")"
    else
        echo -e "${WARNING} Tidak ada backup."
    fi
}

list_backups() {
    echo -e "\n${WHITE}Backup files:${NC}"
    ls -lh "$BACKUP_DIR" 2>/dev/null || echo -e "${PURPLE}Belum ada backup.${NC}"
}

manage_backup_menu() {
    while true; do
        echo -e "\n${PURPLE}------------------------------------------------------"
        echo -e "${WHITE}BACKUP MANAGER"
        echo -e " ${PURPLE}[1]${NC} Backup .bashrc"
        echo -e " ${PURPLE}[2]${NC} Restore .bashrc"
        echo -e " ${PURPLE}[3]${NC} List backups"
        echo -e " ${PURPLE}[4]${NC} Kembali"
        echo -ne "${CYAN}[?] Pilihan: ${NC}"
        read choice
        case "$choice" in
            1) backup_file "$HOME/.bashrc" ;;
            2) restore_backup "$HOME/.bashrc" ;;
            3) list_backups ;;
            4) break ;;
            *) echo -e "${ERROR} Invalid." ;;
        esac
    done
}

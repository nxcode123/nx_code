#!/bin/bash
# ==============================================================================
# MODUL UPDATE – Auto-update dari GitHub
# ==============================================================================

get_github_version() {
    curl -s "$GITHUB_RAW_URL/main.sh" | grep -m1 'VERSION=' | cut -d'"' -f2
}

check_update() {
    local remote=$(get_github_version)
    [ -z "$remote" ] && return 2
    [ "$remote" != "$VERSION" ] && echo "$remote" && return 0
    return 1
}

download_update() {
    local tmp="$CONFIG_DIR/main.sh.new"
    curl -sL "$GITHUB_RAW_URL/main.sh" -o "$tmp" && [ -s "$tmp" ] && echo "$tmp" && return 0
    rm -f "$tmp"
    return 1
}

install_update() {
    local new="$1"
    [ ! -f "$new" ] && return 1
    backup_file "$CONFIG_DIR/main.sh"
    mv "$new" "$CONFIG_DIR/main.sh"
    chmod +x "$CONFIG_DIR/main.sh"
    echo -e "${SUCCESS} Update berhasil! Versi: $(grep -m1 'VERSION=' "$CONFIG_DIR/main.sh" | cut -d'"' -f2)"
    log_info "Updated to new version"
    exec bash "$CONFIG_DIR/main.sh" --menu
}

auto_update() {
    [ "$AUTO_UPDATE_ENABLED" != "true" ] && return 0
    local now=$(date +%s)
    local last=0
    [ -f "$LAST_UPDATE_CHECK" ] && last=$(cat "$LAST_UPDATE_CHECK" 2>/dev/null || echo 0)
    [ $((now - last)) -lt $UPDATE_INTERVAL ] && return 0
    echo "$now" > "$LAST_UPDATE_CHECK"

    echo -e "${PROCESS} Mengecek update..."
    local remote=$(check_update)
    case $? in
        0) echo -e "${INFO} Versi baru: ${NEON_PINK}${remote}${NC}"
           confirm "Install update sekarang?" || return 0
           local tmp=$(download_update)
           [ $? -eq 0 ] && install_update "$tmp" ;;
        1) echo -e "${SUCCESS} Versi terbaru (${CYAN}${VERSION}${NC})." ;;
        2) echo -e "${WARNING} Gagal cek update." ;;
    esac
}

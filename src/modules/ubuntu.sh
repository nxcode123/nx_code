#!/bin/bash
# ==============================================================================
# MODUL UBUNTU – Install, Cek, CLI
# ==============================================================================

is_ubuntu_installed() {
    proot-distro login ubuntu -- true >/dev/null 2>&1
}

install_ubuntu() {
    if [ "$UBUNTU_INSTALLED" = "yes" ]; then
        echo -e "${SUCCESS} Ubuntu sudah terinstall."
        return 0
    fi
    echo -e "${PROCESS} ${CYAN}Menginstall Ubuntu...${NC}"
    proot-distro install ubuntu
    update_status_cache
    if is_ubuntu_installed; then
        echo -e "${SUCCESS} Ubuntu berhasil diinstall."
        log_info "Ubuntu installed"
        return 0
    else
        echo -e "${ERROR} Gagal install Ubuntu."
        log_error "Ubuntu install failed"
        return 1
    fi
}

ubuntu_cli() {
    if ! is_ubuntu_installed; then
        echo -e "${ERROR} Ubuntu tidak terinstall."
        return 1
    fi
    proot-distro login ubuntu $(storage_bind_args)
}

# --- Cache status ---
update_status_cache() {
    UBUNTU_INSTALLED=$(is_ubuntu_installed && echo "yes" || echo "no")
    TERMUX_X11_INSTALLED=$(command -v termux-x11 >/dev/null && echo "yes" || echo "no")
    STORAGE_SETUP=$([ -d "$HOME/storage/shared" ] && echo "yes" || echo "no")
}

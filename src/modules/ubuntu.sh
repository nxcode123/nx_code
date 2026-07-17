#!/bin/bash
# ==============================================================================
# MODUL UBUNTU – Auto-install, Cek, CLI, dan Update Status
# ==============================================================================

# --- Cek status Ubuntu (cache) ---
is_ubuntu_installed() {
    proot-distro login ubuntu -- true >/dev/null 2>&1
}

# --- Install Ubuntu otomatis jika belum ada ---
install_ubuntu_if_needed() {
    if is_ubuntu_installed; then
        return 0
    fi

    echo -e "${PROCESS} ${CYAN}Ubuntu belum terinstall. Menginstall sekarang...${NC}"
    echo -e "${PURPLE}Proses ini memakan waktu dan kuota (~200-300 MB).${NC}"

    if ! check_internet; then
        return 1
    fi

    # Install proot-distro jika belum
    command -v proot-distro >/dev/null || pkg install proot-distro -y

    proot-distro install ubuntu
    if is_ubuntu_installed; then
        echo -e "${SUCCESS} Ubuntu berhasil diinstall."
        log_info "Ubuntu installed successfully"
        UBUNTU_INSTALLED="yes"
        return 0
    else
        echo -e "${ERROR} Gagal install Ubuntu. Coba manual: proot-distro install ubuntu"
        log_error "Ubuntu installation failed"
        return 1
    fi
}

# --- Fungsi update status cache (dipanggil dari luar) ---
update_status_cache() {
    UBUNTU_INSTALLED=$(is_ubuntu_installed && echo "yes" || echo "no")
    TERMUX_X11_INSTALLED=$(command -v termux-x11 >/dev/null && echo "yes" || echo "no")
    STORAGE_SETUP=$([ -d "$HOME/storage/shared" ] && echo "yes" || echo "no")
}

# --- Storage bind args ---
storage_bind_args() {
    [ "$STORAGE_SETUP" = "yes" ] && echo "--bind $HOME/storage/shared:/root/storage"
}

# --- Jalankan Ubuntu CLI (otomatis install jika perlu) ---
ubuntu_cli() {
    if ! install_ubuntu_if_needed; then
        echo -e "${ERROR} Tidak bisa melanjutkan tanpa Ubuntu."
        return 1
    fi
    echo -e "${PROCESS} ${CYAN}Masuk ke Ubuntu CLI...${NC}"
    proot-distro login ubuntu $(storage_bind_args)
}

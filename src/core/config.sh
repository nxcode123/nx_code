#!/bin/bash
# ==============================================================================
# KONFIGURASI GLOBAL NX_CODE
# ==============================================================================

VERSION="3.0.0"
LOG_FILE="$HOME/.nx_code/nx_code.log"
CONFIG_DIR="$HOME/.nx_code"
BACKUP_DIR="$CONFIG_DIR/backups"
LAST_UPDATE_CHECK="$CONFIG_DIR/.last_update_check"
VERSION_FILE="$CONFIG_DIR/.version"

# --- Konfigurasi GitHub ---
GITHUB_USER="nxcode123"
GITHUB_REPO="nx_code"
GITHUB_BRANCH="main"
GITHUB_RAW_URL="https://raw.githubusercontent.com/$GITHUB_USER/$GITHUB_REPO/$GITHUB_BRANCH"

# --- Auto-Update ---
AUTO_UPDATE_ENABLED="true"
UPDATE_INTERVAL=86400   # 24 jam

# --- Status cache ---
UBUNTU_INSTALLED="no"
TERMUX_X11_INSTALLED="no"
STORAGE_SETUP="no"

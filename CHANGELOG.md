# Changelog

All notable changes to NX_CODE will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [3.0.0] - 2024-07-17

### 🚀 Added (Total Rewrite – Modular Architecture)
- **Modular structure** – Code split into core, modules, and menu for better maintenance and scalability.
- **One-command installer** – `installer.sh` downloads all components from GitHub and sets up the environment automatically.
- **Centralized configuration** – All settings in `src/core/config.sh` (version, GitHub, paths, update interval).
- **Utility module** – Colors, logging, progress bar, logo animation, and common helpers.
- **Security module** – Trap cleanup, input validation, path sanitization, confirmation prompts.
- **Backup & Restore Manager** – Backup/restore `.bashrc` and other config files with timestamp.
- **Update module** – Auto-update system now fully separated and more reliable.
- **Submenu support** – Prepared structure for future submenus (Ubuntu, Tools, etc.).
- **Better logging** – All activities logged with timestamps and levels (INFO, WARN, ERROR).
- **Clean main menu** – Simplified, responsive, and easier to navigate.

### 🔄 Changed
- Project structure reorganized – `src/core/`, `src/modules/`, `src/menu/`.
- Installer now downloads **multiple files** instead of a single monolithic script.
- Alias updated – `nx` for main menu, `nx-update`, `nx-info`.
- Versioning follows SemVer strictly.
- `.bashrc` configuration now uses `NX_CODE_HOME` environment variable.

### 🗑️ Removed
- Monolithic `nx_code.sh` replaced by modular system.
- Hardcoded variables moved to config file.

### 🐛 Fixed
- GUI kill process now more reliable.
- Update check timeout improved.
- Resolution selection now correctly handled.
- Better error messages throughout.

### 📝 Documentation
- Added comprehensive `README.md` with installation, usage, and structure.
- Added this `CHANGELOG.md`.

---

## [2.0.0] - 2024-01-15 (Legacy Monolithic)

### Added
- Auto-update system – script checks for updates from GitHub.
- Backup & Restore Manager.
- Multi-distro preparation (Debian, Fedora planned).
- System Information command (`nx-info`).
- Logging system with activity log.
- Internet connection check before downloads.
- Cleanup trap for GUI sessions.

### Changed
- Performance optimization with status caching.
- Better error messages.
- Structured directories for config (`~/.nx_code/`).
- More reliable GUI launch with `setsid`.
- Preset resolutions: 720x1440, 1080x1920.

### Fixed
- Progress bar timing.
- GUI session not properly killed.
- Storage binding when not setup.
- Cursor hiding on script interruption.

---

## [1.0.0] - 2024-01-01 (Initial Release)

### Added
- Ubuntu CLI support in Termux.
- Ubuntu GUI (XFCE4) with Termux:X11.
- Cyberpunk theme with neon colors.
- Quick Dev-Tools installer (git, python, nodejs, build-essential, etc.).
- Menu-based interface.
- Custom `rm` with safety prompt.
- `command_not_found` handler with cyberpunk style.

---

## [Unreleased]

### Planned Features
- [ ] VNC support for headless GUI.
- [ ] Custom themes (dark, light, cyberpunk).
- [ ] Support for Debian and Fedora.
- [ ] Docker container integration.
- [ ] Plugin system for third-party modules.

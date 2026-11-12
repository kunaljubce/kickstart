#!/bin/sh
set -eu

resolution=""
while getopts "r:" opt; do
    case "$opt" in
        r) resolution=$OPTARG ;;
        *) echo "Usage: $0 [-r resolution]" >&2; exit 1 ;;
    esac
done

detect_platform() {
    case "$(uname -s)" in
        Darwin) echo "mac" ;;
        Linux)
            if grep -qi microsoft /proc/version 2>/dev/null; then
                echo "wsl"
            else
                echo "linux"
            fi
            ;;
        *) echo "unsupported" ;;
    esac
}

detect_linux_pkg_manager() {
    if command -v apt-get >/dev/null 2>&1; then echo "apt"
    elif command -v dnf >/dev/null 2>&1; then echo "dnf"
    elif command -v pacman >/dev/null 2>&1; then echo "pacman"
    else echo "none"
    fi
}

ensure_brew() {
    if command -v brew >/dev/null 2>&1; then
        return
    fi
    # Homebrew on Apple Silicon may be installed but not yet on PATH
    if [ -x /opt/homebrew/bin/brew ]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [ -x /usr/local/bin/brew ]; then
        eval "$(/usr/local/bin/brew shellenv)"
    else
        echo "Homebrew not found. Install it from https://brew.sh and re-run." >&2
        exit 1
    fi
}

PLATFORM=$(detect_platform)
echo "Detected platform: $PLATFORM"

case "$PLATFORM" in
    mac)
        ensure_brew
        PKG="brew"
        ;;
    linux|wsl)
        PKG=$(detect_linux_pkg_manager)
        ;;
    *)
        echo "Unsupported OS: $(uname -s)" >&2
        exit 1
        ;;
esac

# Check for available package upgrades and upgrade the required packages, if needed
upgrade_packages() {
    case "$PKG" in
        brew)
            brew update
            if [ -z "$(brew outdated)" ]; then
                echo "Nothing to update, proceeding to next steps!"
            else
                echo "Updating required packages..."
                brew upgrade
            fi
            ;;
        apt)
            sudo apt-get update
            if [ "$(apt list --upgradable 2>/dev/null | grep -c upgradable)" -eq 0 ]; then
                echo "Nothing to update, proceeding to next steps!"
            else
                echo "Updating required packages..."
                sudo apt-get -y upgrade
            fi
            ;;
        dnf)    sudo dnf -y upgrade ;;
        pacman) sudo pacman -Syu --noconfirm ;;
        *)      echo "No supported package manager found." >&2; exit 1 ;;
    esac
}

install_packages() {
    case "$PKG" in
        brew)   brew install "$@" ;;
        apt)    sudo apt-get install -y "$@" ;;
        dnf)    sudo dnf install -y "$@" ;;
        pacman) sudo pacman -S --needed --noconfirm "$@" ;;
    esac
}

upgrade_packages

# Install `tree` and `curl` packages
echo "Installing tree and curl packages..."
install_packages tree curl

# Resolution handling (optional, platform-specific)
if [ -n "$resolution" ]; then
    case "$PLATFORM" in
        linux)
            if command -v xrandr >/dev/null 2>&1; then
                display_name=$(xrandr | grep " connected primary" | cut -d' ' -f1)
                xrandr --output "$display_name" --mode "$resolution"
            else
                echo "xrandr not available; skipping resolution change."
            fi
            ;;
        mac)
            echo "Use 'displayplacer' (brew install displayplacer) to set resolution on macOS; skipping."
            ;;
        wsl)
            echo "Display resolution is managed by Windows under WSL; skipping."
            ;;
    esac
fi

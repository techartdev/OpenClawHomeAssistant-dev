#!/usr/bin/env bash
# Wrapper script for brew that runs as linuxbrew user when called by root
# This is needed because Homebrew refuses to run as root

REAL_BREW="/home/linuxbrew/.linuxbrew/bin/brew"

if [ "$(id -u)" = "0" ]; then
    # Running as root - use su to run as linuxbrew
    exec su -s /bin/bash linuxbrew -c "\"$REAL_BREW\" $*"
else
    # Not root - run directly
    exec "$REAL_BREW" "$@"
fi

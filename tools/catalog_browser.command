#!/bin/sh
SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
cd "$SCRIPT_DIR/.." || exit 1
if command -v python3 >/dev/null 2>&1; then
    exec python3 "$SCRIPT_DIR/catalog_browser.py"
fi
if command -v python >/dev/null 2>&1; then
    exec python "$SCRIPT_DIR/catalog_browser.py"
fi
printf '%s\n' 'Python 3 was not found. Please install Python 3 and try again.'
read -r _

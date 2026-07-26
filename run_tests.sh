#!/usr/bin/env sh
set -u

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
PROJECT="$ROOT/GameProject"

if [ -n "${GODOT_BIN:-}" ]; then
    GODOT=$GODOT_BIN
elif command -v godot >/dev/null 2>&1; then
    GODOT=godot
elif command -v godot4 >/dev/null 2>&1; then
    GODOT=godot4
elif [ -x "/Applications/Godot.app/Contents/MacOS/Godot" ]; then
    GODOT=/Applications/Godot.app/Contents/MacOS/Godot
else
    echo "Godot executable was not found."
    echo "Checked: GODOT_BIN, PATH: godot, PATH: godot4, /Applications/Godot.app/Contents/MacOS/Godot"
    exit 1
fi

"$GODOT" --headless --quiet --no-header --path "$PROJECT" --script "res://scripts/tests/tutorial_and_floors_test.gd"
status=$?
if [ "$status" -eq 0 ]; then
    echo "ALL TESTS PASSED"
fi
exit "$status"

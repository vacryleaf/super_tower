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
elif [ -x "/Applications/Godot.app/Contents/MacOS/Godot" ]; then
    GODOT=/Applications/Godot.app/Contents/MacOS/Godot
else
    echo "Godot executable was not found."
    echo "Checked: GODOT_BIN, PATH: godot, PATH: godot4, /Applications/Godot.app/Contents/MacOS/Godot"
    exit 1
fi

TEST_LOG=$(mktemp "${TMPDIR:-/tmp}/super_tower_tests.XXXXXX")
set +e
"$GODOT" --headless --quiet --no-header --path "$PROJECT" --script "res://scripts/tests/tutorial_and_floors_test.gd" >"$TEST_LOG" 2>&1
status=$?
set -e
cat "$TEST_LOG"
if grep -Eq "Failed to load script|Compilation failed|SCRIPT ERROR" "$TEST_LOG"; then
    status=1
fi
rm -f "$TEST_LOG"
if [ "$status" -ne 0 ]; then
    exit "$status"
fi

echo "ALL TESTS PASSED"
exit 0

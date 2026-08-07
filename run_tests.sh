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

TEST_HOME=$(mktemp -d "${TMPDIR:-/tmp}/super_tower_test_home.XXXXXX")
TEST_LOG_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/super_tower_test_logs.XXXXXX")
trap 'rm -rf "$TEST_HOME" "$TEST_LOG_ROOT"' EXIT HUP INT TERM

run_test() {
    test_name="$1"
    test_log=$(mktemp "$TEST_LOG_ROOT/${test_name}.XXXXXX")
    godot_log=$(mktemp "$TEST_LOG_ROOT/${test_name}.godot.XXXXXX")
    HOME="$TEST_HOME" \
    USERPROFILE="$TEST_HOME" \
    XDG_DATA_HOME="$TEST_HOME/data" \
    XDG_CONFIG_HOME="$TEST_HOME/config" \
    XDG_CACHE_HOME="$TEST_HOME/cache" \
    "$GODOT" --headless --quiet --no-header --log-file "$godot_log" --path "$PROJECT" --script "res://scripts/tests/${test_name}.gd" >"$test_log" 2>&1
    test_status=$?
    cat "$godot_log" >>"$test_log"
    cat "$test_log"
    if grep -Eq "Failed to load script|Compilation failed|SCRIPT ERROR" "$test_log"; then
        test_status=1
    fi
    rm -f "$test_log" "$godot_log"
    return "$test_status"
}

run_test tutorial_and_floors_test || exit $?
run_test pre_run_ui_smoke_test || exit $?
run_test ui_click_smoke_test || exit $?

echo "ALL TESTS PASSED"
exit 0

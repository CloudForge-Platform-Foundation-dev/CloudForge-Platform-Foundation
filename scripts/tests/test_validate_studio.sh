#!/bin/bash
# Tests for scripts/validate-studio.sh
# Run from anywhere: bash scripts/tests/test_validate_studio.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VALIDATE_STUDIO="$SCRIPT_DIR/../validate-studio.sh"

pass_count=0
fail_count=0

assert_exit_code() {
    local description="$1"
    local expected="$2"
    local actual="$3"
    local log_file="$4"
    if [ "$actual" -eq "$expected" ]; then
        echo "✅ PASS: $description (exit $actual)"
        pass_count=$((pass_count + 1))
    else
        echo "❌ FAIL: $description (expected exit $expected, got $actual)"
        echo "   --- captured output ---"
        sed 's/^/   /' "$log_file"
        fail_count=$((fail_count + 1))
    fi
}

run_validator() {
    local dir="$1"
    local log_file="$2"
    set +e
    bash "$VALIDATE_STUDIO" "$dir" > "$log_file" 2>&1
    local rc=$?
    set -e
    echo "$rc"
}

echo "Testing: $VALIDATE_STUDIO"
echo "========================================"

# --- Scenario 1: valid Studio contract -> must PASS (exit 0) ---
valid_dir=$(mktemp -d)
touch "$valid_dir/README.md" "$valid_dir/LICENSE" "$valid_dir/CHANGELOG.md" "$valid_dir/VERSION"
mkdir -p "$valid_dir/docs/adr" "$valid_dir/.github/workflows"
log="/tmp/test_validate_studio_valid.log"
rc=$(run_validator "$valid_dir" "$log")
assert_exit_code "valid Studio contract" 0 "$rc" "$log"
rm -rf "$valid_dir"

# --- Scenario 2: missing required metadata -> must FAIL (exit 1) ---
invalid_dir=$(mktemp -d)
touch "$invalid_dir/README.md"
# LICENSE, CHANGELOG.md, VERSION, docs/adr/ deliberately missing
log="/tmp/test_validate_studio_invalid.log"
rc=$(run_validator "$invalid_dir" "$log")
assert_exit_code "missing required metadata" 1 "$rc" "$log"
rm -rf "$invalid_dir"

# --- Scenario 3: missing docs/adr/ -> must FAIL (exit 1, structural requirement) ---
noadr_dir=$(mktemp -d)
touch "$noadr_dir/README.md" "$noadr_dir/LICENSE" "$noadr_dir/CHANGELOG.md" "$noadr_dir/VERSION"
# docs/adr/ deliberately missing
log="/tmp/test_validate_studio_noadr.log"
rc=$(run_validator "$noadr_dir" "$log")
assert_exit_code "missing docs/adr/ directory" 1 "$rc" "$log"
rm -rf "$noadr_dir"

# --- Scenario 4: missing .github/workflows/ -> must still PASS (soft check, warning only) ---
softcheck_dir=$(mktemp -d)
touch "$softcheck_dir/README.md" "$softcheck_dir/LICENSE" "$softcheck_dir/CHANGELOG.md" "$softcheck_dir/VERSION"
mkdir -p "$softcheck_dir/docs/adr"
# .github/workflows deliberately absent -- must NOT fail the contract
log="/tmp/test_validate_studio_softcheck.log"
rc=$(run_validator "$softcheck_dir" "$log")
assert_exit_code "missing .github/workflows is a warning, not a failure" 0 "$rc" "$log"
rm -rf "$softcheck_dir"

echo "========================================"
echo "Results: $pass_count passed, $fail_count failed"
if [ "$fail_count" -ne 0 ]; then
    exit 1
fi

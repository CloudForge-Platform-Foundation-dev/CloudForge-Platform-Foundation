#!/bin/bash
# Tests for scripts/validate-identity-contract.sh
# Run from anywhere: bash scripts/tests/test_validate_identity_contract.sh
#
# Positive cases: the check must warn. Negative cases: it must NOT warn (false
# positives are the main risk named in ADR-005). Several negative fixtures are lines
# copied from a real Studio (cloudforge-nova-studio) that send a "scopes" list in a
# token request body, which is not a JWT claim.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CHECK="$SCRIPT_DIR/../validate-identity-contract.sh"

pass_count=0
fail_count=0
TMP_ROOT="$(mktemp -d)"
trap 'chmod -R u+rwx "$TMP_ROOT" 2>/dev/null || true; rm -rf "$TMP_ROOT"' EXIT

ok() {
    echo "  PASS: $1"
    pass_count=$((pass_count + 1))
}

bad() {
    echo "  FAIL: $1"
    fail_count=$((fail_count + 1))
}

# run_check <dir> <log-file> [extra args...] -> prints exit code
run_check() {
    local dir="$1" log="$2" rc=0
    shift 2
    bash "$CHECK" "$dir" "$@" > "$log" 2>&1 || rc=$?
    echo "$rc"
}

assert_exit_code() {
    local description="$1" expected="$2" actual="$3" log="$4"
    if [ "$expected" = "$actual" ]; then
        ok "$description (exit $actual)"
    else
        bad "$description (expected exit $expected, got $actual)"
        sed 's/^/        | /' "$log"
    fi
}

warning_count() {
    local n
    n="$(grep -c '^::warning' "$1" || true)"
    echo "${n:-0}"
}

assert_warnings() {
    local description="$1" expected="$2" log="$3" actual
    actual="$(warning_count "$log")"
    if [ "$expected" = "$actual" ]; then
        ok "$description ($actual warning(s))"
    else
        bad "$description (expected $expected warning(s), got $actual)"
        sed 's/^/        | /' "$log"
    fi
}

assert_contains() {
    local description="$1" needle="$2" log="$3"
    if grep -q -F -- "$needle" "$log"; then
        ok "$description"
    else
        bad "$description (missing: $needle)"
        sed 's/^/        | /' "$log"
    fi
}

# new_studio <name> -> echoes the path of a fresh Studio directory with src/
new_studio() {
    local d="$TMP_ROOT/$1"
    mkdir -p "$d/src"
    echo "$d"
}

# put <dir> <relative-path> <content>
put() {
    mkdir -p "$(dirname "$1/$2")"
    printf '%s\n' "$3" > "$1/$2"
}

# One scenario: write a file, run the check, assert the number of warnings.
scenario() {
    local name="$1" relpath="$2" content="$3" expected="$4"
    local d log rc
    d="$(new_studio "$name")"
    log="$TMP_ROOT/$name.log"
    put "$d" "$relpath" "$content"
    rc="$(run_check "$d" "$log")"
    assert_exit_code "$name: warning mode never fails" 0 "$rc" "$log"
    assert_warnings "$name" "$expected" "$log"
}

echo "CloudForge Identity Contract Check tests"
echo "========================================"

echo ""
echo "Positive cases (must warn):"
scenario "pos-claims-index"      "src/a.py" 'scopes = claims["scopes"]' 1
scenario "pos-claims-index-sq"   "src/a.py" "scopes = claims['scopes']" 1
scenario "pos-claims-get"        "src/a.py" 'scopes = claims.get("scopes", [])' 1
scenario "pos-raw-claims"        "src/a.py" 'x = principal.raw_claims["scopes"]' 1
scenario "pos-token-claims-pop"  "src/a.py" 'x = token_claims.pop("scopes")' 1
scenario "pos-in-claims"         "src/a.py" 'if "scopes" in claims:' 1
scenario "pos-import-jwt"        "src/a.py" 'import jwt' 1
scenario "pos-from-jose"         "src/a.py" 'from jose import jwt' 1
scenario "pos-jwt-decode"        "src/a.py" 'data = jwt.decode(token, key, algorithms=["RS256"])' 1

echo ""
echo "Negative cases (must NOT warn):"
# Lines copied from cloudforge-nova-studio (token request side, not JWT claims)
scenario "neg-request-body"      "src/auth/service_token.py" '                json={"scopes": self._scopes},' 0
scenario "neg-param-annotation"  "src/auth/service_token.py" '        scopes: list[str],' 0
scenario "neg-self-assign"       "src/auth/service_token.py" '        self._scopes = list(scopes)' 0
scenario "neg-call-argument"     "src/main.py" '        scopes=["knowledge:read"],' 0
scenario "neg-docstring-body"    "src/auth/service_token.py" '  JSON body {"scopes": ["knowledge:read"]}' 0
# Imports copied from cloudforge-nova-studio (auth-core and Studio wrappers)
scenario "neg-auth-core-import"  "src/auth/dependencies.py" 'from cloudforge_auth_core import Principal, build_auth_dependencies' 0
scenario "neg-auth-core-jwks"    "src/auth/dependencies.py" 'from cloudforge_auth_core.jwks import JWKSCache' 0
scenario "neg-studio-wrapper"    "src/main.py" 'from src.auth.config import auth_settings, service_credentials' 0
scenario "neg-principal-scopes"  "src/api/routes.py" 'allowed = principal.scopes' 0
scenario "neg-comment-claims"    "src/a.py" '# claims["scopes"] is rejected by auth-core' 0
scenario "neg-comment-import"    "src/a.py" '    # import jwt is not allowed here' 0
scenario "neg-word-jwtool"       "src/a.py" 'from jwtool import helper' 0
scenario "neg-skip-tests-dir"    "src/pkg/tests/test_x.py" 'x = claims["scopes"]' 0
scenario "neg-skip-test-file"    "src/pkg/test_claims.py" 'x = claims["scopes"]' 0
scenario "neg-skip-conftest"     "src/conftest.py" 'import jwt' 0
scenario "neg-outside-src"       "tools/a.py" 'x = claims["scopes"]' 0

echo ""
echo "Behaviour:"
d="$(new_studio multi)"
log="$TMP_ROOT/multi.log"
put "$d" "src/a.py" 'x = claims["scopes"]'
put "$d" "src/b.py" 'import jwt'
# Run from inside the Studio with target "." (as the CI step does) so paths are relative.
rc=0
(cd "$d" && bash "$CHECK" .) > "$log" 2>&1 || rc=$?
assert_exit_code "multi: warning mode with findings" 0 "$rc" "$log"
assert_warnings "multi: one warning per finding" 2 "$log"
assert_contains "multi: summary line counts warnings" "2 warning(s)" "$log"
assert_contains "multi: file and line are annotated" "file=src/a.py,line=1" "$log"

d="$(new_studio clean)"
log="$TMP_ROOT/clean.log"
put "$d" "src/a.py" 'from cloudforge_auth_core import Principal'
rc="$(run_check "$d" "$log")"
assert_exit_code "clean Studio" 0 "$rc" "$log"
assert_contains "clean Studio reports no findings" "no findings" "$log"

d="$TMP_ROOT/no-src"
mkdir -p "$d"
log="$TMP_ROOT/no-src.log"
rc="$(run_check "$d" "$log")"
assert_exit_code "no src/ directory" 0 "$rc" "$log"
assert_contains "no src/ directory says nothing to check" "nothing to check" "$log"

d="$(new_studio escape)"
log="$TMP_ROOT/escape.log"
put "$d" "src/a,b:c.py" 'x = claims["scopes"]'
rc="$(run_check "$d" "$log")"
assert_exit_code "special characters in path" 0 "$rc" "$log"
assert_contains "comma and colon in path are escaped" "a%2Cb%3Ac.py" "$log"

echo ""
echo "Errors (exit 2, never reported as a pass):"
log="$TMP_ROOT/missing.log"
rc="$(run_check "$TMP_ROOT/does-not-exist" "$log")"
assert_exit_code "target directory missing" 2 "$rc" "$log"

log="$TMP_ROOT/args.log"
rc=0
bash "$CHECK" "$TMP_ROOT" extra-argument > "$log" 2>&1 || rc=$?
assert_exit_code "too many arguments" 2 "$rc" "$log"

if [ "$(id -u)" != "0" ]; then
    d="$(new_studio unreadable)"
    log="$TMP_ROOT/unreadable.log"
    put "$d" "src/a.py" 'x = 1'
    chmod 000 "$d/src/a.py"
    rc="$(run_check "$d" "$log")"
    assert_exit_code "unreadable file is an error, not a pass" 2 "$rc" "$log"
    chmod 644 "$d/src/a.py"
else
    echo "  SKIP: unreadable-file case (running as root)"
fi

echo ""
echo "Results: $pass_count passed, $fail_count failed"
if [ "$fail_count" -gt 0 ]; then
    exit 1
fi

#!/bin/bash
# CloudForge Identity Contract Check (warning mode)
# Usage: ./scripts/validate-identity-contract.sh [target-directory]
#
# Scope: Identity Contract v1 section 8 (ADR-005, "Gate rule"), checks (b) and (c):
#   (b) a Studio takes auth logic from cloudforge-auth-core only
#   (c) the JWT claim "scopes" (list form) is not read
# Check (a) (OpenAPI endpoints that enforce auth declare both 401 and 403) is NOT
# done here. ADR-005 leaves the OpenAPI part to a separate change (a Spectral rule).
#
# This is a SEPARATE script from scripts/validate-studio.sh by design: the header of
# that script states it deliberately does not cover contract compliance.
#
# Mode: warning only. Findings are printed as GitHub Actions ::warning:: lines and the
# script still exits 0. Turning findings into failures is a separate decision that
# ADR-005 defers until all Studios pass.
#
# Exit codes:
#   0  scan completed (with or without findings), or there is nothing to scan (no src/)
#   2  usage error or internal error (bad arguments, target missing, find/grep failure)
#
# Limits: this is text matching on *.py files under src/, not an AST.
#   - Lines whose first non-space character is # are skipped.
#   - Docstrings and string literals can still match.
#   - Files under src/**/tests/, test_*.py, *_test.py and conftest.py are skipped.
#   - The JWT library list for check (b) is a heuristic: edit JWT_LIBS to extend it.
set -euo pipefail

usage() {
    echo "Usage: $0 [target-directory]" >&2
}

if [ "$#" -gt 1 ]; then
    usage
    exit 2
fi

case "${1:-}" in
    -h|--help)
        usage
        exit 0
        ;;
esac

TARGET_DIR="${1:-.}"

if [ ! -d "$TARGET_DIR" ]; then
    echo "ERROR: target directory not found: $TARGET_DIR" >&2
    exit 2
fi

SRC_DIR="$TARGET_DIR/src"

echo "CloudForge Identity Contract Check (warning mode)"
echo "Target: $TARGET_DIR"

if [ ! -d "$SRC_DIR" ]; then
    echo "No src/ directory found - nothing to check."
    exit 0
fi

# --- patterns -----------------------------------------------------------------
Q="[\"']"

# (c) reads of the JWT claim "scopes". Matches claims["scopes"], claims.get("scopes"),
# raw_claims["scopes"], token_claims.pop("scopes"), "scopes" in claims.
# Does not match request bodies such as json={"scopes": [...]} or scopes: list[str].
PATTERN_SCOPES="[A-Za-z0-9_.]*claims([[:space:]]*\\[[[:space:]]*${Q}scopes${Q}[[:space:]]*\\]|\\.(get|pop|setdefault)\\([[:space:]]*${Q}scopes${Q})|${Q}scopes${Q}[[:space:]]+(not[[:space:]]+)?in[[:space:]]+[A-Za-z0-9_.]*claims"

# (b) JWT handling outside cloudforge-auth-core: imports of JWT libraries and
# direct jwt.decode( calls. Studio wrappers such as src.auth.* and imports from
# cloudforge_auth_core do not match.
JWT_LIBS="jwt|jose|jwcrypto|authlib|pyjwt"
PATTERN_AUTH="^[[:space:]]*(import|from)[[:space:]]+(${JWT_LIBS})([[:space:].]|\$)|(^|[^A-Za-z0-9_.])(jwt|jose\\.jwt)\\.decode[[:space:]]*\\("

MESSAGE_SCOPES='Reads the JWT claim "scopes" (list form). Identity Contract v1 requires the "scope" claim as a space-separated string, and a "scopes" claim must be rejected.'
MESSAGE_AUTH='JWT handling outside cloudforge-auth-core. Studios take auth logic from cloudforge-auth-core only (Identity Contract v1 section 8).'

# --- file list ----------------------------------------------------------------
FILE_LIST="$(mktemp)"
trap 'rm -f "$FILE_LIST"' EXIT

find "$SRC_DIR" -type f -name '*.py' \
    -not -path "$SRC_DIR/tests/*" \
    -not -path "$SRC_DIR/*/tests/*" \
    -not -path "$SRC_DIR/*/__pycache__/*" \
    -not -path "$SRC_DIR/*/.venv/*" \
    -not -path "$SRC_DIR/*/venv/*" \
    -not -name 'test_*.py' \
    -not -name '*_test.py' \
    -not -name 'conftest.py' \
    -print0 > "$FILE_LIST"

FILES_SCANNED=0
while IFS= read -r -d '' _unused; do
    FILES_SCANNED=$((FILES_SCANNED + 1))
done < "$FILE_LIST"

WARNINGS=0

# Escape a value used as a workflow-command property (file path).
esc() {
    local s="$1"
    s="${s//%/%25}"
    s="${s//,/%2C}"
    s="${s//:/%3A}"
    printf '%s' "$s"
}

# scan <check-id> <pattern> <message>
scan() {
    local check_id="$1" pattern="$2" message="$3"
    local f out rc line lineno content rel
    while IFS= read -r -d '' f; do
        rc=0
        out="$(grep -n -E -e "$pattern" -- "$f" 2>&1)" || rc=$?
        if [ "$rc" -gt 1 ]; then
            echo "ERROR: grep failed on $f (exit $rc): $out" >&2
            exit 2
        fi
        if [ "$rc" -eq 1 ]; then
            continue
        fi
        while IFS= read -r line; do
            lineno="${line%%:*}"
            content="${line#*:}"
            if [[ "$content" =~ ^[[:space:]]*# ]]; then
                continue
            fi
            rel="${f#./}"
            printf '::warning file=%s,line=%s,title=identity-contract-v1 section 8(%s)::%s\n' \
                "$(esc "$rel")" "$lineno" "$check_id" "$message"
            WARNINGS=$((WARNINGS + 1))
        done <<< "$out"
    done < "$FILE_LIST"
}

scan "c" "$PATTERN_SCOPES" "$MESSAGE_SCOPES"
scan "b" "$PATTERN_AUTH" "$MESSAGE_AUTH"

echo ""
echo "Scanned $FILES_SCANNED Python file(s) under $SRC_DIR"
if [ "$WARNINGS" -gt 0 ]; then
    echo "Identity Contract check: $WARNINGS warning(s) (warning mode, not failing)"
else
    echo "Identity Contract check: no findings"
fi
exit 0

#!/bin/bash
# CloudForge Studio Contract Validator
# Usage: ./scripts/validate-studio.sh [target-directory]
#
# Scope: validates that a Studio repository satisfies the minimal Studio
# Contract expected by CloudForge Platform Foundation governance
# (see docs/adr/003-three-tier-governance.md). This is deliberately a
# SEPARATE script from scripts/validate.sh, not a parameterized/patched
# version of it:
#
#   scripts/validate.sh          -> Foundation Repository Integrity
#                                    (ROADMAP.md, MASTER_INDEX.md,
#                                    CODE_OF_CONDUCT.md, SUPPORT.md,
#                                    CODEOWNERS, etc. -- Foundation-level,
#                                    org-wide artifacts. NOT changed here.)
#
#   scripts/validate-studio.sh   -> Studio Contract / Structure (this file)
#                                    Studio metadata + repo structure only.
#
# Contract compliance beyond structure -- canonical schema conformance,
# security baseline -- is handled separately by the Studio's own CI
# steps ("Validate Against Canonical Schemas", "Security Scan (Trivy)"
# in templates/studio-template/.github/workflows/validate-against-foundation.yml).
# This script does not duplicate that logic, by design.

set -euo pipefail

TARGET_DIR="${1:-.}"
ERRORS=0

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "🏢 CloudForge Studio Contract Validation"
echo "========================================"
echo "Target: $TARGET_DIR"
echo ""

# ============================================
# Required Studio metadata
# ============================================
check_studio_metadata() {
    echo "📋 Checking required Studio metadata..."

    required_files=(
        "README.md"
        "LICENSE"
        "CHANGELOG.md"
        "VERSION"
    )

    for file in "${required_files[@]}"; do
        if [ -f "$TARGET_DIR/$file" ]; then
            echo -e "${GREEN}✅${NC} $file"
        else
            echo -e "${RED}❌${NC} Missing required file: $file"
            ERRORS=$((ERRORS + 1))
        fi
    done
    echo ""
}

# ============================================
# Repository structure
# ============================================
check_studio_structure() {
    echo "🏗️  Checking Studio repository structure..."

    if [ -d "$TARGET_DIR/docs/adr" ]; then
        echo -e "${GREEN}✅${NC} docs/adr/ present (Studio-specific ADRs)"
    else
        echo -e "${RED}❌${NC} Missing required directory: docs/adr/"
        ERRORS=$((ERRORS + 1))
    fi

    # How a Studio's CI comes to exist (checked in directly from the
    # template, injected later by a platform tool, etc.) is an
    # implementation detail this contract should not couple to.
    # Its absence is surfaced as a warning only, never a failure.
    if [ -d "$TARGET_DIR/.github/workflows" ]; then
        echo -e "${GREEN}✅${NC} .github/workflows/ present"
    else
        echo -e "${YELLOW}⚠️${NC}  .github/workflows/ not found (expected eventually, not enforced here)"
    fi
    echo ""
}

check_studio_metadata
check_studio_structure

echo "========================================"
if [ "$ERRORS" -eq 0 ]; then
    echo -e "${GREEN}✅ Studio contract satisfied.${NC}"
    exit 0
else
    echo -e "${RED}❌ Found $ERRORS error(s). Studio contract not satisfied.${NC}"
    exit 1
fi

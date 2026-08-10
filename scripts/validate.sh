#!/bin/bash
# CloudForge Platform Foundation Validation Script
# Usage: ./scripts/validate.sh [target-directory]
# If no target directory provided, validates current repo

set -e

TARGET_DIR="${1:-.}"
ERRORS=0

echo "🔍 CloudForge Foundation Validation"
echo "===================================="
echo "Target: $TARGET_DIR"
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# ============================================
# Check Required Files
# ============================================
check_required_files() {
    echo "📋 Checking required files..."

    required_files=(
        "README.md"
        "LICENSE"
        "CHANGELOG.md"
        "ROADMAP.md"
        "VERSION"
        "MASTER_INDEX.md"
        "CONTRIBUTING.md"
        "SECURITY.md"
        "CODE_OF_CONDUCT.md"
        "SUPPORT.md"
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
# Check GitHub Configuration
# ============================================
check_github_config() {
    echo "🔧 Checking GitHub configuration..."

    github_items=(
        ".github/workflows"
        ".github/ISSUE_TEMPLATE"
        ".github/CODEOWNERS"
        ".github/PULL_REQUEST_TEMPLATE.md"
    )

    for item in "${github_items[@]}"; do
        if [ -e "$TARGET_DIR/$item" ]; then
            echo -e "${GREEN}✅${NC} $item"
        else
            echo -e "${RED}❌${NC} Missing: $item"
            ERRORS=$((ERRORS + 1))
        fi
    done
    echo ""
}

# ============================================
# Check Naming Conventions
# ============================================
check_naming() {
    echo "🏷️  Checking naming conventions..."

    # Check ADR files
    if [ -d "$TARGET_DIR/docs/adr" ]; then
        for file in "$TARGET_DIR"/docs/adr/*.md; do
            if [ -f "$file" ]; then
                basename_file=$(basename "$file")
                if [[ $basename_file =~ ^[0-9]{3}-[a-z0-9-]+\.md$ ]]; then
                    echo -e "${GREEN}✅${NC} ADR naming valid: $basename_file"
                else
                    echo -e "${YELLOW}⚠️${NC}  ADR naming convention warning: $basename_file (expected: NNN-name.md)"
                fi
            fi
        done
    fi

    # Check schema files
    if [ -d "$TARGET_DIR/schemas" ]; then
        for file in "$TARGET_DIR"/schemas/**/*.schema.json; do
            if [ -f "$file" ]; then
                basename_file=$(basename "$file")
                if [[ $basename_file =~ ^[a-z0-9-]+\.schema\.json$ ]]; then
                    echo -e "${GREEN}✅${NC} Schema naming valid: $basename_file"
                else
                    echo -e "${YELLOW}⚠️${NC}  Schema naming warning: $basename_file"
                fi
            fi
        done 2>/dev/null || true
    fi

    echo ""
}

# ============================================
# Check JSON Schemas
# ============================================
check_schemas() {
    echo "📐 Checking JSON schemas..."

    if ! command -v ajv &> /dev/null; then
        echo -e "${YELLOW}⚠️${NC}  ajv-cli not installed. Install with: npm install -g ajv-cli"
        echo ""
        return
    fi

    if [ -d "$TARGET_DIR/schemas/canonical" ]; then
        for schema in "$TARGET_DIR"/schemas/canonical/*.schema.json; do
            if [ -f "$schema" ]; then
                if ajv compile -s "$schema" --strict > /dev/null 2>&1; then
                    echo -e "${GREEN}✅${NC} Valid schema: $(basename "$schema")"
                else
                    echo -e "${RED}❌${NC} Invalid schema: $(basename "$schema")"
                    ERRORS=$((ERRORS + 1))
                fi
            fi
        done
    fi
    echo ""
}

# ============================================
# Check ADR Format
# ============================================
check_adrs() {
    echo "📋 Checking ADR format..."

    if [ -d "$TARGET_DIR/docs/adr" ]; then
        for adr in "$TARGET_DIR"/docs/adr/*.md; do
            if [ -f "$adr" ] && [ "$(basename "$adr")" != "README.md" ]; then
                basename_adr=$(basename "$adr")

                missing=()
                grep -q "## Status" "$adr" || missing+=("Status")
                grep -q "## Context" "$adr" || missing+=("Context")
                grep -q "## Decision" "$adr" || missing+=("Decision")
                grep -q "## Consequences" "$adr" || missing+=("Consequences")

                if [ ${#missing[@]} -eq 0 ]; then
                    echo -e "${GREEN}✅${NC} Valid ADR: $basename_adr"
                else
                    echo -e "${RED}❌${NC} ADR missing sections [${missing[*]}]: $basename_adr"
                    ERRORS=$((ERRORS + 1))
                fi
            fi
        done
    fi
    echo ""
}

# ============================================
# Check Documentation Links
# ============================================
check_doc_links() {
    echo "🔗 Checking documentation links..."

    if [ -f "$TARGET_DIR/MASTER_INDEX.md" ]; then
        echo -e "${GREEN}✅${NC} MASTER_INDEX.md exists"
    else
        echo -e "${YELLOW}⚠️${NC}  MASTER_INDEX.md not found"
    fi
    echo ""
}

# ============================================
# Main
# ============================================
main() {
    check_required_files
    check_github_config
    check_naming
    check_schemas
    check_adrs
    check_doc_links

    echo "===================================="
    if [ $ERRORS -eq 0 ]; then
        echo -e "${GREEN}✅ All validations passed!${NC}"
        exit 0
    else
        echo -e "${RED}❌ Found $ERRORS error(s). Please fix before merging.${NC}"
        exit 1
    fi
}

main

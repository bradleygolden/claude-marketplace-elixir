#!/usr/bin/env bash

# Tests for inline version manager support in hook scripts
# Verifies the 2-line shim pattern works correctly

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

# Test counters
PASSED=0
FAILED=0

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "Testing Version Manager Inline Support"
echo "================================"
echo ""

# Test helper: check condition
test_condition() {
  local name="$1"
  local condition="$2"

  echo -e "${YELLOW}[TEST]${NC} $name"
  if eval "$condition"; then
    echo -e "  ${GREEN}✅ PASS${NC}"
    ((PASSED++))
  else
    echo -e "  ${RED}❌ FAIL${NC}"
    ((FAILED++))
  fi
}

echo "--- Inline shim pattern tests ---"
echo ""

# Test: Robust home detection works when HOME is unset
echo -e "${YELLOW}[TEST]${NC} Robust home detection (_HOME variable)"
SAVED_HOME="$HOME"
(
  unset HOME
  _HOME="${HOME:-$(eval echo ~${USER:-$(whoami)})}"
  if [[ -n "$_HOME" ]] && [[ "$_HOME" != "~"* ]]; then
    echo -e "  ${GREEN}✅ PASS${NC} - _HOME resolved to: $_HOME"
    exit 0
  else
    echo -e "  ${RED}❌ FAIL${NC} - _HOME failed to resolve (got: $_HOME)"
    exit 1
  fi
) && ((++PASSED)) || ((++FAILED))

# Test: The inline pattern adds mise shims to PATH when directory exists
ORIGINAL_PATH="$PATH"
_HOME="${HOME:-$(eval echo ~${USER:-$(whoami)})}"
MISE_SHIMS="${XDG_DATA_HOME:-$_HOME/.local/share}/mise/shims"
if [[ -d "$MISE_SHIMS" ]]; then
  PATH="$ORIGINAL_PATH"
  [[ -d "$MISE_SHIMS" ]] && export PATH="$MISE_SHIMS:$PATH"
  test_condition "Mise shims added to PATH when directory exists" \
    '[[ "$PATH" == *"mise/shims"* ]]'
else
  echo -e "${YELLOW}[TEST]${NC} Mise shims: directory not present (skipped)"
  ((PASSED++))
fi

# Test: The inline pattern adds asdf shims to PATH when directory exists
PATH="$ORIGINAL_PATH"
ASDF_SHIMS="$_HOME/.asdf/shims"
if [[ -d "$ASDF_SHIMS" ]]; then
  [[ -d "$ASDF_SHIMS" ]] && export PATH="$ASDF_SHIMS:$PATH"
  test_condition "Asdf shims added to PATH when directory exists" \
    '[[ "$PATH" == *".asdf/shims"* ]]'
else
  echo -e "${YELLOW}[TEST]${NC} Asdf shims: directory not present (skipped)"
  ((PASSED++))
fi

# Test: Pattern doesn't add non-existent directories
PATH="$ORIGINAL_PATH"
FAKE_DIR="/nonexistent/fake/shims"
[[ -d "$FAKE_DIR" ]] && PATH="$FAKE_DIR:$PATH"
test_condition "Non-existent directories not added to PATH" \
  '[[ "$PATH" != *"/nonexistent/fake/shims"* ]]'

# Test: XDG_DATA_HOME is respected for mise
echo -e "${YELLOW}[TEST]${NC} XDG_DATA_HOME is respected for mise shims"
(
  export XDG_DATA_HOME="/tmp/test-xdg-data"
  _HOME="${HOME:-$(eval echo ~${USER:-$(whoami)})}"
  MISE_SHIMS="${XDG_DATA_HOME:-$_HOME/.local/share}/mise/shims"
  if [[ "$MISE_SHIMS" == "/tmp/test-xdg-data/mise/shims" ]]; then
    echo -e "  ${GREEN}✅ PASS${NC}"
    exit 0
  else
    echo -e "  ${RED}❌ FAIL${NC} - got: $MISE_SHIMS"
    exit 1
  fi
) && ((++PASSED)) || ((++FAILED))

# Test: All hook scripts contain the inline pattern
echo ""
echo "--- Hook script verification ---"
echo ""

# Check for the robust pattern: _HOME detection line
INLINE_PATTERN='_HOME=.*eval echo'
SCRIPTS=(
  "$REPO_ROOT/plugins/core/scripts/auto-format.sh"
  "$REPO_ROOT/plugins/core/scripts/compile-check.sh"
  "$REPO_ROOT/plugins/core/scripts/pre-commit-check.sh"
  "$REPO_ROOT/plugins/credo/scripts/post-edit-check.sh"
  "$REPO_ROOT/plugins/credo/scripts/pre-commit-check.sh"
  "$REPO_ROOT/plugins/ash/scripts/post-edit-check.sh"
  "$REPO_ROOT/plugins/ash/scripts/pre-commit-check.sh"
  "$REPO_ROOT/plugins/dialyzer/scripts/pre-commit-check.sh"
  "$REPO_ROOT/plugins/sobelow/scripts/post-edit-check.sh"
  "$REPO_ROOT/plugins/sobelow/scripts/pre-commit-check.sh"
  "$REPO_ROOT/plugins/mix_audit/scripts/pre-commit-check.sh"
  "$REPO_ROOT/plugins/ex_doc/scripts/pre-commit-check.sh"
  "$REPO_ROOT/plugins/ex_unit/scripts/pre-commit-test.sh"
  "$REPO_ROOT/plugins/precommit/scripts/pre-commit-check.sh"
)

for script in "${SCRIPTS[@]}"; do
  script_name=$(basename "$script")
  plugin_name=$(echo "$script" | sed 's|.*/plugins/\([^/]*\)/.*|\1|')
  test_condition "$plugin_name/$script_name contains robust shim pattern" \
    "grep -qE '$INLINE_PATTERN' '$script'"
done

# Restore PATH
PATH="$ORIGINAL_PATH"

echo ""
echo "================================"
echo "Test Summary"
echo "================================"
echo "Total:  $((PASSED + FAILED))"
echo -e "Passed: ${GREEN}$PASSED${NC}"
echo -e "Failed: ${RED}$FAILED${NC}"
echo "================================"

if [[ $FAILED -eq 0 ]]; then
  echo -e "${GREEN}✅ Version Manager Tests completed successfully${NC}"
  exit 0
else
  echo -e "${RED}❌ Version Manager Tests failed${NC}"
  exit 1
fi

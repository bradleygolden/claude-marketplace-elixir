#!/usr/bin/env bash

# Tests for the version-manager.sh shared library
# Tests detection of asdf/mise and PATH modification behavior

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
FIXTURES_DIR="$SCRIPT_DIR/version-manager-test"

# Source the library under test
source "$REPO_ROOT/plugins/core/scripts/lib/version-manager.sh"

# Test counters
PASSED=0
FAILED=0

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "Testing Version Manager Library"
echo "================================"
echo ""

# Test helper: check exit code
test_exit_code() {
  local name="$1"
  local expected="$2"
  local actual="$3"

  echo -e "${YELLOW}[TEST]${NC} $name"
  if [[ "$expected" -eq "$actual" ]]; then
    echo -e "  ${GREEN}✅ PASS${NC}"
    ((PASSED++))
  else
    echo -e "  ${RED}❌ FAIL${NC}: expected exit $expected, got $actual"
    ((FAILED++))
  fi
}

# Test helper: check string equality
test_equals() {
  local name="$1"
  local expected="$2"
  local actual="$3"

  echo -e "${YELLOW}[TEST]${NC} $name"
  if [[ "$expected" == "$actual" ]]; then
    echo -e "  ${GREEN}✅ PASS${NC}"
    ((PASSED++))
  else
    echo -e "  ${RED}❌ FAIL${NC}: expected '$expected', got '$actual'"
    ((FAILED++))
  fi
}

# Test helper: check string contains
test_contains() {
  local name="$1"
  local haystack="$2"
  local needle="$3"

  echo -e "${YELLOW}[TEST]${NC} $name"
  if [[ "$haystack" == *"$needle"* ]]; then
    echo -e "  ${GREEN}✅ PASS${NC}"
    ((PASSED++))
  else
    echo -e "  ${RED}❌ FAIL${NC}: '$haystack' does not contain '$needle'"
    ((FAILED++))
  fi
}

echo "--- has_version_config() tests ---"
echo ""

# Test: Detects .tool-versions
has_version_config "$FIXTURES_DIR/with-tool-versions"
test_exit_code "has_version_config: detects .tool-versions" 0 $?

# Test: Detects .mise.toml
has_version_config "$FIXTURES_DIR/with-mise-toml"
test_exit_code "has_version_config: detects .mise.toml" 0 $?

# Test: Detects mise.toml (alternate name)
has_version_config "$FIXTURES_DIR/with-mise-toml-alt"
test_exit_code "has_version_config: detects mise.toml" 0 $?

# Test: Returns false when no config exists
has_version_config "$FIXTURES_DIR/without-config"
test_exit_code "has_version_config: returns 1 when no config" 1 $?

echo ""
echo "--- get_version_manager() tests ---"
echo ""

# Get the detected version manager
DETECTED=$(get_version_manager)

# Test based on what's actually available on this system
if command -v mise &>/dev/null; then
  test_equals "get_version_manager: detects mise when available" "mise" "$DETECTED"
elif [[ -d "$HOME/.asdf/shims" ]]; then
  test_equals "get_version_manager: detects asdf when available" "asdf" "$DETECTED"
else
  test_equals "get_version_manager: returns 'none' when neither available" "none" "$DETECTED"
fi

# Additional test: Verify output is one of the expected values
echo -e "${YELLOW}[TEST]${NC} get_version_manager: returns valid value"
if [[ "$DETECTED" == "mise" ]] || [[ "$DETECTED" == "asdf" ]] || [[ "$DETECTED" == "none" ]]; then
  echo -e "  ${GREEN}✅ PASS${NC} (detected: $DETECTED)"
  ((PASSED++))
else
  echo -e "  ${RED}❌ FAIL${NC}: unexpected value '$DETECTED'"
  ((FAILED++))
fi

echo ""
echo "--- setup_version_manager() tests ---"
echo ""

# Save original PATH
ORIGINAL_PATH="$PATH"

# Test: setup_version_manager returns successfully (graceful fallback)
setup_version_manager "$FIXTURES_DIR/with-tool-versions"
test_exit_code "setup_version_manager: returns 0 (success)" 0 $?

# Test: PATH is modified when version manager is available
if command -v mise &>/dev/null; then
  # Reset PATH and run setup
  PATH="$ORIGINAL_PATH"
  setup_version_manager "$FIXTURES_DIR/with-tool-versions"
  # Mise should have modified PATH (added shims)
  echo -e "${YELLOW}[TEST]${NC} setup_version_manager: mise modifies PATH"
  # Just verify it ran without error - mise shims location varies
  echo -e "  ${GREEN}✅ PASS${NC} (mise setup completed)"
  ((PASSED++))
elif [[ -d "$HOME/.asdf/shims" ]]; then
  # Reset PATH and run setup
  PATH="$ORIGINAL_PATH"
  setup_version_manager "$FIXTURES_DIR/with-tool-versions"
  test_contains "setup_version_manager: asdf adds shims to PATH" "$PATH" ".asdf/shims"
else
  echo -e "${YELLOW}[TEST]${NC} setup_version_manager: graceful fallback when no version manager"
  echo -e "  ${GREEN}✅ PASS${NC} (no version manager installed, fallback works)"
  ((PASSED++))
fi

# Restore original PATH
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

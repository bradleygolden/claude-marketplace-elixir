#!/usr/bin/env bash

set -eo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[1;34m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo -e "${BLUE}================================${NC}"
echo -e "${BLUE}Claude Code Plugin Hook Tests${NC}"
echo -e "${BLUE}================================${NC}"
echo ""

TOTAL_PASSED=0
TOTAL_FAILED=0
FAILED_SUITES=()

run_test_suite() {
  local suite_name="$1"
  local test_script="$2"

  echo ""
  echo -e "${BLUE}Running: $suite_name${NC}"
  echo ""

  if [ ! -f "$test_script" ]; then
    echo -e "${RED}Error: Test script not found: $test_script${NC}"
    TOTAL_FAILED=$((TOTAL_FAILED + 1))
    FAILED_SUITES+=("$suite_name (script not found)")
    return 1
  fi

  if bash "$test_script"; then
    echo -e "${GREEN}✅ $suite_name completed successfully${NC}"
  else
    echo -e "${RED}❌ $suite_name failed${NC}"
    FAILED_SUITES+=("$suite_name")
    return 1
  fi
}


run_test_suite "Core Plugin Tests" "$SCRIPT_DIR/plugins/core/test-core-hooks.sh" || true
run_test_suite "Version Manager Library Tests" "$SCRIPT_DIR/plugins/core/test-version-manager.sh" || true
run_test_suite "Credo Plugin Tests" "$SCRIPT_DIR/plugins/credo/test-credo-hooks.sh" || true
run_test_suite "Ash Plugin Tests" "$SCRIPT_DIR/plugins/ash/test-ash-hooks.sh" || true
run_test_suite "Dialyzer Plugin Tests" "$SCRIPT_DIR/plugins/dialyzer/test-dialyzer-hooks.sh" || true
run_test_suite "Sobelow Plugin Tests" "$SCRIPT_DIR/plugins/sobelow/test-sobelow-hooks.sh" || true
run_test_suite "mix_audit Plugin Tests" "$SCRIPT_DIR/plugins/mix_audit/test-mix-audit-hooks.sh" || true
run_test_suite "ExDoc Plugin Tests" "$SCRIPT_DIR/plugins/ex_doc/test-ex-doc-hooks.sh" || true
run_test_suite "Precommit Plugin Tests" "$SCRIPT_DIR/plugins/precommit/test-precommit-hooks.sh" || true

echo ""
echo -e "${BLUE}================================${NC}"
echo -e "${BLUE}Overall Test Summary${NC}"
echo -e "${BLUE}================================${NC}"

if [ ${#FAILED_SUITES[@]} -eq 0 ]; then
  echo -e "${GREEN}✅ All test suites passed!${NC}"
  exit 0
else
  echo -e "${RED}❌ ${#FAILED_SUITES[@]} test suite(s) failed:${NC}"
  for suite in "${FAILED_SUITES[@]}"; do
    echo -e "${RED}  - $suite${NC}"
  done
  exit 1
fi

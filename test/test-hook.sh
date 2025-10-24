#!/usr/bin/env bash
# Base framework for testing Claude Code hooks in isolation by simulating
# Claude Code's hook execution environment

set -eo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

test_hook() {
  local test_name="$1"
  local hook_script="$2"
  local input_json="$3"
  local expected_exit="$4"
  local expected_output_pattern="$5"

  TESTS_RUN=$((TESTS_RUN + 1))

  echo -e "${YELLOW}[TEST]${NC} $test_name"

  local full_hook_path="$REPO_ROOT/$hook_script"

  if [ ! -f "$full_hook_path" ]; then
    echo -e "  ${RED}❌ FAIL${NC}: Hook script not found: $full_hook_path"
    TESTS_FAILED=$((TESTS_FAILED + 1))
    return 1
  fi

  local output
  local exit_code

  output=$(echo "$input_json" | bash "$full_hook_path" 2>&1) || exit_code=$?
  exit_code=${exit_code:-0}

  if [ "$exit_code" -ne "$expected_exit" ]; then
    echo -e "  ${RED}❌ FAIL${NC}: Expected exit code $expected_exit, got $exit_code"
    echo -e "  ${YELLOW}Output:${NC}"
    echo "$output" | sed 's/^/    /'
    TESTS_FAILED=$((TESTS_FAILED + 1))
    return 1
  fi

  if [ -n "$expected_output_pattern" ]; then
    if ! echo "$output" | grep -q "$expected_output_pattern"; then
      echo -e "  ${RED}❌ FAIL${NC}: Expected output pattern not found: $expected_output_pattern"
      echo -e "  ${YELLOW}Got:${NC}"
      echo "$output" | sed 's/^/    /'
      TESTS_FAILED=$((TESTS_FAILED + 1))
      return 1
    fi
  fi

  echo -e "  ${GREEN}✅ PASS${NC}"
  TESTS_PASSED=$((TESTS_PASSED + 1))
  return 0
}

test_hook_json() {
  local test_name="$1"
  local hook_script="$2"
  local input_json="$3"
  local expected_exit="$4"
  local jq_assertion="$5"

  TESTS_RUN=$((TESTS_RUN + 1))

  echo -e "${YELLOW}[TEST]${NC} $test_name"

  local full_hook_path="$REPO_ROOT/$hook_script"

  if [ ! -f "$full_hook_path" ]; then
    echo -e "  ${RED}❌ FAIL${NC}: Hook script not found: $full_hook_path"
    TESTS_FAILED=$((TESTS_FAILED + 1))
    return 1
  fi

  local output
  local exit_code

  output=$(echo "$input_json" | bash "$full_hook_path" 2>&1) || exit_code=$?
  exit_code=${exit_code:-0}

  if [ "$exit_code" -ne "$expected_exit" ]; then
    echo -e "  ${RED}❌ FAIL${NC}: Expected exit code $expected_exit, got $exit_code"
    echo -e "  ${YELLOW}Output:${NC}"
    echo "$output" | sed 's/^/    /'
    TESTS_FAILED=$((TESTS_FAILED + 1))
    return 1
  fi

  if [ -n "$jq_assertion" ]; then
    if ! echo "$output" | jq -e "$jq_assertion" > /dev/null 2>&1; then
      echo -e "  ${RED}❌ FAIL${NC}: JSON assertion failed: $jq_assertion"
      echo -e "  ${YELLOW}Output:${NC}"
      echo "$output" | sed 's/^/    /'
      TESTS_FAILED=$((TESTS_FAILED + 1))
      return 1
    fi
  fi

  echo -e "  ${GREEN}✅ PASS${NC}"
  TESTS_PASSED=$((TESTS_PASSED + 1))
  return 0
}

print_summary() {
  echo ""
  echo "================================"
  echo "Test Summary"
  echo "================================"
  echo "Total:  $TESTS_RUN"
  echo -e "Passed: ${GREEN}$TESTS_PASSED${NC}"
  echo -e "Failed: ${RED}$TESTS_FAILED${NC}"
  echo "================================"

  if [ "$TESTS_FAILED" -gt 0 ]; then
    exit 1
  fi
}

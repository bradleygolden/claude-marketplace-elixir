#!/bin/bash

# Version Manager Support Library
# Provides unified support for asdf and mise version managers in non-interactive scripts.
#
# Usage:
#   source "${SCRIPT_DIR}/lib/version-manager.sh"
#   setup_version_manager "$PROJECT_ROOT"
#   # Now 'mix' will use the correct version from .tool-versions or .mise.toml

# Setup version manager environment for non-interactive scripts
# This adds the appropriate shims to PATH so that tools like 'mix' use
# the version specified in .tool-versions or .mise.toml
#
# Arguments:
#   $1 - Project root directory (optional, used for context)
#
# Supports:
#   - mise (modern, Rust-based) - preferred if available
#   - asdf (traditional, widely used) - fallback
#
# In non-interactive scripts, version managers don't automatically activate
# because there's no shell prompt to trigger their hooks. This function
# explicitly sets up the PATH to include shims.
setup_version_manager() {
  local project_root="${1:-}"

  # Prefer mise if available (faster, modern, Rust-based)
  if command -v mise &>/dev/null; then
    # Use --shims for non-interactive scripts
    # This adds mise shims to PATH without requiring prompt hooks
    eval "$(mise activate bash --shims 2>/dev/null)" || true
    return 0
  fi

  # Fall back to asdf if available
  if [[ -d "$HOME/.asdf/shims" ]]; then
    # Add asdf shims to PATH for non-interactive scripts
    # Shims will resolve to correct version based on .tool-versions
    export PATH="$HOME/.asdf/shims:$PATH"

    # Also add asdf bin for 'asdf' command availability
    if [[ -d "$HOME/.asdf/bin" ]]; then
      export PATH="$HOME/.asdf/bin:$PATH"
    fi
    return 0
  fi

  # No version manager found - will use system PATH
  return 0
}

# Check if a version manager config file exists in the project
# Arguments:
#   $1 - Project root directory
# Returns:
#   0 if config found, 1 otherwise
has_version_config() {
  local project_root="$1"

  [[ -f "$project_root/.tool-versions" ]] && return 0
  [[ -f "$project_root/.mise.toml" ]] && return 0
  [[ -f "$project_root/mise.toml" ]] && return 0

  return 1
}

# Get the active version manager name
# Returns: "mise", "asdf", or "none"
get_version_manager() {
  if command -v mise &>/dev/null; then
    echo "mise"
  elif [[ -d "$HOME/.asdf/shims" ]]; then
    echo "asdf"
  else
    echo "none"
  fi
}

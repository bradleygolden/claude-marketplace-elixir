---
allowed-tools: [Bash, Read, Edit, Write, MultiEdit, Grep, LS]
argument-hint: "[directory] [usage-rule ...] or --auto"
description: Add nested memory configuration for directories (auto-discovers if not specified)
---

# Add Nested Memory Configuration

I'll add nested memory configuration to automatically generate CLAUDE.md files with specific usage rules in directories.

Request: `$ARGUMENTS`

## Determine Target Directories

! if echo "$ARGUMENTS" | grep -q "^--auto" || [ -z "$ARGUMENTS" ]; then echo "=== Auto-discovery mode ==="; echo "I'll configure nested memories for standard project directories:"; else echo "=== Manual mode ==="; echo "Configuring for: $ARGUMENTS"; fi

## Auto-Discovery (Conservative)

If no directory specified or --auto used, I'll check for these standard directories:

! if echo "$ARGUMENTS" | grep -q "^--auto" || [ -z "$ARGUMENTS" ]; then \
    echo "Checking for standard directories..."; \
    for dir in "test" "lib/$(basename $(pwd))" "lib/$(basename $(pwd))_web"; do \
      if [ -d "$dir" ]; then \
        echo "✓ Found: $dir"; \
      fi; \
    done; \
  fi

## Analyze Directory Contents

! if echo "$ARGUMENTS" | grep -q "^--auto" || [ -z "$ARGUMENTS" ]; then \
    echo -e "\n=== Analyzing directory contents for smart rule selection ==="; \
    if [ -d "test" ]; then \
      echo "test/:"; \
      grep -l "use ExUnit" test/*.exs 2>/dev/null | head -1 && echo "  → Detected ExUnit tests"; \
      grep -l "use.*DataCase\|use.*ConnCase" test/**/*.exs 2>/dev/null | head -1 && echo "  → Detected Ecto/Phoenix test helpers"; \
      grep -l "Oban.Testing" test/**/*.exs 2>/dev/null | head -1 && echo "  → Detected Oban tests"; \
    fi; \
    if [ -d "lib/$(basename $(pwd))" ]; then \
      echo "lib/$(basename $(pwd))/:"; \
      grep -l "use Ecto.Schema" lib/$(basename $(pwd))/**/*.ex 2>/dev/null | head -1 && echo "  → Detected Ecto schemas"; \
      grep -l "use Ash.Resource" lib/$(basename $(pwd))/**/*.ex 2>/dev/null | head -1 && echo "  → Detected Ash resources"; \
      grep -l "use GenServer\|use Supervisor" lib/$(basename $(pwd))/**/*.ex 2>/dev/null | head -1 && echo "  → Detected OTP behaviors"; \
    fi; \
    if [ -d "lib/$(basename $(pwd))_web" ]; then \
      echo "lib/$(basename $(pwd))_web/:"; \
      grep -l "use.*Phoenix.LiveView" lib/$(basename $(pwd))_web/**/*.ex 2>/dev/null | head -1 && echo "  → Detected Phoenix LiveView"; \
      grep -l "use.*Phoenix.Component" lib/$(basename $(pwd))_web/**/*.ex 2>/dev/null | head -1 && echo "  → Detected Phoenix Components"; \
      grep -l "use.*Phoenix.Controller" lib/$(basename $(pwd))_web/**/*.ex 2>/dev/null | head -1 && echo "  → Detected Phoenix Controllers"; \
    fi; \
  fi

## Check Available Usage Rules

! echo -e "\n=== Available usage rules ===" && mix usage_rules.sync --list | head -20

## Discover Project Dependencies

! echo -e "\n=== Project dependencies that may have usage rules ===" && mix deps | grep "* " | awk '{print $2}' | head -20

## Smart Rule Selection

In auto mode, all directories get the base rules plus detected additions:

**Base rules for ALL directories:**
- `"usage_rules:elixir"` - Always included
- `"usage_rules:otp"` - Always included

**Additional rules based on detection:**
- Add package-specific rules ONLY if the package exists and is used
- For example: `"phoenix"`, `"ecto"`, `"ash"`, `"oban"` etc.
- Only add if `mix usage_rules.sync --list` shows they're available

For manual mode, I'll:
1. **Validate the directory** exists in your project
2. **Verify usage rules** are available
3. **Update `.claude.exs`** with the nested memory configuration
4. **Run `mix claude.install`** to generate the CLAUDE.md file

## Current Configuration

Let me check the current nested memories configuration in `.claude.exs`.

## Update Configuration

I'll add or update the nested memory configuration.

The configuration will look like:
```elixir
nested_memories: %{
  "test" => ["usage_rules:elixir", "usage_rules:otp", ...detected_rules],
  "lib/my_app" => ["usage_rules:elixir", "usage_rules:otp", ...detected_rules],
  "lib/my_app_web" => ["usage_rules:elixir", "usage_rules:otp", ...detected_rules]
}
```

This will automatically:
- Create/update `path/to/directory/CLAUDE.md`
- Include the specified usage rules
- Make Claude Code aware of directory-specific context

After updating, I'll run `mix claude.install` to generate the files.

## Important Reminder

✅ **Changes take effect immediately after running `mix claude.install`!**

Let me proceed with adding this configuration.

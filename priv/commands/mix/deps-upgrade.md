---
allowed-tools: [Bash, Read, Edit, Write, MultiEdit, Grep]
argument-hint: "[package[@version] ...] [--all] [--yes] [--no-backup] [--skip-tests]"
description: Smart dependency upgrade with automatic safety checks and Igniter support
---

# Smart Dependency Upgrade

I'll upgrade your dependencies intelligently with safety checks and automatic migration support.

Target for upgrade: `$ARGUMENTS`

## Pre-Upgrade Safety Checks

### 1. Create Backup (unless --no-backup is specified)

! if echo "$ARGUMENTS" | grep -q "no-backup"; then echo "⚠ Skipping backup as requested"; else echo "Creating backup of mix.exs and mix.lock..." && cp mix.exs mix.exs.backup && cp mix.lock mix.lock.backup && echo "✓ Backup created"; fi

### 2. Verify Current State

! echo "Checking current compilation status..." && mix compile --warnings-as-errors && echo "✓ Project compiles cleanly" || echo "⚠ Warning: Project has compilation issues"

! if echo "$ARGUMENTS" | grep -q "skip-tests"; then echo "⚠ Skipping tests as requested"; else echo "Running tests (if available)..." && mix test --max-failures 1 && echo "✓ Tests pass" || echo "⚠ Tests failing or not available"; fi

### 3. Check for Outdated Dependencies

! echo "Checking for outdated packages..." && mix hex.outdated

## Determine Best Upgrade Method

! if mix help igniter.upgrade > /dev/null 2>&1; then echo "✓ Using Igniter for intelligent upgrades with automatic migrations"; else echo "ℹ Using standard mix deps.update"; fi

## Execute Upgrade

Based on your request (`$ARGUMENTS`), I will:

1. **With Igniter** (if available):
   - Use `mix igniter.upgrade` for smart upgrades
   - Apply automatic code migrations
   - Handle breaking changes intelligently
   - Run any package-specific upgraders

2. **Without Igniter**:
   - Use `mix deps.update` for standard upgrades
   - Update to latest allowed versions
   - Fetch and compile dependencies

### Upgrade Process

The upgrade will:
- Parse arguments (packages, --all, --yes flags)
- Update mix.exs if version specified with @
- Run appropriate upgrade command
- Apply any automatic migrations
- Update the lock file

## Post-Upgrade Verification

! echo "Verifying upgrade success..." && mix compile --warnings-as-errors && echo "✓ Project still compiles successfully" || echo "⚠ Compilation issues after upgrade"

! if echo "$ARGUMENTS" | grep -q "skip-tests"; then echo "⚠ Skipping post-upgrade tests"; else mix test --max-failures 1 && echo "✓ Tests still pass" || echo "⚠ Tests failing after upgrade"; fi

! echo "Checking for new deprecation warnings..." && mix compile 2>&1 | grep -i "warning" || echo "✓ No new warnings detected"

## Rollback Option

If any issues occurred during the upgrade, I can restore from the backup:
- Restore mix.exs.backup → mix.exs
- Restore mix.lock.backup → mix.lock
- Run `mix deps.get` to restore previous versions

## Cleanup Backup Files

After successful upgrade, I'll ask if you want to delete the backup files:

! if [ -f "mix.exs.backup" ] || [ -f "mix.lock.backup" ]; then echo ""; echo "Backup files exist. Would you like to delete them?"; echo "- mix.exs.backup"; echo "- mix.lock.backup"; echo ""; echo "I'll ask for confirmation before deleting."; fi

Let me proceed with the upgrade process and handle any issues that arise.

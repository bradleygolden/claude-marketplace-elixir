---
name: usage-rules
description: Search for package-specific usage rules and best practices from Elixir packages. Use when you need coding conventions, patterns, common mistakes, or good/bad examples for packages like Ash, Phoenix, Ecto, etc.
allowed-tools: Read, Grep, Glob, Bash, AskUserQuestion
model: haiku
context: fork
agent: Explore
---

# Usage Rules Search

Find package-specific best practices and coding conventions from `usage-rules.md` files.

## What Are Usage Rules?

A community convention where packages include a `usage-rules.md` file with:
- Coding conventions and patterns
- Good/bad code examples (marked `# GOOD`, `# BAD`, `# AVOID`)
- Common mistakes to avoid
- Domain-specific idioms

## Search Locations (in order)

1. **Project deps**: `deps/<package>/usage-rules.md`
2. **Fetched cache**: `.usage-rules/<package>-<version>/usage-rules.md`
3. **Fetch if needed**: Extract from package (see below)

## Packages With Usage Rules

Primarily the Ash ecosystem:
- `ash`, `ash_postgres`, `ash_phoenix`, `ash_json_api`, `ash_graphql`
- `spark`, `igniter`, `reactor`

Most packages (Phoenix, Ecto, etc.) do not have usage-rules.md yet. For those, suggest `hex-docs-search` skill or official guides.

## Fetching Usage Rules

```bash
# Fetch package and extract usage-rules.md
mix hex.package fetch <package> <version> --unpack --output .usage-rules/.tmp/<package>-<version>

# If usage-rules.md exists, copy to cache
if [ -f ".usage-rules/.tmp/<package>-<version>/usage-rules.md" ]; then
  mkdir -p ".usage-rules/<package>-<version>"
  cp ".usage-rules/.tmp/<package>-<version>/usage-rules.md" ".usage-rules/<package>-<version>/"
fi

# Clean up
rm -rf ".usage-rules/.tmp/<package>-<version>"
```

Mention adding `.usage-rules/` to `.gitignore` once per session when fetching occurs.

## Context-Aware Extraction

Usage rules files can be large. Extract relevant sections based on user's question:

| User Context | Look for Sections |
|--------------|-------------------|
| querying, filters | "Querying", "Filters", "Read Actions" |
| actions, create/update | "Actions", "Changes", "Validations" |
| relationships | "Relationships", "Aggregates" |
| errors, validation | "Error Handling", "Validations" |
| authorization | "Policies", "Authorization" |
| testing | "Testing" |

Find section headings with line numbers, then extract the relevant section content.

## Key Behaviors

- Extract relevant sections, don't dump entire file
- Highlight `# GOOD` vs `# BAD` patterns explicitly
- Note when package doesn't provide usage rules
- Suggest `hex-docs-search` for API documentation (complementary)
- Version awareness: prefer deps/ version over cached

# Usage Rules Search Skill

A comprehensive skill for searching Elixir and Erlang package usage rules and best practices using a cascading strategy.

## Overview

This skill helps Claude search for package usage rules intelligently by:
1. **Local dependencies** - Searches installed packages in `deps/` directory
2. **Fetched cache** - Checks previously fetched usage rules in `.usage-rules/`
3. **Progressive fetch** - Automatically fetches missing usage rules when needed
4. **Context-aware extraction** - Extracts relevant sections based on coding context
5. **Fallback guidance** - Provides alternatives when rules unavailable

## Usage

This skill is automatically available when the `core@elixir` plugin is installed. Claude will use it when appropriate, for example:

```
User: "What are Ash best practices for querying?"
User: "Show me error handling patterns in Phoenix"
User: "How should I structure Ecto schemas?"
User: "What are common mistakes with LiveView?"
User: "Best practices for Ash relationships"
```

## How it Works

### 1. Local Dependencies Search (deps/)

Searches installed packages for `usage-rules.md` files:
- Finds usage rules matching your project's version
- Searches for relevant sections based on context
- Extracts code examples with good/bad patterns

**Advantage**: Matches the exact version used in the project

### 2. Fetched Cache Search (.usage-rules/)

Checks for previously fetched usage rules:
- Searches `.usage-rules/<package>-<version>/usage-rules.md`
- Includes sub-rules if package provides them
- Uses same search patterns as deps/

**Advantage**: Fast, offline-capable access to packages not in project dependencies

### 3. Progressive Fetch

When usage rules aren't found locally, automatically fetches them:
- **Version detection**: Checks mix.lock, mix.exs, or hex.pm for version
- **User prompting**: Asks user to choose version when ambiguous (latest vs specific)
- **Package fetch**: Downloads package with `mix hex.package fetch`
- **Extraction**: Copies usage-rules.md to `.usage-rules/<package>-<version>/`
- **Cached for future**: All fetched rules reusable in subsequent queries

**Advantage**: Builds a local knowledge base of usage rules over time

### 4. Context-Aware Extraction

Extracts relevant sections based on what you're working on:
- **Querying** → "## Querying Data" section
- **Error handling** → "## Error Handling" section
- **Actions** → "## Actions" section
- **Relationships** → "## Relationships" section
- **Testing** → "## Testing" section

**Advantage**: Focused guidance without overwhelming context

### 5. Fallback Guidance

When package doesn't provide usage rules:
- Notes that package hasn't adopted convention
- Suggests using hex-docs-search for API documentation
- Recommends checking package README or guides
- Lists packages that currently have usage rules

**Advantage**: Graceful handling of unavailable rules

## Examples

### Example 1: Looking up Ash querying best practices

```
User: "What are Ash best practices for querying?"

Claude will:
1. Find deps/ash/usage-rules.md or .usage-rules/ash-*/usage-rules.md
2. Extract "## Querying Data" section
3. Show code examples with GOOD/BAD patterns
4. Provide file path for full rules
```

### Example 2: Unknown package with progressive fetch

```
User: "What are Spark DSL best practices?"

Claude will:
1. Check deps/spark/usage-rules.md (not found)
2. Check .usage-rules/spark-*/usage-rules.md (not found)
3. Detect version from mix.exs or query hex.pm
4. Prompt: "Fetch Spark 2.2.24 usage rules?"
5. User confirms: "Latest"
6. Fetch: mix hex.package fetch spark 2.2.24 --unpack
7. Extract: .usage-rules/spark-2.2.24/usage-rules.md
8. Present usage rules with relevant sections
9. Suggest adding to .gitignore

Future queries: Instant access to cached rules
```

### Example 3: Cached rules (offline access)

```
User: "Show me Ash relationship best practices again"

Claude will:
1. Check deps/ash/usage-rules.md (not found)
2. Check .usage-rules/ash-*/usage-rules.md (found version 3.5.20!)
3. **No fetch needed** - use cached rules
4. Extract "## Relationships" section
5. Present instantly

Result: Fast, offline search without network requests
```

### Example 4: Package without usage rules

```
User: "Phoenix LiveView best practices?"

Claude will:
1. Check for usage rules (not found)
2. Note that LiveView doesn't provide usage-rules.md yet
3. Suggest alternatives:
   - Use hex-docs-search for API documentation
   - Check Phoenix LiveView guides
   - Search web for community practices
```

### Example 5: Context-aware extraction

```
User: "Common mistakes with Ash actions?"

Claude will:
1. Find Ash usage rules
2. Identify context: "actions" + "mistakes"
3. Extract "## Actions" section
4. Search for keywords: "mistake", "avoid", "bad", "wrong"
5. Present consolidated best practices with patterns to avoid
```

## Requirements

- `curl` - For hex.pm API queries
- `jq` - For JSON parsing
- `mix` - For fetching packages

These are standard on Linux/Mac, use Git Bash or WSL on Windows.

## Recommended .gitignore Entries

Add these to your `.gitignore` to exclude fetched usage rules:

```gitignore
# Fetched usage rules
/.usage-rules/
```

These directories can be large and are easily re-fetched on demand.

## Integration with hex-docs-search

This skill focuses on **coding conventions and best practices**. For **API documentation** (function signatures, parameters, return values), use the **hex-docs-search** skill.

**Comprehensive guidance**: Agents can invoke both skills to provide complete "how to use it correctly" guidance:
- **usage-rules**: Conventions, patterns, good/bad examples
- **hex-docs-search**: API documentation, function signatures

**Example**:
```
User: "Help me implement Ash queries properly"

Agent combines both:
1. usage-rules: Get Ash querying conventions (use code interfaces, avoid manual queries)
2. hex-docs-search: Get Ecto.Query API documentation (filter operators, query functions)
3. Synthesize: "Here's how to do it (conventions) + what's available (API)"
```

## Current Usage Rules Availability

**Packages with usage rules** (as of 2025-10-31):
- **Ash ecosystem**: ash, ash_postgres, ash_json_api
- **Build tools**: igniter, spark, reactor

**Note**: Usage rules are a community-driven convention. Not all packages have adopted this yet, but adoption is growing.

**Help the ecosystem**: Encourage package maintainers to add `usage-rules.md` files! These files help both humans and AI understand best practices.

## What are Usage Rules?

Usage rules are **LLM-optimized markdown files** (`usage-rules.md`) that packages provide to guide proper usage:

**Characteristics**:
- Located at package root: `<package>/usage-rules.md`
- Dense, token-efficient format
- Code-first with good/bad examples
- Organized by topic (querying, error handling, testing, etc.)
- Includes inline comments and quick references

**Example structure**:
```markdown
# Rules for working with Ash

## Understanding Ash
[High-level overview]

## Code Structure & Organization
[Conventions for organizing code]

## Querying Data
```elixir
# GOOD - Use code interface
MyApp.Blog.list_posts!(query: [filter: [status: :published]])

# BAD - Don't bypass domain
Ash.Query.filter(MyApp.Blog.Post, status: :published) |> Ash.read!()
```
```

## How to Create Usage Rules

If you're a package maintainer:

1. Create `usage-rules.md` in your package root
2. Start with "# Rules for working with [Package]"
3. Add "## Understanding [Package]" section (overview)
4. Organize by common tasks and features
5. Use code examples with `# GOOD` and `# BAD` patterns
6. Keep it dense and token-efficient
7. Include in your hex package `files` list

See [Ash's usage-rules.md](https://github.com/ash-project/ash/blob/main/usage-rules.md) for a comprehensive example.

## Integration

This skill is bundled with the `core@elixir` plugin and doesn't require separate installation.

See [SKILL.md](SKILL.md) for the complete skill prompt and instructions.

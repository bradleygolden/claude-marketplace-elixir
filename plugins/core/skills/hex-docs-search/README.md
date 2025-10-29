# Hex Docs Search Skill

A comprehensive skill for searching Elixir and Erlang package documentation using a cascading search strategy.

## Overview

This skill helps Claude search for Hex package documentation intelligently by:
1. First checking local dependencies in `deps/`
2. Then checking previously fetched documentation and source in `.hex-docs/` and `.hex-packages/`
3. Automatically fetching missing documentation or source code when needed (with version prompting)
4. Searching the codebase for real usage examples
5. Querying the hex.pm API for official docs
6. Falling back to web search if needed

## Usage

This skill is automatically available when the `core@elixir` plugin is installed. Claude will use it when appropriate, for example:

```
User: "How do I use Phoenix.LiveView mount/3?"
User: "Show me Ecto.Query examples"
User: "What does Jason.decode!/1 do?"
User: "Research the Sobelow hex package"
User: "Learn about the Credo library"
User: "Understand how Ash Framework works"
```

## How it Works

### 1. Local Dependencies Search (deps/)

Uses Grep and Glob tools to search installed packages for BOTH code and docs:
- **Source code**: Finds module definitions, function implementations, and `@moduledoc`/`@doc` annotations
- **Generated docs**: Checks for HTML documentation in `deps/*/doc/` directories
- Provides full context from whichever source is most helpful

**Advantage**: Matches the exact version used in the project

### 2. Fetched Cache Search (.hex-docs/ and .hex-packages/)

Checks for previously fetched documentation and source code:
- **Documentation**: Searches `.hex-docs/docs/hexpm/<package>/<version>/` for HTML docs
- **Source code**: Searches `.hex-packages/<package>-<version>/` for unpacked source
- Uses same search patterns as deps/ directory

**Advantage**: Fast, offline-capable access to packages not in project dependencies

### 3. Progressive Fetch (NEW)

When packages aren't found locally, automatically fetches them:
- **Version detection**: Checks mix.lock, mix.exs, or hex.pm for version
- **User prompting**: Asks user to choose version when ambiguous (latest vs specific)
- **Documentation first**: Fetches HTML docs with `mix hex.docs fetch` to `.hex-docs/`
- **Source if needed**: Fetches source code with `mix hex.package fetch --unpack` to `.hex-packages/`
- **Cached for future**: All fetched content reusable in subsequent queries

**Advantage**: Builds a local knowledge base of documentation and source code over time

### 4. Codebase Usage Search

Searches the project's `lib/` and `test/` directories:
- Finds `alias` and `import` statements
- Locates function calls
- Shows real-world usage from your code

**Advantage**: Context-aware examples from your actual codebase

### 5. HexDocs Search API

Uses the HexDocs search API at `https://search.hexdocs.pm/`:
- Full-text search across documentation content
- Filters by package name and version
- Returns documentation excerpts with direct links
- Falls back to hex.pm API for package info

**Advantage**: Searches actual documentation content, not just package metadata

### 6. Web Search Fallback

Uses WebSearch with targeted queries:
- `site:hexdocs.pm <package> <module>` for specific docs
- General Elixir documentation search

**Advantage**: Finds community examples and guides

## Examples

### Example 1: Looking up a commonly used dependency

```
User: "How do I query with Ecto?"

Claude will:
1. Find deps/ecto/lib/ecto/query.ex
2. Search for "import Ecto.Query" in lib/
3. Show usage examples from the project
4. Read @moduledoc from the source
```

### Example 2: Unknown package with progressive fetch

```
User: "What is the Timex library?"

Claude will:
1. Check deps/timex (not found)
2. Check .hex-docs/docs/hexpm/timex/ (not found)
3. Detect no version in project dependencies
4. Query hex.pm for latest version
5. Prompt: "Fetch latest (3.7.11) or specific version?"
6. User selects "Latest"
7. Fetch: HEX_HOME=.hex-docs mix hex.docs fetch timex 3.7.11
8. Search fetched HTML documentation
9. Present findings with link to cached docs
10. Suggest adding to .gitignore if not present

Future queries: Instant access to cached documentation
```

### Example 3: Specific function lookup

```
User: "How does Jason.decode!/2 work?"

Claude will:
1. Find deps/jason/lib/jason.ex
2. Grep for "def decode!"
3. Show the @doc and implementation
4. Find usage in tests/
```

## Requirements

- `curl` - For hex.pm API queries
- `jq` - For JSON parsing (recommended)
- `mix` - For fetching packages and documentation
- Internet access - For API, web search, and fetching packages/docs

## Recommended .gitignore Entries

Add these to your `.gitignore` to exclude fetched content:

```gitignore
# Fetched Hex documentation and packages
/.hex-docs/
/.hex-packages/
```

These directories can be large and are easily re-fetched on demand.

## Integration

This skill is bundled with the `core@elixir` plugin and doesn't require separate installation.

See [SKILL.md](SKILL.md) for the complete skill prompt and instructions.

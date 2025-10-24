# Hex Docs Search Skill

A comprehensive skill for searching Elixir and Erlang package documentation using a cascading search strategy.

## Overview

This skill helps Claude search for Hex package documentation intelligently by:
1. First checking local dependencies in `deps/`
2. Then searching the codebase for real usage examples
3. Querying the hex.pm API for official docs
4. Falling back to web search if needed

## Usage

This skill is automatically available when the `core@elixir` plugin is installed. Claude will use it when appropriate, for example:

```
User: "How do I use Phoenix.LiveView mount/3?"
User: "Show me Ecto.Query examples"
User: "What does Jason.decode!/1 do?"
```

## How it Works

### 1. Local Dependencies Search (deps/)

Uses Grep and Glob tools to search installed packages for BOTH code and docs:
- **Source code**: Finds module definitions, function implementations, and `@moduledoc`/`@doc` annotations
- **Generated docs**: Checks for HTML documentation in `deps/*/doc/` directories
- Provides full context from whichever source is most helpful

**Advantage**: Matches the exact version used in the project

### 2. Codebase Usage Search

Searches the project's `lib/` and `test/` directories:
- Finds `alias` and `import` statements
- Locates function calls
- Shows real-world usage from your code

**Advantage**: Context-aware examples from your actual codebase

### 3. HexDocs API Search

Queries `https://hex.pm/api/packages/<name>`:
- Gets latest version information
- Fetches package description
- Constructs hexdocs.pm URLs

**Advantage**: Official, up-to-date documentation

### 4. Web Search Fallback

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

### Example 2: Unknown package

```
User: "What is the Timex library?"

Claude will:
1. Check deps/timex (not found)
2. Query hex.pm API for package info
3. Provide link: https://hexdocs.pm/timex
4. Show description and offer to add to mix.exs
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
- Internet access - For API and web search

## Integration

This skill is bundled with the `core@elixir` plugin and doesn't require separate installation.

See [SKILL.md](SKILL.md) for the complete skill prompt and instructions.

---
name: hex-docs-search
description: Search Elixir/Erlang package documentation and usage. Use when looking up Hex packages, module documentation, function signatures, or examples. Searches local deps, codebase usage, hexdocs.pm API, and web as fallback.
allowed-tools: Read, Grep, Glob, Bash, WebSearch
---

# Hex Documentation Search

Comprehensive search for Elixir and Erlang package documentation, following a cascading strategy to find the most relevant and context-aware information.

## When to use this skill

Use this skill when you need to:
- Look up documentation for a Hex package or dependency
- Find function signatures, module documentation, or type specs
- See usage examples of a library or module
- Understand how a dependency is used in the current project
- Search for Elixir/Erlang standard library documentation

## Search strategy

This skill implements a **cascading search** that prioritizes local and contextual information:

1. **Local dependencies** - Search installed packages in `deps/` directory
2. **Codebase usage** - Find how packages are used in the current project
3. **HexDocs API** - Search official documentation on hexdocs.pm
4. **Web search** - Fallback to general web search

## Instructions

### Step 1: Identify the search target

Extract the package name and optionally the module or function name from the user's question.

Examples:
- "How do I use Phoenix.LiveView?" → Package: `phoenix_live_view`, Module: `Phoenix.LiveView`
- "Show me Ecto query examples" → Package: `ecto`, Module: `Ecto.Query`
- "What does Jason.decode!/1 do?" → Package: `jason`, Module: `Jason`, Function: `decode!`

### Step 2: Search local dependencies

Use the **Glob** and **Grep** tools to search the `deps/` directory:

1. **Find the package directory**:
   ```
   Use Glob: pattern="deps/<package_name>/**/*.ex"
   ```

   If no results, the package isn't installed locally. Skip to Step 4.

2. **Search for module definition**:
   ```
   Use Grep: pattern="defmodule <ModuleName>", path="deps/<package_name>/lib"
   ```

3. **Search for function definition** (if looking for specific function):
   ```
   Use Grep: pattern="def <function_name>", path="deps/<package_name>/lib", output_mode="content", -A=5
   ```

4. **Find documentation**:
   ```
   Use Grep: pattern="@moduledoc|@doc", path="deps/<package_name>/lib", output_mode="content", -A=10
   ```

5. **Read the relevant file** using the Read tool to get the full context.

### Step 3: Search codebase usage

Use the **Grep** tool to find usage patterns in the current project:

1. **Find imports and aliases**:
   ```
   Use Grep: pattern="alias <ModuleName>|import <ModuleName>", path="lib", output_mode="content", -n=true
   ```

2. **Find function calls**:
   ```
   Use Grep: pattern="<ModuleName>\.", path="lib", output_mode="content", -A=3
   ```

3. **Search test files for examples**:
   ```
   Use Grep: pattern="<ModuleName>", path="test", output_mode="content", -A=5
   ```

This provides **real-world usage examples** from the current project, which is often the most helpful context.

### Step 4: Search HexDocs API

If local search doesn't provide sufficient information, use the **Bash** tool to query the hex.pm API:

```bash
# Search for package on hex.pm API
curl -s "https://hex.pm/api/packages/<package_name>" | jq -r '.releases[0].version, .meta.description, .meta.links'
```

This will:
1. Fetch the package information from hex.pm
2. Get the latest version
3. Show description and links

Then construct the hexdocs.pm URL:
```
https://hexdocs.pm/<package_name>/<version>/<Module>.html
```

Provide this link to the user along with the version and description.

### Step 5: Web search fallback

If the above steps don't provide sufficient information, use the **WebSearch** tool:

First try searching hexdocs.pm specifically:
```
Use WebSearch: query="site:hexdocs.pm <package_name> <module_or_function>"
```

If that doesn't help, do a general search:
```
Use WebSearch: query="elixir <package_name> <module_or_function> documentation examples"
```

## Output format

When presenting results, organize them as follows:

### If found locally:

```
Found <package_name> in local dependencies:

**Location**: deps/<package_name>
**Version**: <version from mix.lock>

**Documentation**:
<relevant documentation or code snippets>

**Usage in this project**:
<usage examples from codebase>
```

### If found on HexDocs:

```
Found <package_name> on HexDocs:

**Package**: <package_name>
**Latest version**: <version>
**Documentation**: https://hexdocs.pm/<package_name>/<version>/<Module>.html

<summary of key information>
```

### If using web search:

```
Searching web for <package_name> documentation:

<summary of web search results>
```

## Examples

### Example 1: Finding Phoenix.LiveView documentation

**User asks**: "How do I use Phoenix.LiveView mount/3?"

**Search process**:
1. Check `deps/phoenix_live_view/`
2. Search for `def mount` in `lib/phoenix_live_view.ex`
3. Read the `@doc` for `mount/3`
4. Search project for `mount` implementations in `lib/*/live/*.ex`
5. Show examples from the codebase

### Example 2: Looking up Ecto.Query

**User asks**: "Show me Ecto.Query examples"

**Search process**:
1. Check `deps/ecto/`
2. Search project for `import Ecto.Query`
3. Find query examples in `lib/*/queries/*.ex` or `lib/*_context.ex`
4. If needed, fetch from hexdocs.pm using the script
5. Show local examples first, then external docs

### Example 3: Unknown package

**User asks**: "How do I use the Timex library?"

**Search process**:
1. Check `deps/timex/` (not found)
2. Search hex.pm API for "timex"
3. Provide hexdocs.pm link: https://hexdocs.pm/timex
4. Offer to add it to mix.exs if user wants to use it

## Tool usage summary

Use Claude's built-in tools in this order:

1. **Glob** - Find package files in deps/
2. **Grep** - Search for modules, functions, and documentation in deps/ and project code
3. **Read** - Read full files for detailed documentation
4. **Bash** - Query hex.pm API with curl
5. **WebSearch** - Fallback search for hexdocs.pm or general web

## Best practices

1. **Start local**: Always check local dependencies first - they match the version used in the project
2. **Show usage**: Real code examples from the current project are more valuable than generic documentation
3. **Version awareness**: Note which version is installed locally vs latest on hex.pm
4. **Progressive disclosure**: Start with a summary, offer to dive deeper if needed
5. **Link to source**: Provide file paths (with line numbers) so users can explore further

## Troubleshooting

### Package not found in deps/

- Check if it's in mix.exs dependencies
- Suggest running `mix deps.get` if it should be installed
- Search hex.pm to verify the package exists

### No documentation in deps/

- Some packages don't include @doc annotations
- Fall back to hexdocs.pm search
- Read the source code directly and explain it

### HexDocs API rate limiting

- If the API is rate limited, fall back to web search
- Cache results when possible
- Use web search with `site:hexdocs.pm` filter

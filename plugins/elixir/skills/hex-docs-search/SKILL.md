---
name: hex-docs-search
description: Research Hex packages (Sobelow, Phoenix, Ecto, Credo, Ash, etc). Use when investigating packages, understanding integration patterns, or finding module/function docs and usage examples. Automatically fetches missing documentation and source code locally.
allowed-tools: Read, Grep, Glob, Bash, WebSearch, AskUserQuestion
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

1. **Local dependencies** - Search installed packages in `deps/` directory (both source code AND generated docs)
2. **Fetched cache** - Check previously fetched documentation and source code in `.hex-docs/` and `.hex-packages/`
3. **Progressive fetch** - Automatically fetch missing documentation or source code locally when needed
4. **Codebase usage** - Find how packages are used in the current project
5. **HexDocs API** - Search official documentation on hexdocs.pm (fallback)
6. **Web search** - Fallback to general web search (last resort)

## Instructions

### Step 1: Identify the search target

Extract the package name and optionally the module or function name from the user's question.

Examples:
- "How do I use Phoenix.LiveView?" → Package: `phoenix_live_view`, Module: `Phoenix.LiveView`
- "Show me Ecto query examples" → Package: `ecto`, Module: `Ecto.Query`
- "What does Jason.decode!/1 do?" → Package: `jason`, Module: `Jason`, Function: `decode!`

### Step 2: Search local dependencies

Use the **Glob** and **Grep** tools to search the `deps/` directory for BOTH code and documentation:

1. **Find the package directory**:
   ```
   Use Glob: pattern="deps/<package_name>/**/*.ex"
   ```

   If no results, the package isn't installed locally. Skip to Step 4.

2. **Search for module definition in source code**:
   ```
   Use Grep: pattern="defmodule <ModuleName>", path="deps/<package_name>/lib"
   ```

3. **Search for function definition in source code** (if looking for specific function):
   ```
   Use Grep: pattern="def <function_name>", path="deps/<package_name>/lib", output_mode="content", -A=5
   ```

4. **Find documentation in source code** (@moduledoc/@doc annotations):
   ```
   Use Grep: pattern="@moduledoc|@doc", path="deps/<package_name>/lib", output_mode="content", -A=10
   ```

5. **Check for generated HTML documentation** (if available):
   ```
   Use Glob: pattern="deps/<package_name>/doc/**/*.html"
   ```

   If HTML docs exist, search them for relevant content:
   ```
   Use Grep: pattern="<ModuleName>|<function_name>", path="deps/<package_name>/doc"
   ```

6. **Read the relevant files** using the Read tool to get full context from either source or HTML docs.

### Step 3: Check fetched cache and fetch if needed

If the package wasn't found in `deps/`, check for previously fetched documentation or source code, or fetch it now.

#### 3.1: Check fetched documentation cache

Use the **Glob** tool to check if documentation was previously fetched:

```
Use Glob: pattern=".hex-docs/docs/hexpm/<package_name>/*/*.html"
```

If found, search the fetched documentation using the same patterns as Step 2 (sections 5 and 6).

#### 3.2: Check fetched source code cache

Use the **Glob** tool to check if source code was previously fetched:

```
Use Glob: pattern=".hex-packages/<package_name>-*/**/*.ex"
```

If found, search the fetched source using the same patterns as Step 2 (sections 2-4).

#### 3.3: Determine version to fetch

If no cached docs or source found, determine which version to fetch:

1. **Check mix.lock** for locked version:
   ```
   Use Bash: grep '"<package_name>"' mix.lock | grep -oE '[0-9]+\.[0-9]+\.[0-9]+'
   ```

2. **Check mix.exs** for version constraint:
   ```
   Use Bash: grep -E '\{:<package_name>' mix.exs | grep -oE '[0-9]+\.[0-9]+\.[0-9]+'
   ```

3. **Get latest version from hex.pm**:
   ```
   Use Bash: curl -s "https://hex.pm/api/packages/<package_name>" | jq -r '.releases[0].version'
   ```

4. **If version ambiguous**, use **AskUserQuestion** to prompt:
   ```
   Question: "Package '<package_name>' not found locally. Which version would you like to fetch?"
   Options:
   - "Latest (X.Y.Z)" - Fetch most recent release
   - "Project version (X.Y.Z)" - Use version from mix.exs/mix.lock (if available)
   - "Specific version" - User provides custom version in "Other" field
   - "Skip fetching" - Continue to HexDocs API search without fetching
   ```

#### 3.4: Progressive fetch (documentation first)

Once version is determined, fetch documentation to project-local cache:

```bash
# Use custom HEX_HOME to store in project directory
HEX_HOME=.hex-docs mix hex.docs fetch <package_name> <version>
```

**Storage location**: `.hex-docs/docs/hexpm/<package_name>/<version>/`

If successful:
- Search the fetched HTML documentation using patterns from Step 2 (sections 5-6)
- Read relevant files with the Read tool

If **documentation fetch fails** (package has no docs) or **docs lack sufficient detail**:
- Proceed to Step 3.5 to fetch source code

#### 3.5: Fetch source code if needed

If documentation is insufficient or unavailable, fetch package source code:

```bash
# Fetch and unpack to project-local directory
mix hex.package fetch <package_name> <version> --unpack --output .hex-packages/<package_name>-<version>
```

**Storage location**: `.hex-packages/<package_name>-<version>/`

If successful:
- Search the source code using patterns from Step 2 (sections 2-4)
- Read source files with the Read tool
- Examine @moduledoc and @doc annotations

If **source fetch fails**:
- Continue to Step 5 (HexDocs API search) as fallback

#### 3.6: Git ignore recommendation

Inform the user that fetched content should be git-ignored. Suggest adding to `.gitignore`:

```gitignore
# Fetched Hex documentation and packages
/.hex-docs/
/.hex-packages/
```

This only needs to be mentioned once per session, and only if fetching actually occurred.

### Step 4: Search codebase usage

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

### Step 5: Search HexDocs Search API

If local search doesn't provide sufficient information, use the **Bash** tool to search the HexDocs search API.

**Full-text search across documentation:**

```bash
# Search across all packages
curl -s "https://search.hexdocs.pm/?q=<query>&query_by=doc,title" | jq -r '.found, .hits[0:5][] | .document | "\(.package) - \(.title)\n\(.doc)\n---"'

# Search within a specific package (get version first)
VERSION=$(curl -s "https://hex.pm/api/packages/<package_name>" | jq -r '.releases[0].version')
curl -s "https://search.hexdocs.pm/?q=<query>&query_by=doc,title&filter_by=package:=[<package>-$VERSION]" | jq -r '.hits[] | .document | "\(.title)\n\(.doc)\nURL: https://hexdocs.pm\(.url)\n---"'
```

**Examples:**

```bash
# Search for "mount" in phoenix_live_view
VERSION=$(curl -s "https://hex.pm/api/packages/phoenix_live_view" | jq -r '.releases[0].version')
curl -s "https://search.hexdocs.pm/?q=mount&query_by=doc,title&filter_by=package:=[phoenix_live_view-$VERSION]" | jq -r '.hits[0:3][] | .document | "\(.title)\n\(.doc)\n---"'

# General search for Ecto.Query
curl -s "https://search.hexdocs.pm/?q=Ecto.Query&query_by=doc,title" | jq -r '.hits[0:5][] | .document | "\(.package) - \(.title)\n\(.doc)\n"'
```

**API Response structure:**
- `found`: Total number of results
- `hits[]`: Array of results with:
  - `document.package`: Package name
  - `document.ref`: Version
  - `document.title`: Function/module name
  - `document.doc`: Documentation text
  - `document.url`: Path to docs (append to https://hexdocs.pm)

**Requirements:** curl and jq (available on Linux/Mac, use Git Bash or WSL on Windows)

### Step 6: Web search fallback

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
1. Check `deps/phoenix_live_view/` exists
2. Search for `def mount` in `deps/phoenix_live_view/lib/` (source code)
3. Read the `@doc` annotation for `mount/3` from source
4. Check for HTML docs in `deps/phoenix_live_view/doc/` and read if available
5. Search project for `mount` implementations in `lib/*/live/*.ex` (usage examples)
6. Show documentation and examples from both deps and codebase

### Example 2: Looking up Ecto.Query

**User asks**: "Show me Ecto.Query examples"

**Search process**:
1. Check `deps/ecto/` for source code
2. Search project for `import Ecto.Query`
3. Find query examples in `lib/*/queries/*.ex` or `lib/*_context.ex`
4. If needed, search HexDocs API:
   ```bash
   curl -s "https://search.hexdocs.pm/?q=Ecto.Query&query_by=doc,title" | jq '.hits[0:3]'
   ```
5. Show local examples first, then external docs

### Example 3: Unknown package with progressive fetch

**User asks**: "How do I use the Timex library?"

**Search process**:
1. Check `deps/timex/` (not found)
2. Check `.hex-docs/docs/hexpm/timex/` (not found)
3. Check `.hex-packages/timex-*/` (not found)
4. Check mix.exs/mix.lock (not in project dependencies)
5. Get latest version from hex.pm:
   ```bash
   curl -s "https://hex.pm/api/packages/timex" | jq -r '.releases[0].version'
   # Returns: 3.7.11
   ```
6. Prompt user: "Package 'timex' not found locally. Fetch latest (3.7.11)?"
7. User confirms: "Latest"
8. Fetch documentation:
   ```bash
   HEX_HOME=.hex-docs mix hex.docs fetch timex 3.7.11
   # Stores in: .hex-docs/docs/hexpm/timex/3.7.11/
   ```
9. Search fetched HTML documentation
10. If docs sufficient, present findings
11. If docs lack detail, offer to fetch source:
    ```bash
    mix hex.package fetch timex 3.7.11 --unpack --output .hex-packages/timex-3.7.11
    ```
12. Search source code for implementation details
13. Suggest adding to .gitignore if not already present
14. Offer to add it to mix.exs if user wants to use it

**Future queries**: Documentation and source cached locally for instant offline access

### Example 4: Cached documentation (offline-capable)

**User asks**: "Show me Phoenix.LiveView.mount/3 again"

**Search process**:
1. Check `deps/phoenix_live_view/` (not found)
2. Check `.hex-docs/docs/hexpm/phoenix_live_view/` (found version 0.20.0!)
3. **No fetch needed** - use cached documentation
4. Search cached HTML: `.hex-docs/docs/hexpm/phoenix_live_view/0.20.0/Phoenix.LiveView.html`
5. Present documentation instantly

**Result**: Fast, offline search without network requests. Works even when disconnected.

### Example 5: Progressive fetch (docs → source)

**User asks**: "Show me the implementation of Jason.decode!/2"

**Search process**:
1. Check `deps/jason/` (not found)
2. Check `.hex-docs/docs/hexpm/jason/` (not found)
3. Check project version in mix.exs: `{:jason, "~> 1.4"}`
4. Resolve to latest 1.4.x from hex.pm: 1.4.4
5. Fetch docs:
   ```bash
   HEX_HOME=.hex-docs mix hex.docs fetch jason 1.4.4
   ```
6. Search docs: Find signature but not implementation details
7. Offer: "Documentation shows the signature. Fetch source code for implementation?"
8. User confirms
9. Fetch source:
   ```bash
   mix hex.package fetch jason 1.4.4 --unpack --output .hex-packages/jason-1.4.4
   ```
10. Search source: `.hex-packages/jason-1.4.4/lib/jason.ex`
11. Present implementation with line numbers

**Result**: Both docs and source cached for comprehensive future queries

## Tool usage summary

Use Claude's built-in tools in this order:

1. **Glob** - Find package files in deps/, .hex-docs/, and .hex-packages/
2. **Grep** - Search for modules, functions, and documentation in deps/, fetched cache, and project code
3. **Read** - Read full files for detailed documentation
4. **Bash** - Fetch packages/docs with mix hex commands; Query HexDocs Search API with curl + jq
5. **AskUserQuestion** - Prompt for version when ambiguous
6. **WebSearch** - Fallback search for hexdocs.pm or general web

**Requirements:** curl and jq (Linux/Mac native, use Git Bash or WSL on Windows)

## Best practices

1. **Start local**: Always check local dependencies first - they match the version used in the project
2. **Check cache before fetch**: Look for previously fetched docs/source in `.hex-docs/` and `.hex-packages/` before fetching
3. **Progressive fetch**: Try documentation first (lighter, faster), then source if needed
4. **Prompt for clarity**: Always prompt for version when ambiguous - don't assume latest is desired
5. **Show usage**: Real code examples from the current project are more valuable than generic documentation
6. **Version awareness**: Note which version is installed locally vs latest on hex.pm vs fetched
7. **Progressive disclosure**: Start with a summary, offer to dive deeper if needed
8. **Link to source**: Provide file paths (with line numbers) so users can explore further
9. **Git ignore reminder**: Mention .gitignore addition once per session when fetching occurs
10. **Offline capability**: Once fetched, documentation and source available without network access

## Troubleshooting

### Package not found in deps/

- Check `.hex-docs/` and `.hex-packages/` for previously fetched content
- If not cached, determine version and offer to fetch
- Check if it's in mix.exs dependencies (for version resolution)
- Suggest running `mix deps.get` if it should be a project dependency
- Search hex.pm to verify the package exists

### Fetch failures

**Documentation fetch fails**:
- Package may not have published docs (some packages only have source)
- Offer to fetch source code instead
- Fall back to HexDocs API search

**Source fetch fails**:
- Verify package name spelling
- Check network connectivity
- Fall back to HexDocs API search

### Cache location issues

**Fetched content not found on repeat queries**:
- Verify `.hex-docs/` and `.hex-packages/` directories exist
- Check that fetch commands completed successfully
- May need to re-fetch if directories were deleted

### No documentation in deps/

- Some packages don't include @doc annotations
- Fall back to hexdocs.pm search
- Read the source code directly and explain it

### HexDocs API rate limiting

- If the API is rate limited, fall back to web search
- Cache results when possible
- Use web search with `site:hexdocs.pm` filter

---
name: hex-docs-search
description: Research Hex packages (Sobelow, Phoenix, Ecto, Credo, Ash, etc). Use when investigating packages, understanding integration patterns, or finding module/function docs and usage examples. Automatically fetches missing documentation and source code locally.
allowed-tools: Read, Grep, Glob, Bash, WebSearch, AskUserQuestion
model: haiku
context: fork
agent: Explore
---

# Hex Documentation Search

Search Elixir package documentation. Prioritize local sources, fetch if needed.

## Search Locations (in order)

1. **Project deps**: `deps/<package>/lib/` (source with @moduledoc/@doc), `deps/<package>/doc/` (HTML if generated)
2. **Fetched docs cache**: `.hex-docs/docs/hexpm/<package>/<version>/`
3. **Fetched source cache**: `.hex-packages/<package>-<version>/`
4. **HexDocs API**: Programmatic search (see below)
5. **Web search**: Last resort with `site:hexdocs.pm`

## Fetching Locally

Determine version from `mix.lock`, `mix.exs`, or prompt user if ambiguous.

```bash
# Fetch documentation (stores in .hex-docs/)
HEX_HOME=.hex-docs mix hex.docs fetch <package> <version>

# Fetch source code (if docs insufficient or unavailable)
mix hex.package fetch <package> <version> --unpack --output .hex-packages/<package>-<version>
```

Mention adding `.hex-docs/` and `.hex-packages/` to `.gitignore` once per session when fetching occurs.

## HexDocs Search API

Powered by Typesense at `search.hexdocs.pm`.

```bash
# Search within a specific package
curl -s "https://search.hexdocs.pm/?q=<query>&filter_by=package:=[<package>-<version>]" \
  | jq '.hits[].document | {title, doc, url}'

# Search across all packages
curl -s "https://search.hexdocs.pm/?q=<query>" \
  | jq '.hits[].document | {package, title, doc}'
```

Response fields:
- `package`: Package name
- `title`: Module/function name
- `doc`: Documentation text
- `url`: Path to append to `https://hexdocs.pm`

## Version Resolution

```bash
# From mix.lock
grep '"<package>"' mix.lock | grep -oE '[0-9]+\.[0-9]+\.[0-9]+'

# Latest from hex.pm
curl -s "https://hex.pm/api/packages/<package>" | jq -r '.releases[0].version'
```

## Key Behaviors

- Prefer local/cached results (version matches project)
- Show real usage examples from project codebase when relevant
- Include file:line references for source code
- Prompt user before fetching external packages
- Source code @moduledoc/@doc often has more detail than HTML docs

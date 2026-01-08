---
name: usage-rules
description: Search for package-specific usage rules and best practices from Elixir packages. Use when you need coding conventions, patterns, common mistakes, or good/bad examples for packages like Ash, Phoenix, Ecto, etc.
allowed-tools: Read, Grep, Glob, Bash, AskUserQuestion
---

# Usage Rules Search

Comprehensive search for Elixir and Erlang package usage rules and best practices, following a cascading strategy to find the most relevant coding conventions and patterns.

## When to use this skill

Use this skill when you need to:
- Look up coding conventions for a Hex package
- Find best practices and recommended patterns
- See good/bad code examples for proper usage
- Understand common mistakes to avoid
- Learn package-specific idioms and conventions
- Get context-aware recommendations for implementation

## Search strategy

This skill implements a **cascading search** that prioritizes local and contextual information:

1. **Local dependencies** - Search installed packages in `deps/` directory for usage-rules.md
2. **Fetched cache** - Check previously fetched usage rules in `.usage-rules/`
3. **Progressive fetch** - Automatically fetch package and extract usage-rules.md if missing
4. **Context-aware extraction** - Extract relevant sections based on coding context
5. **Fallback** - Note when package doesn't provide usage rules, suggest alternatives

## Instructions

### Step 1: Identify the package and context

Extract the package name and identify the coding context from the user's question.

**Package name examples**:
- "Ash best practices" → Package: `ash`
- "Phoenix LiveView patterns" → Package: `phoenix_live_view`
- "How to use Ecto properly?" → Package: `ecto`

**Context keywords**:
- Querying: "query", "filter", "search", "find", "list"
- Error handling: "error", "validation", "exception", "handle"
- Actions: "create", "update", "delete", "action", "change"
- Relationships: "relationship", "association", "belongs_to", "has_many"
- Testing: "test", "testing", "mock", "fixture"
- Authorization: "authorization", "permissions", "policy", "access"
- Structure: "structure", "organization", "architecture", "setup"

### Step 2: Search local dependencies

Use the **Glob** and **Grep** tools to search the `deps/` directory for usage rules:

1. **Find the package directory with usage-rules.md**:
   ```
   Use Glob: pattern="deps/<package_name>/usage-rules.md"
   ```

   If no results, the package isn't installed locally or doesn't provide usage rules. Skip to Step 3.

2. **Check for sub-rules** (advanced packages may have specialized rules):
   ```
   Use Glob: pattern="deps/<package_name>/usage-rules/*.md"
   ```

3. **Search for relevant sections** based on context keywords:
   ```
   Use Grep: pattern="^## (Querying|Error Handling|Actions)", path="deps/<package_name>/usage-rules.md", output_mode="content", -n=true
   ```

   This finds section headings with line numbers.

4. **Extract relevant sections**:
   ```
   Use Grep: pattern="^## Error Handling", path="deps/<package_name>/usage-rules.md", output_mode="content", -A=50
   ```

   Use `-A` flag to get section content (adjust number based on typical section length).

5. **Read the complete file** if needed for broader context:
   ```
   Use Read: file_path="deps/<package_name>/usage-rules.md"
   ```

### Step 3: Check fetched cache and fetch if needed

If the package wasn't found in `deps/`, check for previously fetched usage rules, or fetch them now.

#### 3.1: Check fetched cache

Use the **Glob** tool to check if usage rules were previously fetched:

```
Use Glob: pattern=".usage-rules/<package_name>-*/usage-rules.md"
```

If found, search the cached rules using the same patterns as Step 2 (sections 3-5).

#### 3.2: Determine version to fetch

If no cached rules found, determine which version to fetch:

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
   Question: "Package '<package_name>' usage rules not found locally. Which version would you like to fetch?"
   Options:
   - "Latest (X.Y.Z)" - Fetch most recent release
   - "Project version (X.Y.Z)" - Use version from mix.exs/mix.lock (if available)
   - "Specific version" - User provides custom version in "Other" field
   - "Skip fetching" - Continue without usage rules
   ```

#### 3.3: Fetch package and extract usage rules

Once version is determined, fetch the package and extract usage-rules.md:

```bash
# Create temp directory and fetch package
mkdir -p .usage-rules/.tmp
mix hex.package fetch <package_name> <version> --unpack --output .usage-rules/.tmp/<package_name>-<version>

# Check if usage-rules.md exists
if [ -f ".usage-rules/.tmp/<package_name>-<version>/usage-rules.md" ]; then
  # Create version-specific directory
  mkdir -p ".usage-rules/<package_name>-<version>"

  # Copy main usage rules file
  cp ".usage-rules/.tmp/<package_name>-<version>/usage-rules.md" ".usage-rules/<package_name>-<version>/"

  # Copy sub-rules if present
  if [ -d ".usage-rules/.tmp/<package_name>-<version>/usage-rules/" ]; then
    cp -r ".usage-rules/.tmp/<package_name>-<version>/usage-rules/" ".usage-rules/<package_name>-<version>/"
  fi

  echo "Usage rules cached in .usage-rules/<package_name>-<version>/"
else
  echo "Package does not provide usage-rules.md"
fi

# Clean up temp directory
rm -rf ".usage-rules/.tmp/<package_name>-<version>"
```

**Storage location**: `.usage-rules/<package_name>-<version>/`

If successful:
- Search the cached usage rules using patterns from Step 2
- Read relevant files with the Read tool

If **package doesn't include usage-rules.md**:
- Package may not have adopted usage rules convention
- Proceed to Step 5 (fallback suggestions)

#### 3.4: Git ignore recommendation

Inform the user that fetched usage rules should be git-ignored. Suggest adding to `.gitignore`:

```gitignore
# Fetched usage rules
/.usage-rules/
```

This only needs to be mentioned once per session, and only if fetching actually occurred.

### Step 4: Extract relevant sections based on context

Usage rules files can be large (1000+ lines). Extract only relevant sections to avoid context overload.

#### 4.1: Find section headings

```bash
# Find all h2 section headings with line numbers
Use Grep: pattern="^## ", path=".usage-rules/<package>-<version>/usage-rules.md", output_mode="content", -n=true
```

This returns a list like:
```
7:## Understanding Ash
13:## Code Structure & Organization
21:## Code Interfaces
85:## Actions
120:## Querying Data
```

#### 4.2: Match context to sections

Based on user's context keywords, identify relevant sections:

**Context: "querying"** → Look for sections containing:
- "Querying", "Query", "Filters", "Search", "Find"

**Context: "error handling"** → Look for sections containing:
- "Error", "Validation", "Exception", "Handle"

**Context: "actions"** → Look for sections containing:
- "Actions", "Create", "Update", "Delete", "CRUD"

#### 4.3: Extract matched sections

```bash
# Extract specific section with content
Use Grep: pattern="^## Querying Data", path=".usage-rules/<package>-<version>/usage-rules.md", output_mode="content", -A=80
```

**Adjust `-A` value** based on typical section length:
- Small sections (< 50 lines): `-A=50`
- Medium sections (50-150 lines): `-A=100`
- Large sections (> 150 lines): `-A=150` or read specific ranges

#### 4.4: Include code examples

Look for code blocks within sections:

```bash
# Find code examples in section
Use Grep: pattern="```elixir|# GOOD|# BAD", path=".usage-rules/<package>-<version>/usage-rules.md", output_mode="content", -A=10
```

Code examples often include:
- **Good patterns**: Marked with `# GOOD`, `# PREFERRED`
- **Bad patterns**: Marked with `# BAD`, `# AVOID`, `# WRONG`
- **Inline comments**: Explanatory comments in code blocks

### Step 5: Present usage rules

Format the output based on what was found.

## Output format

When presenting results, organize them as follows:

### If found in local dependencies:

```
Found usage rules for <package_name>:

**Location**: deps/<package_name>/usage-rules.md
**Version**: <version from mix.lock>

**Relevant Best Practices** (<section_name>):

<extracted section content with code examples>

---

**Full Rules**: deps/<package_name>/usage-rules.md

**Integration**: For API documentation, use the hex-docs-search skill.
```

### If found in fetched cache:

```
Found cached usage rules for <package_name>:

**Version**: <version>
**Cache Location**: .usage-rules/<package>-<version>/usage-rules.md

**Relevant Best Practices** (<section_name>):

<extracted section content with code examples>

---

**Full Rules**: .usage-rules/<package>-<version>/usage-rules.md

**Note**: Rules are cached locally for offline access.

**Integration**: For API documentation, use the hex-docs-search skill.
```

### If usage rules not available:

```
Package '<package_name>' does not provide usage-rules.md.

**Note**: Usage rules are a community-driven convention where packages provide
best practices in markdown format. Not all packages have adopted this yet.

**Alternatives**:
- Use hex-docs-search skill for API documentation and guides
- Check package README or official documentation
- Search for "<package_name> elixir best practices" online
- Look for community guides and blog posts

**Current packages with usage rules**:
- ash, ash_postgres, ash_json_api (Ash Framework ecosystem)
- igniter, spark, reactor (Build tools and engines)

**Help the ecosystem**: Encourage package maintainers to add usage-rules.md!
```

### If user needs comprehensive guidance:

```
For comprehensive implementation guidance, use both:

1. **usage-rules skill** - Coding conventions and best practices
2. **hex-docs-search skill** - API documentation and function signatures

Combining both provides complete "how to implement correctly" guidance.
```

## Examples

### Example 1: Finding Ash querying best practices

**User asks**: "What are the best practices for querying data in Ash?"

**Search process**:
1. Extract package: `ash`
2. Identify context: "querying"
3. Check `deps/ash/usage-rules.md` (found)
4. Search for section: `## Querying Data`
5. Extract section with code examples
6. Present best practices

**Output**:
```
Found usage rules for ash:

**Location**: deps/ash/usage-rules.md
**Version**: 3.5.20

**Relevant Best Practices** (Querying Data):

## Querying Data

### Common Query Operations

Prefer using code interface functions with the `query` option for filtering, sorting, and limiting:

```elixir
# PREFERRED - Use the query option
posts = MyApp.Blog.list_posts!(
  query: [
    filter: [status: :published],
    sort: [published_at: :desc],
    limit: 10
  ],
  load: [author: :profile]
)

# AVOID - Don't build queries manually outside domain
query = MyApp.Blog.Post
|> Ash.Query.filter(status: :published)
|> Ash.Query.sort(published_at: :desc)
posts = Ash.read!(query)
```

All query-related options go in the `query` parameter, not as separate arguments.

---

**Full Rules**: deps/ash/usage-rules.md

**Integration**: For Ecto.Query API documentation, use hex-docs-search skill.
```

### Example 2: Error handling conventions

**User asks**: "How should I handle errors in Phoenix LiveView?"

**Search process**:
1. Extract package: `phoenix_live_view`
2. Identify context: "error handling"
3. Check `deps/phoenix_live_view/usage-rules.md` (not found - LiveView doesn't provide usage rules yet)
4. Check `.usage-rules/phoenix_live_view-*/usage-rules.md` (not found)
5. Attempt fetch (package doesn't include usage-rules.md)
6. Provide fallback suggestions

**Output**:
```
Package 'phoenix_live_view' does not provide usage-rules.md.

**Alternatives**:
- Use hex-docs-search skill for Phoenix.LiveView API documentation
- Check Phoenix LiveView guides: https://hexdocs.pm/phoenix_live_view/
- Search for "phoenix liveview error handling best practices"

**Note**: Usage rules are a community convention. Help the ecosystem by encouraging
package maintainers to add usage-rules.md files!
```

### Example 3: Unknown package with progressive fetch

**User asks**: "What are the best practices for using Spark DSL?"

**Search process**:
1. Extract package: `spark`
2. Identify context: general (no specific context)
3. Check `deps/spark/usage-rules.md` (not found)
4. Check `.usage-rules/spark-*/usage-rules.md` (not found)
5. Check mix.exs: `{:spark, "~> 2.0"}`
6. Get latest 2.x from hex.pm:
   ```bash
   curl -s "https://hex.pm/api/packages/spark" | jq -r '.releases[] | select(.version | startswith("2.")) | .version' | head -1
   # Returns: 2.2.24
   ```
7. Fetch package:
   ```bash
   mix hex.package fetch spark 2.2.24 --unpack --output .usage-rules/.tmp/spark-2.2.24
   ```
8. Extract usage-rules.md (found!)
9. Copy to cache: `.usage-rules/spark-2.2.24/usage-rules.md`
10. Clean up temp
11. Read and present usage rules

**Output**:
```
Found cached usage rules for spark:

**Version**: 2.2.24
**Cache Location**: .usage-rules/spark-2.2.24/usage-rules.md

**Relevant Best Practices** (Understanding Spark):

## Understanding Spark

Spark is a foundation for declarative DSLs in Elixir. It powers frameworks like Ash
by providing the infrastructure for building expressive, compile-time-validated DSLs.

### Key Concepts

- **Extensions**: Modules that add DSL sections to Spark DSLs
- **Sections**: Top-level DSL constructs (like `actions do ... end`)
- **Entities**: Individual items within sections (like `read :list`)
- **Options**: Configuration for entities

<...more content...>

---

**Full Rules**: .usage-rules/spark-2.2.24/usage-rules.md

**Note**: Rules are now cached locally for offline access.

**Recommendation**: Add `.usage-rules/` to your .gitignore.
```

### Example 4: Cached rules (offline access)

**User asks**: "Show me Ash relationship best practices again"

**Search process**:
1. Extract package: `ash`
2. Identify context: "relationship"
3. Check `deps/ash/usage-rules.md` (not found - not in project)
4. Check `.usage-rules/ash-*/usage-rules.md` (found version 3.5.20!)
5. **No fetch needed** - use cached rules
6. Search for "## Relationships" section
7. Extract and present

**Result**: Fast, offline search without network requests. Works even when disconnected.

### Example 5: Context-aware extraction

**User asks**: "Common mistakes with Ash actions?"

**Search process**:
1. Extract package: `ash`
2. Identify context: "actions" + "mistakes"
3. Find usage rules (local or cached)
4. Search for "## Actions" section
5. Also search for keywords: "mistake", "avoid", "wrong", "bad"
6. Extract relevant parts from multiple sections
7. Present consolidated best practices

**Output**:
```
Found usage rules for ash:

**Relevant Best Practices** (Actions - Common Mistakes):

## Actions

**AVOID** - Don't create generic CRUD actions:
```elixir
# BAD - Generic naming
create :create
update :update
```

**PREFER** - Create domain-specific actions:
```elixir
# GOOD - Specific business operations
create :register_user
update :activate_account
update :suspend_for_violation
```

**AVOID** - Don't put business logic outside actions:
```elixir
# BAD - Logic in controller
def create_post(conn, params) do
  {:ok, post} = Blog.create_post(params)
  # Business logic here
  send_notifications(post)
  update_stats()
end
```

**PREFER** - Put business logic in action changes:
```elixir
# GOOD - Logic in action
create :publish_post do
  change after_action(fn _changeset, post ->
    send_notifications(post)
    update_stats()
    {:ok, post}
  end)
end
```

---

**Full Rules**: deps/ash/usage-rules.md

## Tool usage summary

Use Claude's built-in tools in this order:

1. **Glob** - Find usage-rules.md files in deps/, .usage-rules/, and check for sub-rules
2. **Grep** - Search for section headings, context keywords, and code examples
3. **Read** - Read complete usage rules files when broader context needed
4. **Bash** - Fetch packages with mix hex.package, version resolution, extract and cache rules
5. **AskUserQuestion** - Prompt for version when ambiguous

**Requirements:** curl and jq (Linux/Mac native, use Git Bash or WSL on Windows)

## Best practices

1. **Start local**: Always check local dependencies first - they match the version used in the project
2. **Check cache before fetch**: Look for previously fetched rules in `.usage-rules/` before fetching
3. **Context-aware extraction**: Don't present entire file - extract relevant sections based on keywords
4. **Show code examples**: Always include good/bad pattern examples when available
5. **Highlight patterns**: Point out `# GOOD` vs `# BAD` comparisons explicitly
6. **Link to source**: Provide file path so users can explore complete rules
7. **Note integration**: Mention hex-docs-search for complementary API documentation
8. **Git ignore reminder**: Mention .gitignore addition once per session when fetching occurs
9. **Offline capability**: Once fetched, usage rules available without network access
10. **Version awareness**: Note which version is installed locally vs fetched from cache

## Troubleshooting

### Package not found in deps/

- Check `.usage-rules/` for previously fetched rules
- If not cached, determine version and offer to fetch
- Check if package is in mix.exs dependencies (for version resolution)
- Verify package name spelling (convert `Phoenix.LiveView` → `phoenix_live_view`)

### Package doesn't provide usage-rules.md

- This is expected - usage rules are a convention, not all packages have them
- Fallback to hex-docs-search for API documentation
- Suggest checking package README or guides
- Encourage package maintainers to add usage rules

### Fetch failures

**Package fetch fails**:
- Verify package name spelling
- Check network connectivity
- Verify package exists on hex.pm
- Try web search as fallback

**Extraction fails**:
- Package was fetched but doesn't include usage-rules.md
- Clean up temp directory
- Note that package doesn't provide rules

### Cache location issues

**Fetched rules not found on repeat queries**:
- Verify `.usage-rules/` directory exists
- Check that fetch command completed successfully
- May need to re-fetch if directories were deleted
- Ensure temp cleanup didn't remove permanent cache

### Section extraction challenges

**Section too large**:
- Increase `-A` value in Grep to get more content
- Or read complete file and extract programmatically
- Consider showing summary + offering full section

**Multiple relevant sections**:
- Extract multiple sections
- Present them in logical order
- Clearly label each section

**No section matches context**:
- Show "## Understanding [Package]" section as default
- List available sections for user to choose from
- Read complete file if user wants comprehensive overview

### Version mismatches

**Different version in deps/ vs cache**:
- Prefer deps/ version (matches project)
- Note version difference if using cache
- Offer to fetch version matching project dependencies

**Version specified doesn't exist**:
- List available versions from hex.pm
- Prompt user to select valid version
- Fall back to latest if user unsure

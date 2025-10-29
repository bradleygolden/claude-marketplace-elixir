# Git Plugin

Intelligent git commit workflow automation for Claude Code marketplace.

## Features

- **AI-powered file grouping** - Automatically groups changed files by context (feature, fix, refactor, docs, tests, config)
- **Configurable commit message formats** - Choose between Conventional Commits, Imperative Mood, or custom templates
- **Structured commit workflow** - Review → Plan → Approve → Execute → Display
- **User-only attribution** - Clean commits without Claude Code attribution
- **First-run configuration wizard** - One-time setup that persists across sessions
- **Conversation-aware grouping** - Uses discussion context to improve file grouping accuracy

## Installation

### From Marketplace (after publication)

```bash
/plugin marketplace add github:bradleygolden/claude-marketplace-elixir
/plugin install git@elixir
```

### From Local Directory (development)

```bash
/plugin marketplace add /path/to/claude-marketplace-elixir
/plugin install git@elixir
```

## Usage

### Basic Commit Workflow

```bash
/commit
```

Or with full namespace:

```bash
/git:commit
```

### First Run

On first use, you'll be prompted to configure your commit message format preference:

1. **Conventional Commits**: `type(scope): description`
2. **Imperative Mood**: `description`
3. **Custom Template**: Your own format

Your preference is saved to `CLAUDE.md` or `AGENTS.md` and persists across sessions.

### Workflow Steps

The command executes a 5-phase workflow:

1. **Configuration**: Check/prompt for preferences (first run only)
2. **Review**: Analyze `git status` and `git diff` plus conversation context
3. **Group**: AI intelligently groups files by context
4. **Plan**: Generate commit messages based on your format preference
5. **Approve**: Review and explicitly approve the commit plan
6. **Execute**: Create commits sequentially with user-only attribution
7. **Display**: Show results with `git log` output

### Changing Configuration

To reconfigure your preferences:

1. Edit `CLAUDE.md` or `AGENTS.md`
2. Find the `## Git Commit Configuration` section
3. Modify the **Format** field
4. Save the file

Changes take effect on next `/commit` invocation.

## Commit Message Formats

### Conventional Commits

Format: `<type>(<scope>): <description>`

**Types**:
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting, whitespace)
- `refactor`: Code refactoring
- `test`: Test additions/modifications
- `chore`: Build process, tooling, dependencies

**Examples**:
```
feat(auth): add JWT authentication
fix(api): resolve null pointer in user endpoint
docs: update installation instructions
refactor(database): optimize query performance
test(auth): add session expiry tests
chore(deps): update Elixir to 1.15
```

### Imperative Mood

Format: `<description>`

Start with imperative verb (Add, Update, Fix, Remove, Refactor, etc.)

**Examples**:
```
Add JWT authentication
Fix null pointer in user endpoint
Update installation instructions
Optimize database query performance
Add session expiry tests
Update Elixir to 1.15
```

### Custom Template

Define your own format. The command will follow your template structure and you can specify the format in the configuration section.

## File Grouping Logic

The plugin analyzes your changes and groups files intelligently based on multiple signals:

| Group | Criteria | Example Files | Signals |
|-------|----------|---------------|---------|
| **Feature** | New functionality | `lib/auth.ex`, `lib/auth/session.ex` | New files, new functions, "feat" in conversation |
| **Fix** | Bug corrections | Files mentioned in bug discussions | "fix", "bug", "error" keywords |
| **Refactor** | Code improvements | Renamed/moved files, structure changes | "refactor", "optimize", "clean up" |
| **Documentation** | Docs and comments | `README.md`, `*.md` files | `.md` extension, `docs/` directory |
| **Tests** | Test changes | `test/**/*_test.exs` | `test/` directory, `_test` suffix |
| **Configuration** | Settings and deps | `mix.exs`, `.formatter.exs` | Config file extensions, `config/` directory |

**Grouping considers**:
- File paths and extensions (obvious categorization)
- Diff content analysis (what changed in the files)
- Conversation context (what you discussed before running `/commit`)
- Logical relationships (tests grouped with implementations)

**Example Grouping**:
```
Changed files:
- lib/auth.ex (new)
- lib/auth/session.ex (new)
- test/auth_test.exs (new)
- README.md (modified)
- mix.exs (modified)

Grouped into 3 commits:
1. Feature: lib/auth.ex, lib/auth/session.ex, test/auth_test.exs
2. Documentation: README.md
3. Configuration: mix.exs
```

## Configuration Storage

Preferences are stored in project-level configuration files:

**Priority order**:
1. `CLAUDE.md` (checked first)
2. `AGENTS.md` (fallback)
3. `CLAUDE.md` (created if neither exists)

**Configuration format**:

```markdown
## Git Commit Configuration

**Configured**: 2025-10-28

### Commit Message Format

**Format**: conventional-commits

#### Conventional Commits Template
```
<type>(<scope>): <description>

<optional body>
```

**Types**: feat, fix, docs, style, refactor, test, chore

### Configuration Notes

- This configuration is used by the `/commit` command to format commit messages
- You can manually edit this section to change preferences
- Changes take effect immediately on next `/commit` invocation
```

## Examples

### Example 1: Feature Development with Tests

```
User: /commit

System analyzes changes:
- lib/auth.ex (new file)
- lib/auth/session.ex (new file)
- test/auth_test.exs (new file)
- README.md (modified documentation)

System groups into 2 commits:
1. feat(auth): add user authentication system
   - lib/auth.ex
   - lib/auth/session.ex
   - test/auth_test.exs

2. docs: update README with authentication guide
   - README.md

User approves → Commits created

Result:
abc1234 feat(auth): add user authentication system
def5678 docs: update README with authentication guide
```

### Example 2: Bug Fix Session

```
User: /commit

System analyzes changes:
- lib/api/users.ex (modified)
- test/api/users_test.exs (modified)

Conversation context: "fixing null pointer bug in user endpoint"

System groups into 1 commit:
1. fix(api): resolve null pointer in user endpoint
   - lib/api/users.ex
   - test/api/users_test.exs

User approves → Commit created

Result:
ghi9012 fix(api): resolve null pointer in user endpoint
```

### Example 3: Refactoring with Documentation

```
User: /commit

System analyzes changes:
- lib/database/query.ex (modified - optimization)
- lib/database/connection.ex (modified - pooling)
- test/database_test.exs (modified - updated tests)
- CHANGELOG.md (modified)

System groups into 2 commits:
1. refactor(database): optimize query performance and connection pooling
   - lib/database/query.ex
   - lib/database/connection.ex
   - test/database_test.exs

2. docs: update CHANGELOG with database optimizations
   - CHANGELOG.md

User approves → Commits created
```

## Troubleshooting

### Configuration Not Prompting

If you've already configured but want to reconfigure:
1. Open `CLAUDE.md` or `AGENTS.md`
2. Find and delete the `## Git Commit Configuration` section
3. Run `/commit` again to trigger first-run prompt

### Files Not Grouping as Expected

The AI groups files based on conversation context, file paths, and diff analysis. To improve grouping:

- **Discuss your changes** before running `/commit` (mention "adding feature X", "fixing bug Y", etc.)
- **Use descriptive branch names** (feature/auth, bugfix/null-pointer)
- **Review the plan** before approving - you can always abort and regroup manually

### Commit Failed

If a commit fails during execution:

1. **Review the error message** displayed by the system
2. **Choose an option**:
   - **Retry**: Try the same commit again (useful if it was a temporary issue)
   - **Skip**: Skip this commit and continue with remaining commits
   - **Abort**: Cancel all remaining commits
3. **Fix the underlying issue** (merge conflicts, file permissions, etc.)
4. **Run `/commit` again** if needed

### No Changes to Commit

If you see "No changes to commit. Working directory is clean":
- Check `git status` manually to verify
- Ensure you've saved all file changes
- Check if changes were already committed

### Configuration File Not Found

If the system can't find or create configuration files:
- Ensure you're in a directory where you have write permissions
- The system will create `CLAUDE.md` if neither it nor `AGENTS.md` exists
- You can create these files manually and add the configuration section

## Attribution

This plugin creates **user-only commits** with no Claude Code attribution. Your git history will show:
- ✅ Your name as author
- ✅ Your email as committer
- ✅ Clean commit messages
- ❌ NO "Generated with Claude Code" messages
- ❌ NO "Co-Authored-By: Claude" lines

This follows the HumanLayer pattern for authentic user attribution.

## Contributing

Found a bug or have a suggestion? Open an issue at:
https://github.com/bradleygolden/claude-marketplace-elixir/issues

## License

MIT License - see repository for details.

## Version

Current version: 1.0.0

## Keywords

git, commit, workflow, version-control, automation, ai-powered, intelligent-grouping

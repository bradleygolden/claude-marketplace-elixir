---
allowed-tools: Bash(git status:*), Bash(git diff:*), Bash(git add:*), Bash(git commit:*), Read(*), Write(*), Edit(*), AskUserQuestion
description: Create structured git commits with intelligent file grouping
---

# Commit Changes

You are tasked with committing changes using a structured process that respects user preferences and maintains clean commit history.

## Process Overview

1. **Check user's commit style preference** (first time only)
2. **Review** the conversation and run `git status` and `git diff` to understand what has changed
3. **Plan** the commits by grouping related files and drafting appropriate commit messages
4. **Present** the plan to the user for approval ("Shall I proceed?")
5. **Execute** by adding files and creating commits, then show results

## Check for User's Commit Message Preference

Before creating commits, check if the user has configured their preferred commit message format:

1. **Check for configuration** in this order:
   - Read `CLAUDE.md` if it exists
   - Otherwise, read `AGENTS.md` if it exists
   - If neither exists, create `CLAUDE.md`

2. **Look for existing configuration** by searching for a `## Git Commit Configuration` section

3. **If no configuration exists**, prompt the user:

Use AskUserQuestion to ask:

```javascript
{
  "questions": [
    {
      "question": "What commit message format would you like to use?",
      "header": "Format",
      "multiSelect": false,
      "options": [
        {
          "label": "Conventional Commits",
          "description": "Structured format like 'feat(auth): add login' with types: feat, fix, docs, refactor, test, chore"
        },
        {
          "label": "Imperative Mood",
          "description": "Simple imperative statements like 'Add user authentication' - direct and concise"
        },
        {
          "label": "Custom Template",
          "description": "Use your own format - you can describe it after selection"
        }
      ]
    }
  ]
}
```

4. **Store the preference** by appending this section to the configuration file:

```markdown
## Git Commit Configuration

**Configured**: [today's date]

### Commit Message Format

**Format**: [conventional-commits|imperative-mood|custom]

#### Conventional Commits Template
```
<type>(<scope>): <description>
```
**Types**: feat, fix, docs, style, refactor, test, chore

#### Imperative Mood Template
```
<description>
```
Start with imperative verb: Add, Update, Fix, Remove, etc.

#### Custom Template
```
[user's template if they chose custom]
```
```

5. **Parse the preference** and use it when generating commit messages

## Planning Commits

Group related changes together logically:
- Features with their tests
- Bug fixes with their tests
- Documentation separately
- Configuration/tooling separately
- Refactoring separately

Draft commit messages using the user's preferred format:
- **Conventional Commits**: `type(scope): description` (e.g., `feat(auth): add login`)
- **Imperative Mood**: Start with verb (e.g., `Add user authentication`)
- **Custom**: Follow their template

Use imperative mood for descriptions. Explain the "why" not just the "what".

## Present the Plan

Ask: "I plan to create [N] commits:

1. **[Brief description]** ([X] files)
   - file1.ex
   - file2.ex

   Message: `[commit message]`

2. **[Next description]** ([Y] files)
   - file3.md

   Message: `[commit message]`

Shall I proceed?"

Wait for explicit approval before executing.

## Execute Commits

For each commit in the plan:

1. Stage files with explicit paths: `git add file1 file2 file3`
2. Create commit: `git commit -m "[message]"`
3. If a commit fails, inform the user and ask how to proceed

After all commits, run `git log --oneline -n [count]` to show what was created.

## Important

**CRITICAL**: Create user-only commits with NO Claude Code attribution:
- Do NOT add "Generated with Claude Code" messages
- Do NOT add "Co-Authored-By: Claude" lines
- Commits must appear solely authored by the user

Use explicit file names with `git add` - never use `git add -A` or `git add .`

The user trusts your judgment to group changes appropriately and write clear commit messages based on their preferred format.

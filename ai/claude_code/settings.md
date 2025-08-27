<!-- CACHE-METADATA
source_url: https://docs.anthropic.com/en/docs/claude-code/settings.md
cached_at: 2025-08-27T04:19:01.179768Z
-->

<!-- Content fetched and converted by MarkItDown -->
# Claude Code settings

> Configure Claude Code with global and project-level settings, and environment variables.

Claude Code offers a variety of settings to configure its behavior to meet your needs. You can configure Claude Code by running the `/config` command when using the interactive REPL.

## Settings files

The `settings.json` file is our official mechanism for configuring Claude
Code through hierarchical settings:

* **User settings** are defined in `~/.claude/settings.json` and apply to all
  projects.
* **Project settings** are saved in your project directory:
  * `.claude/settings.json` for settings that are checked into source control and shared with your team
  * `.claude/settings.local.json` for settings that are not checked in, useful for personal preferences and experimentation. Claude Code will configure git to ignore `.claude/settings.local.json` when it is created.
* For enterprise deployments of Claude Code, we also support **enterprise
  managed policy settings**. These take precedence over user and project
  settings. System administrators can deploy policies to:
  * macOS: `/Library/Application Support/ClaudeCode/managed-settings.json`
  * Linux and WSL: `/etc/claude-code/managed-settings.json`
  * Windows: `C:\ProgramData\ClaudeCode\managed-settings.json`

```JSON Example settings.json
{
  "permissions": {
    "allow": [
      "Bash(npm run lint)",
      "Bash(npm run test:*)",
      "Read(~/.zshrc)"
    ],
    "deny": [
      "Bash(curl:*)",
      "Read(./.env)",
      "Read(./.env.*)",
      "Read(./secrets/**)"
    ]
  },
  "env": {
    "CLAUDE_CODE_ENABLE_TELEMETRY": "1",
    "OTEL_METRICS_EXPORTER": "otlp"
  }
}
```

### Available settings

`settings.json` supports a number of options:

| Key                          | Description                                                                                                                                                           | Example                                                     |
| :--------------------------- | :-------------------------------------------------------------------------------------------------------------------------------------------------------------------- | :---------------------------------------------------------- |
| `apiKeyHelper`               | Custom script, to be executed in `/bin/sh`, to generate an auth value. This value will be sent as `X-Api-Key` and `Authorization: Bearer` headers for model requests  | `/bin/generate_temp_api_key.sh`                             |
| `cleanupPeriodDays`          | How long to locally retain chat transcripts based on last activity date (default: 30 days)                                                                            | `20`                                                        |
| `env`                        | Environment variables that will be applied to every session                                                                                                           | `{"FOO": "bar"}`                                            |
| `includeCoAuthoredBy`        | Whether to include the `co-authored-by Claude` byline in git commits and pull requests (default: `true`)                                                              | `false`                                                     |
| `permissions`                | See table below for structure of permissions.                                                                                                                         |                                                             |
| `hooks`                      | Configure custom commands to run before or after tool executions. See [hooks documentation](hooks)                                                                    | `{"PreToolUse": {"Bash": "echo 'Running command...'"}}`     |
| `model`                      | Override the default model to use for Claude Code                                                                                                                     | `"claude-3-5-sonnet-20241022"`                              |
| `statusLine`                 | Configure a custom status line to display context. See [statusLine documentation](statusline)                                                                         | `{"type": "command", "command": "~/.claude/statusline.sh"}` |
| `forceLoginMethod`           | Use `claudeai` to restrict login to Claude.ai accounts, `console` to restrict login to Anthropic Console (API usage billing) accounts                                 | `claudeai`                                                  |
| `forceLoginOrgUUID`          | Specify the UUID of an organization to automatically select it during login, bypassing the organization selection step. Requires `forceLoginMethod` to be set         | `"xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"`                    |
| `enableAllProjectMcpServers` | Automatically approve all MCP servers defined in project `.mcp.json` files                                                                                            | `true`                                                      |
| `enabledMcpjsonServers`      | List of specific MCP servers from `.mcp.json` files to approve                                                                                                        | `["memory", "github"]`                                      |
| `disabledMcpjsonServers`     | List of specific MCP servers from `.mcp.json` files to reject                                                                                                         | `["filesystem"]`                                            |
| `awsAuthRefresh`             | Custom script that modifies the `.aws` directory (see [advanced credential configuration](/en/docs/claude-code/amazon-bedrock#advanced-credential-configuration))     | `aws sso login --profile myprofile`                         |
| `awsCredentialExport`        | Custom script that outputs JSON with AWS credentials (see [advanced credential configuration](/en/docs/claude-code/amazon-bedrock#advanced-credential-configuration)) | `/bin/generate_aws_grant.sh`                                |

### Permission settings

| Keys                           | Description                                                                                                                                                       | Example                                                                |
| :----------------------------- | :---------------------------------------------------------------------------------------------------------------------------------------------------------------- | :--------------------------------------------------------------------- |
| `allow`                        | Array of [permission rules](/en/docs/claude-code/iam#configuring-permissions) to allow tool use                                                                   | `[ "Bash(git diff:*)" ]`                                               |
| `ask`                          | Array of [permission rules](/en/docs/claude-code/iam#configuring-permissions) to ask for confirmation upon tool use.                                              | `[ "Bash(git push:*)" ]`                                               |
| `deny`                         | Array of [permission rules](/en/docs/claude-code/iam#configuring-permissions) to deny tool use. Use this to also exclude sensitive files from Claude Code access. | `[ "WebFetch", "Bash(curl:*)", "Read(./.env)", "Read(./secrets/**)" ]` |
| `additionalDirectories`        | Additional [working directories](iam#working-directories) that Claude has access to                                                                               | `[ "../docs/" ]`                                                       |
| `defaultMode`                  | Default [permission mode](iam#permission-modes) when opening Claude Code                                                                                          | `"acceptEdits"`                                                        |
| `disableBypassPermissionsMode` | Set to `"disable"` to prevent `bypassPermissions` mode from being activated. See [managed policy settings](iam#enterprise-managed-policy-settings)                | `"disable"`                                                            |

### Settings precedence

Settings are applied in order of precedence (highest to lowest):

1. **Enterprise managed policies** (`managed-settings.json`)
   * Deployed by IT/DevOps
   * Cannot be overridden

2. **Command line arguments**
   * Temporary overrides for a specific session

3. **Local project settings** (`.claude/settings.local.json`)
   * Personal project-specific settings

4. **Shared project settings** (`.claude/settings.json`)
   * Team-shared project settings in source control

5. **User settings** (`~/.claude/settings.json`)
   * Personal global settings

This hierarchy ensures that enterprise security policies are always enforced while still allowing teams and individuals to customize their experience.

### Key points about the configuration system

* **Memory files (CLAUDE.md)**: Contain instructions and context that Claude loads at startup
* **Settings files (JSON)**: Configure permissions, environment variables, and tool behavior
* **Slash commands**: Custom commands that can be invoked during a session with `/command-name`
* **MCP servers**: Extend Claude Code with additional tools and integrations
* **Precedence**: Higher-level configurations (Enterprise) override lower-level ones (User/Project)
* **Inheritance**: Settings are merged, with more specific settings adding to or overriding broader ones

### System prompt availability

<Note>
  Unlike for claude.ai, we do not publish Claude Code's internal system prompt on this website. Use CLAUDE.md files or `--append-system-prompt` to add custom instructions to Claude Code's behavior

[Content truncated due to length]

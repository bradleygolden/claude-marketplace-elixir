<!-- CACHE-METADATA
source_url: https://docs.anthropic.com/en/docs/claude-code/settings.md
cached_at: 2025-10-06T09:26:30.883328Z
-->

<!-- Content fetched and converted by MarkItDown -->
# Claude Code settings

> Configure Claude Code with global and project-level settings, and environment variables.

Claude Code offers a variety of settings to configure its behavior to meet your needs. You can configure Claude Code by running the `/config` command when using the interactive REPL, which opens a tabbed Settings interface where you can view status information and modify configuration options.

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
* Enterprise deployments can also configure **managed MCP servers** that override
  user-configured servers. See [Enterprise MCP configuration](/en/docs/claude-code/mcp#enterprise-mcp-configuration):
  * macOS: `/Library/Application Support/ClaudeCode/managed-mcp.json`
  * Linux and WSL: `/etc/claude-code/managed-mcp.json`
  * Windows: `C:\ProgramData\ClaudeCode\managed-mcp.json`

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

| Key                          | Description                                                                                                                                                                                   | Example                                                     |
| :--------------------------- | :-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | :---------------------------------------------------------- |
| `apiKeyHelper`               | Custom script, to be executed in `/bin/sh`, to generate an auth value. This value will be sent as `X-Api-Key` and `Authorization: Bearer` headers for model requests                          | `/bin/generate_temp_api_key.sh`                             |
| `cleanupPeriodDays`          | How long to locally retain chat transcripts based on last activity date (default: 30 days)                                                                                                    | `20`                                                        |
| `env`                        | Environment variables that will be applied to every session                                                                                                                                   | `{"FOO": "bar"}`                                            |
| `includeCoAuthoredBy`        | Whether to include the `co-authored-by Claude` byline in git commits and pull requests (default: `true`)                                                                                      | `false`                                                     |
| `permissions`                | See table below for structure of permissions.                                                                                                                                                 |                                                             |
| `hooks`                      | Configure custom commands to run before or after tool executions. See [hooks documentation](hooks)                                                                                            | `{"PreToolUse": {"Bash": "echo 'Running command...'"}}`     |
| `disableAllHooks`            | Disable all [hooks](hooks)                                                                                                                                                                    | `true`                                                      |
| `model`                      | Override the default model to use for Claude Code                                                                                                                                             | `"claude-sonnet-4-5-20250929"`                              |
| `statusLine`                 | Configure a custom status line to display context. See [statusLine documentation](statusline)                                                                                                 | `{"type": "command", "command": "~/.claude/statusline.sh"}` |
| `outputStyle`                | Configure an output style to adjust the system prompt. See [output styles documentation](output-styles)                                                                                       | `"Explanatory"`                                             |
| `forceLoginMethod`           | Use `claudeai` to restrict login to Claude.ai accounts, `console` to restrict login to Claude Console (API usage billing) accounts                                                            | `claudeai`                                                  |
| `forceLoginOrgUUID`          | Specify the UUID of an organization to automatically select it during login, bypassing the organization selection step. Requires `forceLoginMethod` to be set                                 | `"xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"`                    |
| `enableAllProjectMcpServers` | Automatically approve all MCP servers defined in project `.mcp.json` files                                                                                                                    | `true`                                                      |
| `enabledMcpjsonServers`      | List of specific MCP servers from `.mcp.json` files to approve                                                                                                                                | `["memory", "github"]`                                      |
| `disabledMcpjsonServers`     | List of specific MCP servers from `.mcp.json` files to reject                                                                                                                                 | `["filesystem"]`                                            |
| `useEnterpriseMcpConfigOnly` | When set in managed-settings.json, restricts MCP servers to only those defined in managed-mcp.json. See [Enterprise MCP configuration](/en/docs/claude-code/mcp#enterprise-mcp-configuration) | `true`                                                      |
| `awsAuthRefresh`             | Custom script that modifies the `.aws` directory (see [advanced credential configuration](/en/docs/claude-code/amazon-bedrock#advanced-credential-configuration))                             | `aws sso login --profile myprofile`                         |
| `awsCredentialExport`        | Custom script that outputs JSON with AWS credentials (see [advanced credential configuration](/en/docs/claude-code/amazon-bedrock#advanced-credential-configuration))                         | `/bin/generate_aws_grant.sh`                                |

### Permission settings

| Keys                           | Description                                                                                                                                                                                                                                                                                                                   | Example                                                                |
| :----------------------------- | :---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | :--------------------------------------------------------------------- |
| `allow`                        | Array of [permission rules](/en/docs/claude-code/iam#configuring-permissions) to allow tool use. **Note:** Bash rules use prefix matching, not regex                                                                                                                                                                          | `[ "Bash(git diff:*)" ]`                                               |
| `ask`                          | Array of [permission rules](/en/docs/claude-code/iam#configuring-permissions) to ask for confirmation upon tool use.                                                                                                                                                                                                          | `[ "Bash(git push:*)" ]`                                               |
| `deny`                         | Array of [permission rules](/en/docs/claude-code/iam#configuring-permissions) to deny tool use. Use this to also exclude sensitive files from Claude Code access. **Note:** Bash patterns are prefix matches and can be bypassed (see [Bash permissi

[Content truncated due to length]

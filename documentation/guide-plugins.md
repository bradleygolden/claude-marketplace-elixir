# Plugin System Guide

The Claude plugin system provides an extensible, composable architecture for configuring `.claude.exs` files. Plugins automatically adapt to your project setup, provide smart defaults, and can be combined seamlessly.

## Quick Start

### Basic Configuration

Add plugins to your `.claude.exs`:

```elixir
%{
  plugins: [
    Claude.Plugins.Base,        # Standard hooks
    Claude.Plugins.ClaudeCode,  # Documentation
    Claude.Plugins.Phoenix      # Auto-configured for Phoenix projects
  ]
}
```

Run `mix claude.install` to apply the configuration.

### Automatic Phoenix Detection

For Phoenix projects, the Phoenix plugin automatically activates:

```elixir
# This configuration:
%{
  plugins: [Claude.Plugins.Phoenix]
}

# Automatically becomes:
%{
  mcp_servers: [tidewave: [port: "${PORT:-4000}"]],
  nested_memories: %{
    "test" => ["usage_rules:elixir", "usage_rules:otp"],
    "lib/my_app" => ["usage_rules:elixir", "usage_rules:otp", "phoenix:ecto"],
    "lib/my_app_web" => [
      {:url, "https://daisyui.com/llms.txt", as: "DaisyUI Component Library", cache: "./ai/daisyui/llms.md"},
      "usage_rules:elixir", "usage_rules:otp", "phoenix:phoenix", "phoenix:html", "phoenix:elixir", "phoenix:liveview"
    ]
  }
}
```

## Built-in Plugins

### Claude.Plugins.Base

Provides standard hook configuration with atom shortcuts:

```elixir
%{
  hooks: %{
    stop: [:compile, :format],
    subagent_stop: [:compile, :format], 
    post_tool_use: [:compile, :format],
    pre_tool_use: [:compile, :format, :unused_deps]
  }
}
```

**Atom Shortcuts:**
- `:compile` - Runs `mix compile --warnings-as-errors` 
- `:format` - Runs `mix format --check-formatted`
- `:unused_deps` - Checks for unused dependencies

### Claude.Plugins.ClaudeCode

Provides comprehensive Claude Code documentation and the Meta Agent:

```elixir
%{
  nested_memories: %{
    "." => [
      {:url, "https://docs.anthropic.com/en/docs/claude-code/hooks.md", 
       as: "Claude Code Hooks Reference", cache: "./ai/claude_code/hooks_reference.md"},
      # ... more Claude Code documentation
    ],
    "test" => ["usage_rules:elixir", "usage_rules:otp"]
  },
  subagents: [
    %{
      name: "Meta Agent",
      description: "Generates new, complete Claude Code subagent from user descriptions. Use PROACTIVELY when users ask to create new subagents.",
      # ... full Meta Agent configuration
    }
  ]
}
```

### Claude.Plugins.Phoenix

Auto-detects Phoenix projects and provides:

- **MCP Servers**: Configures Tidewave for Phoenix development
- **Smart Dependencies**: Automatically includes Ecto and LiveView rules when detected
- **Directory-Specific Memories**: Different usage rules for `lib/app/`, `lib/app_web/`, and `test/`
- **DaisyUI Integration**: Component library documentation for UI development

**Options:**
```elixir
{Claude.Plugins.Phoenix, 
 include_daisyui?: false,    # Disable DaisyUI docs
 port: 4001,                 # Custom Tidewave port
 tidewave_enabled?: false}   # Disable Tidewave entirely
```

### Claude.Plugins.Webhook

Configures webhook event reporting:

```elixir
%{
  reporters: [
    {:webhook, url: "https://example.com/claude-events"}
  ]
}
```

### Claude.Plugins.Logging

Configures structured event logging to files:

```elixir
%{
  reporters: [
    {:jsonl, file: "claude-events.jsonl"}
  ],
  hooks: %{
    # Registers ALL hook events for complete observability
    pre_tool_use: ["claude_hooks_reporter"],
    post_tool_use: ["claude_hooks_reporter"],
    stop: ["claude_hooks_reporter"],
    subagent_stop: ["claude_hooks_reporter"],
    session_start: ["claude_hooks_reporter"],
    session_end: ["claude_hooks_reporter"]    # New in 0.6.0
  }
}
```

**Features:**
- **All Events Captured**: Automatically logs every hook event type including `session_end`
- **Structured Output**: JSONL format for easy processing
- **Configurable Location**: Specify custom log file paths

## Configuration Merging

Plugins compose together intelligently:

```elixir
%{
  plugins: [
    Claude.Plugins.Base,        # Provides hooks
    Claude.Plugins.Phoenix,     # Adds MCP servers + nested memories  
    Claude.Plugins.Webhook      # Adds reporters
  ],
  
  # Direct configuration (lower priority)
  hooks: %{
    session_end: ["mix myapp.cleanup"]     # New in 0.6.0 - runs when Claude sessions end
  }
}

# Results in merged configuration with plugin settings taking precedence
```

### Merge Rules

- **Maps**: Deep merged (plugins override direct config)
- **Lists**: Combined and deduplicated for simple values
- **Conflicts**: Plugin configurations take precedence

## Creating Custom Plugins

### Basic Plugin Structure

```elixir
defmodule MyApp.CustomPlugin do
  @moduledoc "Custom plugin for MyApp-specific configuration"
  
  @behaviour Claude.Plugin
  
  def config(opts) do
    %{
      hooks: %{
        stop: ["mix myapp.cleanup"]
      },
      mcp_servers: [myapp_server: []],
      nested_memories: %{
        "lib/myapp" => ["myapp:usage_rules"]
      }
    }
  end
end
```

### Advanced Plugin with Options

```elixir
defmodule MyApp.ConditionalPlugin do
  @behaviour Claude.Plugin
  
  def config(opts) do
    if detect_condition?(opts) do
      %{
        hooks: %{
          post_tool_use: [:compile, :format, "mix myapp.validate"]
        },
        reporters: build_reporters(opts)
      }
    else
      %{}  # No configuration when condition not met
    end
  end
  
  defp detect_condition?(opts) do
    # Check for specific dependencies, files, etc.
    igniter = Keyword.get(opts, :igniter)
    Igniter.Project.Deps.has_dep?(igniter, :myapp_core)
  end
  
  defp build_reporters(opts) do
    webhook_url = Keyword.get(opts, :webhook_url)
    if webhook_url do
      [{:webhook, url: webhook_url}]
    else
      []
    end
  end
end
```

### Plugin with URL Documentation

```elixir
defmodule MyApp.DocumentationPlugin do
  @behaviour Claude.Plugin
  
  def config(_opts) do
    %{
      nested_memories: %{
        "lib/myapp" => [
          {:url, "https://docs.myapp.com/llm-guide.md", 
           as: "MyApp Development Guide", 
           cache: "./ai/myapp/guide.md"}
        ]
      }
    }
  end
end
```

## URL Documentation References

Plugins can include URL-based documentation that automatically caches locally:

### Basic URL Reference

```elixir
{:url, "https://example.com/docs.md", as: "Example Docs", cache: "./ai/example/docs.md"}
```

### URL Reference Options

- `as` - Human-readable name for the documentation
- `cache` - Local file path for cached content
- `headers` - HTTP headers for the request (optional)

### Caching Behavior

- Documentation is fetched once and cached locally
- Cached files are used for offline development  
- Cache files should be committed to version control
- Re-fetch by deleting cache files and running `mix claude.install`

## Event Reporting with Plugins

### Webhook Reporting

```elixir
defmodule MyApp.WebhookPlugin do
  @behaviour Claude.Plugin
  
  def config(_opts) do
    %{
      reporters: [
        {:webhook, 
         url: "https://api.myapp.com/claude-events",
         headers: %{"Authorization" => "Bearer #{System.get_env("MYAPP_TOKEN")}"}}
      ]
    }
  end
end
```

### Custom Reporter

```elixir
defmodule MyApp.CustomReporter do
  @behaviour Claude.Hooks.Reporter
  
  @impl true
  def report(event_data, opts) do
    # Process the event data - all hook events including SessionEnd
    case event_data["hook_event_name"] do
      "SessionEnd" -> 
        handle_session_end(event_data, opts)
      "PreToolUse" ->
        handle_tool_event(event_data, opts)
      _ ->
        handle_generic_event(event_data, opts)
    end
  end
  
  defp handle_session_end(event_data, opts) do
    # SessionEnd events include reason: "clear", "logout", "prompt_input_exit", "other"
    reason = event_data["reason"]
    session_id = event_data["session_id"]
    
    send_to_custom_service(%{type: "session_end", reason: reason, session: session_id}, opts)
  end
  
  defp send_to_custom_service(event_data, opts) do
    # Your custom implementation
    {:ok, "processed"}
  end
end

# Plugin configuration:
%{
  reporters: [
    {MyApp.CustomReporter, api_key: "secret"}
  ]
}
```

## Plugin Development Best Practices

### 1. Conditional Activation

Only activate plugins when appropriate:

```elixir
def config(opts) do
  if should_activate?(opts) do
    generate_config(opts)
  else
    %{}
  end
end
```

### 2. Respect User Options

Make plugins configurable:

```elixir
def config(opts) do
  enabled? = Keyword.get(opts, :enabled, true)
  port = Keyword.get(opts, :port, 4000)
  
  if enabled? do
    %{mcp_servers: [myserver: [port: port]]}
  else
    %{}
  end
end
```

### 3. Use Smart Defaults

Provide sensible defaults that work out of the box:

```elixir
def config(opts) do
  %{
    hooks: %{
      post_tool_use: [:compile, :format] ++ custom_hooks(opts)
    }
  }
end
```

### 4. Document Dependencies

Clearly document what your plugin requires:

```elixir
@moduledoc """
MyApp plugin for Claude Code integration.

## Requirements
- Phoenix framework
- MyApp.Core dependency
- Environment variable MYAPP_API_KEY

## Usage
    %{plugins: [MyApp.Plugin]}
"""
```

## SessionEnd Hook Event (New in 0.6.0)

The `SessionEnd` hook event runs when Claude Code sessions end and is useful for cleanup tasks, logging session statistics, or saving session state.

### SessionEnd Event Data

```elixir
%{
  "hook_event_name" => "SessionEnd",
  "session_id" => "abc123",
  "transcript_path" => "~/.claude/projects/.../transcript.jsonl",
  "cwd" => "/path/to/project",
  "reason" => "clear"  # One of: "clear", "logout", "prompt_input_exit", "other"
}
```

### SessionEnd Hook Configuration

```elixir
%{
  hooks: %{
    session_end: [
      "mix myapp.cleanup",           # Run cleanup tasks
      "mix myapp.save_metrics",      # Save session metrics 
      {:cmd, "rm -rf tmp/claude-*", when: "Bash"}  # Shell commands
    ]
  }
}
```

### Using SessionEnd with Reporters

```elixir
defmodule MyApp.SessionTracker do
  @behaviour Claude.Hooks.Reporter
  
  @impl true
  def report(%{"hook_event_name" => "SessionEnd"} = event_data, opts) do
    session_id = event_data["session_id"]
    reason = event_data["reason"]
    
    # Log session end
    File.write!("sessions.log", "#{session_id} ended: #{reason}\n", [:append])
    
    # Clean up session-specific resources
    cleanup_session_files(session_id)
    
    :ok
  end
  
  def report(_other_event, _opts), do: :ok
  
  defp cleanup_session_files(session_id) do
    # Your cleanup logic here
  end
end
```

## Common Patterns

### Environment-Based Configuration

```elixir
def config(_opts) do
  if Mix.env() == :prod do
    %{reporters: [{:webhook, url: production_webhook_url()}]}
  else
    %{reporters: [{:jsonl, file: "dev-claude-events.jsonl"}]}
  end
end
```

### Dependency Detection

```elixir
def config(opts) do
  igniter = Keyword.get(opts, :igniter)
  
  base_config = %{hooks: base_hooks()}
  
  config_with_ecto = 
    if Igniter.Project.Deps.has_dep?(igniter, :ecto) do
      add_ecto_config(base_config)
    else
      base_config
    end
  
  if Igniter.Project.Deps.has_dep?(igniter, :phoenix_live_view) do
    add_liveview_config(config_with_ecto)
  else
    config_with_ecto
  end
end
```

### Modular Configuration Building

```elixir
def config(opts) do
  %{}
  |> add_base_hooks()
  |> add_mcp_servers(opts)
  |> add_nested_memories(opts)
  |> add_reporters(opts)
end

defp add_base_hooks(config) do
  Map.put(config, :hooks, %{stop: [:compile, :format]})
end

defp add_mcp_servers(config, opts) do
  if Keyword.get(opts, :enable_mcp?, true) do
    Map.put(config, :mcp_servers, [myserver: []])
  else
    config
  end
end
```

## Debugging Plugins

### Plugin Loading Issues

Check plugin loading with:

```elixir
# In IEx:
{:ok, configs} = Claude.Plugin.load_plugins([Claude.Plugins.Base])
```

### Configuration Inspection

View merged configuration:

```elixir
# Add debugging to your .claude.exs temporarily:
config = %{plugins: [Claude.Plugins.Base, Claude.Plugins.Phoenix]}
{:ok, plugin_configs} = Claude.Plugin.load_plugins(config[:plugins])
merged = Claude.Plugin.merge_configs(plugin_configs)
IO.inspect(merged, label: "Final Plugin Config")

config  # Your regular config
```

### Common Issues

1. **Plugin Not Loading**: Check module name and that it implements `Claude.Plugin`
2. **Configuration Not Merging**: Ensure proper map structure and key names
3. **Conditional Logic**: Test your detection conditions in IEx

## Migration from Direct Configuration

### Before (Direct Configuration)

```elixir
%{
  hooks: %{
    stop: [{"mix compile --warnings-as-errors", halt_pipeline?: true, blocking?: false}],
    post_tool_use: [{"mix format --check-formatted {{tool_input.file_path}}", when: "Edit|MultiEdit|Write"}]
  },
  mcp_servers: [tidewave: [port: 4000]],
  nested_memories: %{
    "test" => ["usage_rules:elixir", "usage_rules:otp"]
  }
}
```

### After (Plugin-Based)

```elixir
%{
  plugins: [
    Claude.Plugins.Base,    # Replaces hooks with shortcuts
    Claude.Plugins.Phoenix  # Replaces mcp_servers + nested_memories
  ]
}
```

The plugin system handles all the complex configuration details automatically while remaining fully customizable.
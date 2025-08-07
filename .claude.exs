%{
  hooks: %{
    stop: [:compile, :format],
    subagent_stop: [:compile, :format],
    post_tool_use: [:compile, :format],
    # These are only ran on git commit
    pre_tool_use: [:compile, :format, :unused_deps]
  }
}

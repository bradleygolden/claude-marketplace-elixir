%{
  hooks: %{
    stop: [:compile, :format],
    post_tool_use: [:compile, :format],
    pre_tool_use: [:compile, :format, :unused_deps],
    subagent_stop: [:compile, :format]
  }
}

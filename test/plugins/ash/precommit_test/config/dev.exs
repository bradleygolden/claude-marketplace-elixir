import Config

config :precommit_test, PrecommitTest.Repo,
  database: "../path/to/your.db",
  show_sensitive_data_on_connection_error: true,
  pool_size: 10

config :ash, policies: [show_policy_breakdowns?: true]

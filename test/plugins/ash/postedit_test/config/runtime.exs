import Config

if config_env() == :prod do
  config :postedit_test, PosteditTest.Repo,
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10")
end

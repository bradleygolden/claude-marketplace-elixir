import Config

config :ash_project,
  ash_domains: [AshProject.Domain],
  ecto_repos: [AshProject.Repo]

config :ash_project, AshProject.Repo,
  database: "ash_project_dev",
  username: "postgres",
  password: "postgres",
  hostname: "localhost"

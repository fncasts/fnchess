# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# General application configuration
config :fn_chess,
  ecto_repos: [FnChess.Repo]

# Configures the endpoint
config :fn_chess, FnChessWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "qHEy0i8tB0+QChUpS7Qod++1owqH87DinOm4OlAX9l7x18SHoUM5YrgETb0KEs5o",
  render_errors: [view: FnChessWeb.ErrorView, accepts: ~w(html json)],
  pubsub: [name: FnChess.PubSub,
           adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"

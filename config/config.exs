# This file is responsible for configuring your umbrella
# and **all applications** and their dependencies with the
# help of Mix.Config.
#
# Note that all applications in your umbrella share the
# same configuration and dependencies, which is why they
# all use the same configuration file. If you want different
# configurations or dependencies per app, it is best to
# move said applications out of the umbrella.
use Mix.Config



config :pr_parking_web,
  generators: [context_app: :pr_parking]

# Configures the endpoint
config :pr_parking_web, PrParkingWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "g69EWuQU1Y2UzsIx4n823UkdYbxpUdt5v3WFlgZZZOx8HkY3n0hS9Bw4Yl92SqUS",
  render_errors: [view: PrParkingWeb.ErrorView, accepts: ~w(json), layout: false],
  pubsub_server: PrParking.PubSub,
  live_view: [signing_salt: "1dM5f41F"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"

use Mix.Config

config :pr_parking_web, PrParkingWeb.Endpoint,
  http: [port: 4000],
  debug_errors: true,
  code_reloader: true,
  check_origin: false,
  watchers: []

config :logger, :console, format: "[$level] $message\n"

config :phoenix, :plug_init_mode, :runtime

config :phoenix, :stacktrace_depth, 20

config :pr_parking,
  resources: [
    %{id: "534013", refresh_period: 1}
  ]

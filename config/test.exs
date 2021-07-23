use Mix.Config

config :pr_parking_web, PrParkingWeb.Endpoint,
  http: [port: 4002],
  server: false

config :logger, level: :warn

config :tesla, adapter: Tesla.Mock

config :pr_parking, :module, PrParkingMock
config :mojepraha_api, :module, MojeprahaApiMock

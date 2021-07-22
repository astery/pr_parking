defmodule PrParkingWeb.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      PrParkingWeb.Telemetry,
      PrParkingWeb.Endpoint
    ]

    opts = [strategy: :one_for_one, name: PrParkingWeb.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def config_change(changed, _new, removed) do
    PrParkingWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end

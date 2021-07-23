defmodule PrParking.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    children =
      [
        {Phoenix.PubSub, name: PrParking.PubSub}
      ] ++ get_pr_parking_workers()

    Supervisor.start_link(children, strategy: :one_for_one, name: PrParking.Supervisor)
  end

  def get_pr_parking_workers() do
    if Application.get_env(:pr_parking, :start, true) do
      resources = Application.get_env(:pr_parking, :resources, [])
      opts = %{resources: resources}

      [{PrParking, opts}]
    else
      []
    end
  end
end

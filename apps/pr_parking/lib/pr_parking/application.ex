defmodule PrParking.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      {Phoenix.PubSub, name: PrParking.PubSub}
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: PrParking.Supervisor)
  end
end

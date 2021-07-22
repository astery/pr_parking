defmodule PrParking.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      # Start the PubSub system
      {Phoenix.PubSub, name: PrParking.PubSub}
      # Start a worker by calling: PrParking.Worker.start_link(arg)
      # {PrParking.Worker, arg}
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: PrParking.Supervisor)
  end
end

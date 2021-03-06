defmodule Cached.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {Task.Supervisor, name: Cached.TaskSupervisor}
    ]

    opts = [strategy: :one_for_one, name: Cached.Supervisor]
    Supervisor.start_link(children, opts)
  end
end

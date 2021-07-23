defmodule PrParking do
  @moduledoc """
  Provides pr parkings properties using cache

  """

  defmodule Behaviour do
    @moduledoc false

    alias MojeprahaApi.Behaviour, as: Api

    @type errors ::
            :error
            | {:error, :not_found}
            | {:error, :connection_failed}
            | {:error, :too_many_requests}
            | {:error, :not_ready}
    @type pr_parking_response :: {:ok, Api.parking_properties()} | errors()
    @type period :: timeout()

    @type minutes :: integer()
    @type resource_opt :: %{
            id: String.t() | integer(),
            refresh_period: minutes()
          }

    @type start_opts :: %{
            optional(:start) => boolean(),
            optional(:resources) => [resource_opt()]
          }

    @callback start_link(start_opts) :: {:ok, pid()}
    @callback get_pr_parking(Api.parking_id()) :: pr_parking_response
    @callback set_pr_parking_refresh_period(Api.parking_id(), period()) ::
                :ok | :error | {:error, :bad_arg} | {:error, :not_found}
  end

  defmodule Impl do
    @moduledoc false

    @behaviour Behaviour

    def start_link(opts) do
      cached_opts =
        opts
        |> Map.get(:resources, [])
        |> Enum.map(fn %{id: id, refresh_period: refresh_period} ->
          {:refresh_period, get_pr_parking_mfa(id), refresh_period}
        end)

      with {:ok, pid} <- Cached.start_link(cached_opts, name: __MODULE__) do
        before_warm_up(opts, pid)
        Cached.warm_up(pid)
        {:ok, pid}
      end
    end

    def get_pr_parking(id) do
      Cached.call(__MODULE__, get_pr_parking_mfa(id))
    end

    def set_pr_parking_refresh_period(id, period) do
      Cached.set_refresh_period(__MODULE__, get_pr_parking_mfa(id), period)
    end

    def get_pr_parking_refresh_period(id) do
      Cached.get_refresh_period(__MODULE__, get_pr_parking_mfa(id))
    end

    defp get_pr_parking_mfa(id), do: {MojeprahaApi, :get_pr_parking, [id]}

    defp before_warm_up(%{before_warm_up: f}, pid), do: f.(pid)
    defp before_warm_up(_opts, _pid), do: nil
  end

  @behaviour Behaviour
  @adapter Application.compile_env(:pr_parking, :module, Impl)

  defdelegate start_link(opts), to: @adapter
  defdelegate get_pr_parking(id), to: @adapter
  defdelegate set_pr_parking_refresh_period(id, period), to: @adapter
end

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

    @callback get_pr_parking(Api.parking_id()) :: pr_parking_response
    @callback set_pr_parking_refresh_period(Api.parking_id(), period()) ::
                :ok | :error | {:error, :bad_arg} | {:error, :not_found}
  end

  defmodule Impl do
    @moduledoc false

    @behaviour Behaviour

    def get_pr_parking(_id) do
      # Here should be calls to an api wrapped in cache layer
      #
      # Cached.call({MojeprahaApi, :get_pr_parking, [id]})

      {:ok,
       %{
         num_of_taken_places: 10,
         total_num_of_places: 30
       }}
    end

    def set_pr_parking_refresh_period(_id, _period) do
      # Here should be calls to cache layer config
      #
      # Cached.set_refresh_period({MojeprahaApi, :get_pr_parking, [id]}, period)

      :ok
    end
  end

  @behaviour Behaviour
  @adapter Application.compile_env(:pr_parking, :module, Impl)

  # Here should be functions to start process (deletating to Cached)
  #
  # def start_link(opts) do
  #   cached_opts =
  #     Applications.get_env(:pr_parking, :resources)
  #     |> Enum.map(...)
  #
  #   ...
  #   Cached.start_link(cached_opts)
  # end

  defdelegate get_pr_parking(id), to: @adapter
  defdelegate set_pr_parking_refresh_period(id, period), to: @adapter
end

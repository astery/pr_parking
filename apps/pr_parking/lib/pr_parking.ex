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

    @callback get_pr_parking(Api.parking_id()) :: pr_parking_response
    @callback set_pr_parking_refresh_timeout(Api.parking_id(), timeout()) ::
                :ok | :error | {:error, :bad_arg} | {:error, :not_found}
  end

  defmodule Impl do
    @moduledoc false

    @behaviour Behaviour

    def get_pr_parking(_id) do
      {:ok,
       %{
         num_of_taken_places: 10,
         total_num_of_places: 30
       }}
    end

    def set_pr_parking_refresh_timeout(_id, _timeout) do
      :ok
    end
  end

  @behaviour Behaviour
  @adapter Application.compile_env(:pr_parking, :module, Impl)

  defdelegate get_pr_parking(id), to: @adapter
  defdelegate set_pr_parking_refresh_timeout(id, timeout), to: @adapter
end

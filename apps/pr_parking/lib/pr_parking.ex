defmodule PrParking do
  @moduledoc """
  Provides pr parkings properties using cache

  """

  defmodule Behaviour do
    @moduledoc false

    alias MojeprahaApi.Behaviour, as: Api

    @callback get_pr_parking(Api.parking_id()) :: Api.pr_parking_response()
    @callback set_pr_parking_refresh_timeout(Api.parking_id(), timeout()) :: :ok | :error
  end

  defmodule Impl do
    @moduledoc false

    @behaviour Behaviour

    @dialyzer :no_return

    def get_pr_parking(_id) do
      raise "not implemented"
    end

    def set_pr_parking_refresh_timeout(_id, _timeout) do
      raise "not implemented"
    end
  end

  @behaviour Behaviour
  @adapter Application.compile_env(:pr_parking, :module, Impl)

  @dialyzer :no_return

  defdelegate get_pr_parking(id), to: @adapter
  defdelegate set_pr_parking_refresh_timeout(id, timeout), to: @adapter
end

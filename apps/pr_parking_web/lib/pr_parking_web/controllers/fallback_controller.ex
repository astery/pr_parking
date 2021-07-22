defmodule PrParkingWeb.FallbackController do
  @moduledoc """
  Translates controller action results into valid `Plug.Conn` responses.

  See `Phoenix.Controller.action_fallback/1` for more details.
  """
  use PrParkingWeb, :controller

  import PrParkingWeb.ErrorHelpers, only: [detail: 1]

  # This clause is an example of how to handle resources that cannot be found.
  def call(conn, {:error, error_key}) when is_atom(error_key) do
    status = status(error_key)
    detail = detail(error_key)

    conn
    |> put_status(status)
    |> put_view(PrParkingWeb.ErrorView)
    |> render("error.json", detail: detail)
  end

  def call(conn, :error) do
    conn
    |> put_status(:internal_server_error)
    |> put_view(PrParkingWeb.ErrorView)
    |> render("500.json")
  end

  defp status(:not_found), do: :not_found
  defp status(:bad_arg), do: :bad_request
  defp status(:too_many_requests), do: :too_many_requests
  defp status(:not_ready), do: :service_unavailable
  defp status(_), do: :internal_server_error
end

defmodule PrParkingWeb.ParkingController do
  use PrParkingWeb, :controller

  action_fallback PrParkingWeb.FallbackController

  def show(conn, %{"id" => id}) do
    with {:ok, parking} <- PrParking.get_pr_parking(id) do
      render(conn, "show.json", parking: parking)
    end
  end

  def set_refresh_period(conn, %{"id" => id, "refresh_period" => refresh_period}) do
    with :ok <- PrParking.set_pr_parking_refresh_period(id, refresh_period) do
      render(conn, "refresh_period.json", refresh_period: refresh_period)
    end
  end
end

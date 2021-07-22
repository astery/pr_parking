defmodule PrParkingWeb.Router do
  use PrParkingWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", PrParkingWeb do
    pipe_through :api

    get "/parkings/:id", ParkingController, :show
    post "/crawlers/:id", ParkingController, :set_refresh_period
  end

  if Mix.env() in [:dev, :test] do
    import Phoenix.LiveDashboard.Router

    scope "/" do
      pipe_through [:fetch_session, :protect_from_forgery]
      live_dashboard "/dashboard", metrics: PrParkingWeb.Telemetry
    end
  end
end

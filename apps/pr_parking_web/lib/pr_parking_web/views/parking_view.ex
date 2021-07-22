defmodule PrParkingWeb.ParkingView do
  @moduledoc """
  The view is a bit dull, but it's better to have such filter
  """

  use PrParkingWeb, :view

  def render("show.json", %{parking: parking}) do
    %{
      "total_places" => parking.total_num_of_places,
      "taken_places" => parking.num_of_taken_places
    }
  end

  def render("refresh_period.json", %{refresh_period: refresh_period}) do
    %{"refresh_period" => refresh_period}
  end
end

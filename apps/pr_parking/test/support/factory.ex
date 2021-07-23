defmodule PrParking.Support.Factory do
  @moduledoc false

  def build_parking() do
    %{
      num_of_taken_places: 8,
      total_num_of_places: 9
    }
  end
end

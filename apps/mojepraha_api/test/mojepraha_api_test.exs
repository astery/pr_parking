defmodule MojeprahaApiTest do
  use ExUnit.Case
  doctest MojeprahaApi

  alias MojeprahaApi.HttpApi

  describe "HttpApi" do
    test "get_pr_parkings/1 sanity check" do
      id = 534_013

      Tesla.Mock.mock(fn
        %{method: :get} -> %Tesla.Env{status: 200, body: get_pr_parking_response()}
      end)

      assert {:ok, %{num_of_taken_places: 57, total_num_of_places: 57}} ==
               HttpApi.get_pr_parking(id)
    end
  end

  defp get_pr_parking_response() do
    %{
      "geometry" => %{"coordinates" => [14.350451, 50.05053], "type" => "Point"},
      "properties" => %{
        "address" => "Seydlerova 2152/1, Stodůlky, 158 00 Praha-Praha 13, Česko",
        "district" => "praha-13",
        "id" => 534_013,
        "last_updated" => 1_502_178_725_000,
        "name" => "Nové Butovice",
        "num_of_free_places" => 0,
        "num_of_taken_places" => 57,
        "pr" => true,
        "total_num_of_places" => 57
      },
      "type" => "Feature"
    }
  end
end

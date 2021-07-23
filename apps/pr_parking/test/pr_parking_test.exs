defmodule PrParkingTest do
  use ExUnit.Case

  import PrParking.Support.Factory, only: [build_parking: 0]
  import Hammox

  setup :verify_on_exit!

  describe "Impl" do
    alias PrParking.Impl

    setup do
      parking_id = "34"
      parking = build_parking()

      MojeprahaApiMock
      |> stub(:get_pr_parking, fn ^parking_id -> {:ok, parking} end)

      assert {:ok, _} =
               Impl.start_link(%{
                 resources: [%{id: parking_id, refresh_period: 20}],
                 before_warm_up: fn pid ->
                   allow(MojeprahaApiMock, self(), pid)
                 end
               })

      %{parking_id: parking_id, parking: parking}
    end

    setup :wait_for_warm_up

    test "&get_pr_parking/1 sanity check", ctx do
      assert {:ok, ctx.parking} == Impl.get_pr_parking(ctx.parking_id)
    end

    test "&set_pr_parking_refresh_period/1 sanity check", ctx do
      assert {:ok, 20} == Impl.get_pr_parking_refresh_period(ctx.parking_id)
      assert :ok == Impl.set_pr_parking_refresh_period(ctx.parking_id, 10)
      assert {:ok, 10} == Impl.get_pr_parking_refresh_period(ctx.parking_id)
    end
  end

  # Fast hack, should be replaced with sync version of warm_up call
  defp wait_for_warm_up(_) do
    Process.sleep(100)
  end
end

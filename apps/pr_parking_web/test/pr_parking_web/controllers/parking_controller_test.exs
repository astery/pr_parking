defmodule PrParkingWeb.ParkingControllerTest do
  use PrParkingWeb.ConnCase

  alias PrParkingWeb.ErrorView

  import PrParking.Support.Factory, only: [build_parking: 0]
  import PrParkingWeb.ParkingView, only: [render: 2]
  import Hammox

  setup :verify_on_exit!

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  # Using ParkingView.render in test helps to make tests less
  # fragile in the face of cosmetic changes of view

  setup do
    %{parking: build_parking(), id: "49", refresh_period: 20}
  end

  describe "&show/2" do
    test "should return a json with status 200 if succeeded", ctx do
      expect_get_to_return(ctx, {:ok, ctx.parking})
      conn = get_show(ctx)
      assert render("show.json", %{parking: ctx.parking}) == json_response(conn, 200)
    end

    test "should return a json with status 429 if too many requests", ctx do
      expect_get_to_return(ctx, {:error, :too_many_requests})
      conn = get_show(ctx)
      assert ErrorView.from(:too_many_requests) == json_response(conn, 429)
    end

    test "should return a json with status 404 if not found", ctx do
      expect_get_to_return(ctx, {:error, :not_found})
      conn = get_show(ctx)
      assert ErrorView.from(:not_found) == json_response(conn, 404)
    end

    test "should return a json with status 503 if not ready to serve", ctx do
      # assert Retry-After: <delay-seconds>
      expect_get_to_return(ctx, {:error, :not_ready})
      conn = get_show(ctx)
      assert ErrorView.from(:not_ready) == json_response(conn, 503)
    end

    test "should return a json with status 500 if error is unknown", ctx do
      expect_get_to_return(ctx, :error)
      conn = get_show(ctx)
      assert ErrorView.render("500.json", []) == json_response(conn, 500)
    end

    def expect_get_to_return(%{id: id}, expectation) do
      expect(PrParkingMock, :get_pr_parking, fn ^id -> expectation end)
    end

    def get_show(ctx) do
      get(ctx.conn, Routes.parking_path(ctx.conn, :show, ctx.id))
    end
  end

  describe "&update/2" do
    test "should return a json with status 200 if succeeded", ctx do
      expect_set_to_return(ctx, :ok)
      conn = post_update(ctx)
      json = json_response(conn, 200)
      assert render("refresh_period.json", %{refresh_period: ctx.refresh_period}) == json
    end

    test "should return a json with status 400 if params is bad", ctx do
      expect_set_to_return(ctx, {:error, :bad_arg})
      conn = post_update(ctx)
      assert ErrorView.from(:bad_arg) == json_response(conn, 400)
    end

    test "should return a json with status 404 if not found", ctx do
      expect_set_to_return(ctx, {:error, :not_found})
      conn = post_update(ctx)
      assert ErrorView.from(:not_found) == json_response(conn, 404)
    end

    test "should return a json with status 500 if unknown error", ctx do
      expect_set_to_return(ctx, :error)
      conn = post_update(ctx)
      assert ErrorView.render("500.json", []) == json_response(conn, 500)
    end

    def expect_set_to_return(%{} = ctx, expectation) do
      refresh_period = ctx.refresh_period
      id = ctx.id

      expect(PrParkingMock, :set_pr_parking_refresh_period, fn ^id, ^refresh_period ->
        expectation
      end)
    end

    def post_update(%{} = ctx) do
      post(
        ctx.conn,
        Routes.parking_path(ctx.conn, :set_refresh_period, ctx.id),
        refresh_period: ctx.refresh_period
      )
    end
  end
end

defmodule CachedTest do
  use ExUnit.Case
  doctest Cached

  import Hammox

  alias Cached.Api

  Mox.defmock(ApiMock, for: Api)
  Mox.defmock(TimerMock, for: Cached.Timer.Behaviour)

  setup :verify_on_exit!

  describe "cached started" do
    setup [
      :single_refresh_period_set,
      :expect_timer_call,
      :cached_started
    ]

    test "&call/1 should return :not_ready then not initialized", ctx do
      assert Cached.call(ctx.pid, ctx.mfa) == :not_ready
    end
  end

  describe "cached warmed up" do
    setup [
      :single_refresh_period_set,
      :expect_timer_call,
      :cached_started,
      :expect_to_request_successfully,
      :assert_receive_timer_event,
      :send_pending_timer_event,
      :assert_recieve_request_call
    ]

    test "&call/1 should return cached result without calling api", ctx do
      assert ctx.api_response == Cached.call(ctx.pid, ctx.mfa)
      assert ctx.api_response == Cached.call(ctx.pid, ctx.mfa)

      refute_receive {:requested, _}
    end
  end

  defp assert_recieve_request_call(ctx) do
    {event, pending_api_events} = List.pop_at(ctx.pending_api_events, 0)

    assert_receive ^event

    %{pending_api_events: pending_api_events}
  end

  defp expect_to_request_successfully(ctx) do
    {_, _, [arg]} = ctx.mfa
    event = {:api_request, ctx.mfa}
    response = {:ok, :payload}

    test_pid = self()

    ApiMock
    |> expect(:request, fn ^arg ->
      send(test_pid, event)
      response
    end)

    events = ctx[:pending_api_events] || []

    %{
      pending_api_events: events ++ [event],
      api_response: response
    }
  end

  defp send_pending_timer_event(ctx) do
    {{:timer_send_after, msg, _}, pending_timer_events} = List.pop_at(ctx.pending_timer_events, 0)

    send(ctx.pid, msg)

    %{pending_timer_events: pending_timer_events}
  end

  defp assert_receive_timer_event(ctx) do
    assert_receive {:timer_send_after, _, _} = event

    events = ctx[:pending_timer_events] || []
    %{pending_timer_events: events ++ [event]}
  end

  defp single_refresh_period_set(_ctx) do
    mfa = {ApiMock, :request, [:arg]}
    refresh_period = 30
    cached_options = [{:refresh_period, mfa, refresh_period}]

    %{mfa: mfa, refresh_period: refresh_period, cached_options: cached_options}
  end

  defp expect_timer_call(_ctx) do
    test_pid = self()

    TimerMock
    |> expect(:send_after, fn _, msg, timeout ->
      send(test_pid, {:timer_send_after, msg, timeout})
    end)

    :ok
  end

  defp cached_started(ctx) do
    opts = [{:timer, TimerMock}] ++ ctx.cached_options
    {:ok, pid} = Cached.start_link(opts)

    allow(TimerMock, self(), pid)
    allow(ApiMock, self(), pid)

    :ok = Cached.warm_up(pid)

    %{pid: pid}
  end
end

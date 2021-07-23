defmodule CachedTest do
  use ExUnit.Case
  doctest Cached

  import Hammox

  setup :verify_on_exit!

  setup do
    test_pid = self()

    TimerMock
    |> stub(:send_after, fn _, msg, timeout ->
      send(test_pid, {:timer_send_after, msg, timeout})
    end)

    :ok
  end

  describe "cached started" do
    setup [
      :single_refresh_period_set,
      :cached_started
    ]

    test "&call/1 should return :not_ready then not initialized", ctx do
      assert Cached.call(ctx.pid, ctx.mfa) == {:error, :not_ready}
    end
  end

  describe "cached warmed up" do
    setup [
      :single_refresh_period_set,
      :cached_started,
      :expect_to_request_successfully,
      :assert_receive_timer_event,
      :send_pending_timer_event,
      :assert_recieve_request_call,
      :assert_receive_timer_event,
      :wait_refresh_to_apply
    ]

    test "&call/1 should return cached result without calling api", ctx do
      assert ctx.api_response == Cached.call(ctx.pid, ctx.mfa)
      assert ctx.api_response == Cached.call(ctx.pid, ctx.mfa)

      refute_receive {:api_request, _}
    end

    test "&call/1 after refresh time passed should return a new info", ctx do
      new_response = {:ok, :new_payload}

      ctx =
        %{ctx | api_response: new_response}
        |> merge(&expect_to_request_successfully/1)
        |> merge(&send_pending_timer_event/1)
        |> merge(&assert_recieve_request_call/1)
        |> merge(&assert_receive_timer_event/1)

      wait_refresh_to_apply()

      assert new_response == Cached.call(ctx.pid, ctx.mfa)

      refute_receive {:api_request, _}
    end

    test "&set_refresh_period/1 should change period", ctx do
      assert :ok == Cached.set_refresh_period(ctx.pid, ctx.mfa, 43)
      assert {:ok, 43} == Cached.get_refresh_period(ctx.pid, ctx.mfa)

      refute_receive {:api_request, _}
    end
  end

  describe "no periods set and cached warmed up" do
    setup [
      :no_refresh_periods_set,
      :cached_started
    ]

    test "&call/1 should return {:error, :not_cached}", ctx do
      assert {:error, :has_no_refresh_period} == Cached.call(ctx.pid, ctx.mfa)

      refute_receive {:api_request, _}
    end

    test "&set_refresh_period/1 should call api if before that it was nil", ctx do
      expect_to_request_successfully(ctx)

      assert {:ok, nil} == Cached.get_refresh_period(ctx.pid, ctx.mfa)
      assert :ok == Cached.set_refresh_period(ctx.pid, ctx.mfa, 43)
      assert {:ok, 43} == Cached.get_refresh_period(ctx.pid, ctx.mfa)

      assert_receive {:api_request, _}
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
    response = ctx[:api_response] || {:ok, :payload}

    test_pid = self()

    ApiMock
    |> stub(:request, fn ^arg ->
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

  defp no_refresh_periods_set(_ctx) do
    mfa = {ApiMock, :request, [:arg]}

    %{mfa: mfa, refresh_period: nil, cached_options: []}
  end

  defp cached_started(ctx) do
    test_pid = self()

    before_each_call = fn task_pid ->
      allow(ApiMock, test_pid, task_pid)
    end

    opts =
      [
        {:timer, TimerMock},
        {:before_each_call, before_each_call}
      ] ++ ctx.cached_options

    {:ok, pid} = start_supervised({Cached, opts})

    allow(TimerMock, test_pid, pid)
    allow(ApiMock, test_pid, pid)

    :ok = Cached.warm_up(pid)

    %{pid: pid}
  end

  defp merge(ctx, step) do
    Map.merge(ctx, step.(ctx))
  end

  # We need to replace that with an update event cache
  defp wait_refresh_to_apply(_ \\ nil) do
    Process.sleep(100)
  end
end

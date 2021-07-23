defmodule Cached do
  @moduledoc """
  Returns cached result. Actualizes cache in background.

  Calls not listed in refresh period list will be dropped.
  """

  defmodule Timer do
    @moduledoc false

    defmodule Behaviour do
      @moduledoc false

      @type msg :: any()

      @callback send_after(pid(), msg(), timeout()) :: any()
    end

    @behaviour Behaviour

    def send_after(pid, msg, timeout) do
      Process.send_after(pid, msg, timeout)
    end
  end

  defmodule State do
    @moduledoc false

    defstruct refresh_periods: %{},
              cached_values: %{},
              refs: %{},
              timer: Timer,
              before_each_call: nil

    # 30 min
    @retry_timeout 30 * 60 * 1000

    require Logger

    def build(opts) do
      Enum.reduce(opts, %__MODULE__{}, fn
        {:timer, timer}, state ->
          %{state | timer: timer}

        {:before_each_call, before_each_call}, state ->
          %{state | before_each_call: before_each_call}

        {:refresh_period, mfa, timeout}, state ->
          set_refresh_period(state, mfa, timeout)
      end)
    end

    def warm_up_cache(%{refresh_periods: periods} = state) do
      periods
      |> Map.keys()
      |> Enum.each(fn mfa ->
        # Here we need to randomize starting point of each request
        # Ideally gradually increase with every request call, and with respect
        # to :requests_per_minute_warm_up_limit
        offset = 0
        call_later(state, self(), mfa, offset)
      end)
    end

    defp call_later(state, server_pid, mfa, offset) do
      state.timer.send_after(server_pid, {:make_call, mfa}, offset)
    end

    def get_cached_value(state, mfa) do
      if has_refresh_period?(state, mfa) do
        Map.get(state.cached_values, mfa)
        |> case do
          nil -> {:error, :not_ready}
          value -> value
        end
      else
        {:error, :has_no_refresh_period}
      end
    end

    def set_and_start_refresh_period(state, mfa, period) do
      state =
        if has_refresh_period?(state, mfa) do
          state
        else
          make_call(state, mfa)
        end

      set_refresh_period(state, mfa, period)
    end

    def set_refresh_period(state, mfa, period) do
      %{state | refresh_periods: Map.put(state.refresh_periods, mfa, period)}
    end

    def get_refresh_period(state, mfa) do
      state.refresh_periods |> Map.get(mfa)
    end

    defp has_refresh_period?(state, mfa) do
      !is_nil(get_refresh_period(state, mfa))
    end

    def make_call(state, {m, f, a} = mfa) do
      server_pid = self()

      task =
        Task.Supervisor.async_nolink(Cached.TaskSupervisor, fn ->
          before_each_call(state, self())

          result = apply(m, f, a)

          offset = get_refresh_period(state, mfa)

          if is_integer(offset) do
            call_later(state, server_pid, mfa, offset)
          end

          result
        end)

      %{state | refs: Map.put(state.refs, task.ref, mfa)}
    end

    def receive_call_result(state, ref, result) do
      Process.demonitor(ref, [:flush])
      {mfa, refs} = Map.pop(state.refs, ref)

      %{state | refs: refs, cached_values: Map.put(state.cached_values, mfa, result)}
    end

    def receive_call_failing(state, ref, reason) do
      mfa = state.refs[ref]
      Logger.warn("Failed to call #{inspect(mfa)} due: #{inspect(reason)}")
      # Here should be implemented backoff logic
      call_later(state, self(), mfa, @retry_timeout)
    end

    def before_each_call(%{before_each_call: nil}, _pid), do: nil
    def before_each_call(%{before_each_call: f}, pid), do: f.(pid)
  end

  defmodule Server do
    @moduledoc false

    use GenServer

    @impl true
    def init(opts) do
      {:ok, State.build(opts)}
    end

    @impl true
    def handle_call(:warm_up, _from, state) do
      State.warm_up_cache(state)

      {:reply, :ok, state}
    end

    @impl true
    def handle_call({:call, mfa}, _from, state) do
      {:reply, State.get_cached_value(state, mfa), state}
    end

    @impl true
    def handle_call({:set_refresh_period, mfa, period}, _from, state) do
      {:reply, :ok, State.set_and_start_refresh_period(state, mfa, period)}
    end

    @impl true
    def handle_call({:get_refresh_period, mfa}, _from, state) do
      {:reply, {:ok, State.get_refresh_period(state, mfa)}, state}
    end

    @impl true
    def handle_info({:make_call, mfa}, state) do
      {:noreply, State.make_call(state, mfa)}
    end

    # The task completed successfully
    def handle_info({ref, result}, state) do
      {:noreply, State.receive_call_result(state, ref, result)}
    end

    # The task failed
    def handle_info({:DOWN, ref, :process, _pid, reason}, %{ref: ref} = state) do
      # Log and possibly restart the task...
      {:noreply, State.receive_call_failing(state, ref, reason)}
    end
  end

  @doc """
  ## Options

    - {:refresh_period, <module>, <fun>, <args>, <timeout>} - if mfa matches
        function will be called  with given period and result will be cached
    - {:timer, <module>} - optional, should implement Timer.Behaviour

  ## Gen options

    - {:name, <atom>} - optional, start named
  """
  def start_link(opts \\ [], gen_opts \\ [])
      when is_list(opts) and is_list(gen_opts) do
    GenServer.start_link(Server, opts, gen_opts)
  end

  def child_spec(opts) do
    %{id: Cached, start: {Cached, :start_link, [opts]}}
  end

  def warm_up(pid) do
    GenServer.call(pid, :warm_up)
  end

  def call(pid, mfa) do
    GenServer.call(pid, {:call, mfa})
  end

  def set_refresh_period(pid, mfa, period) do
    GenServer.call(pid, {:set_refresh_period, mfa, period})
  end

  def get_refresh_period(pid, mfa) do
    GenServer.call(pid, {:get_refresh_period, mfa})
  end
end

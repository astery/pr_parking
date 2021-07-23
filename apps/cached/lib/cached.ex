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

  # Used in tests
  defmodule Api do
    @moduledoc false
    @callback request(any()) :: any()
  end

  defmodule State do
    @moduledoc false

    defstruct refresh_periods: %{}, cached_values: %{}, refs: %{}, timer: Timer

    # 30 min
    @retry_timeout 30 * 60 * 1000

    require Logger

    def build(opts) do
      Enum.reduce(opts, %__MODULE__{}, fn
        {:timer, timer}, state ->
          %{state | timer: timer}

        {:refresh_period, mfa, timeout}, state ->
          %{state | refresh_periods: Map.put(state.refresh_periods, mfa, timeout)}
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
        call_later(state, mfa, offset)
      end)
    end

    defp call_later(state, mfa, offset) do
      state.timer.send_after(self(), {:make_call, mfa}, offset)
    end

    def get_cached_value(state, mfa) do
      state.cached_values
      |> Map.get(mfa, :not_ready)
    end

    def make_call(state, {m, f, a} = mfa) do
      task =
        Task.Supervisor.async_nolink(Cached.TaskSupervisor, fn ->
          apply(m, f, a)
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
      call_later(state, mfa, @retry_timeout)
    end
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

    - {:name, <atom>} - process name
    - {:refresh_period, <module>, <fun>, <args>, <timeout>} - if mfa matches
        function will be called  with given period and result will be cached
    - {:timer, <module>} - optional, should implement Timer.Behaviour

  """
  def start_link(opts \\ []) when is_list(opts) do
    GenServer.start_link(Server, opts)
  end

  def warm_up(pid) do
    GenServer.call(pid, :warm_up)
  end

  def call(pid, mfa) do
    GenServer.call(pid, {:call, mfa})
  end
end

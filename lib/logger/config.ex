defmodule Logger.Config do
  @moduledoc false

  use GenEvent

  @name __MODULE__
  @data :__data__

  def start_link do
    GenServer.start_link(__MODULE__, :ok, name: @name)
  end

  def configure(options) do
    GenEvent.call(Logger, @name, {:configure, options})
  end

  def __data__() do
    Application.get_env(:logger, @data)
  end

  def clear_data() do
    Application.delete_env(:logger, @data)
  end

  ## Callbacks

  def init(_) do
    # Use previous data if available in case this handler crashed.
    state = __data__ || compute_state(:async)
    {:ok, state}
  end

  def handle_event({_type, gl, _msg} = event, state) when node(gl) != node() do
    # Cross node messages are always async which also
    # means this handler won't crash in case there is
    # no logger installed in the other node.
    GenEvent.notify({Logger, node(gl)}, event)
    {:ok, state}
  end

  def handle_event(_event, state) do
    {:message_queue_len, len} = Process.info(self(), :message_queue_len)

    cond do
      len > state.sync_threshold and state.mode == :async ->
        state = %{state | mode: :sync}
        persist(state)
        {:ok, state}
      len < state.async_threshold and state.mode == :sync ->
        state = %{state | mode: :async}
        persist(state)
        {:ok, state}
      true ->
        {:ok, state}
    end
  end

  def handle_call({:configure, options}, state) do
    Enum.each options, fn {key, value} ->
      Application.put_env(:logger, key, value)
    end
    {:ok, :ok, compute_state(state.mode)}
  end

  ## Helpers

  defp compute_state(mode) do
    level    = Application.get_env(:logger, :level)
    utc_log  = Application.get_env(:logger, :utc_log)
    truncate = Application.get_env(:logger, :truncate)

    sync_threshold  = Application.get_env(:logger, :sync_threshold)
    async_threshold = trunc(sync_threshold * 0.75)

    state =
      %{level: level, mode: mode, truncate: truncate, utc_log: utc_log,
        sync_threshold: sync_threshold, async_threshold: async_threshold}
    persist(state)
    state
  end

  defp persist(state) do
    Application.put_env(:logger, @data, state)
  end
end

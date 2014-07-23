defmodule Logger.Watcher do
  @moduledoc false

  use GenServer
  @name Logger.Watcher

  @doc """
  Starts the watcher supervisor.
  """
  def start_link() do
    options  = [strategy: :one_for_one, name: @name]
    Supervisor.start_link([], options)
  end

  @doc """
  Watches the given handlers as part of the handler supervision tree.
  """
  def watch(handlers) do
    _ = for {mod, handler, args} <- handlers do
      {:ok, _pid} = watch(mod, handler, args)
    end
    :ok
  end

  @doc """
  Watches the given handler as part of the handler supervision tree.
  """
  def watch(mod, handler, args) do
    import Supervisor.Spec
    id = {mod, handler}
    child = worker(__MODULE__, [mod, handler, args],
      [id: id, function: :async_watcher, restart: :transient])
    case Supervisor.start_child(@name, child) do
      {:ok, _pid} = result ->
        result
      {:error, :already_present} ->
        _ = Supervisor.delete_child(@name, id)
        watch(mod, handler, args)
      {:error, _reason} = error ->
        error
    end
  end

  @doc """
  Starts a watcher server.

  This is useful when there is a need to start a handler
  outside of the handler supervision tree.
  """
  def watcher(mod, handler, args) do
    GenServer.start_link(__MODULE__, {mod, handler, args})
  end

  @doc """
  Starts an async watcher.
  """
  def async_watcher(mod, handler, args) do
    {:ok, :proc_lib.spawn_link(__MODULE__, :init_async, [{mod, handler, args}])}
  end

  ## Callbacks

  def init_async({_, _, _} = state) do
    install_handler(state)
    :gen_server.enter_loop(__MODULE__, [], state)
  end

  def init({_, _, _} = state) do
    install_handler(state)
    {:ok, state}
  end

  def handle_info({:gen_event_EXIT, handler, reason}, {_, handler, _} = state) do
    {:stop, reason, state}
  end

  def handle_info(_msg, state) do
    {:noreply, state}
  end

  # TODO: We need to log if we can't install the handler
  defp install_handler({mod, handler, args}) do
    :ok = :gen_event.add_sup_handler(mod, handler, args)
  end
end

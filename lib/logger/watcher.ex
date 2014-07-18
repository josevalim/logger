defmodule Logger.Watcher do
  @moduledoc false

  use GenServer
  @name Logger.Watcher

  @doc """
  Starts the watcher supervisor.
  """
  def start_link() do
    import Supervisor.Spec
    children = [worker(@name, [], function: :watcher, type: :temporary)]
    options  = [strategy: :simple_one_for_one, name: @name]
    Supervisor.start_link(children, options)
  end

  @doc """
  Start watching a handler.
  """
  def watch(mod, handler, args) do
    Supervisor.start_child(@name, [mod, handler, args])
  end

  ## Callbacks

  def watcher(mod, handler, args) do
    GenServer.start_link(__MODULE__, {mod, handler, args})
  end

  def init({_, _, _} = state) do
    install_handler(state)
    {:ok, state}
  end

  def handle_info({:gen_event_EXIT, handler, reason}, {_, handler, _} = state)
      when reason in [:normal, :shutdown] do
    {:stop, reason, state}
  end

  # TODO: We need to log the handler died
  def handle_info({:gen_event_EXIT, handler, _reason}, {_, handler, _} = state) do
    install_handler(state)
    {:noreply, state}
  end

  def handle_info(_msg, state) do
    {:noreply, state}
  end

  # TODO: We need to log if we can't install the handler
  defp install_handler({mod, handler, args}) do
    :ok = :gen_event.add_sup_handler(mod, handler, args)
  end
end

defmodule Logger.Reloader do


  use GenServer
  @name Logger.Reloader

  def start_link(), do: GenServer.start_link(__MODULE__, nil, [name: @name])

  def reload(), do: GenServer.call(@name, :reload)

  def init(state) do
    {:ok, state}
  end

  def handle_call(:reload, _from, state) do
    :ok = Supervisor.terminate_child(Logger.Supervisor, Logger.Watcher.Supervisor)
    case Supervisor.restart_child(Logger.Supervisor, Logger.Watcher.Supervisor) do
      {:ok, _pid} ->
        {:reply, :ok, state}
      # Something went wrong, stopping will trigger a restart of everything
      {:error, reason} ->
        {:stop, reason, state}
    end
  end
end

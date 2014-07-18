defmodule Logger.Watcher do
  @moduledoc false

  use GenServer

  @name __MODULE__
  @data :__data__
  @handler Logger.Handler

  def start_link do
    GenServer.start_link(__MODULE__, :ok, name: @name)
  end

  def configure(options) do
    GenServer.call(@name, {:configure, options})
  end

  def __data__() do
    Application.get_env(:logger, @data)
  end

  def clear_data() do
    Application.delete_env(:logger, @data)
  end

  ## Callbacks

  def init(:ok) do
    recompute_data()
    install_handler()
    {:ok, %{}}
  end

  def handle_call({:configure, options}, _from, state) do
    Enum.each options, fn {key, value} ->
      Application.put_env(:logger, key, value)
    end
    recompute_data()
    {:reply, :ok, state}
  end

  def handle_info({:gen_event_EXIT, @handler, reason}, state) when reason in [:normal, :shutdown] do
    {:stop, reason, state}
  end

  # TODO: We need to log the handler died
  def handle_info({:gen_event_EXIT, @handler, _reason}, state) do
    install_handler()
    {:noreply, state}
  end

  def handle_info(_msg, state) do
    {:noreply, state}
  end

  ## Helpers

  defp recompute_data() do
    truncate  = Application.get_env(:logger, :truncate, 8096)
    log_level = nil # For now
    Application.put_env(:logger, @data, {truncate, log_level})
  end

  # TODO: We need to log if we can't install the handler
  defp install_handler do
    :gen_event.add_sup_handler(:error_logger, @handler, :ok)
  end
end

defmodule Logger.Watcher do
  use GenServer

  @handler Logger.Handler

  def start_link do
    GenServer.start_link(__MODULE__, :ok)
  end

  def init(:ok) do
    install_handler()
    {:ok, %{}}
  end

  def handle_info({:gen_event_EXIT, @handler, reason}, state) when reason in [:normal, :shutdown] do
    {:stop, reason, state}
  end

  # TODO: We need to log the handler died
  def handle_info({:gen_event_EXIT, @handler, reason}, state) do
    install_handler()
    {:noreply, state}
  end

  def handle_info(_msg, state) do
    {:noreply, state}
  end

  # TODO: We need to log if we can't install the handler
  defp install_handler do
    :gen_event.add_sup_handler(:error_logger, @handler, :ok)
  end
end

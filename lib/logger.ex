defmodule Logger do
  use Application

  @moduledoc """
  A logger able to format in Elixir terms.

  ## Handlers

  The supported handlers are:

    * `:tty` - log entries to the terminal

  """

  @type handler :: :tty
  @handlers [:tty]

  @doc false
  def start(_type, _args) do
    import Supervisor.Spec

    children   = [worker(Logger.Watcher, [])]
    options    = [strategy: :one_for_one, name: Logger.Supervisor]
    {:ok, sup} = Supervisor.start_link(children, options)

    case :error_logger.delete_report_handler(:error_logger_tty_h) do
      {:error, :module_not_found} -> :ok
      _ -> enable(:tty)
    end

    {:ok, sup}
  end

  # @doc """
  # Enables a logger handler.
  # """
  # @spec enable(handler) :: :ok
  defp enable(handler) when handler in @handlers do
    GenEvent.call(:error_logger, Logger.Handler, {:enable, handler})
  end

  # @doc """
  # Disables a logger handler.
  # """
  # @spec disable(handler) :: :ok
  # defp disable(handler) when handler in @handlers do
  #   GenEvent.call(:error_logger, Logger.Handler, {:disable, handler})
  # end
end

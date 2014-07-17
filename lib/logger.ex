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
    :error_logger.add_report_handler(Logger.Handler, :ok)

    case :error_logger.delete_report_handler(:error_logger_tty_h) do
      {:error, :module_not_found} -> :ok
      _ -> enable(:tty)
    end

    Supervisor.start_link([], strategy: :one_for_one)
  end

  @doc """
  Enables a logger handler.
  """
  @spec enable(handler) :: :ok
  def enable(handler) when handler in @handlers do
    GenEvent.call(:error_logger, Logger.Handler, {:enable, handler})
  end

  @doc """
  Disables a logger handler.
  """
  @spec disable(handler) :: :ok
  def disable(handler) when handler in @handlers do
    GenEvent.call(:error_logger, Logger.Handler, {:disable, handler})
  end
end

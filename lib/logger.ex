defmodule Logger do
  use Application

  @moduledoc """
  A info, warning or error logger.

  ## Level

  The supported levels are:

    * `:info` - for information of any kind
    * `:warn` - for warnings
    * `:error` - for errors

  ## Handlers

  The supported handlers are:

    * `:tty` - log entries to the terminal

  ## Implementation notes

  Elixir's Logger is built on top of Erlang's
  [`:error_logger`](http://www.erlang.org/doc/man/error_logger.html).

  For this reason, when Logger is started, Elixir looks if the Erlang
  error logger is bound to tty and replaces it by its own that is
  able to format messages in Elixir's format.

  Furthermore, Elixir's Logger includes many improvements on top
  of Erlang's `error_logger`:

    * Logger is watched over which guarantees it is restarted
      in case of crashes;

    * Logger formats message on the client to avoid clogging
      the logger event manager

  """

  @type handler :: :tty
  @type level :: :error | :info | :warning

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

  @doc """
  Logs a message.

  Developers should rather use the macros `Logger.warn/2`,
  `Logger.info/2` or `Logger.error/2` instead of this function
  as they automatically include caller metadata.

  Use this function only when there is a need to log dynamically
  or you want to explicitly avoid embedding metadata.
  """
  @spec log(level, IO.chardata, Keyword.t) :: :ok
  def log(level, chardata, metadata \\ [])
      when is_list(metadata) and (is_list(chardata) or is_binary(chardata)) do
    GenEvent.notify(:error_logger,
      {level_to_report(level),
       Process.group_leader(),
       {self(), {Logger, metadata}, chardata}})
  end

  @doc """
  Logs a warning.

  ## Examples

    Logger.warning "knob turned too much to the right"

  """
  defmacro warn(chardata, metadata \\ []) do
    quote do
      Logger.log(:warning, unquote(chardata), unquote(metadata))
    end
  end

  @doc """
  Logs some info.

  ## Examples

      Logger.info "mission accomplished"

  """
  defmacro info(chardata, metadata \\ []) do
    quote do
      Logger.log(:info, unquote(chardata), unquote(metadata))
    end
  end

  @doc """
  Logs an error.

  ## Examples

      Logger.error "oops"

  """
  defmacro error(chardata, metadata \\ []) do
    quote do
      Logger.log(:error, unquote(chardata), unquote(metadata))
    end
  end

  # @doc """
  # Enables a logger handler.
  # """
  # @spec enable(handler) :: :ok
  defp enable(handler) do
    GenEvent.call(:error_logger, Logger.Handler, {:enable, handler})
  end

  # @doc """
  # Disables a logger handler.
  # """
  # @spec disable(handler) :: :ok
  # defp disable(handler) do
  #   GenEvent.call(:error_logger, Logger.Handler, {:disable, handler})
  # end

  defp level_to_report(:warning), do: :warning_report
  defp level_to_report(:error),   do: :error_report
  defp level_to_report(:info),    do: :info_report
end

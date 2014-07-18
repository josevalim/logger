defmodule Logger do
  use Application

  @moduledoc """
  A info, warning or error logger.

  ## Level

  The supported levels are:

    * `:debug` - for debug-related messages
    * `:info` - for information of any kind
    * `:warn` - for warnings
    * `:error` - for errors

  ## Handlers

  The supported handlers are:

    * `:tty` - log entries to the terminal

  ## Configuration

    * `:truncate` - the maximum message size to be logged. Defaults
      to 8192 bytes. Note this configuration is approximate. Truncated
      messages will have "(truncated)" at the end.

  At runtime, `Logger.configure/1` must be used to configure Logger
  options, which guarantees the configuration is serialized.

  ## Comparison to :error_logger

  Elixir's Logger is built on top of Erlang's
  [`:error_logger`](http://www.erlang.org/doc/man/error_logger.html).

  For this reason, when Logger is started, Elixir looks if the Erlang
  error logger is bound to tty and replaces it by its own that is
  able to format messages in Elixir's format.

  Furthermore, Elixir's Logger includes many improvements on top
  of Erlang's `error_logger`:

    * Logger adds a new level, specific to Elixir logger,
      named debug.

    * Logger event handler process is watched over which guarantees
      it is restarted in case of crashes.

    * Logger formats messages on the client to avoid clogging
      the logger event manager.

    * Logger truncates error messages to avoid large log messages.

  """

  @type handler :: :tty
  @type level :: :error | :info | :warning | :debug

  @doc false
  def start(_type, _args) do
    import Supervisor.Spec

    children   = [worker(Logger.Watcher, [])]
    options    = [strategy: :one_for_one, name: Logger.Supervisor]
    {:ok, sup} = Supervisor.start_link(children, options)

    tty_was_enabled? =
      case :error_logger.delete_report_handler(:error_logger_tty_h) do
        {:error, :module_not_found} -> false
        _ -> enable(:tty); true
      end

    {:ok, sup, tty_was_enabled?}
  end

  @doc false
  def stop(tty_was_enabled?) do
    :error_logger.tty(tty_was_enabled?)
    # We need to do this in another process as the Application
    # Controller is currently blocked shutting down this app.
    spawn_link(fn -> Logger.Watcher.clear_data end)
    :ok
  end

  @doc """
  Configures the logger.

  See the "Configuration" section in `Logger` module documentation
  for the available options.
  """
  def configure(options) do
    Logger.Watcher.configure(options)
  end

  @doc """
  Logs a message.

  Developers should rather use the macros `Logger.debug/2`,
  `Logger.warn/2`, `Logger.info/2` or `Logger.error/2` instead
  of this function as they automatically include caller metadata.

  Use this function only when there is a need to log dynamically
  or you want to explicitly avoid embedding metadata.
  """
  @spec log(level, IO.chardata, Keyword.t) :: :ok
  def log(level, chardata, metadata \\ [])
      when is_list(metadata) and (is_list(chardata) or is_binary(chardata)) do
    case Logger.Watcher.__data__ do
      {truncate, _} ->
        notify(level, truncate(chardata, truncate), metadata)
      nil ->
        raise "Cannot log messages, the :logger application is not running"
    end
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

  @doc """
  Logs a debug message.
  """
  defmacro debug(chardata, metadata \\ []) do
    quote do
      Logger.log(:debug, unquote(chardata), unquote(metadata))
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

  defp truncate(data, n) do
    Logger.Formatter.truncate(data, n)
  end

  defp notify(:debug, chardata, metadata) do
    send(:error_logger,
      {:debug,
       Process.group_leader(),
       {self(), {Logger, metadata}, chardata}})
    :ok
  end

  defp notify(level, chardata, metadata) do
    GenEvent.notify(:error_logger,
      {level_to_report(level),
       Process.group_leader(),
       {self(), {Logger, metadata}, chardata}})
  end

  defp level_to_report(:warning), do: :warning_report
  defp level_to_report(:error),   do: :error_report
  defp level_to_report(:info),    do: :info_report
end

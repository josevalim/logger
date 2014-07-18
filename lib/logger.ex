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

  ## Configuration

    * `:backends` - the backends to be used. Defaults to `[:tty]`
      only. See the "Backends" section for more information.

    * `:truncate` - the maximum message size to be logged. Defaults
      to 8192 bytes. Note this configuration is approximate. Truncated
      messages will have "(truncated)" at the end.

    * `:handle_otp_reports` - redirects OTP reports to Logger so
      they are formatted in Elixir terms. This uninstalls Erlang's
      logger that prints terms to terminal. This configuration must
      be set before the application starts and defaults to true.

    * `:handle_sasl_reports` - redirects SASL reports to Logger so
      they are formatted in Elixir terms. This uninstalls SASL's
      logger that prints terms to terminal. This configuration must
      be set before the application starts and defaults to true.
      Note for this to work SASL must be started *before* Logger.

  At runtime, `Logger.configure/1` must be used to configure Logger
  options, which guarantees the configuration is serialized and
  properly reloaded.

  ## Backends

  The supported backends are:

    * `:tty` - log entries to the terminal (enabled by default)

  ## Comparison to :error_logger

  Elixir's Logger includes many improvements over OTP's
  `error_logger` as such as:

    * it adds a new log level named debug.

    * it guarantees event handlers are restarted on crash.

    * it formats messages on the client to avoid clogging
      the logger event manager.

    * it truncates error messages to avoid large log messages.

  """

  @type handler :: :tty
  @type level :: :error | :info | :warn | :debug

  @levels [:error, :info, :warn, :debug]

  @doc false
  def start(_type, _args) do
    import Supervisor.Spec

    options  = [strategy: :one_for_one, name: Logger.Supervisor]
    children = [worker(GenEvent, [[name: Logger]]),
                supervisor(Logger.Watcher, []),
                worker(Logger.Config, [])]

    {:ok, sup} = Supervisor.start_link(children, options)

    otp_reports?   = Application.get_env(:logger, :handle_otp_reports)
    sasl_reports?  = Application.get_env(:logger, :handle_sasl_reports)
    reenable_tty?  = delete_error_logger_handler(otp_reports?, :error_logger_tty_h)
    reenable_sasl? = delete_error_logger_handler(sasl_reports?, :sasl_report_tty_h)
    Logger.Watcher.watch(:error_logger, Logger.ErrorHandler, {otp_reports?, sasl_reports?})

    # TODO: Start this based on the backends config
    # TODO: Runtime backend configuration
    Logger.Watcher.watch(Logger, Logger.Backends.TTY, :ok)

    {:ok, sup, {reenable_tty?, reenable_sasl?}}
  end

  @doc false
  def stop({reenable_tty?, reenable_sasl?}) do
    add_error_logger_handler(reenable_tty?, :error_logger_tty_h)
    add_error_logger_handler(reenable_sasl?, :sasl_report_tty_h)

    # We need to do this in another process as the Application
    # Controller is currently blocked shutting down this app.
    spawn_link(fn -> Logger.Config.clear_data end)

    :ok
  end

  defp add_error_logger_handler(was_enabled?, handler) do
    was_enabled? and :error_logger.add_report_handler(handler)
    :ok
  end

  defp delete_error_logger_handler(should_delete?, handler) do
    should_delete? and
      :error_logger.delete_report_handler(handler) != {:error, :module_not_found}
  end

  @doc """
  Configures the logger.

  See the "Configuration" section in `Logger` module documentation
  for the available options.
  """
  def configure(options) do
    Logger.Config.configure(options)
  end

  @doc """
  Logs a message.

  Developers should rather use the macros `Logger.debug/2`,
  `Logger.warn/2`, `Logger.info/2` or `Logger.error/2` instead
  of this function as they automatically include caller metadata.

  Use this function only when there is a need to log dynamically
  or you want to explicitly avoid embedding metadata.
  """
  @spec log(level, IO.chardata | (() -> IO.chardata), Keyword.t) :: :ok
  def log(level, chardata, metadata \\ []) when level in @levels and is_list(metadata) do
    # TODO: Consider log level
    # TODO: Handle async/sync modes
    unless Process.whereis(Logger) do
      raise "Cannot log messages, the :logger application is not running"
    end

    {truncate, _} = Logger.Config.__data__
    notify(level, truncate(chardata, truncate), metadata)
  end

  @doc """
  Logs a warning.

  ## Examples

    Logger.warn "knob turned too much to the right"

  """
  defmacro warn(chardata, metadata \\ []) do
    quote do
      Logger.log(:warn, unquote(chardata), unquote(metadata))
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

  ## Examples

      Logger.debug "hello?"

  """
  defmacro debug(chardata, metadata \\ []) do
    quote do
      Logger.log(:debug, unquote(chardata), unquote(metadata))
    end
  end

  defp truncate(data, n) when is_function(data, 0) do
    Logger.Formatter.truncate(data.(), n)
  end

  defp truncate(data, n) when is_list(data) or is_binary(data) do
    Logger.Formatter.truncate(data, n)
  end

  defp notify(level, chardata, metadata) do
    GenEvent.notify(Logger,
      {level, Process.group_leader(),
        {self(), {Logger, metadata}, chardata}})
  end
end

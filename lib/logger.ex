defmodule Logger do
  use Application

  @moduledoc ~S"""
  A logger for Elixir applications.

  It includes many features:

    * Provides debug, info, warn and error levels.

    * Supports multiple backends which are automatically
      supervised when plugged into Logger.

    * Formats and truncates messages on the client
      to avoid clogging logger backends.

    * Alternates between sync and async modes to keep
      it performant when required but also apply back-
      pressure when under stress.

    * Wraps OTP's error_logger to avoid it from
      overflowing.

  ## Levels

  The supported levels are:

    * `:debug` - for debug-related messages
    * `:info` - for information of any kind
    * `:warn` - for warnings
    * `:error` - for errors

  ## Configuration

  Logger supports a wide range of configuration.

  This configuration is split in three categories:

    * Application configuration - must be set before the logger
      application is started

    * Runtime configuration - can be set before the logger
      application is started but changed during runtime

    * Error logger configuration - configuration for the
      wrapper around OTP's error_logger

  ### Application configuration

  The following configuration must be set via config files
  before the logger application is started.

    * `:backends` - the backends to be used. Defaults to `[:console]`.
      See the "Backends" section for more information.

  ### Runtime Configuration

  All configuration below can be set via the config files but also
  changed dynamically during runtime via `Logger.configure/1`.

    * `:level` - the logging level. Attempting to log any message
      with severity less than the configured level will simply
      cause the message to be ignored. Keep in mind that each backend
      may have its specific level too.

    * `:utc_log` - when true, uses UTC in logs. By default it uses
      local time (i.e. it defaults to false).

    * `:truncate` - the maximum message size to be logged. Defaults
      to 8192 bytes. Note this configuration is approximate. Truncated
      messages will have " (truncated)" at the end.

    * `:sync_threshold` - if the logger manager has more than
      `sync_threshold` messages in its queue, logger will change
      to sync mode, to apply back-pressure to the clients.
      Logger will return to sync mode once the number of messages
      in the queue reduce to `sync_threshold * 0.75` messages.
      Defaults to 20 messages.

  ### Error logger configuration

  The following configuration applies to the Logger wrapper around
  Erlang's error_logger. All the configurations below must be set
  before the logger application starts.

    * `:handle_otp_reports` - redirects OTP reports to Logger so
      they are formatted in Elixir terms. This uninstalls Erlang's
      logger that prints terms to terminal.

    * `:handle_sasl_reports` - redirects SASL reports to Logger so
      they are formatted in Elixir terms. This uninstalls SASL's
      logger that prints terms to terminal as long as the SASL
      application is started before Logger.

    * `:discard_threshold_for_error_logger` - a value that, when
      reached, triggers the error logger to discard messages. This
      value must be a positive number that represents the maximum
      number of messages accepted per second. Once above this
      threshold, the error_logger enters in discard mode for the
      remaining of that second. Defaults to 500 messages.

  ## Backends

  Logger supports different backends where log message are written to.

  The available backends by default are:

    * `:console` - Logs messages to the console (enabled by default)

  Developers may also implement their own backends, an option that
  is explored with detail below.

  The initial backends are loaded via the `:backends` configuration,
  which must be set before the logger application is started. However,
  backends can be added or removed dynamically via the `add_backend/2`,
  `remove_backend/1` and `configure_backend/2` functions.

  ### Console backend

  The console backend logs message to the console. It supports the
  following options:

    * `:level` - the level to be logged by this backend.
      Note though messages are first filtered by the general
      `:level` configuration in `:logger`

    * `:format` - the format message used to print logs.
      Defaults to: "$time $metadata[$level] $message\n"

    * `:metadata` - the metadata to be printed by `$metadata`.
      Defaults to an empty list (no metadata)

  Here is an example on how to configure the `:console` in a
  `config/config.exs` file:

      config :logger, :console,
        format: "$date $time [$level] $metadata$message\n",
        metadata: [:user_id]

  You can read more about formatting in `Logger.Formatter`.

  ### Custom backends

  TODO

  """

  @type level :: :error | :info | :warn | :debug
  @levels [:error, :info, :warn, :debug]

  @doc false
  def start(_type, _args) do
    import Supervisor.Spec

    options  = [strategy: :one_for_one, name: Logger.Supervisor]
    children = [worker(GenEvent, [[name: Logger]]),
                supervisor(Logger.Watcher, [])]

    {:ok, sup} = Supervisor.start_link(children, options)

    # TODO: Start this based on the backends config
    # TODO: Runtime backend configuration
    Logger.Watcher.watch(Logger, Logger.Config, :ok)
    Logger.Watcher.watch(Logger, Logger.Backends.Console, :ok)

    otp_reports?   = Application.get_env(:logger, :handle_otp_reports)
    sasl_reports?  = Application.get_env(:logger, :handle_sasl_reports)
    reenable_tty?  = delete_error_logger_handler(otp_reports?, :error_logger_tty_h)
    reenable_sasl? = delete_error_logger_handler(sasl_reports?, :sasl_report_tty_h)

    threshold = Application.get_env(:logger, :discard_threshold_for_error_logger)
    Logger.Watcher.watch(:error_logger, Logger.ErrorHandler,
      {otp_reports?, sasl_reports?, threshold})

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

  @metadata :logger_metadata

  @doc """
  Adds the given keyword list to the current process metadata.
  """
  def metadata(dict) do
    Process.put(@metadata, dict ++ metadata)
  end

  @doc """
  Reads the current process metadata.
  """
  def metadata() do
    Process.get(@metadata) || []
  end

  @doc """
  Retrieves the logger level.

  The logger level can be changed via `configure/1`.
  """
  @spec level() :: level
  def level() do
    check_logger!
    %{level: level} = Logger.Config.__data__
    level
  end

  @doc """
  Compare log levels.

  Receives to log levels and compares the `left`
  against `right` and returns `:lt`, `:eq` or `:gt`.
  """
  @spec compare_levels(level, level) :: :lt | :eq | :gt
  def compare_levels(level, level), do:
    :eq
  def compare_levels(left, right), do:
    if(level_to_number(left) > level_to_number(right), do: :gt, else: :lt)

  defp level_to_number(:debug), do: 0
  defp level_to_number(:info),  do: 1
  defp level_to_number(:warn),  do: 2
  defp level_to_number(:error), do: 3

  @doc """
  Configures the logger.

  See the "Runtime Configuration" section in `Logger` module
  documentation for the available options.
  """
  def configure(options) do
    Logger.Config.configure(Dict.take(options, [:sync_threshold, :truncate, :level]))
  end

  @doc """
  Configures the given backend.
  """
  def configure_backend(backend, options) do
    GenEvent.call(Logger, translate_backend(backend), {:configure, options})
    :ok
  end

  defp translate_backend(:console), do: Logger.Backends.Console
  defp translate_backend(other),    do: other

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
    check_logger!
    %{mode: mode, truncate: truncate,
      level: min_level, utc_log: utc_log?} = Logger.Config.__data__

    if compare_levels(level, min_level) != :lt do
      tuple = {Logger, truncate(chardata, truncate), Logger.Utils.timestamp(utc_log?),
               [pid: self()] ++ metadata() ++ metadata}
      notify(mode, {level, Process.group_leader(), tuple})
    end

    :ok
  end

  @doc """
  Logs a warning.

  ## Examples

      Logger.warn "knob turned too much to the right"
      Logger.warn fn -> "expensive to calculate warning" end

  """
  defmacro warn(chardata, metadata \\ []) do
    caller = caller_metadata(__CALLER__)
    quote do
      Logger.log(:warn, unquote(chardata), unquote(caller) ++ unquote(metadata))
    end
  end

  @doc """
  Logs some info.

  ## Examples

      Logger.info "mission accomplished"
      Logger.info fn -> "expensive to calculate info" end

  """
  defmacro info(chardata, metadata \\ []) do
    caller = caller_metadata(__CALLER__)
    quote do
      Logger.log(:info, unquote(chardata), unquote(caller) ++ unquote(metadata))
    end
  end

  @doc """
  Logs an error.

  ## Examples

      Logger.error "oops"
      Logger.error fn -> "expensive to calculate error" end

  """
  defmacro error(chardata, metadata \\ []) do
    caller = caller_metadata(__CALLER__)
    quote do
      Logger.log(:error, unquote(chardata), unquote(caller) ++ unquote(metadata))
    end
  end

  @doc """
  Logs a debug message.

  ## Examples

      Logger.debug "hello?"
      Logger.debug fn -> "expensive to calculate debug" end

  """
  defmacro debug(chardata, metadata \\ []) do
    caller = caller_metadata(__CALLER__)
    quote do
      Logger.log(:debug, unquote(chardata), unquote(caller) ++ unquote(metadata))
    end
  end

  defp caller_metadata(%{module: module, function: function, line: line}) do
    [module: module, function: function, line: line]
  end

  defp truncate(data, n) when is_function(data, 0),
    do: Logger.Utils.truncate(data.(), n)
  defp truncate(data, n) when is_list(data) or is_binary(data),
    do: Logger.Utils.truncate(data, n)

  defp notify(:sync, msg),  do: GenEvent.sync_notify(Logger, msg)
  defp notify(:async, msg), do: GenEvent.notify(Logger, msg)

  defp check_logger! do
    unless Process.whereis(Logger) do
      raise "Cannot log messages, the :logger application is not running"
    end
  end
end

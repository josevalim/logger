defmodule Logger.Watcher.Supervisor do
  @moduledoc false

  use Supervisor
  @name Logger.Watch.Supervisor

  def start_link() do
    Supervisor.start_link(__MODULE__, nil, [name: @name])
  end

  def init(nil) do
    otp_reports? = Application.get_env(:logger, :handle_otp_reports)
    threshold    = Application.get_env(:logger, :discard_threshold_for_error_logger)

    handlers =
      for backend <- Application.get_env(:logger, :backends) do
        {Logger, Logger.translate_backend(backend), []}
      end

    delete_handlers = if otp_reports?, do: [:error_logger_tty_h], else: []

    children = [worker(Logger.Watcher, [Logger, Logger.Config, []],
                 [id: Logger.Config, function: :watcher]),
                supervisor(Logger.Watcher, [handlers]),
                worker(Logger.Deleter, [delete_handlers], [restart: :transient]),
                worker(Logger.Watcher,
                  [:error_logger, Logger.ErrorHandler, {otp_reports?, threshold}],
                  [id: Logger.ErrorHandler, function: :watcher])]

    supervise(children, [strategy: :rest_for_one])
  end

end

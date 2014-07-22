defmodule Logger.ErrorHandler do
  use GenEvent

  require Logger

  def init({otp?, sasl?, threshold}) do
    {:ok, %{otp: otp?, sasl: sasl?, threshold: threshold,
            last_length: 0, last_time: :os.timestamp, dropped: 0}}
  end

  ## Handle event

  def handle_event({_type, gl, _msg}, state) when node(gl) != node() do
    {:ok, state}
  end

  def handle_event(event, state) do
    state = check_threshold(state)
    log_event(event, state)
    {:ok, state}
  end

  ## Helpers

  defp log_event({:error, _gl, {pid, format, data}}, %{otp: true}),
    do: log_event(:error, :format, pid, {format, data})
  defp log_event({:error_report, _gl, {pid, :std_error, format}}, %{otp: true}),
    do: log_event(:error, :report, pid, format)

  defp log_event({:warning_msg, _gl, {pid, format, data}}, %{otp: true}),
    do: log_event(:warn, :format, pid, {format, data})
  defp log_event({:warning_report, _gl, {pid, :std_warning, format}}, %{otp: true}),
    do: log_event(:warn, :report, pid, format)

  defp log_event({:info_msg, _gl, {pid, format, data}}, %{otp: true}),
    do: log_event(:info, :format, pid, {format, data})
  defp log_event({:info_report, _gl, {pid, :std_info, format}}, %{otp: true}),
    do: log_event(:info, :report, pid, format)

  defp log_event(_, _state),
    do: :ok

  defp log_event(level, kind, pid, data) do
    %{level: min_level, truncate: truncate} = Logger.Config.__data__

    if Logger.compare_levels(level, min_level) != :lt do
      message = format_event(level, kind, data, truncate)

      # Mode is always async to avoid clogging the error_logger
      GenEvent.notify(Logger,
        {level, Process.group_leader(),
          {Logger, message, Logger.Utils.timestamp(), [pid: ensure_pid(pid)]}})
    end
    :ok
  end

  defp ensure_pid(pid) when is_pid(pid), do: pid
  defp ensure_pid(_), do: self()

  defp check_threshold(%{last_time: last_time, last_length: last_length,
                         dropped: dropped, threshold: threshold} = state) do
    {m, s, _} = current_time = :os.timestamp
    current_length = message_queue_length()

    cond do
      match?({^m, ^s, _}, last_time) and current_length - last_length > threshold ->
        count = drop_messages(current_time, 0)
        %{state | dropped: dropped + count, last_length: message_queue_length()}
      match?({^m, ^s, _}, last_time) ->
        state
      true ->
        if dropped > 0 do
          Logger.warn "Logger dropped #{dropped} OTP/SASL messages as it " <>
                      "exceeded the amount of #{threshold} messages/second"
        end
        %{state | dropped: 0, last_time: current_time, last_length: current_length}
    end
  end

  defp message_queue_length() do
    {:message_queue_len, len} = Process.info(self(), :message_queue_len)
    len
  end

  defp drop_messages({m, s, _} = last_time, count) do
    case :os.timestamp do
      {^m, ^s, _} ->
        receive do
          {:notify, _event} -> drop_messages(last_time, count + 1)
        after
          0 -> count
        end
      _ ->
        count
    end
  end

  defp format_event(_level, :report, format, truncate) do
    Logger.Utils.truncate(Kernel.inspect(format), truncate)
  end

  defp format_event(_level, :format, {format, args}, truncate) do
    {format, args} = Logger.Utils.inspect(format, args, truncate)
    Logger.Utils.truncate(:io_lib.format(format, args), truncate)
  end
end

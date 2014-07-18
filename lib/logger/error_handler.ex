defmodule Logger.ErrorHandler do
  use GenEvent

  # TODO: Make threshold configurable
  def init({otp?, sasl?}) do
    {:ok, %{otp: otp?, sasl: sasl?, threshold: 50,
            messages: 0, last_time: :os.timestamp, dropped: 0}}
  end

  ## Handle event

  def handle_event({_type, gl, _msg}, state) when node(gl) != node() do
    {:ok, state}
  end

  def handle_event(event, state) do
    state = log_event(event, state)
    {:ok, state}
  end

  ## Helpers

  defp log_event({:error, _gl, {_pid, format, data}}, %{otp: true} = state),
    do: log_event(:error, :format, {format, data}, state)
  defp log_event({:error_report, _gl, {_pid, :std_error, format}}, %{otp: true} = state),
    do: log_event(:error, :report, format, state)

  defp log_event({:warning_msg, _gl, {_pid, format, data}}, %{otp: true} = state),
    do: log_event(:warn, :format, {format, data}, state)
  defp log_event({:warning_report, _gl, {_pid, :std_warning, format}}, %{otp: true} = state),
    do: log_event(:warn, :report, format, state)

  defp log_event({:info_msg, _gl, {_pid, format, data}}, %{otp: true} = state),
    do: log_event(:info, :format, {format, data}, state)
  defp log_event({:info_report, _gl, {_pid, :std_info, format}}, %{otp: true} = state),
    do: log_event(:info, :report, format, state)

  defp log_event(_, state),
    do: state

  defp log_event(level, kind, data, state) do
    state = check_threshold(state)
    Logger.log(level, fn -> format_event(level, kind, data) end)
    state
  end

  defp check_threshold(%{messages: messages, threshold: threshold} = state)
      when messages <= threshold do
    %{state | messages: messages + 1}
  end

  defp check_threshold(%{last_time: last_time, dropped: dropped} = state) do
    {m, s, _} = now = :os.timestamp
    case last_time do
      {^m, ^s, _} ->
        count = drop_messages(now, 0)
        %{state | dropped: dropped + count}
      {_, _, _} ->
        if dropped > 0 do
          Logger.warn "Logger dropped #{dropped} OTP/SASL messages that " <>
                      "exceeded the amount of #{state.threshold} messages/second"
        end
        %{state | last_time: now, messages: 1, dropped: 0}
    end
  end

  defp drop_messages(now, count) do
    {m, s, _} = :os.timestamp
    case now do
      {^m, ^s, _} ->
        receive do
          {:notify, _event} -> drop_messages(now, count + 1)
        after
          0 -> count
        end
      _ ->
        count
    end
  end

  defp format_event(_level, :report, format), do: Kernel.inspect(format)
  defp format_event(_level, :format, {format, args}) do
    {format, args} = Logger.Formatter.inspect(format, args)
    :io_lib.format(format, args)
  end
end

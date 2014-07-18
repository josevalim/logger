defmodule Logger.ErrorHandler do
  use GenEvent

  # TODO: Make watermark configurable
  def init({otp?, sasl?}) do
    {:ok, %{otp: otp?, sasl: sasl?, watermark: 50,
            mps: 0, last_time: :os.timestamp}}
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
    state = check_watermark(state)
    Logger.log(level, fn -> format_event(level, kind, data) end)
    state
  end

  defp check_watermark(%{mps: mps, watermark: watermark} = state) when mps <= watermark do
    %{state | mps: mps + 1}
  end

  defp check_watermark(%{last_time: last_time} = state) do
    {m, s, _} = now = :os.timestamp
    case last_time do
      {^m, ^s, _} ->
        # TODO: Drop messages
        state
      {_, _, _} ->
        %{state | last_time: now, mps: 0}
    end
  end

  defp format_event(_level, :report, format), do: Kernel.inspect(format)
  defp format_event(_level, :format, {format, args}) do
    {format, args} = Logger.Formatter.inspect(format, args)
    :io_lib.format(format, args)
  end
end

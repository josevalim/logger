defmodule Logger.Handler do
  use GenEvent

  def init(_) do
    if user = Process.whereis(:user) do
      Process.link(user)
      Process.group_leader(self(), user)
    end

    {:ok, %{handlers: [], user: user}}
  end

  ## Handle call

  def handle_call({:enable, handler}, state) do
    state = update_in(state.handlers, fn handlers ->
      [handler|List.delete(handlers, handler)]
    end)
    {:ok, :ok, state}
  end

  def handle_call({:disable, handler}, state) do
    state = update_in(state.handlers, &List.delete(&1, handler))
    {:ok, :ok, state}
  end

  ## Handle event

  def handle_event({_type, gl, _msg}, state) when node(gl) != node() do
    {:ok, state}
  end

  def handle_event(_, %{handlers: []} = state) do
    {:ok, state}
  end

  def handle_event(event, state) do
    state = log_event(event, state)
    {:ok, state}
  end

  ## Handle info

  def handle_info({:EXIT, user, _reason}, %{user: user} = state) do
    # If the user process is dead, remove :tty from the list of handlers
    {:ok, update_in(state.handlers, &List.delete(&1, :tty))}
  end

  def handle_info(_, state) do
    {:ok, state}
  end

  ## Helpers

  defp log_event({:error, _gl, {pid, format, data}}, state),
    do: log_event(:error, :format, pid, format, data, state)
  defp log_event({:error_report, _gl, {pid, :std_error, format}}, state),
    do: log_event(:error, :report, pid, format, [], state)
  defp log_event({:error_report, _gl, _}, state),
    do: state

  defp log_event({:warning_msg, _gl, {pid, format, data}}, state),
    do: log_event(:warning, :format, pid, format, data, state)
  defp log_event({:warning_report, _gl, {pid, :std_warning, format}}, state),
    do: log_event(:warning, :report, pid, format, [], state)
  defp log_event({:warning_report, _gl, _}, state),
    do: state

  defp log_event({:info_msg, _gl, {pid, format, data}}, state),
    do: log_event(:info, :format, pid, format, data, state)
  defp log_event({:info_report, _gl, {pid, :std_info, format}}, state),
    do: log_event(:info, :report, pid, format, [], state)
  defp log_event({:info_report, _gl, _}, state),
    do: state

  # TODO: Support custom formatters
  # TODO: Support severity
  # TODO: Support high watermark
  defp log_event(severity, kind, pid, format, data, state) do
    formatted = format_event(severity, kind, format, data)
    time = :erlang.universaltime
    for handler <- state.handlers do
      log_event(handler, time, severity, pid, formatted)
    end
    state
  end

  defp format_event(_severity, :report, format, []), do: [Kernel.inspect(format), ?\n]
  defp format_event(_severity, :format, format, args) do
    {format, args} = Logger.Formatter.inspect(format, args)
    :io_lib.format(format, args)
  end

  defp log_event(:tty, time, severity, _pid, formatted) do
    :io.put_chars :user, [format_time(time), ?\s, format_severity(severity), ?\s, formatted]
  end

  defp format_time({{yy, mm, dd}, {hh, mi, ss}}) do
    [pad(yy), ?-, pad(mm), ?-, pad(dd), ?\s, pad(hh), ?:, pad(mi), ?:, pad(ss)]
  end

  defp pad(int) when int < 10, do: [?0, Integer.to_string(int)]
  defp pad(int), do: Integer.to_string(int)

  defp format_severity(:warning), do: "[warning]"
  defp format_severity(:error),   do: "[error]"
  defp format_severity(:info),    do: "[info]"
end

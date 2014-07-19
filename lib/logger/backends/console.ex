defmodule Logger.Backends.Console do
  use GenEvent

  def init(_) do
    # TODO: What happens if user is not available?
    if user = Process.whereis(:user) do
      Process.group_leader(self(), user)
    end
    {:ok, %{}}
  end

  ## Handle event

  def handle_event({_type, gl, _msg}, state) when node(gl) != node() do
    {:ok, state}
  end

  def handle_event({type, _gl, {pid, {Logger, metadata}, message}}, state) do
    log_event(type, pid, message, metadata, state)
    {:ok, state}
  end

  ## Helpers

  # TODO: Add node to report if node(pid) != node()
  # TODO: Support custom formatting (new line is a formatting concern)
  defp log_event(type, _pid, message, _metadata, _state) do
    time = :erlang.universaltime
    :io.put_chars :user, [format_time(time), ?\s, ?[, Atom.to_string(type), ?], ?\s, message, ?\n]
  end

  defp format_time({{yy, mm, dd}, {hh, mi, ss}}) do
    [pad(yy), ?-, pad(mm), ?-, pad(dd), ?\s, pad(hh), ?:, pad(mi), ?:, pad(ss)]
  end

  defp pad(int) when int < 10, do: [?0, Integer.to_string(int)]
  defp pad(int), do: Integer.to_string(int)
end

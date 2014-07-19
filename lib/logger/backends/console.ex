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

  def handle_event({_level, gl, _event}, state) when node(gl) != node() do
    {:ok, state}
  end

  def handle_event({level, _gl, {Logger, message, _timestamp, metadata}}, state) do
    log_event(level, message, metadata, state)
    {:ok, state}
  end

  ## Helpers

  # TODO: Support custom formatting (new line is a formatting concern)
  defp log_event(type, message, _metadata, _state) do
    time = :erlang.universaltime
    :io.put_chars :user, [format_time(time), ?\s, ?[, Atom.to_string(type), ?], ?\s, message, ?\n]
  end

  defp format_time({{yy, mm, dd}, {hh, mi, ss}}) do
    [pad(yy), ?-, pad(mm), ?-, pad(dd), ?\s, pad(hh), ?:, pad(mi), ?:, pad(ss)]
  end

  defp pad(int) when int < 10, do: [?0, Integer.to_string(int)]
  defp pad(int), do: Integer.to_string(int)
end

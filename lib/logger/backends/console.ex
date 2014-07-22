defmodule Logger.Backends.Console do
  use GenEvent

  def init(_) do
    # TODO: What happens if user is not available?
    if user = Process.whereis(:user) do
      Process.group_leader(self(), user)
    end

    format = Application.get_env(:logger, :tty, [])
      |> Dict.get(:formatter, nil)
      |> Logger.Formatter.compile

    {:ok, %{format: format}}
  end

  ## Handle event

  def handle_event({_level, gl, _event}, state) when node(gl) != node() do
    {:ok, state}
  end

  def handle_event({level, _gl, {Logger, message, timestamp, metadata}}, state) do
    log_event(level, timestamp, message, metadata, state)
    {:ok, state}
  end

  ## Helpers
  defp log_event(level, ts, message, metadata, %{format: format}) do
    :io.put_chars :user, Logger.Formatter.format(format, level, ts, message, metadata)
  end
end

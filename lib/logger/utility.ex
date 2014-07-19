defmodule Logger.Utility do
  def local_date_time(), do: timestamp |> format_time
  def timestamp() do
    {_, _, micro} = now = :os.timestamp()
    {date, {hours, minutes, seconds}} = :calendar.now_to_universal_time(now)
    {date, {hours, minutes, seconds, div(micro, 1000) |> rem(1000)}}
  end

  def format_time({{yy, mm, dd}, {hh, mi, ss, ms}}) do
    {[pad(yy), ?-, pad(mm), ?-, pad(dd)], [pad(hh), ?:, pad(mi), ?:, pad(ss), ?:, pad(ms)]}
  end

  def format_time({{yy, mm, dd}, {hh, mi, ss}}) do
    [pad(yy), ?-, pad(mm), ?-, pad(dd), ?\s, pad(hh), ?:, pad(mi), ?:, pad(ss)]
  end

  defp pad(int) when int < 10, do: [?0, Integer.to_string(int)]
  defp pad(int), do: Integer.to_string(int)
end

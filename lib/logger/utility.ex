defmodule Logger.Utility do
  def timestamp() do
    {_, _, micro} = now = :os.timestamp()
    {date, {hours, minutes, seconds}} = :calendar.now_to_universal_time(now)
    {date, {hours, minutes, seconds, div(micro, 1000)}}
  end

  def format_timestamp({date={yy, mm, dd}, time={hh, mi, ss, ms}}) do
    [format_date(date), format_time(time)]
  end


  def format_time({hh, mi, ss, ms}) do
    [pad(hh), ?:, pad(mi), ?:, pad(ss), ?., pad3(ms)]
  end

  def format_date({yy, mm, dd}) do
    [Integer.to_string(yy), ?-, pad(mm), ?-, pad(dd)]
  end

  defp pad3(int) when int < 100 and int > 10, do: [?0, Integer.to_string(int)]
  defp pad3(int) when int < 10, do: [?0, ?0, Integer.to_string(int)]
  defp pad3(int), do: Integer.to_string(int)

  defp pad(int) when int < 10, do: [?0, Integer.to_string(int)]
  defp pad(int), do: Integer.to_string(int)
end

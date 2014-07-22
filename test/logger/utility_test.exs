defmodule Logger.UtilityTest do
  use Logger.Case, async: true
  defp pad(int), do: Logger.Utility.pad(int)
  defp pad3(int), do: Logger.Utility.pad3(int)
  test "pad" do
    assert pad(1) == [?0, "1"]
    assert pad(9) == [?0, "9"]
    assert pad(10) == "10"
  end
  
  test "pad3" do
    assert pad3(1) == [?0, ?0, "1"]
    assert pad3(9) == [?0, ?0, "9"]
    assert pad3(99) == [?0, "99"]
    assert pad3(100) == "100"
  end

  test "format_date" do
    date = {2015, 1, 30}
    assert Logger.Utility.format_date(date) == ["2015", ?-, [?0, "1"], ?-, "30"]
  end

  test "format_time" do
    time = {12, 30, 10, 1}
    assert Logger.Utility.format_time(time) == ["12", ?:, "30", ?:, "10", ?., [?0, ?0, "1"]]
  end
end

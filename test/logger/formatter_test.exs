defmodule Logger.FormatterTest do
  use Logger.Case, async: true
  doctest Logger.Formatter

  import Kernel, except: [inspect: 2]

  defp truncate(arg, n),      do: Logger.Formatter.truncate(arg, n)
  defp inspect(format, args), do: Logger.Formatter.inspect(format, args, 10)

  test "truncate/2" do
    # ASCII binaries
    assert truncate("foo", 4) == "foo"
    assert truncate("foo", 3) == "foo"
    assert truncate("foo", 2) == ["fo", " (truncated)"]

    # UTF-8 binaries
    assert truncate("olá", 2) == ["ol", " (truncated)"]
    assert truncate("olá", 3) == ["ol", " (truncated)"]
    assert truncate("olá", 4) == "olá"
    assert truncate("ááááá:", 10)  == ["ááááá", " (truncated)"]
    assert truncate("áááááá:", 10) == ["ááááá", " (truncated)"]

    # Charlists
    assert truncate('olá', 2) == ['olá', " (truncated)"]
    assert truncate('olá', 3) == ['olá', " (truncated)"]
    assert truncate('olá', 4) == 'olá'

    # Chardata
    assert truncate('ol' ++ "á", 2) == ['ol' ++ "", " (truncated)"]
    assert truncate('ol' ++ "á", 3) == ['ol' ++ "", " (truncated)"]
    assert truncate('ol' ++ "á", 4) == 'ol' ++ "á"
  end

  test "inspect/2 formats" do
    assert inspect('~p', [1])  == {'~ts', [["1"]]}
    assert inspect("~p", [1])  == {'~ts', [["1"]]}
    assert inspect(:"~p", [1]) == {'~ts', [["1"]]}
  end

  test "inspect/2 sigils" do
    assert inspect('~10.10tp', [1]) == {'~ts', [["1"]]}
    assert inspect('~-10.10tp', [1]) == {'~ts', [["1"]]}

    assert inspect('~10.10lp', [1]) == {'~ts', [["1"]]}
    assert inspect('~10.10x~p~n', [1, 2, 3]) == {'~10.10x~ts~n', [1, 2, ["3"]]}
  end

  test "inspect/2 with modifier t has no effect (as it is the default)" do
    assert inspect('~tp', [1]) == {'~ts', [["1"]]}
    assert inspect('~tw', [1]) == {'~ts', [["1"]]}
  end

  test "inspect/2 with modifier l always prints lists" do
    assert inspect('~lp', ['abc']) ==
           {'~ts', [["[", "97", ",", " ", "98", ",", " ", "99", "]"]]}
    assert inspect('~lw', ['abc']) ==
           {'~ts', [["[", "97", ",", " ", "98", ",", " ", "99", "]"]]}
  end

  test "inspect/2 with modifier for width" do
    assert inspect('~5lp', ['abc']) ==
           {'~ts', [["[", "97", ",", "\n ", "98", ",", "\n ", "99", "]"]]}

    assert inspect('~5lw', ['abc']) ==
           {'~ts', [["[", "97", ",", " ", "98", ",", " ", "99", "]"]]}
  end

  test "inspect/2 with modifier for limit" do
    assert inspect('~5lP', ['abc', 2]) ==
           {'~ts', [["[", "97", ",", "\n ", "98", ",", "\n ", "...", "]"]]}

    assert inspect('~5lW', ['abc', 2]) ==
           {'~ts', [["[", "97", ",", " ", "98", ",", " ", "...", "]"]]}
  end

  test "inspect/2 truncates binaries" do
    assert inspect('~ts', ["abcdeabcdeabcdeabcde"]) ==
           {'~ts', ["abcdeabcde"]}

    assert inspect('~ts~ts~ts', ["abcdeabcde", "abcde", "abcde"]) ==
           {'~ts~ts~ts', ["abcdeabcde", "", ""]}
  end


  defp compile(format), do: Logger.Formatter.compile(format)
  defp format(config, l, t, m, md), do: Logger.Formatter.format(config, l, t, m, md)
  test "compile/1 with nil" do
    assert compile(nil) == [:time, " ", :metadata, " [", :level, "] ", :message, "\n"]
  end

  test "compile/1 with str" do
    assert compile("$level $time $date $metadata $message $node") == Enum.intersperse([:level, :time, :date, :metadata, :message, :node], " ")
    assert_raise ArgumentError,"$bad is an invalid format pattern.", fn ->
      compile("$bad $good")
    end
  end

  defmodule CompileMod do
    def format(level, ts, msg, md) do
      true
    end
  end
  test "compile/1 with {mod, fun}" do
    assert compile({CompileMod, :format}) == {CompileMod, :format}
  end

  test "format with {mod, fun}" do
    assert format({CompileMod, :format}, nil, nil, nil,nil) == true
    assert_raise ArgumentError,"#{CompileMod} needs to define blah\4, ex: format(level, ts, msg, meta)", fn ->
      format({CompileMod, :blah}, nil, nil, nil, nil)
    end
  end

  test "format with format string" do
    compiled = compile("[$level] $message")
    assert format(compiled, :error, nil, "hello", []) == ["[", 'error', "] ", "hello"]
    compiled = compile("$metadata")
    assert format(compiled, :error, nil, nil, [meta: :data]) == ["meta=:data"]
  end
end

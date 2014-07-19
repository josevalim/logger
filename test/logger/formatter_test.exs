defmodule Logger.FormatterTest do
  use Logger.Case, async: true

  import Kernel, except: [inspect: 2]
  import Logger.Formatter

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
end

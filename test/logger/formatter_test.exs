defmodule Logger.FormatterTest do
  use ExUnit.Case, async: true

  import Kernel, except: [inspect: 2]
  import Logger.Formatter

  test "inspect/2 formats" do
    assert inspect('~p', [1]) == {'~ts', ["1"]}
    assert inspect("~p", [1]) == {'~ts', ["1"]}
    assert inspect(:"~p", [1]) == {'~ts', ["1"]}
  end

  test "inspect/2 sigils" do
    assert inspect('~10.10tp', [1]) == {'~ts', ["1"]}
    assert inspect('~-10.10tp', [1]) == {'~ts', ["1"]}

    assert inspect('~10.10lp', [1]) == {'~ts', ["1"]}
    assert inspect('~10.10x~p~n', [1, 2, 3]) == {'~10.10x~ts~n', [1, 2, "3"]}
  end

  test "inspect/2 with modifier t has no effect (as it is the default)" do
    assert inspect('~tp', [1]) == {'~ts', ["1"]}
    assert inspect('~tw', [1]) == {'~ts', ["1"]}
  end

  test "inspect/2 with modifier l always prints lists" do
    assert inspect('~lp', ['abc']) == {'~ts', ["[97, 98, 99]"]}
    assert inspect('~lw', ['abc']) == {'~ts', ["[97, 98, 99]"]}
  end

  test "inspect/2 with modifier for width" do
    assert inspect('~5lp', ['abc']) == {'~ts', ["[97,\n 98,\n 99]"]}
    assert inspect('~5lw', ['abc']) == {'~ts', ["[97, 98, 99]"]}
  end

  test "inspect/2 with modifier for limit" do
    assert inspect('~5lP', ['abc', 2]) == {'~ts', ["[97,\n 98,\n ...]"]}
    assert inspect('~5lW', ['abc', 2]) == {'~ts', ["[97, 98, ...]"]}
  end
end

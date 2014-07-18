defmodule Logger.HandlerTest do
  use Logger.Case

  test "survives after crashes" do
    assert error_log(:info_msg, "~p~n", []) == ""
    wait_for_handler()
    assert error_log(:info_msg, "~p~n", [:hello]) =~ regex("[info] :hello\n")
  end

  ## Elixir formatting

  test "formats logger messages" do
    assert log(:info, "hello") =~ regex("[info] hello")
    assert log(:debug, "hello") =~ regex("[debug] hello")
    assert log(:error, "hello") =~ regex("[error] hello")
    assert log(:warning, "hello") =~ regex("[warning] hello")
  end

  ## Erlang formatting

  test "truncates messages" do
    Logger.configure(truncate: 4)
    assert error_log(:info_msg, "hello", []) =~ regex("[info] hell (truncated)")
  after
    Logger.configure(truncate: 8096)
  end

  test "formats error_logger info message" do
    assert error_log(:info_msg, "hello", []) =~ regex("[info] hello")
    assert error_log(:info_msg, "~p~n", [:hello]) =~ regex("[info] :hello\n")
  end

  test "formats error_logger info report" do
    assert error_log(:info_report, "hello") =~ regex("[info] \"hello\"")
    assert error_log(:info_report, :hello) =~ regex("[info] :hello\n")
    assert error_log(:info_report, :special, :hello) == ""
  end

  test "formats error_logger error message" do
    assert error_log(:error_msg, "hello", []) =~ regex("[error] hello")
    assert error_log(:error_msg, "~p~n", [:hello]) =~ regex("[error] :hello\n")
  end

  test "formats error_logger error report" do
    assert error_log(:error_report, "hello") =~ regex("[error] \"hello\"")
    assert error_log(:error_report, :hello) =~ regex("[error] :hello\n")
    assert error_log(:error_report, :special, :hello) == ""
  end

  test "formats error_logger warning message" do
    # Warnings by default are logged as errors by Erlang
    assert error_log(:warning_msg, "hello", []) =~ regex("[error] hello")
    assert error_log(:warning_msg, "~p~n", [:hello]) =~ regex("[error] :hello\n")
  end

  test "formats error_logger warning report" do
    # Warnings by default are logged as errors by Erlang
    assert error_log(:warning_report, "hello") =~ regex("[error] \"hello\"")
    assert error_log(:warning_report, :hello) =~ regex("[error] :hello\n")
    assert error_log(:warning_report, :special, :hello) == ""
  end

  defp regex(msg) do
    ~r/^\d\d\d\d\-\d\d\-\d\d \d\d:\d\d:\d\d #{Regex.escape(msg)}$/
  end

  defp log(level, message) do
    capture_log(fn -> Logger.log(level, message) end)
  end

  defp error_log(fun, format) do
    do_error_log(fun, [format])
  end

  defp error_log(fun, format, args) do
    do_error_log(fun, [format, args])
  end

  defp do_error_log(fun, args) do
    capture_log(fn -> apply(:error_logger, fun, args) end)
  end
end
defmodule Logger.HandlerTest do
  use ExUnit.Case

  import ExUnit.CaptureIO

  test "formats error_logger info message" do
    assert error_logger(:info_msg, "hello", []) =~ regex("[info] hello")
    assert error_logger(:info_msg, "~p~n", [:hello]) =~ regex("[info] :hello\n")
  end

  test "formats error_logger info report" do
    assert error_logger(:info_report, "hello") =~ regex("[info] \"hello\"")
    assert error_logger(:info_report, :hello) =~ regex("[info] :hello\n")
    assert error_logger(:info_report, :special, :hello) == ""
  end

  test "formats error_logger error message" do
    assert error_logger(:error_msg, "hello", []) =~ regex("[error] hello")
    assert error_logger(:error_msg, "~p~n", [:hello]) =~ regex("[error] :hello\n")
  end

  test "formats error_logger error report" do
    assert error_logger(:error_report, "hello") =~ regex("[error] \"hello\"")
    assert error_logger(:error_report, :hello) =~ regex("[error] :hello\n")
    assert error_logger(:error_report, :special, :hello) == ""
  end

  test "formats error_logger warning message" do
    # Warnings by default are logged as errors by Erlang
    assert error_logger(:warning_msg, "hello", []) =~ regex("[error] hello")
    assert error_logger(:warning_msg, "~p~n", [:hello]) =~ regex("[error] :hello\n")
  end

  test "formats error_logger warning report" do
    # Warnings by default are logged as errors by Erlang
    assert error_logger(:warning_report, "hello") =~ regex("[error] \"hello\"")
    assert error_logger(:warning_report, :hello) =~ regex("[error] :hello\n")
    assert error_logger(:warning_report, :special, :hello) == ""
  end

  defp regex(msg) do
    ~r/^\d\d\d\d\-\d\d\-\d\d \d\d:\d\d:\d\d #{Regex.escape(msg)}$/
  end

  defp error_logger(fun, format) do
    do_error_logger(fun, [format])
  end

  defp error_logger(fun, format, args) do
    do_error_logger(fun, [format, args])
  end

  defp do_error_logger(fun, args) do
    capture_io(:user, fn ->
      apply(:error_logger, fun, args)
      :error_logger.tty(true) # Wait until the message is printed
    end)
  end
end
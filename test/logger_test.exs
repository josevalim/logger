defmodule LoggerTest do
  use Logger.Case
  require Logger

  test "level/0" do
    assert Logger.level == :debug
  end

  test "compare_levels/2" do
    assert Logger.compare_levels(:debug, :debug) == :eq
    assert Logger.compare_levels(:debug, :info)  == :lt
    assert Logger.compare_levels(:debug, :warn)  == :lt
    assert Logger.compare_levels(:debug, :error) == :lt

    assert Logger.compare_levels(:info, :debug) == :gt
    assert Logger.compare_levels(:info, :info)  == :eq
    assert Logger.compare_levels(:info, :warn)  == :lt
    assert Logger.compare_levels(:info, :error) == :lt

    assert Logger.compare_levels(:warn, :debug) == :gt
    assert Logger.compare_levels(:warn, :info)  == :gt
    assert Logger.compare_levels(:warn, :warn)  == :eq
    assert Logger.compare_levels(:warn, :error) == :lt

    assert Logger.compare_levels(:error, :debug) == :gt
    assert Logger.compare_levels(:error, :info)  == :gt
    assert Logger.compare_levels(:error, :warn)  == :gt
    assert Logger.compare_levels(:error, :error) == :eq
  end

  test "debug/2" do
    assert capture_log(fn ->
      assert Logger.debug("hello", []) == :ok
    end) =~ msg("[debug] hello")

    assert capture_log(:info, fn ->
      assert Logger.debug("hello", []) == :ok
    end) == ""
  end

  test "info/2" do
    assert capture_log(fn ->
      assert Logger.info("hello", []) == :ok
    end) =~ msg("[info] hello")

    assert capture_log(:warn, fn ->
      assert Logger.info("hello", []) == :ok
    end) == ""
  end

  test "warn/2" do
    assert capture_log(fn ->
      assert Logger.warn("hello", []) == :ok
    end) =~ msg("[warn] hello")

    assert capture_log(:error, fn ->
      assert Logger.warn("hello", []) == :ok
    end) == ""
  end

  test "error/2" do
    assert capture_log(fn ->
      assert Logger.error("hello", []) == :ok
    end) =~ msg("[error] hello")
  end

  test "log/2 truncates messages" do
    Logger.configure(truncate: 4)
    assert capture_log(fn ->
      Logger.log(:debug, "hello")
    end) =~ "hell (truncated)"
  after
    Logger.configure(truncate: 8096)
  end

  test "log/2 fails when the application is off" do
    logger = Process.whereis(Logger)
    Process.unregister(Logger)

    try do
      assert_raise RuntimeError,
                   "Cannot log messages, the :logger application is not running", fn ->
        Logger.log(:debug, "hello")
      end
    after
      Process.register(logger, Logger)
    end
  end

  test "Logger.Config survives Logger exit" do
    Process.whereis(Logger)
      |> Process.exit(:kill)
    wait_for_logger()
    wait_for_handler(Logger, Logger.Config)
  end
end

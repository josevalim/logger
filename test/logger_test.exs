defmodule LoggerTest do
  use Logger.Case
  require Logger

  test "warn/2" do
    assert capture_log(fn ->
      assert Logger.warn("hello", []) == :ok
    end) =~ msg("[warn] hello")
  end

  test "error/2" do
    assert capture_log(fn ->
      assert Logger.error("hello", []) == :ok
    end) =~ msg("[error] hello")
  end

  test "info/2" do
    assert capture_log(fn ->
      assert Logger.info("hello", []) == :ok
    end) =~ msg("[info] hello")
  end

  test "debug/2" do
    assert capture_log(fn ->
      assert Logger.debug("hello", []) == :ok
    end) =~ msg("[debug] hello")
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
end

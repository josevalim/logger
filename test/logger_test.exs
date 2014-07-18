defmodule LoggerTest do
  use Logger.Case

  require Logger

  test "log/2 truncates messages" do
    Logger.configure(truncate: 4)
    assert capture_log(fn ->
      Logger.log(:debug, "hello")
    end) =~ "hell (truncated)"
  after
    Logger.configure(truncate: 8096)
  end

  test "log/2 fails when the application is off" do
    capture_log fn -> Application.stop(:logger) end
    assert_raise RuntimeError,
                 "Cannot log messages, the :logger application is not running", fn ->
      Logger.log(:debug, "hello")
    end
  after
    Application.start(:logger)
    wait_for_handler()
  end

  test "warn/2" do
    capture_log fn ->
      assert Logger.warn("warning", []) == :ok
    end
  end

  test "error/2" do
    capture_log fn ->
      assert Logger.error("error", []) == :ok
    end
  end

  test "info/2" do
    capture_log fn ->
      assert Logger.info("info", []) == :ok
    end
  end

  test "debug/2" do
    capture_log fn ->
      assert Logger.debug("debug", []) == :ok
    end
  end
end

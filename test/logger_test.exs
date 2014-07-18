defmodule LoggerTest do
  use Logger.Case

  require Logger

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

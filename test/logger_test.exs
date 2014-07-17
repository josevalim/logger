defmodule LoggerTest do
  use ExUnit.Case

  require Logger

  test "warn/2" do
    assert Logger.warn("warning", []) == :ok
  end

  test "error/2" do
    assert Logger.error("error", []) == :ok
  end

  test "info/2" do
    assert Logger.info("info", []) == :ok
  end
end

defmodule Logger.Backends.ConsoleTest do
  use Logger.Case
  require Logger

  setup do
    on_exit fn ->
      :ok = Logger.configure_backend(:console, [format: nil, level: nil, metadata: []])
    end
  end

  test "can configure format" do
    Logger.configure_backend(:console, format: "$message [$level]")

    assert capture_log(fn ->
      Logger.debug("hello")
    end) =~ "hello [debug]"
  end

  test "can configure metadata" do
    Logger.configure_backend(:console, format: "$metadata$message", metadata: [:user_id])

    assert capture_log(fn ->
      Logger.debug("hello")
    end) =~ "hello"

    Logger.metadata(user_id: 13)

    assert capture_log(fn ->
      Logger.debug("user_id=13 hello")
    end) =~ "hello"
  end

  test "can configure level" do
    Logger.configure_backend(:console, level: :info)

    assert capture_log(fn ->
      Logger.debug("hello")
    end) == ""
  end
end
defmodule Logger.TranslatorTest do
  use Logger.Case

  defmodule MyGenServer do
    use GenServer

    def handle_call(:error, _, _) do
      raise "oops"
    end
  end

  test "translates GenServer crashes" do
    {:ok, pid} = GenServer.start(MyGenServer, :ok)

    assert capture_log(:info, fn ->
      catch_exit(GenServer.call(pid, :error))
    end) =~ """
    [error] GenServer #{inspect pid} terminating
    ** (exit) an exception was raised:
        ** (RuntimeError) oops
    """
  end

  test "translates GenServer crashes on debug" do
    {:ok, pid} = GenServer.start(MyGenServer, :ok)

    assert capture_log(:debug, fn ->
      catch_exit(GenServer.call(pid, :error))
    end) =~ """
    [error] GenServer #{inspect pid} terminating
    Last message: :error
    State: :ok
    ** (exit) an exception was raised:
        ** (RuntimeError) oops
    """
  end
end

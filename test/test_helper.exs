ExUnit.start()

defmodule Logger.Case do
  use ExUnit.CaseTemplate
  import ExUnit.CaptureIO

  using _ do
    quote do
      import Logger.Case
    end
  end

  def wait_for_handler() do
    if Logger.Handler in GenEvent.which_handlers(:error_logger) do
      # TODO: We should not need this. We need to store
      # the handler data somewhere so it is able to recover.
      GenEvent.call(:error_logger, Logger.Handler, {:enable, :tty})
    else
      :timer.sleep(10)
      wait_for_handler()
    end
  end

  def capture_log(fun) do
    capture_io(:user, fn ->
      fun.()
      :gen_event.which_handlers(:error_logger)
    end)
  end
end

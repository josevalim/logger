ExUnit.start()

defmodule Logger.Case do
  use ExUnit.CaseTemplate
  import ExUnit.CaptureIO

  using _ do
    quote do
      import Logger.Case
    end
  end

  def capture_log(fun) do
    capture_io(:user, fn ->
      fun.()
      :gen_event.which_handlers(:error_logger)
    end)
  end
end

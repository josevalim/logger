ExUnit.start()

defmodule Logger.Case do
  use ExUnit.CaseTemplate
  import ExUnit.CaptureIO

  using _ do
    quote do
      import Logger.Case
    end
  end

  def msg(msg) do
    ~r/^\d\d\d\d\-\d\d\-\d\d \d\d:\d\d:\d\d #{Regex.escape(msg)}$/
  end

  def wait_for_handler() do
    unless Logger.ErrorHandler in GenEvent.which_handlers(:error_logger) do
      :timer.sleep(10)
      wait_for_handler()
    end
  end

  def capture_log(fun) do
    capture_io(:user, fn ->
      fun.()
      GenEvent.which_handlers(:error_logger)
      GenEvent.which_handlers(Logger)
    end)
  end
end

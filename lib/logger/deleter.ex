defmodule Logger.Deleter do
  @moduledoc false

  def start_link([]), do: :ignore

  def start_link(handlers) do
    :proc_lib.start_link(__MODULE__, :init, [self(), handlers])
  end

  def init(parent, handlers) do
    delete_handlers(handlers)
    :proc_lib.init_ack(parent, :ignore)
  end

  defp delete_handlers(handlers) do
    Enum.each(handlers, &delete_handler/1)
  end

  defp delete_handler(handler) do
    case :error_logger.delete_report_handler(handler) do
      {:error, :module_not_found} ->
        :ok
      _other ->
        put_handler(handler)
    end
  end

  defp put_handler(handler) do
    handlers = Application.get_env(:logger, :deleted_handlers)
    handlers = HashSet.put(handlers, handler)
    Application.put_env(:logger, :deleted_handlers, handlers)
  end

end

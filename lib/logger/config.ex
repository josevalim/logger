defmodule Logger.Config do
  @moduledoc false

  use GenServer

  @name __MODULE__
  @data :__data__

  def start_link do
    GenServer.start_link(__MODULE__, :ok, name: @name)
  end

  def configure(options) do
    GenServer.call(@name, {:configure, options})
  end

  def __data__() do
    Application.get_env(:logger, @data)
  end

  def clear_data() do
    Application.delete_env(:logger, @data)
  end

  ## Callbacks

  def init(:ok) do
    recompute_data()
    {:ok, %{}}
  end

  def handle_call({:configure, options}, _from, state) do
    Enum.each options, fn {key, value} ->
      Application.put_env(:logger, key, value)
    end
    recompute_data()
    {:reply, :ok, state}
  end

  ## Helpers

  defp recompute_data() do
    truncate  = Application.get_env(:logger, :truncate, 8096)
    log_level = nil # For now
    Application.put_env(:logger, @data, {truncate, log_level})
  end
end

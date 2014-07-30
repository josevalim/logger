defmodule Logger.ReloaderTest do
  use Logger.Case
  require Logger

  setup do
    on_exit(
      fn() ->
        # Reset so one failed test won't break others
        _ = Application.stop(:logger)
        :ok = Application.unload(:logger)
        # load will set default configs
        :ok = Application.load(:logger)
        :ok = Application.start(:logger)
      end)
    :ok
  end

  test "reload/0 add and removes backend" do
    backends = Application.get_env(:logger, :backends, [])
    Application.put_env(:logger, :backends, [])

    assert :ok = Logger.Reloader.reload()

    assert capture_log(fn ->
      assert Logger.debug("hello", []) == :ok
    end) == ""

    Application.put_env(:logger, :backends, backends)

    assert :ok = Logger.Reloader.reload()

    assert capture_log(fn ->
      assert Logger.debug("hello", []) == :ok
    end) =~ msg("[debug] hello")

  end

  test "reload/0 changes config" do
    truncate = Application.get_env(:logger, :truncate, 8096)
    Application.put_env(:logger, :truncate, 4)

    assert :ok = Logger.Reloader.reload()

    assert capture_log(fn ->
      assert Logger.debug("hello", []) == :ok
    end) =~ msg("[debug] hell (truncated)")

    Application.put_env(:logger, :truncate, truncate)

    assert :ok = Logger.Reloader.reload()

    assert capture_log(fn ->
      assert Logger.debug("hello", []) == :ok
    end) =~ msg("[debug] hello")

  end

  test "reload/0 starts and stops handle_otp_reports" do
    otp_reports? = Application.get_env(:logger, :handle_otp_reports, true)
    Application.put_env(:logger, :handle_otp_reports, false)

    assert :ok = Logger.Reloader.reload()

    assert capture_log(fn ->
      assert :error_logger.info_msg('hello') == :ok
    end) == ""

    Application.put_env(:logger, :handle_otp_reports, :true)

    assert :ok = Logger.Reloader.reload()

    assert capture_log(fn ->
      assert :error_logger.info_msg('hello') == :ok
    end) =~ msg("[info] hello")

    Application.put_env(:logger, :handle_otp_reports, otp_reports?)

  end

  test "reload/0 add tty handler on stop if deleted" do
    refute Enum.member?(GenEvent.which_handlers(:error_logger), :error_logger_tty_h)
    Application.stop(:logger)
    assert Enum.member?(GenEvent.which_handlers(:error_logger), :error_logger_tty_h)

    Application.put_env(:logger, :handle_otp_reports, false)
    :ok = Application.start(:logger)
    assert Enum.member?(GenEvent.which_handlers(:error_logger), :error_logger_tty_h)

    :ok = Application.stop(:logger)
    assert Enum.member?(GenEvent.which_handlers(:error_logger), :error_logger_tty_h)

    Application.start(:logger)
    Application.put_env(:logger, :handle_otp_reports, true)
    assert :ok = Logger.Reloader.reload()

    assert :ok = Application.stop(:logger)
    assert Enum.member?(GenEvent.which_handlers(:error_logger), :error_logger_tty_h)

  end

  test "reload/0 with bad config crashes logger" do
    Application.put_env(:logger, :backends, nil)
    catch_exit(Logger.Reloader.reload())
    # wait for restart limits to be exceeded and logger exit
    :timer.sleep(500)
    refute Enum.any?(:application.which_applications(), &(elem(&1, 0) == :logger))
  end

end

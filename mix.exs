defmodule Logger.Mixfile do
  use Mix.Project

  def project do
    [app: :logger,
     version: "0.4.0",
     elixir: "~> 0.15.0-dev",
     deps: deps]
  end

  # Configuration for the OTP application
  #
  # Type `mix help compile.app` for more information
  def application do
    [applications: [],
     mod: {Logger, []},
     env: [level: :debug,
           utc_log: false,
           truncate: 8096,
           backends: [:console],
           translators: [{Logger.Translator, :translate}],
           sync_threshold: 20,
           handle_otp_reports: true,
           compile_time_purge_level: :debug,
           discard_threshold_for_error_logger: 500,
           console: []]]
  end

  # Dependencies can be hex.pm packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1"}
  #
  # Type `mix help deps` for more examples and options
  defp deps do
    []
  end
end

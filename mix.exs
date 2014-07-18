defmodule Logger.Mixfile do
  use Mix.Project

  def project do
    [app: :logger,
     version: "0.2.0-dev",
     elixir: "~> 0.14.3",
     deps: deps]
  end

  # Configuration for the OTP application
  #
  # Type `mix help compile.app` for more information
  def application do
    [applications: [],
     mod: {Logger, []},
     env: [truncate: 8096,
           backends: [:tty],
           handle_otp_reports: true,
           handle_sasl_reports: true]]
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

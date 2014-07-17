Logger
======

The goal of this project is to explore a Logger implementation that will be included in Elixir. One of the big influences for this project is [Lager](https://github.com/basho/lager) and [Andrew's talk on the matter](http://www.youtube.com/watch?v=8BNpOHFvg_Q).

Obviously, one of the first questions may be: why not Lager? We need a project that knows how to log terms in Elixir syntax, in particular, using the `Inspect` protocol. That's why the focus of this project is on the error handler and not on the error logger itself.

By default `Logger` will run on top of OTP's `error_logger` and we will include an API that mostly wraps the `error_logger` one. However we hope this project provides the proper API so someone can easily implement an elixir handler for Lager too.

## Installation

Add `:logger` as a dependency to your `mix.exs` file:

```elixir
defp deps do
  [{:logger, github: "josevalim/logger"}]
end
```

You should also update your application list to include `:logger`:

```elixir
def application do
  [applications: [:logger]]
end
```

Logger is not published on Hex as we intend to merge it into Elixir before 1.0.

## Features

Below we detail the features we plan to include in the short-term, long-term or when it does not apply.

Short-term features (before 1.0):

  * *done* A `Logger` module to log warning, info and error messages.
  * *done* A backend that can print log messages using Elixir terms.
  * *done* A watcher to ensure the handler is registered even if it crashes.
  * Extensions to the `Inspect` protocol to allow us to customize the maximum data size in bytes (so we never try to log a binary of 100MB).
  * An error handler that supports high watermark (as seen in Lager) to limit the amount of messages we print per second (so we never bring the node down due to excessive messages, see [cascading-failures](https://github.com/ferd/cascading-failures)).
  * Error translators, so we can translate GenServer and other OTP errors into something more palatable.
  * Custom formatting, so we can change the format of logging or add ANSI colors.
  * A way to lazily calculate the log messages to avoid generating expensive log messages that won't be used.

Long-term features (after 1.0):

  * Print SASL reports.
  * Logging to files and log rotation.
  * Metadata (like file, line and module) and tracing.
  * Switching between sync and async modes.
  * Support a logger that redirects messages for testing.

The following features won't be supported to stay closer to Erlang's logger:

  * New warnings levels.

Notice it is unclear what the `Logger` module API will look like for now. We could implement the logging functionality with macros but it is unclear how well it would play with the configuration system. We also need remember to keep the API extensible for future features coming in the mid-term, like metadata.

## LICENSE

This project is under the same LICENSE as Elixir.

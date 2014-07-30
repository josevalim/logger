Logger
======

**Note: this project has been merged into Elixir and is available since v0.15.0**

The goal of this project is to explore a Logger implementation that will be included in Elixir. One of the big influences for this project is [Lager](https://github.com/basho/lager) and [Andrew's talk on the matter](http://www.youtube.com/watch?v=8BNpOHFvg_Q).

Obviously, one of the first questions may be: why not Lager? We need a project that knows how to log terms in Elixir syntax, in particular, using the `Inspect` protocol. That's why the focus of this project is on the error handler and not on the error logger itself.

By default `Logger` will run on top of OTP's `error_logger` and we will include an API that mostly wraps the `error_logger` one.

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
  * *done* Data truncation so we never try to log a message of megabytes of size.
  * *done* A way to lazily calculate the log messages to avoid generating expensive log messages that won't be used.
  * *done* An error handler that supports a threshold (as seen in Lager) to limit the amount of messages we print per second (so we never bring the node down due to excessive messages, see [cascading-failures](https://github.com/ferd/cascading-failures)).
  * *done* Switching between sync and async modes.
  * *done* Custom formatting.
  * *done* Metadata (via options and process dictionary).
  * *done* Error translators, so we can translate GenServer and other OTP errors into something more palatable.
  * *done* Custom backends.

Long-term features (after 1.0):

  * SASL reports.
  * Logging to files and log rotation.
  * Tracing.

## LICENSE

This project is under the same LICENSE as Elixir.

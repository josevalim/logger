Logger
======

The goal of this project is to explore a Logger implementation that will be included in Elixir. One of the big influences for this project is [Lager](https://github.com/basho/lager) and [Andrew's talk on the matter](http://www.youtube.com/watch?v=8BNpOHFvg_Q).

Obviously, one of the first questions may be: why not Lager? We need a project that knows how to log terms in Elixir syntax, in particular, using the `Inspect` protocol. That's why the focus of this project is on the error handler and not on the error logger itself.

By default `Logger` will run on top of OTP's `error_logger` and we will include an API that mostly wraps the `error_logger` one. However we hope this project provides the proper API so someone can easily implement an elixir handler for Lager too.

## Features

Below we detail the features we plan to include in the short-term, long-term or when it does not apply.

Short-term features (before 1.0):

  * A `Logger` module to log warning, info and error messages.
  * Extensions to the `Inspect` protocol to allow us to customize the maximum data size in bytes (so we never try to log a binary of 100MB).
  * An `IO.format/2` function that understands Erlang's `io:format/2` formats.
  * An error handler that supports high watermark (as seen in Lager) to limit the amount of messages we print per second (so we never bring the node down due to excessive messages, see [cascading-failures](https://github.com/ferd/cascading-failures)).

Long-term features (after 1.0):

  * Error translators, so we can translate GenServer and other OTP errors into something more palatable.
  * Custom formatting, so we can change the format of logging or add ANSI colors.
  * Logging to files and log rotation.
  * Metadata (like file, line and module) and tracing, the existing logging format used by the error logger may allow us to pass metadata into the logger and therefore support tracing.

The following features existing in Lager cannot be supported because we are just wrapping Erlang's `error_logger`:

  * Switching between sync and async modes.
  * New warnings levels.

Notice it is unclear what the `Logger` module API will look like for now. We could implement the logging functionality with macros but it is unclear how well it would play with the configuration system. We also need remember to keep the API extensible for future features coming in the mid-term, like metadata.

## LICENSE

This project is under the same LICENSE as Elixir.

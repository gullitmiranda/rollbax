# Rollbax [![Build Status](https://travis-ci.org/elixir-addicts/rollbax.svg?branch=master "Build Status")](https://travis-ci.org/elixir-addicts/rollbax)

This is an Elixir client for the Rollbar service.

## Installation

Add Rollbax as a dependency to your `mix.exs` file:

```elixir
def application() do
  [applications: [:rollbax]]
end

defp deps() do
  [{:rollbax, "~> 0.5"}]
end
```

Then run `mix deps.get` in your shell to fetch the dependencies.

### Configuration

It requires `access_token` and `environment` parameters to be set
in your application environment, usually defined in your `config/config.exs`:

```elixir
config :rollbax,
  access_token: "ffb8056a621f309eeb1ed87fa0c7",
  environment: "production"
```

## Usage

```elixir
try do
  DoesNotExist.for_sure()
rescue
  exception ->
    Rollbax.report(exception, System.stacktrace())
end
```

### Notifier for Logger

There is a Logger backend to send logs to the Rollbar,
which could be configured as follows:

```elixir
config :logger,
  backends: [Rollbax.Notifier]

config :logger, Rollbax.Notifier,
  level: :error
```

The Rollbax log sending can be disabled by using Logger metadata:

```elixir
Logger.metadata(rollbar: false)
# For a single call
Logger.error("oops", rollbar: false)
```

### Non-production reporting

For non-production environments error reporting
can be disabled or turned into logging:

```elixir
config :rollbax, enabled: :log
```

### Tests (with [azk](http://azk.io)):

Requirements:

  - Install [azk](http://docs.azk.io/en/installation/)

Run tests:

```shell
$ azk shell -- mix test
```

## License

This software is licensed under [the ISC license](LICENSE).

defmodule Rollbax do
  use Application

  @moduledoc """
    This module contains the report and context function you can use in
    your applications.

    ### Configuring
    By default the ROLLBAX_ACCESS_TOKEN environment variable is used to find
    your API key for Rollbax. You can also manually set your API key by
    configuring the :rollbax application. You can see the default
    configuration in the default_config/0 private function at the bottom of
    this file.

        config :rollbax,
          access_token: "token",
          hostname:     "myserver.domain.com",
          origin:       "https://api.rollbar.com/api/1",
          project_root: System.cwd,
          enabled:      true,
          environment:  :development,

  ### Using the Plug
  If you're using Phoenix, or any Plug-based Elixir web framework, you can
  `use` the Rollbax.Plug module in your Router and all exceptions in web
  requests will automatically be reported to Rollbax.

      defmodule MoneyPrinter.Router do
        use MoneyPrinter.Web, :router
        use Rollbax.Plug
      end

  You can also automatically set useful context on every request by defining
  a Plug compatible function:

      defmodule MoneyPrinter.Router do
        use MoneyPrinter.Web, :router
        use Rollbax.Plug

        plug :set_rollbax_context

        # your routes

        defp set_rollbax_context(conn, _opts) do
          user = get_user(conn)
          Rollbax.context(user_id: user.id, account: user.account)
          conn
        end
      end
  """
  @context :rollbax_context

  @doc """
    This is here as a callback to Application to configure and start the
    Rollbax client's dependencies. You'll likely never need to call this
    function yourself.
  """
  def start(_type, _args) do
    import Supervisor.Spec

    config = parse_config

    children = [
      worker(Rollbax.Client, [config])
    ]

    Supervisor.start_link(children, strategy: :one_for_one)
  end

  def parse_config(opts \\ []) do
    otp_app    = Keyword.get(opts, :otp_app) || :rollbax
    app_config = Application.get_all_env(otp_app)

    config = default_config
      |> Keyword.merge(app_config)
      |> Keyword.merge(opts)
      |> Keyword.put(:otp_app, otp_app)

    if (!Keyword.get(config, :access_token)) do
      raise ArgumentError, "the configuration parameter :access_token is not set"
    end

    config
  end

  defp default_config do
    [
      access_token: System.get_env("ROLLBAX_ACCESS_TOKEN"),
      hostname:     System.get_env("ROLLBAX_HOSTNAME") || (:inet.gethostname |> elem(1) |> List.to_string),
      origin:       "https://api.rollbar.com/api/1",
      project_root: System.cwd,
      enabled:      true,
      environment:  nil
    ]
  end

  def report(exception, stacktrace, meta \\ %{} , occurr_data \\ %{}, module_name \\ Rollbax.Client)
  when is_list(stacktrace) and is_map(meta) and is_map(occurr_data) do
    message = Exception.format(:error, exception, stacktrace)
    meta = Map.put(meta, :rollbax_occurr_data, occurr_data)
    Rollbax.Client.emit(:error, message, meta, module_name)
  end

  def context do
    (Process.get(@context) || %{}) |> Enum.into(Map.new)
  end

  def context(dict) do
    Process.put(@context, Dict.merge(context, dict))
  end
end

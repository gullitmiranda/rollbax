Logger.configure(level: :info)
Application.ensure_all_started(:hackney)
ExUnit.start()

defmodule ExUnit.RollbaxCase do
  use ExUnit.CaseTemplate

  using(_) do
    quote do
      import unquote(__MODULE__)
    end
  end

  def start_rollbax_client(token, envt) do
    config = [
      access_token: token,
      environment: envt,
      origin: "http://localhost:4004",
      otp_app: :rollbax_test,
    ]

    RollbaxTest.Client.start_link(config)
  end

  def capture_log(fun) do
    ExUnit.CaptureIO.capture_io(:user, fn ->
      fun.()
      :timer.sleep(100)
      Logger.flush()
    end)
  end
end

defmodule RollbaxTest.Client do
  use Rollbax.Api, [otp_app: :rollbax_test]
end

defmodule RollbarAPI do
  alias Plug.Conn
  alias Plug.Adapters.Cowboy

  import Conn

  def start(pid) do
    :timer.sleep(30)
    Cowboy.http(__MODULE__, [test: pid], port: 4004)
  end

  def stop() do
    :timer.sleep(200)
    Cowboy.shutdown(__MODULE__.HTTP)
  end

  def init(opts) do
    Keyword.fetch!(opts, :test)
  end

  def call(%Conn{method: "POST"} = conn, test) do
    {:ok, body, conn} = read_body(conn)
    :timer.sleep(30)
    send test, {:api_request, body}
    send_resp(conn, 200, "OK")
  end

  def call(conn, _test) do
    send_resp(conn, 404, "Not Found")
  end
end

defmodule ExUnit.PlugApp do
  import Plug.Conn
  use Plug.Router
  use Rollbax.Plug, otp_app: :rollbax_test

  plug :match
  plug :dispatch

  get "/bang" do
    _ = conn
    raise RuntimeError, "Oops"
  end

  post "/push" do
    _ = conn
    raise RuntimeError, "Whats?"
  end
end

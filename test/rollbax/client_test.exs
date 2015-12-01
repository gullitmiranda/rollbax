defmodule Rollbax.ClientTest do
  use ExUnit.RollbaxCase

  alias Rollbax.Client
  @module_name ExUnit.RollbaxCase

  setup_all do
    {:ok, _} = start_rollbax_client("token1", "test")
    :ok
  end

  setup do
    {:ok, _} = RollbarAPI.start(self())
    on_exit(fn -> RollbarAPI.stop() end)
  end

  test "post payload" do
    :ok = Client.emit(:warn, "pass", %{meta: "OK"}, @module_name)
    assert_receive {:api_request, body}, 200
    assert body =~ "access_token\":\"token1"
    assert body =~ "environment\":\"test"
    assert body =~ "level\":\"warn"
    assert body =~ "body\":\"pass"
    assert body =~ "meta\":\"OK"
  end

  test "mass sending" do
    for _ <- 1..60 do
      :ok = Client.emit(:error, "pass", %{}, @module_name)
    end

    for _ <- 1..60 do
      assert_receive {:api_request, _body}, 200
    end
  end

  test "endpoint is down" do
    :ok = RollbarAPI.stop()
    log = capture_log(fn ->
      :ok = Client.emit(:error, "miss", %{}, @module_name)
    end)
    assert log =~ "[error] (Rollbax) connection error:"
    refute_receive {:api_request, _body}
  end
end

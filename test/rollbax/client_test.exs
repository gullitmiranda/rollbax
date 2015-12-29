defmodule Rollbax.ClientTest do
  use ExUnit.RollbaxCase

  alias RollbaxTest.Client
  @opt_app :rollbax_test

  setup_all do
    {:ok, _} = start_rollbax_client("token1", "test")
    :ok
  end

  setup do
    {:ok, _} = RollbarAPI.start(self())
    on_exit(fn -> RollbarAPI.stop() end)
  end

  test "post payload" do
    :ok = Client.emit(:warn, "pass", %{meta: "OK"})
    assert_receive {:api_request, body}, 250
    assert body =~ "access_token\":\"token1"
    assert body =~ "environment\":\"test"
    assert body =~ "level\":\"warn"
    assert body =~ "body\":\"pass"
    assert body =~ "meta\":\"OK"
  end

  test "mass sending" do
    for _ <- 1..60 do
      :ok = Client.emit(:error, "pass", %{})
    end

    for _ <- 1..60 do
      assert_receive {:api_request, _body}, 250
    end
  end

  test "endpoint is down" do
    :ok = RollbarAPI.stop()
    log = capture_log(fn ->
      :ok = Client.emit(:error, "miss", %{})
    end)
    assert log =~ "[error] (Rollbax) connection error:"
    refute_receive {:api_request, _body}
  end
end

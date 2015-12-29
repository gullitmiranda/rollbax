defmodule Rollbax.NotifierTest do
  use ExUnit.RollbaxCase

  require Logger

  alias Rollbax.Notifier

  setup_all do
    {:ok, _} = start_rollbax_client("token1", "test")
    {:ok, _} = Logger.add_backend(Notifier, flush: true)
    on_exit(fn ->
      Logger.remove_backend(Notifier, flush: true)
    end)
  end

  setup do
    {:ok, _} = RollbarAPI.start(self())
    on_exit(fn -> RollbarAPI.stop() end)
  end

  test "notify level filtering" do
    Logger.configure_backend(Notifier, level: :warn, module_name: ExUnit.RollbaxCase)
    capture_log(fn ->
      Logger.error(["test", ?\s, "pass"])
      Logger.info("miss")
    end)
    assert_receive {:api_request, body}, 200
    assert body =~ "body\":\"test pass"
    refute_receive {:api_request, _body}
  end

  test "notifier skip" do
    Logger.metadata(rollbax: false)
    capture_log(fn -> Logger.error("miss") end)
    refute_receive {:api_request, _body}
  end

  test "endpoint is down" do
    :ok = RollbarAPI.stop()
    capture_log(fn -> Logger.error("miss") end)
    refute_receive {:api_request, _body}
  end
end

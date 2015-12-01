defmodule RollbaxTest do
  use ExUnit.RollbaxCase

  setup_all do
    {:ok, _} = start_rollbax_client("token1", "test")
    :ok
  end

  setup do
    {:ok, _} = RollbarAPI.start(self())
    on_exit(fn -> RollbarAPI.stop() end)
  end

  test "parse config" do
    custom = [
      access_token: "token",
      envt: "envt",
      origin: "http://localhost:4004"
    ]

    config = Rollbax.parse_config(custom)

    assert config[:otp_app     ] == :rollbax
    assert config[:access_token] == "token"
    assert config[:envt        ] == "envt"
    assert config[:origin      ] == "http://localhost:4004"
  end

  test "exception report" do
    stacktrace = [{Test, :report, 2, [file: 'file.exs', line: 16]}]
    exception = RuntimeError.exception("pass")
    :ok = Rollbax.report(exception, stacktrace, %{}, %{uuid: "d4c7"})
    assert_receive {:api_request, body}
    assert body =~ "level\":\"error"
    assert body =~ "body\":\"** (RuntimeError) pass\\n    file.exs:16: Test.report/2\\n"
    assert body =~ "uuid\":\"d4c7"
    refute body =~ "custom"
  end
end

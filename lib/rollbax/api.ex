defmodule Rollbax.Api do
  defmacro __using__(_opts) do
    quote do
      use GenServer

      require Logger

      alias Rollbax.Item

      @entrypoint_url "/item"
      @headers [{"content-type", "application/json"}]

      defstruct [:draft, :url, :enabled, :config]

      def start_link(opts, module_name \\ nil) do
        module_name = module_name || __MODULE__
        state = opts |> Rollbax.parse_config |> new
        GenServer.start_link(__MODULE__, state, [name: module_name])
      end

      def new(config) do
        draft = Item.draft(config[:access_token], config[:environment])
        url   = (config[:origin] <> @entrypoint_url)
        %__MODULE__{
          draft: draft,
          url: url,
          enabled: config[:enabled],
          config: config,
        }
      end

      def init(state) do
        Logger.metadata(rollbax: false)
        :ok = :hackney_pool.start_pool(__MODULE__, [max_connections: 20])
        {:ok, state}
      end

      def terminate(_reason, _state) do
        :ok = :hackney_pool.stop_pool(__MODULE__)
      end

      def emit(lvl, msg, meta, module_name \\ nil) when is_map(meta) do
        module_name = module_name || __MODULE__
        event = {Atom.to_string(lvl), msg, unix_timestamp(), meta}
        GenServer.cast(module_name, {:emit, event})
      end

      def handle_cast({:emit, _event}, %{enabled: false} = state) do
        {:noreply, state}
      end

      def handle_cast({:emit, event}, %{enabled: :log} = state) do
        {level, message, time, meta} = event
        Logger.info [
          "(Rollbax) registered report:", ?\n, message,
          "\n    Level: ", level,
          "\nTimestamp: ", Integer.to_string(time),
          "\n Metadata: " | inspect(meta)]
        {:noreply, state}
      end

      def handle_cast({:emit, event}, %{enabled: true} = state) do
        payload = compose_json(state.draft, event)
        opts = [:async, pool: __MODULE__]
        case :hackney.post(state.url, @headers, payload, opts) do
          {:ok, _ref} -> :ok
          {:error, reason} ->
            Logger.error("(Rollbax) connection error: #{inspect(reason)}")
        end
        {:noreply, state}
      end

      def handle_info({:hackney_response, _ref, :done}, state) do
        {:noreply, state}
      end

      def handle_info({:hackney_response, _ref, response}, state) do
        case response do
          {:status, code, desc} when code != 200 ->
            Logger.warn("(Rollbax) unexpected API status: #{code}/#{desc}")
          {:error, reason} ->
            Logger.error("(Rollbax) connection error: #{inspect(reason)}")
          _otherwise ->
            Logger.debug("(Rollbax) API response: #{inspect(response)}")
        end
        {:noreply, state}
      end

      defp unix_timestamp() do
        {mgsec, sec, _usec} = :os.timestamp()
        mgsec * 1_000_000 + sec
      end

      defp compose_json(draft, event) do
        Item.compose(draft, event)
        |> Poison.encode!(iodata: true)
      end
    end
  end
end

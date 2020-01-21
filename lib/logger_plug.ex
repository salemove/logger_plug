defmodule Glia.LoggerPlug do
  @moduledoc """
  A plug that logs every processed HTTP request with single line that includes
  all necessary metadata.

  Heavily inspired by (Logster)[https://github.com/navinpeiris/logster], but
  adapted for Logstash-centric logging.

  See also `Plug.Logger`.

  ## Configuration

    * `:level` - The log level at which this plug should log its request info.
      Default is `:info`.
    * `:allowed_parameters` - list of request parameters which values will be logged
      without masking. Default is `[]`.

  ## Example

      plug TransporterWeb.LoggerPlug, level: :info

  """

  require Logger

  alias Plug.Conn

  @behaviour Plug

  @default_level :info
  @filtered_placeholder "[FILTERED]"

  @impl Plug
  def init(options) do
    [
      level: Keyword.get(options, :level, @default_level),
      allowed_parameters: extract_allowed_parameters(options)
    ]
  end

  @impl Plug
  def call(conn, options) do
    start_time = System.monotonic_time()

    Conn.register_before_send(conn, fn conn ->
      level = determine_log_level(conn, options)

      Logger.log(level, fn ->
        allowed_parameters = Keyword.fetch!(options, :allowed_parameters)

        stop_time = System.monotonic_time()
        duration = System.convert_time_unit(stop_time - start_time, :native, :millisecond)

        metadata = [
          method: conn.method,
          path: conn.request_path,
          params: conn.params |> filter_params(allowed_parameters) |> inspect(),
          duration: duration,
          status: conn.status,
          state: conn.state,
          controller: conn.private[:phoenix_controller],
          action: conn.private[:phoenix_action],
          user_agent: conn |> Plug.Conn.get_req_header("user-agent") |> Enum.at(0)
        ]

        {"Request processed", metadata}
      end)

      conn
    end)
  end

  defp determine_log_level(%{status: status}, _options) when status >= 500, do: :error
  defp determine_log_level(%{status: status}, _options) when status >= 400, do: :info
  defp determine_log_level(_conn, options), do: Keyword.fetch!(options, :level)

  defp filter_params(params, allowed) do
    for {key, value} <- params, into: Map.new() do
      if MapSet.member?(allowed, key) do
        {key, value}
      else
        {key, @filtered_placeholder}
      end
    end
  end

  defp extract_allowed_parameters(options) do
    options
    |> Keyword.get(:allowed_parameters, [])
    |> Enum.map(&to_string/1)
    |> MapSet.new()
  end
end

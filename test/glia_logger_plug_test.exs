defmodule Glia.LoggerPlugTest do
  use ExUnit.Case
  use Plug.Test

  alias Glia.LoggerPlug

  import ExUnit.CaptureLog

  setup tags do
    Logger.configure_backend(
      :console,
      format: "$time $metadata[$level] $message",
      metadata: :all,
      colors: [enabled: false]
    )

    options = LoggerPlug.init(tags[:options] || [])
    {:ok, options: options}
  end

  @tag options: [allowed_parameters: [:site_id], level: :info]
  test "logs the incoming request and result of its processing", %{options: options} do
    user_agent = "some user agent"

    logged_line =
      capture_log(fn ->
        conn =
          conn(:post, "/queues", site_id: "site", phone: "1234")
          |> put_req_header("user-agent", user_agent)
          |> put_private(:phoenix_controller, EngagementRouterWeb.QueueController)
          |> put_private(:phoenix_action, :create)
          |> LoggerPlug.call(options)

        # simulate request processing
        Process.sleep(1)
        send_resp(conn, 200, "Response OK")
      end)

    assert logged_line =~ "Request processed"
    assert logged_line =~ ~s("site_id" => "site")
    assert logged_line =~ ~s("phone" => "[FILTERED]")
    assert logged_line =~ "method=POST"
    assert logged_line =~ "path=/queues"
    assert logged_line =~ "controller=EngagementRouterWeb.QueueController"
    assert logged_line =~ "action=create"
    assert logged_line =~ "duration="
    assert logged_line =~ "user_agent=#{user_agent}"
  end
end

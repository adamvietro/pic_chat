defmodule PicChat.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      PicChatWeb.Telemetry,
      PicChat.Repo,
      {DNSCluster, query: Application.get_env(:pic_chat, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: PicChat.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: PicChat.Finch},
      # Start a worker by calling: PicChat.Worker.start_link(arg)
      # {PicChat.Worker, arg},
      # Start to serve requests, typically the last entry
      PicChatWeb.Endpoint,
      # Added Oban
      {Oban, Application.fetch_env!(:pic_chat, Oban)}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: PicChat.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    PicChatWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end

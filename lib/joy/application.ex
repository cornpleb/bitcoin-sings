defmodule Joy.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  alias Joy.Bitcoin.Network
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      JoyWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: Joy.PubSub},
      # Start Finch
      {Finch, name: Joy.Finch},
      # Start the Endpoint (http/https)
      JoyWeb.Endpoint,
      # Start a worker by calling: Joy.Worker.start_link(arg)
      # {Joy.Worker, arg}

      {
        DynamicSupervisor,
        name: Joy.Bitcoin.Network.Node.Supervisor,
        strategy: :one_for_one,
        max_children: 2
      }
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Joy.Supervisor]
    Supervisor.start_link(children, opts)

    Network.connect_to_node(
      Application.get_env(:joy, :ip),
      Application.get_env(:joy, :port)
    )
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    JoyWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end

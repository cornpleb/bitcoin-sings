defmodule Joy.Bitcoin.Network do
  @moduledoc false
  alias Joy.Bitcoin.Network.Node.Supervisor
  alias Joy.Bitcoin.Network.NodeServer
  alias Joy.Bitcoin.Network.Protocol.NetAddr

  def connect_to_node(%NetAddr{ip: ip, port: port}),
    do: connect_to_node(ip, port)

  def connect_to_node(ip, port) do
    DynamicSupervisor.start_child(Supervisor, %{
      id: NodeServer,
      start: {NodeServer, :start_link, [{ip, port}]},
      restart: :transient
    })
  end
end

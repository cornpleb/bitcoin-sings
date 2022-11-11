defmodule Joy.Bitcoin.Network.Protocol.Version do
  @moduledoc """
  https://en.bitcoin.it/wiki/Protocol_documentation#version
  https://developer.bitcoin.org/reference/p2p_networking.html#version

  When a node creates an outgoing connection, it will immediately advertise its
  version. The remote node will respond with its version. No further
  communication is possible until both peers have exchanged their version.

  Payload:

  Field Size 	Description 	Data type 	Comments
  4 	        version 	    int32_t 	  Identifies protocol version being used
                                          by the node
  8 	        services 	    uint64_t 	  bitfield of features to be enabled for
                                          this connection
  8 	        timestamp 	  int64_t 	  standard UNIX timestamp in seconds
  26 	        addr_recv 	  net_addr 	  The network address of the node
                                          receiving this message

  (Fields below require version ≥ 106)
  26 	        addr_from 	  net_addr 	  Field can be ignored. This used to be
                                          the network address of the node
                                          emitting this message, but most P2P
                                          implementations send 26 dummy bytes.
                                          The "services" field of the address
                                          would also be redundant with the
                                          second field of the version message.
  8 	        nonce 	      uint64_t 	  Node random nonce, randomly generated
                                          every time a version packet is sent.
                                          This nonce is used to detect
                                          connections to self.
  ? 	        user_agent 	  var_str 	  User Agent (0x00 if string is 0 bytes
                                          long)
  4 	        start_height 	int32_t 	  The last block received by the emitting
                                          node

  (Fields below require version ≥ 70001)
  1 	        relay 	      bool 	      Whether the remote peer should announce
                                          relayed transactions or not, see
                                          BIP 0037

  A "verack" packet shall be sent if the version packet was accepted.

  The following services are currently assigned:

  Value 	Name 	                  Description
  1 	    NODE_NETWORK 	          This node can be asked for full blocks instead
                                    of just headers.
  2 	    NODE_GETUTXO 	          See BIP 0064
  4 	    NODE_BLOOM 	            See BIP 0111
  8 	    NODE_WITNESS 	          See BIP 0144
  16 	    NODE_XTHIN 	            Never formally proposed (as a BIP), and
                                    discontinued. Was historically sporadically
                                    seen on the network.
  64 	    NODE_COMPACT_FILTERS 	  See BIP 0157
  1024 	  NODE_NETWORK_LIMITED 	  See BIP 0159
  """

  defstruct version: nil,
            services: nil,
            timestamp: nil,
            recv_ip: nil,
            recv_port: nil,
            recv_services: nil,
            from_ip: nil,
            from_port: nil,
            from_services: nil,
            nonce: nil,
            user_agent: nil,
            start_height: nil

  alias Joy.Bitcoin.Network.Protocol.{VarStr, Version, VersionNetAddr}

  def parse(binary) do
    with <<version::32-little, services::64-little, timestamp::64-little, rest::binary>> <-
           binary,
         {:ok,
          %VersionNetAddr{
            ip: recv_ip,
            port: recv_port,
            services: recv_services
          },
          rest} <-
           VersionNetAddr.parse(rest),
         {:ok,
          %VersionNetAddr{
            ip: from_ip,
            port: from_port,
            services: from_services
          },
          rest} <-
           VersionNetAddr.parse(rest),
         <<nonce::64-little, rest::binary>> <- rest,
         {:ok, %VarStr{value: user_agent}, rest} <- VarStr.parse(rest),
         <<start_height::32-little, rest::binary>> <- rest do
      {:ok,
       %Version{
         version: version,
         services: services,
         timestamp: timestamp,
         recv_ip: recv_ip,
         recv_port: recv_port,
         recv_services: recv_services,
         from_ip: from_ip,
         from_port: from_port,
         from_services: from_services,
         nonce: nonce,
         user_agent: user_agent,
         start_height: start_height
       }, rest}
    end
  end
end

defimpl Joy.Bitcoin.Network.Protocol,
  for: Joy.Bitcoin.Network.Protocol.Version do
  alias Joy.Bitcoin.Network.Protocol
  alias Joy.Bitcoin.Network.Protocol.{VersionNetAddr, VarStr}

  def serialize(version) do
    <<
      version.version::32-little,
      version.services::64-little,
      version.timestamp::64-little,
      Protocol.serialize(%VersionNetAddr{
        services: version.recv_services,
        ip: version.recv_ip,
        port: version.recv_port
      })::binary,
      Protocol.serialize(%VersionNetAddr{
        services: version.from_services,
        ip: version.from_ip,
        port: version.from_port
      })::binary,
      version.nonce::64-little,
      Protocol.serialize(%VarStr{value: version.user_agent})::binary,
      version.start_height::32-little
    >>
  end
end

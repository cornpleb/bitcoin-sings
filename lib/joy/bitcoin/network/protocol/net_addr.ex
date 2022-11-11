defmodule Joy.Bitcoin.Network.Protocol.NetAddr do
  @moduledoc """
  https://en.bitcoin.it/wiki/Protocol_documentation#Network_address

  When a network address is needed somewhere, this structure is used. Network
  addresses are not prefixed with a timestamp in the version message.

  Field Size 	Description 	Data type 	Comments
  4 	        time 	        uint32 	    The Time (version >= 31402). Not present
                                          in version message.
  8 	        services 	    uint64_t 	  Same service(s) listed in version
  16 	        IPv6/4 	      char[16] 	  IPv6 address. Network byte order. The
                                          original client only supported IPv4
                                          and only read the last 4 bytes to get
                                          the IPv4 address. However, the IPv4
                                          address is written into the message as
                                          a 16 byte IPv4-mapped IPv6 address
                                          (12 bytes 00 00 00 00 00 00 00 00 00
                                          00 FF FF, followed by the 4 bytes of
                                          the IPv4 address).
  2 	        port 	        uint16_t 	    port number, network byte order
  """

  defstruct time: nil,
            services: nil,
            ip: nil,
            port: nil

  alias Joy.Bitcoin.Network.Protocol.NetAddr

  def parse(<<
        time::32-little,
        services::64-little,
        ip::binary-size(16),
        port::16-big,
        rest::binary
      >>) do
    {:ok,
     %NetAddr{
       time: time,
       services: services,
       ip: ip,
       port: port
     }, rest}
  end
end

defimpl Joy.Bitcoin.Network.Protocol,
  for: Joy.Bitcoin.Network.Protocol.NetAddr do
  alias Joy.Bitcoin.Network.Protocol.NetAddr

  def serialize(%NetAddr{time: time, services: services, ip: ip, port: port}) do
    <<
      time::32-little,
      services::64-little,
      :binary.decode_unsigned(ip)::128-big,
      port::16-big
    >>
  end
end

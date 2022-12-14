defmodule Joy.Bitcoin.Network.Protocol.Message do
  @moduledoc false
  defstruct magic: nil,
            command: nil,
            size: nil,
            checksum: nil,
            payload: nil,
            parsed_payload: nil

  alias Joy.Bitcoin.Network.Protocol

  alias Joy.Bitcoin.Network.Protocol.{
    Addr,
    Block,
    GetAddr,
    Inv,
    Message,
    Ping,
    Pong,
    Tx,
    Verack,
    Version
  }

  def parse(binary) do
    with <<
           magic::binary-size(4),
           command::binary-size(12),
           size::32-little,
           checksum::binary-size(4),
           payload::binary-size(size),
           rest::binary
         >> <- binary,
         {:ok, parsed_payload, _} <- parse_payload(command, payload) do
      {:ok,
       %Message{
         magic: magic,
         command: binary_to_str(command),
         size: size,
         checksum: checksum,
         payload: payload,
         parsed_payload: parsed_payload
       }, rest}
    else
      _ -> nil
    end
  end

  def parse_payload("addr" <> _, payload), do: Addr.parse(payload)
  def parse_payload("block" <> _, payload), do: Block.parse(payload)
  def parse_payload("getaddr" <> _, payload), do: GetAddr.parse(payload)
  def parse_payload("inv" <> _, payload), do: Inv.parse(payload)
  def parse_payload("ping" <> _, payload), do: Ping.parse(payload)
  def parse_payload("pong" <> _, payload), do: Pong.parse(payload)
  def parse_payload("tx" <> _, payload), do: Tx.parse(payload)
  def parse_payload("verack" <> _, payload), do: Verack.parse(payload)
  def parse_payload("version" <> _, payload), do: Version.parse(payload)

  def parse_payload(_command, payload) do
    {:ok, payload, <<>>}
  end

  def serialize(command, payload \\ <<>>)

  def serialize(command, payload) when is_binary(payload) do
    Protocol.serialize(%Message{
      command: command,
      payload: payload
    })
  end

  def serialize(command, payload) do
    Protocol.serialize(%Message{
      command: command,
      payload: Protocol.serialize(payload)
    })
  end

  def verify_checksum(%Message{size: size, checksum: checksum, payload: payload}) do
    checksum(payload) == checksum && byte_size(payload) == size
  end

  def verify_checksum(_), do: false

  def checksum(payload) do
    <<checksum::binary-size(4), _::binary>> =
      payload
      |> hash(:sha256)
      |> hash(:sha256)

    checksum
  end

  defp hash(data, algorithm), do: :crypto.hash(algorithm, data)

  defp binary_to_str(bin) do
    bin
    |> :binary.bin_to_list()
    |> Enum.reject(&(&1 == 0))
    |> :binary.list_to_bin()
  end
end

defimpl Joy.Bitcoin.Network.Protocol,
  for: Joy.Bitcoin.Network.Protocol.Message do
  alias Joy.Bitcoin.Network.Protocol.Message

  def serialize(%Message{command: command, payload: payload}) do
    <<
      Application.get_env(:joy, :magic)::binary,
      String.pad_trailing(command, 12, <<0>>)::binary,
      byte_size(payload)::32-little,
      Message.checksum(payload)::binary,
      payload::binary
    >>
  end
end

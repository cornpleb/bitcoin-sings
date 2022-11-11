defmodule Joy.Bitcoin.Network.Protocol.Outpoint do
  @moduledoc """
  https://en.bitcoin.it/wiki/Protocol_documentation#tx

  The OutPoint structure is used as part of Tx.

  The OutPoint structure consists of the following fields:

  Field Size 	Description 	Data type 	Comments
  32 	        hash 	        char[32] 	  The hash of the referenced transaction.
  4 	        index 	      uint32_t 	  The index of the specific output in the
                                          transaction. The first output is 0.
  """

  alias Joy.Bitcoin.Network.Protocol.Outpoint

  defstruct hash: nil,
            index: nil

  def parse(binary) do
    with {:ok, hash, rest} <- parse_hash(binary),
         {:ok, index, rest} <- parse_index(rest) do
      {:ok, %Outpoint{hash: hash, index: index}, rest}
    end
  end

  # TODO: Replace 'Base.encode16(Binary.reverse(hash))' with just 'hash':
  defp parse_hash(<<hash::binary-size(32), rest::binary>>),
    do: {:ok, Base.encode16(Binary.reverse(hash)), rest}

  defp parse_hash(_binary),
    do: {:error, :bad_hash}

  defp parse_index(<<index::32-little, rest::binary>>),
    do: {:ok, index, rest}

  defp parse_index(_binary),
    do: {:error, :bad_index}
end

defimpl Joy.Bitcoin.Network.Protocol,
  for: Joy.Bitcoin.Network.Protocol.Outpoint do
  def serialize(outpoint),
    do: <<
      serialize_hash(outpoint)::binary,
      serialize_index(outpoint)::binary
    >>

  defp serialize_hash(%{hash: hash}),
    do: hash

  defp serialize_index(%{index: index}),
    do: <<index::32-little>>
end

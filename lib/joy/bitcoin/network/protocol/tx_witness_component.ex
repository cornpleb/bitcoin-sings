defmodule Joy.Bitcoin.Network.Protocol.TxWitnessComponent do
  @moduledoc """
  https://en.bitcoin.it/wiki/Protocol_documentation#tx

  The TxWitnessComponent structure is used as part of TxWitness.
  """

  alias Joy.Bitcoin.Network.Protocol.{TxWitnessComponent, VarInt}

  defstruct length: nil,
            data: nil

  def parse(binary) do
    with {:ok, length, rest} <- parse_length(binary),
         {:ok, data, rest} <- parse_data(rest, length) do
      {:ok, %TxWitnessComponent{length: length, data: data}, rest}
    end
  end

  defp parse_length(binary) do
    with {:ok, %VarInt{value: length}, rest} <- VarInt.parse(binary) do
      {:ok, length, rest}
    end
  end

  defp parse_data(binary, length) do
    case binary do
      <<data::binary-size(length), rest::binary>> ->
        {:ok, data, rest}

      _ ->
        {:error, :bad_data}
    end
  end
end

defimpl Joy.Bitcoin.Network.Protocol,
  for: Joy.Bitcoin.Network.Protocol.TxWitnessComponent do
  alias Joy.Bitcoin.Network.Protocol
  alias Joy.Bitcoin.Network.Protocol.VarInt

  def serialize(tx_witness_component),
    do: <<
      serialize_length(tx_witness_component)::binary,
      serialize_data(tx_witness_component)::binary
    >>

  defp serialize_length(%{length: length}),
    do: Protocol.serialize(%VarInt{value: length})

  defp serialize_data(%{data: data}),
    do: data
end

defmodule Joy.Bitcoin.Network.Protocol.TxOut do
  @moduledoc """
  https://en.bitcoin.it/wiki/Protocol_documentation#tx

  The TxOut structure is used as part of Tx.

  The TxOut structure consists of the following fields:

  Field Size 	Description 	    Data type 	Comments
  8 	        value 	          int64_t 	  Transaction Value
  1+ 	        pk_script length 	var_int 	  Length of the pk_script
  ? 	        pk_script 	      uchar[] 	  Usually contains the public key as a
                                              Bitcoin script setting up
                                              conditions to claim this output.
  """

  alias Joy.Bitcoin.Network.Protocol.{TxOut, VarInt}

  defstruct value: nil,
            pk_script_length: nil,
            pk_script: nil

  def parse(binary) do
    with {:ok, value, rest} <- parse_value(binary),
         {:ok, pk_script_length, rest} <- parse_pk_script_length(rest),
         {:ok, pk_script, rest} <- parse_pk_script(rest, pk_script_length) do
      {:ok,
       %TxOut{
         value: value,
         pk_script_length: pk_script_length,
         pk_script: pk_script
       }, rest}
    end
  end

  defp parse_value(<<value::64-little, rest::binary>>),
    do: {:ok, value, rest}

  defp parse_value(_binary),
    do: {:error, :bad_value}

  defp parse_pk_script_length(binary) do
    with {:ok, %VarInt{value: pk_script_length}, rest} <- VarInt.parse(binary) do
      {:ok, pk_script_length, rest}
    end
  end

  defp parse_pk_script(binary, pk_script_length) do
    case binary do
      <<pk_script::binary-size(pk_script_length), rest::binary>> ->
        {:ok, pk_script, rest}

      _ ->
        {:error, :bad_pk_script}
    end
  end
end

defimpl Joy.Bitcoin.Network.Protocol,
  for: Joy.Bitcoin.Network.Protocol.TxOut do
  alias Joy.Bitcoin.Network.Protocol
  alias Joy.Bitcoin.Network.Protocol.VarInt

  def serialize(tx),
    do: <<
      serialize_value(tx)::binary,
      serialize_pk_script_length(tx)::binary,
      serialize_pk_script(tx)::binary
    >>

  defp serialize_value(%{value: value}),
    do: <<value::64-little>>

  defp serialize_pk_script_length(%{pk_script_length: pk_script_length}),
    do: Protocol.serialize(%VarInt{value: pk_script_length})

  defp serialize_pk_script(%{pk_script: pk_script}),
    do: pk_script
end

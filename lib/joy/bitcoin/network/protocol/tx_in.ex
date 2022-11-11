defmodule Joy.Bitcoin.Network.Protocol.TxIn do
  @moduledoc """
  https://en.bitcoin.it/wiki/Protocol_documentation#tx

  The TxIn structure is used as part of Tx.

  If all TxIn inputs have final (0xffffffff) sequence numbers then lock_time is
  irrelevant. Otherwise, the transaction may not be added to a block until after
  lock_time (see NLockTime).

  TxIn consists of the following fields:

  Field Size 	Description 	    Data type 	Comments
  36 	        previous_output 	outpoint 	  The previous output transaction
                                              reference, as an OutPoint
                                              structure
  1+ 	        script length 	  var_int 	  The length of the signature script
  ? 	        signature script 	uchar[] 	  Computational Script for confirming
                                              transaction authorization
  4 	        sequence 	        uint32_t 	  Transaction version as defined by
                                              the sender. Intended for
                                              "replacement" of transactions when
                                              information is updated before
                                              inclusion into a block.

  The Script structure consists of a series of pieces of information and
  operations related to the value of the transaction.

  (Structure to be expanded in the future… see script.h and script.cpp and
  Script for more information)
  """
  alias Joy.Bitcoin.Network.Protocol.{Outpoint, TxIn, VarInt}

  defstruct previous_output: nil,
            script_length: nil,
            signature_script: nil,
            sequence: nil

  def parse(binary) do
    with {:ok, previous_output, rest} <- parse_previous_output(binary),
         {:ok, script_length, rest} <- parse_script_length(rest),
         {:ok, signature_script, rest} <-
           parse_signature_script(rest, script_length),
         {:ok, sequence, rest} <- parse_sequence(rest) do
      {:ok,
       %TxIn{
         previous_output: previous_output,
         script_length: script_length,
         signature_script: signature_script,
         sequence: sequence
       }, rest}
    end
  end

  defp parse_previous_output(binary),
    do: Outpoint.parse(binary)

  defp parse_script_length(binary) do
    with {:ok, %VarInt{value: script_length}, rest} <- VarInt.parse(binary) do
      {:ok, script_length, rest}
    end
  end

  defp parse_signature_script(binary, script_length) do
    case binary do
      <<signature_script::binary-size(script_length), rest::binary>> ->
        {:ok, signature_script, rest}

      _ ->
        {:error, :bad_signature_script}
    end
  end

  defp parse_sequence(<<sequence::32-little, rest::binary>>),
    do: {:ok, sequence, rest}

  defp parse_sequence(_binary),
    do: {:error, :bad_sequence}
end

defimpl Joy.Bitcoin.Network.Protocol,
  for: Joy.Bitcoin.Network.Protocol.TxIn do
  alias Joy.Bitcoin.Network.Protocol
  alias Joy.Bitcoin.Network.Protocol.VarInt

  def serialize(tx),
    do: <<
      serialize_previous_output(tx)::binary,
      serialize_script_length(tx)::binary,
      serialize_signature_script(tx)::binary,
      serialize_sequence(tx)::binary
    >>

  defp serialize_previous_output(%{previous_output: previous_output}),
    do: Protocol.serialize(previous_output)

  defp serialize_script_length(%{script_length: script_length}),
    do: Protocol.serialize(%VarInt{value: script_length})

  defp serialize_signature_script(%{signature_script: signature_script}),
    do: signature_script

  defp serialize_sequence(%{sequence: sequence}),
    do: <<sequence::32-little>>
end

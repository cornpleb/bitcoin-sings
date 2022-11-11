defmodule Joy.Bitcoin.Network.Protocol.Tx do
  @moduledoc """
  https://en.bitcoin.it/wiki/Protocol_documentation#tx
  https://developer.bitcoin.org/reference/transactions.html

  tx describes a bitcoin transaction, in reply to getdata. When a bloom filter
  is applied tx objects are sent automatically for matching transactions
  following the merkleblock.


  Field Size 	Description 	  Data type 	  Comments
  4 	        version 	      uint32_t 	    Transaction data format version
  0 or 2 	    flag 	optional  uint8_t[2] 	  If present, always 0001, and
                                              indicates the presence of
                                              witness data
  1+ 	        tx_in count 	  var_int 	    Number of Transaction inputs
                                              (never zero)
  41+ 	      tx_in 	        tx_in[] 	    A list of 1 or more transaction
                                              inputs or sources for coins
  1+ 	        tx_out count 	  var_int	      Number of Transaction outputs
  9+ 	        tx_out 	        tx_out[] 	    A list of 1 or more transaction
                                              outputs or destinations for coins
  0+ 	        tx_witnesses 	  tx_witness[] 	A list of witnesses, one for each
                                              input; omitted if flag is omitted
                                              above
  4 	        lock_time 	    uint32_t 	    The block number or timestamp at
                                              which this transaction is
                                              unlocked:
                                              Value 	      Description
                                              0 	          Not locked
                                              < 500000000 	Block number at
                                                              which this
                                                              transaction is
                                                              unlocked
                                              >= 500000000 	UNIX timestamp at
                                                              which this
                                                              transaction is
                                                              unlocked
  """

  defstruct version: nil,
            flag: nil,
            tx_in_count: nil,
            tx_in: nil,
            tx_out_count: nil,
            tx_out: nil,
            tx_witnesses: nil,
            lock_time: nil,
            size: nil,
            tx_id: nil

  alias Joy.Bitcoin.Network.Hash

  alias Joy.Bitcoin.Network.Protocol.{
    Tx,
    TxIn,
    TxOut,
    TxWitness,
    VarInt
  }

  def parse(binary) do
    with {:ok, version, rest} <- parse_version(binary),
         {:ok, flag, rest} <- parse_flag(rest),
         {:ok, tx_in_count, rest} <- parse_tx_in_count(rest),
         {:ok, tx_in, rest} <- parse_tx_in(rest, tx_in_count),
         {:ok, tx_out_count, rest} <- parse_tx_out_count(rest),
         {:ok, tx_out, rest2} <- parse_tx_out(rest, tx_out_count),
         {:ok, tx_witnesses, rest3} <-
           parse_tx_witnesses(rest2, tx_in_count, flag),
         {:ok, lock_time, rest} <- parse_lock_time(rest3) do
      {:ok,
       %Tx{
         version: version,
         flag: flag,
         tx_in_count: tx_in_count,
         tx_in: tx_in,
         tx_out_count: tx_out_count,
         tx_out: tx_out,
         tx_witnesses: tx_witnesses,
         lock_time: lock_time,
         size: byte_size(binary),
         tx_id: calc_tx_id(binary, rest2, rest3, flag)
       }, rest}
    end
  end

  defp parse_version(<<version::32-little, rest::binary>>),
    do: {:ok, version, rest}

  defp parse_version(_binary),
    do: {:error, :bad_version}

  defp parse_flag(<<0x00, 0x01, rest::binary>>),
    do: {:ok, 1, rest}

  defp parse_flag(rest),
    do: {:ok, 0, rest}

  defp parse_tx_in_count(binary) do
    with {:ok, %VarInt{value: tx_in_count}, rest} <- VarInt.parse(binary) do
      {:ok, tx_in_count, rest}
    end
  end

  defp parse_tx_in(binary, tx_in_count, tx_in \\ [])

  defp parse_tx_in(binary, tx_in_count, tx_in) when tx_in_count == 0,
    do: {:ok, tx_in, binary}

  defp parse_tx_in(binary, tx_in_count, tx_in) do
    with {:ok, tx, rest} <- TxIn.parse(binary) do
      parse_tx_in(rest, tx_in_count - 1, tx_in ++ [tx])
    end
  end

  defp parse_tx_out_count(binary) do
    with {:ok, %VarInt{value: tx_out_count}, rest} <- VarInt.parse(binary) do
      {:ok, tx_out_count, rest}
    end
  end

  defp parse_tx_out(binary, tx_out_count, tx_out \\ [])

  defp parse_tx_out(binary, tx_out_count, tx_out) when tx_out_count == 0,
    do: {:ok, tx_out, binary}

  defp parse_tx_out(binary, tx_out_count, tx_out) do
    with {:ok, tx, rest} <- TxOut.parse(binary) do
      parse_tx_out(rest, tx_out_count - 1, tx_out ++ [tx])
    end
  end

  defp parse_tx_witnesses(binary, tx_in_count, flag, tx_witnesses \\ [])

  defp parse_tx_witnesses(binary, _tx_in_count, 0, _tx_witnesses),
    do: {:ok, [], binary}

  defp parse_tx_witnesses(binary, tx_in_count, _flag, tx_witnesses)
       when tx_in_count == 0,
       do: {:ok, tx_witnesses, binary}

  defp parse_tx_witnesses(binary, tx_in_count, _flag, tx_witnesses) do
    with {:ok, tx_witness, rest} <- TxWitness.parse(binary) do
      parse_tx_witnesses(rest, tx_in_count - 1, tx_witnesses ++ [tx_witness])
    end
  end

  defp parse_lock_time(<<lock_time::32-little, rest::binary>>),
    do: {:ok, lock_time, rest}

  defp parse_lock_time(_binary),
    do: {:error, :bad_lock_time}

  # Calculate the unique Tx identifier (also known as the hash of a Tx).
  # For Tx with flag=0 this is simply the whole Tx binary. However for Tx with
  # flag=1 we first need to remove the flag part and the witness part of the
  # binary. See also:
  # https://github.com/bitcoin/bips/blob/master/bip-0144.mediawiki#Hashes
  defp calc_tx_id(binary1, binary2, binary3, flag) do
    binary2_size = byte_size(binary2)
    size_diff = byte_size(binary1) - binary2_size

    <<binary_diff::binary-size(size_diff), _::binary>> = binary1

    flag_size =
      case flag do
        1 -> 2
        0 -> 0
      end

    <<
      version::binary-size(4),
      _::binary-size(flag_size),
      input_output::binary
    >> = binary_diff

    <<lock_time::binary-size(4), _::binary>> = binary3

    Hash.double_hash(version <> input_output <> lock_time)
  end
end

defimpl Joy.Bitcoin.Network.Protocol,
  for: Joy.Bitcoin.Network.Protocol.Tx do
  alias Joy.Bitcoin.Network.Protocol
  alias Joy.Bitcoin.Network.Protocol.VarInt

  def serialize(tx),
    do: <<
      serialize_version(tx)::binary,
      serialize_flag(tx)::binary,
      serialize_tx_in_count(tx)::binary,
      serialize_tx_in(tx)::binary,
      serialize_tx_out_count(tx)::binary,
      serialize_tx_out(tx)::binary,
      serialize_tx_witnesses(tx)::binary,
      serialize_lock_time(tx)::binary
    >>

  defp serialize_version(%{version: version}),
    do: <<version::32-little>>

  defp serialize_flag(%{flag: 0}),
    do: <<>>

  defp serialize_flag(%{flag: flag}),
    do: <<flag::16-little>>

  defp serialize_tx_in_count(%{tx_in_count: tx_in_count}),
    do: Protocol.serialize(%VarInt{value: tx_in_count})

  defp serialize_tx_in(%{tx_in: tx_in}),
    do: Enum.map_join(tx_in, &Protocol.serialize/1)

  defp serialize_tx_out_count(%{tx_out_count: tx_out_count}),
    do: Protocol.serialize(%VarInt{value: tx_out_count})

  defp serialize_tx_out(%{tx_out: tx_out}),
    do: Enum.map_join(tx_out, &Protocol.serialize/1)

  defp serialize_tx_witnesses(%{tx_witnesses: tx_witnesses}),
    do: Enum.map_join(tx_witnesses, &Protocol.serialize/1)

  defp serialize_lock_time(%{lock_time: lock_time}),
    do: <<lock_time::32-little>>
end

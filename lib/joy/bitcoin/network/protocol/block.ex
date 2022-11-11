defmodule Joy.Bitcoin.Network.Protocol.Block do
  @moduledoc """
  https://en.bitcoin.it/wiki/Protocol_documentation#block

  The block message is sent in response to a getdata message which requests
  transaction information from a block hash.

  Field Size 	Description 	Data type 	Comments
  4 	        version 	    int32_t 	  Block version information (note, this
                                          is signed)
  32 	        prev_block 	  char[32] 	  The hash value of the previous block
                                          this particular block references
  32 	        merkle_root 	char[32] 	  The reference to a Merkle tree
                                          collection which is a hash of all
                                          transactions related to this block
  4 	        timestamp 	  uint32_t 	  A Unix timestamp recording when this
                                          block was created (Currently limited
                                          to dates before the year 2106!)
  4 	        bits 	        uint32_t 	  The calculated difficulty target being
                                          used for this block
  4 	        nonce 	      uint32_t 	  The nonce used to generate this block to
                                          allow variations of the header and
                                          compute different hashes
  1+ 	        txs_count  	  var_int 	  Number of transaction entries
  ? 	        txs           txs[]       Block transactions, in format of
                                          "tx" command


  CUSTOM FIELDS

  block_hash:
  The SHA256 hash that identifies each block (and which must have a run of 0
  bits) is calculated from the first 6 fields of this structure (version,
  prev_block, merkle_root, timestamp, bits, nonce, and standard SHA256 padding,
  making two 64-byte chunks in all) and not from the complete block. To
  calculate the hash, only two chunks need to be processed by the SHA256
  algorithm. Since the nonce field is in the second chunk, the first chunk
  stays constant during mining and therefore only the second chunk needs to be
  processed. However, a Bitcoin hash is the hash of the hash, so two SHA256
  rounds are needed for each mining iteration.

  size:
  The size in bytes of the block as it "goes over the wire". Note: The size of
  a block including its witness data differs from the same block without it.
  (The size of the latter is also referred to as 'stripped size'.)
  See also https://en.bitcoin.it/wiki/Weight_units#Detailed_example
  """

  defstruct version: nil,
            prev_block: nil,
            merkle_root: nil,
            timestamp: nil,
            bits: nil,
            nonce: nil,
            txs_count: nil,
            txs: nil,
            block_hash: nil,
            size: nil

  alias Joy.Bitcoin.Network.Hash
  alias Joy.Bitcoin.Network.Protocol.{Block, Tx, VarInt}

  def parse(binary) do
    with {:ok, version, rest} <- parse_version(binary),
         {:ok, prev_block, rest} <- parse_prev_block(rest),
         {:ok, merkle_root, rest} <- parse_merkle_root(rest),
         {:ok, timestamp, rest} <- parse_timestamp(rest),
         {:ok, bits, rest} <- parse_bits(rest),
         {:ok, nonce, rest} <- parse_nonce(rest),
         {:ok, txs_count, rest} <- parse_txs_count(rest),
         {:ok, txs, rest} <- parse_txs(rest, txs_count),
         {:ok, block_hash} <- calc_block_hash(binary) do
      {
        :ok,
        %Block{
          version: version,
          prev_block: prev_block,
          merkle_root: merkle_root,
          timestamp: timestamp,
          bits: bits,
          nonce: nonce,
          txs_count: txs_count,
          txs: txs,
          block_hash: block_hash,
          size: byte_size(binary)
        },
        rest
      }
    else
      err -> err
    end
  end

  defp parse_version(<<version::32-little, rest::binary>>),
    do: {:ok, version, rest}

  defp parse_version(_binary),
    do: {:error, :bad_version}

  defp parse_prev_block(<<hash::binary-size(32), rest::binary>>),
    do: {:ok, Base.encode16(Binary.reverse(hash)), rest}

  defp parse_prev_block(_binary),
    do: {:error, :bad_prev_block}

  defp parse_merkle_root(<<hash::binary-size(32), rest::binary>>),
    do: {:ok, Base.encode16(Binary.reverse(hash)), rest}

  defp parse_merkle_root(_binary),
    do: {:error, :bad_merkle_root}

  defp parse_timestamp(<<index::32-little, rest::binary>>),
    do: {:ok, index, rest}

  defp parse_timestamp(_binary),
    do: {:error, :bad_timestamp}

  defp parse_bits(<<index::32-little, rest::binary>>),
    do: {:ok, index, rest}

  defp parse_bits(_binary),
    do: {:error, :bad_bits}

  defp parse_nonce(<<index::32-little, rest::binary>>),
    do: {:ok, index, rest}

  defp parse_nonce(_binary),
    do: {:error, :bad_nonce}

  defp parse_txs_count(binary) do
    with {:ok, %VarInt{value: txs_count}, rest} <- VarInt.parse(binary) do
      {:ok, txs_count, rest}
    end
  end

  defp parse_txs(binary, txs_count, txs \\ [])

  defp parse_txs(binary, txs_count, txs) when txs_count == 0,
    do: {:ok, txs, binary}

  defp parse_txs(binary, txs_count, txs) do
    with {:ok, tx, rest} <- Tx.parse(binary) do
      parse_txs(rest, txs_count - 1, txs ++ [tx])
    end
  end

  # The first 80 bytes contain the first 6 fields (version, prev_block,
  # merkle_root, timestamp, bits, nonce) that are necessary to calculate
  # the block hash.
  defp calc_block_hash(<<binary::binary-size(80), _::binary>>) do
    {:ok, Hash.double_hash(binary)}
  end
end

defimpl Joy.Bitcoin.Network.Protocol,
  for: Joy.Bitcoin.Network.Protocol.Block do
  def serialize(_block) do
    <<>>
  end
end

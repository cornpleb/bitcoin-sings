defmodule Joy.Bitcoin.Network.Protocol.InvVect do
  @moduledoc """
  https://en.bitcoin.it/wiki/Protocol_documentation#Inventory_Vectors

  Inventory vectors are used for notifying other nodes about objects
  they have or data which is being requested.

  Inventory vectors consist of the following data format:

  Field Size 	Description 	Data type 	Comments
  4 	        type 	        uint32_t 	  Identifies the object type
                                          linked to this inventory
  32 	        hash 	        char[32] 	  Hash of the object


  The object type is currently defined as one of the following possibilities:

  Value 	    Name 	                      Description
  0 	        ERROR 	                    Any data of with this number may be
                                            ignored
  1 	        MSG_TX 	                    Hash is related to a transaction
  2 	        MSG_BLOCK 	                Hash is related to a data block
  3 	        MSG_FILTERED_BLOCK 	        Hash of a block header; identical to
                                            MSG_BLOCK. Only to be used in
                                            getdata message. Indicates the
                                            reply should be a merkleblock
                                            message rather than a block
                                            message; this only works if a
                                            bloom filter has been set. See
                                            BIP 37 for more info.
  4 	        MSG_CMPCT_BLOCK 	          Hash of a block header; identical to
                                            MSG_BLOCK. Only to be used in
                                            getdata message. Indicates the
                                            reply should be a cmpctblock
                                            message. See BIP 152 for more info.
  0x40000001 	MSG_WITNESS_TX 	            Hash of a transaction with witness
                                            data. See BIP 144 for more info.
  0x40000002 	MSG_WITNESS_BLOCK 	        Hash of a block with witness data.
                                            See BIP 144 for more info.
  0x40000003 	MSG_FILTERED_WITNESS_BLOCK 	Hash of a block with witness data.
                                            Only to be used in getdata message.
                                            Indicates the reply should be a
                                            merkleblock message rather than a
                                            block message; this only works if a
                                            bloom filter has been set. See
                                            BIP 144 for more info.
  """

  defstruct type: nil, hash: nil

  alias Joy.Bitcoin.Network.Protocol.InvVect

  def parse(<<type::32-little, hash::binary-size(32), rest::binary>>) do
    inv_vect = %InvVect{
      type: change_to_witness_type(type),
      hash: hash
    }

    {:ok, inv_vect, rest}
  end

  # By default Tx and Blocks are received without their witness data being
  # added by the sending node. (For backwards compatibility with older nodes.)
  # However, we want to receive them. See also:
  # https://github.com/bitcoin/bips/blob/master/bip-0144.mediawiki#Relay
  # (Note: Only works for nodes signaling 'NODE_WITNESS' in their services.)
  defp change_to_witness_type(type) do
    case type do
      1 -> 0x40000001
      2 -> 0x40000002
      _ -> type
    end
  end
end

defimpl Joy.Bitcoin.Network.Protocol,
  for: Joy.Bitcoin.Network.Protocol.InvVect do
  def serialize(inv_vect) do
    <<inv_vect.type::32-little, inv_vect.hash::binary-size(32)>>
  end
end

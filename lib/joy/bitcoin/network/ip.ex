defmodule Joy.Bitcoin.Network.IP do
  @moduledoc false
  def to_string(binary) do
    binary
    |> :binary.bin_to_list()
    |> Enum.chunk_every(4)
    |> Enum.map(&:binary.list_to_bin/1)
    |> Enum.map_join(":", &Base.encode16/1)
  end

  def to_tuple(binary) do
    binary
    |> :binary.bin_to_list()
    |> Enum.chunk_every(2)
    |> Enum.map(&:binary.list_to_bin/1)
    |> Enum.map(&:binary.decode_unsigned/1)
    |> List.to_tuple()
  end
end

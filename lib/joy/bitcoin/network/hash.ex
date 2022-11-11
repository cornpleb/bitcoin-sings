defmodule Joy.Bitcoin.Network.Hash do
  @moduledoc false

  def double_hash(binary) do
    binary
    |> sha256(:sha256)
    |> sha256(:sha256)
    |> Binary.reverse()
    |> Base.encode16()
  end

  defp sha256(data, algorithm), do: :crypto.hash(algorithm, data)
end

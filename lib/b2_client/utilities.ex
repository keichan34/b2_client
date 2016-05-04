defmodule B2Client.Utilities do
  @moduledoc false

  @spec sha1hash(iodata) :: binary
  def sha1hash(iodata) do
    :crypto.hash(:sha, iodata) |> Base.encode16(case: :lower)
  end
end

defmodule B2Client do
  use Application

  def start(_type, _args) do
    B2Client.Supervisor.start_link
  end

  @doc """
  Returns the currently configured backend.

  The `HTTPoison`-based backend is the default.

  Example:

      iex> B2Client.backend
      B2Client.Backend.HTTPoison

  """
  def backend,
    do: Application.get_env(:b2_client, :backend, B2Client.Backend.HTTPoison)

  @doc """
  Returns whether the memory server should be started at boot or not.

  Default false.
  """
  def start_memory_server?,
    do: Application.get_env(:b2_client, :start_memory_server, false)
end

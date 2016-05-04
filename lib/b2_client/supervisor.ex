defmodule B2Client.Supervisor do
  @moduledoc false

  use Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    children = []

    if requires_memory_server? do
      children = children ++ [
        worker(B2Client.Backend.Memory, [])
      ]
    end

    supervise(children, strategy: :one_for_one)
  end

  defp requires_memory_server? do
    B2Client.start_memory_server? || B2Client.backend == B2Client.Backend.Memory
  end
end

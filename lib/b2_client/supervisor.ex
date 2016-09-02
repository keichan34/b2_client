defmodule B2Client.Supervisor do
  @moduledoc false

  use Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    children = []

    children = children ++ memory_server_if_required()

    supervise(children, strategy: :one_for_one)
  end

  defp memory_server_if_required do
    if requires_memory_server? do
      [worker(B2Client.Backend.Memory, [])]
    else
      []
    end
  end

  defp requires_memory_server? do
    B2Client.start_memory_server || B2Client.backend == B2Client.Backend.Memory
  end
end

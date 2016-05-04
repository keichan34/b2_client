defprotocol B2Client.Backend.JSONResponseParser do
  @spec parse(any) :: {:ok, %{String.t => any}} | {:error, :server_error} |
    {:error, %{String.t => any}}

  def parse(response)
end

if Code.ensure_loaded?(HTTPoison) do
  defimpl B2Client.Backend.JSONResponseParser, for: HTTPoison.Response do
    def parse(%{status_code: 200, body: raw_body}) do
      case Poison.decode(raw_body) do
        {:ok, body} -> {:ok, body}
        _ -> {:error, :server_error}
      end
    end

    def parse(%{status_code: code, body: raw_body}) when code >= 400 and code < 500 do
      case Poison.decode(raw_body) do
        {:ok, body} -> {:error, body}
        _ -> {:error, :server_error}
      end
    end

    def parse(%{status_code: code}) when code >= 500 and code < 600 do
      {:error, :server_error}
    end
  end
end

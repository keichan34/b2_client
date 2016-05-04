defprotocol B2Client.Backend.FileResponseParser do
  @type metadata :: %{String.t => any}
  @spec parse(any) :: {:ok, B2Client.File.t} | {:error, :server_error} |
    {:error, :bad_hash} | {:error, %{String.t => any}}

  def parse(response)
end

defmodule B2Client.Backend.FileResponseParserHelpers do
  @moduledoc false

  alias B2Client.Utilities

  def to_file(body, headers) do
    metadata = Enum.map(headers, fn({key, value}) ->
      {String.downcase(key), value}
    end) |> Enum.into(%{})

    file = B2Client.File.from_response_metadata(metadata)
    |> Map.put(:contents, body)

    verify_sha1(file)
  end

  defp verify_sha1(%{contents: body, content_sha1: remote_hash} = file) do
    case Utilities.sha1hash(body) do
      ^remote_hash -> {:ok, file}
      _ -> {:error, :bad_hash}
    end
  end
end

if Code.ensure_loaded?(HTTPoison) do
  defimpl B2Client.Backend.FileResponseParser, for: HTTPoison.Response do
    def parse(%{status_code: 200, body: body, headers: headers}) do
      B2Client.Backend.FileResponseParserHelpers.to_file(body, headers)
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

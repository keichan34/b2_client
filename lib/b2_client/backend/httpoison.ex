defmodule B2Client.Backend.HTTPoison do
  @moduledoc """
  A backend that uses HTTPoison as its HTTP library.
  """

  alias B2Client.{Authorization, Bucket, File, UploadAuthorization, Utilities}
  alias B2Client.Backend.{HTTPRequest, JSONResponseParser, FileResponseParser}

  @behaviour B2Client.Backend

  def authenticate(account_id, application_key) do
    resp = HTTPRequest.b2_authorize_account(account_id, application_key)
    |> perform_request
    |> parse_json_response

    case resp do
      {:ok, map} ->
        {:ok, %Authorization{
          account_id: account_id,
          api_url: map["apiUrl"],
          authorization_token: map["authorizationToken"],
          download_url: map["downloadUrl"]
        }}
      error -> error
    end
  end

  def buckets(auth) do
    resp = HTTPRequest.b2_list_buckets(auth)
    |> perform_request
    |> parse_json_response

    case resp do
      {:ok, body} ->
        {:ok, Enum.map(body["buckets"], &Bucket.from_json/1)}
      error -> error
    end
  end

  def get_bucket(auth, bucket_name) do
    case buckets(auth) do
      {:ok, buckets} ->
        bucket = Enum.find(buckets, fn
          (%{bucket_name: ^bucket_name}) -> true
          (_) -> false
        end)
        if bucket do
          {:ok, bucket}
        else
          {:error, :bucket_not_found}
        end
      error -> error
    end
  end

  def download(auth, bucket, path) do
    HTTPRequest.b2_download_file_by_name(auth, bucket, path)
    |> perform_request
    |> parse_file_response
  end

  def download_head(auth, bucket, path) do
    req = HTTPRequest.b2_download_file_by_name(auth, bucket, path)
    req = %{req | method: :head}
    resp = perform_request(req)

    case resp do
      {:ok, %{status_code: 200, headers: headers}} ->
        {_, size} = Enum.find headers, {nil, 0}, fn({key, _}) ->
          String.downcase(key) == "content-length"
        end

        {:ok, String.to_integer(size)}
      other -> parse_file_response(other)
    end
  end

  def get_upload_authorization(auth, bucket) do
    resp = HTTPRequest.b2_get_upload_url(auth, bucket)
    |> perform_request
    |> parse_json_response

    with  {:ok, body} <- resp,
          do: {:ok, UploadAuthorization.from_json(body)}
  end

  def upload(%Authorization{} = auth, %Bucket{} = bucket, iodata, filename) do
    with  {:ok, upload_auth} <- get_upload_authorization(auth, bucket),
          do: upload(upload_auth, iodata, filename)
  end

  def upload(%UploadAuthorization{} = upload_auth, iodata, filename) do
    headers = [
      {"X-Bz-File-Name", filename},
      {"Content-Type", "b2/x-auto"},
      {"X-Bz-Content-Sha1", Utilities.sha1hash(iodata)}
    ]
    resp = HTTPRequest.b2_upload_file(upload_auth, headers, iodata)
    |> perform_request
    |> parse_json_response

    with  {:ok, file} <- resp,
          do: {:ok, File.from_json(file)}
  end

  def delete(auth, %File{file_name: fname, file_id: fid}) do
    resp = HTTPRequest.b2_delete_file_version(auth, fname, fid)
    |> perform_request
    |> parse_json_response

    with  {:ok, _} <- resp,
          do: :ok
  end

  def delete(auth, bucket, filename) when is_binary(filename) do
    files = list_file_versions(auth, bucket, %{"startFileName" => filename})
    _ = Enum.take_while(files, fn
      %File{file_name: ^filename} = file ->
        :ok = delete(auth, file)
        true
      _ ->
        false
    end)
    :ok
  end

  def list_file_versions(auth, bucket, opts \\ %{}) do
    Stream.resource(fn -> :start end,
    fn
      :start ->
        fetch_file_versions!(auth, bucket, opts)
      nil ->
        {:halt, nil}
      next_file_id ->
        opts = Map.put(opts, "startFileId", next_file_id)
        fetch_file_versions!(auth, bucket, opts)
    end,
    fn(_) -> :ok end)
  end

  defp fetch_file_versions!(auth, bucket, opts) do
    resp = HTTPRequest.b2_list_file_versions(auth, bucket, opts)
    |> perform_request
    |> parse_json_response
    case resp do
      {:ok, %{"files" => files} = resp_json} ->
        next_file_id = Map.get(resp_json, "nextFileId")
        files = Enum.map(files, &File.from_json/1)
        {files, next_file_id}
      other ->
        raise(inspect(other))
    end
  end

  defp perform_request(request) do
    HTTPoison.request(request.method, request.url, request.request_body,
      request.headers)
  end

  defp parse_json_response({:ok, response}), do: JSONResponseParser.parse(response)
  defp parse_json_response({:error, error}), do: {:error, error.reason}

  defp parse_file_response({:ok, response}), do: FileResponseParser.parse(response)
  defp parse_file_response({:error, error}), do: {:error, error.reason}
end

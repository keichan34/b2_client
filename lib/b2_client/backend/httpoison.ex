defmodule B2Client.Backend.HTTPoison do
  import HTTPoison, only: [get: 3, head: 3, post: 4]

  alias B2Client.{Authorization, Bucket, File, UploadAuthorization}

  @behaviour B2Client.Backend

  def authenticate(application_key_id, application_key) do
    headers = [
      {"Authorization", authorization_header_contents(application_key_id, application_key)}
    ]

    case get("https://api.backblaze.com/b2api/v2/b2_authorize_account", headers, []) do
      {:ok, %{status_code: 200, body: original_body}} ->
        body = Jason.decode!(original_body)

        {:ok,
         %Authorization{
           account_id: body["accountId"],
           api_url: body["apiUrl"],
           authorization_token: body["authorizationToken"],
           bucket_id: body["allowed"]["bucketId"],
           download_url: body["downloadUrl"]
         }}

      {:ok, %{status_code: code, body: original_body}} ->
        body = Jason.decode!(original_body)
        {:error, {:"http_#{code}", body["message"]}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp authorization_header_contents(application_key_id, application_key) do
    "Basic " <> Base.encode64(application_key_id <> ":" <> application_key)
  end

  def get_bucket(b2, bucket_name) do
    uri = b2.api_url <> "/b2api/v2/b2_list_buckets"
    {:ok, request_body} = Jason.encode(%{
      "accountId" => b2.account_id,
      "bucketName" => bucket_name
    })

    case post(uri, request_body, headers(:post, b2), []) do
      {:ok, %{status_code: 200, body: original_body}} ->
        body = Jason.decode!(original_body)

        bucket =
          Enum.find(body["buckets"], fn
            %{"bucketName" => ^bucket_name} -> true
            _ -> false
          end)

        if bucket do
          {:ok,
           %Bucket{
             bucket_name: bucket["bucketName"],
             bucket_id: bucket["bucketId"],
             bucket_type: bucket["bucketType"],
             account_id: bucket["accountId"]
           }}
        else
          {:error, :bucket_not_found}
        end

      {:ok, %{status_code: code, body: original_body}} ->
        body = Jason.decode!(original_body)
        {:error, {:"http_#{code}", body["message"]}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def download(b2, bucket, path) do
    uri = get_download_url(b2, bucket, path)

    case get(uri, headers(:get, b2), []) do
      {:ok, %{status_code: 200, body: body}} ->
        {:ok, body}

      {:ok, %{status_code: code, body: original_body}} ->
        body = Jason.decode!(original_body)
        {:error, {:"http_#{code}", body["message"]}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def download(b2, file_id) do
    uri = get_download_url(b2, file_id)

    case get(uri, headers(:get, b2), []) do
      {:ok, %{status_code: 200, body: body}} ->
        {:ok, body}

      {:ok, %{status_code: code, body: original_body}} ->
        body = Jason.decode!(original_body)
        {:error, {:"http_#{code}", body["message"]}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def download_head(b2, bucket, path) do
    uri = get_download_url(b2, bucket, path)

    case head(uri, headers(:head, b2), []) do
      {:ok, %{status_code: 200, headers: headers}} ->
        {_, size} =
          Enum.find(headers, {nil, 0}, fn {key, _} ->
            String.downcase(key) == "content-length"
          end)

        {:ok, String.to_integer(size)}
      {:ok, %{status_code: 400, headers: _headers}} ->
        {:error, "Bad request"}
      {:ok, %{status_code: 404, headers: _headers}} ->
        {:error, "File does not exist"}
      {:error, reason} ->
        {:error, reason}
    end
  end

  def download_head(b2, file_id) do
    uri = get_download_url(b2, file_id)

    case head(uri, headers(:head, b2), []) do
      {:ok, %{status_code: 200, headers: headers}} ->
        {_, size} =
          Enum.find(headers, {nil, 0}, fn {key, _} ->
            String.downcase(key) == "content-length"
          end)
        {_, filename} =
          Enum.find(headers, {nil, 0}, fn {key, _} ->
            String.downcase(key) == "x-bz-file-name"
          end)

        {:ok, %{
            size: String.to_integer(size),
            filename: filename
          }
        }
      {:ok, %{status_code: 400, headers: _headers}} ->
        {:error, "Bad request"}
      {:ok, %{status_code: 404, headers: _headers}} ->
        {:error, "File does not exist"}
      {:error, reason} ->
        {:error, reason}
    end
  end

  def get_upload_url(b2, bucket) do
    uri = b2.api_url <> "/b2api/v2/b2_get_upload_url"
    {:ok, request_body} = Jason.encode(%{"bucketId" => bucket.bucket_id})

    case post(uri, request_body, headers(:post, b2), []) do
      {:ok, %{status_code: 200, body: original_body}} ->
        body = Jason.decode!(original_body)

        {:ok,
         %UploadAuthorization{
           bucket_id: body["bucketId"],
           upload_url: body["uploadUrl"],
           authorization_token: body["authorizationToken"]
         }}

      {:ok, %{status_code: code, body: original_body}} ->
        body = Jason.decode!(original_body)
        {:error, {:"http_#{code}", body["message"]}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def upload(b2, iodata, filename) do
    upload(b2, %Bucket{bucket_id: b2.bucket_id}, iodata, filename)
  end

  def upload(b2, %Bucket{} = bucket, iodata, filename) do
    case get_upload_url(b2, bucket) do
      {:ok, auth} ->
        upload(b2, auth, iodata, filename)

      {:error, reason} ->
        {:error, reason}
    end
  end

  def upload(b2, %UploadAuthorization{} = auth, iodata, filename) do
    headers = [
      {"Authorization", auth.authorization_token},
      {"X-Bz-File-Name", filename},
      {"Content-Type", "b2/x-auto"},
      {"X-Bz-Content-Sha1", sha1hash(iodata)}
    ]

    options = [
      recv_timeout: :infinity
    ]

    case post(auth.upload_url, iodata, headers, options) do
      {:ok, %{status_code: 200, body: original_body}} ->
        body = Jason.decode!(original_body)
        {:ok, to_file(body)}

      {:ok, %{status_code: code}} when code >= 500 and code < 600 ->
        # Failure codes in the range 500 through 599 mean that the storage pod
        # is having trouble accepting your data. In this case you must call
        # b2_get_upload_url to get a new uploadUrl and a new authorizationToken.
        upload(b2, %Bucket{bucket_id: auth.bucket_id}, iodata, filename)

      {:ok, %{status_code: code, body: original_body}} when code >= 400 and code < 500 ->
        # If the failure returns an HTTP status code in the range 400 through
        # 499, it means that there is a problem with your request.
        body = Jason.decode!(original_body)
        {:error, {:"http_#{code}", body["message"]}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def delete(b2, %File{} = file) do
    uri = b2.api_url <> "/b2api/v2/b2_delete_file_version"

    {:ok, request_body} =
      Jason.encode(%{
        "fileName" => file.file_name,
        "fileId" => file.file_id
      })

    case post(uri, request_body, headers(:post, b2), []) do
      {:ok, %{status_code: 200}} ->
        :ok

      {:ok, %{status_code: code, body: original_body}} ->
        body = Jason.decode!(original_body)
        {:error, {:"http_#{code}", body["message"]}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def delete(b2, bucket, filename) when is_binary(filename) do
    case list_file_versions(b2, bucket, filename) do
      {:ok, files} ->
        Enum.each(files, fn file ->
          delete(b2, file)
        end)

      error ->
        error
    end
  end

  def list_file_versions(b2, bucket, filename) when is_binary(filename) do
    uri = b2.api_url <> "/b2api/v2/b2_list_file_versions"

    {:ok, request_body} =
      Jason.encode(%{
        "bucketId" => bucket.bucket_id,
        "startFileName" => filename
      })

    case post(uri, request_body, headers(:post, b2), []) do
      {:ok, %{status_code: 200, body: original_body}} ->
        body = Jason.decode!(original_body)

        {:ok,
         body["files"]
         |> Enum.filter(&match?(%{"fileName" => ^filename}, &1))
         |> Enum.map(&to_file(&1, bucket))}

      {:ok, %{status_code: code, body: original_body}} ->
        body = Jason.decode!(original_body)
        {:error, {:"http_#{code}", body["message"]}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @spec headers(atom, Authorization.t()) :: [{String.t(), String.t()}, ...]
  defp headers(:post, auth) do
    headers(:get, auth) ++
      [
        {"Content-Type", "application/json"}
      ]
  end

  defp headers(_, auth) do
    [
      {"Accept", "application/json"},
      {"Authorization", auth.authorization_token},
      {"User-Agent", "Elixir/B2Client"}
    ]
  end

  defp sha1hash(iodata) do
    :crypto.hash(:sha, iodata) |> Base.encode16(case: :lower)
  end

  defp get_download_url(%{download_url: download_url}, %{bucket_name: bucket_name}, filename) do
    download_url <> "/file/" <> bucket_name <> "/" <> filename
  end

  defp get_download_url(%{download_url: download_url}, file_id) do
    download_url <> "/b2api/v2/b2_download_file_by_id?fileId=" <> file_id
  end

  defp to_file(file, bucket \\ %Bucket{}) do
    %File{
      bucket_id: file["bucketId"] || bucket.bucket_id,
      file_id: file["fileId"],
      file_name: file["fileName"],
      content_length: file["contentLength"],
      content_sha1: file["contentSha1"],
      content_type: file["contentType"],
      file_info: file["fileInfo"]
    }
  end
end

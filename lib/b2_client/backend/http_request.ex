defmodule B2Client.Backend.HTTPRequest do
  @moduledoc false

  defstruct [:method, :url, :request_body, :headers]

  @type http_header :: {String.t, String.t}
  @type http_headers :: list(http_header)

  @type t :: %__MODULE__{
    method: :get | :post | :head,
    url: String.t,
    request_body: iodata,
    headers: http_headers
  }

  alias B2Client.{Authorization, Bucket, UploadAuthorization}
  alias B2Client.Backend.HTTPRequest

  @spec b2_authorize_account(String.t, String.t) :: t
  def b2_authorize_account(account_id, application_key) do
    basic_auth_header = "Basic " <>
      Base.encode64(account_id <> ":" <> application_key)

    %HTTPRequest{
      method: :get,
      url: "https://api.backblaze.com/b2api/v1/b2_authorize_account",
      headers: [
        {"Authorization", basic_auth_header},
        {"User-Agent", "Elixir/B2Client"}
      ]
    }
  end

  @spec b2_delete_file_version(Authorization.t, String.t, String.t) :: t
  def b2_delete_file_version(auth, file_name, file_id) do
    build_request(:post, auth, :api, "b2_delete_file_version")
    |> put_request_body(~s({"fileName":"#{file_name}","fileId":"#{file_id}"}))
  end

  @spec b2_download_file_by_id(Authorization.t, String.t) :: t
  def b2_download_file_by_id(auth, file_id) do
    build_request(:get, auth, :download, "b2_download_file_by_id", %{"fileId" => file_id})
  end

  @spec b2_download_file_by_name(Authorization.t, Bucket.t, String.t) :: t
  def b2_download_file_by_name(auth, bucket, file_path) do
    request = build_request(:get, auth, :download, "b2_download_file_by_name")
    Map.update(request, :url, "", &(&1 <> bucket.bucket_name <> "/" <> file_path))
  end

  @spec b2_get_file_info(Authorization.t, String.t) :: t
  def b2_get_file_info(auth, file_id) do
    build_request(:post, auth, :api, "b2_get_file_info")
    |> put_request_body(~s({"fileId":"#{file_id}"}))
  end

  @spec b2_get_upload_url(Authorization.t, Bucket.t) :: t
  def b2_get_upload_url(auth, bucket) do
    build_request(:post, auth, :api, "b2_get_upload_url")
    |> put_request_body(~s({"bucketId":"#{bucket.bucket_id}"}))
  end

  @spec b2_list_buckets(Authorization.t) :: t
  def b2_list_buckets(auth) do
    build_request(:post, auth, :api, "b2_list_buckets")
    |> put_request_body(~s({"accountId":"#{auth.account_id}"}))
  end

  @spec b2_list_file_names(Authorization.t, Bucket.t) :: t
  @spec b2_list_file_names(Authorization.t, Bucket.t, map) :: t
  def b2_list_file_names(auth, bucket, opts \\ %{}) do
    opts = Map.put(opts, "bucketId", bucket.bucket_id)
    build_request(:post, auth, :api, "b2_list_file_names")
    |> put_request_body(opts)
  end

  @spec b2_list_file_versions(Authorization.t, Bucket.t) :: t
  @spec b2_list_file_versions(Authorization.t, Bucket.t, map) :: t
  def b2_list_file_versions(auth, bucket, opts \\ %{}) do
    opts = Map.put(opts, "bucketId", bucket.bucket_id)
    build_request(:post, auth, :api, "b2_list_file_versions")
    |> put_request_body(opts)
  end

  @spec b2_upload_file(UploadAuthorization.t, http_headers, iodata) :: t
  def b2_upload_file(upload_auth, headers, file_contents) do
    headers = Enum.into(headers, %{})
    headers = Map.merge(%{
      "Content-Type" => "b2/x-auto",
      "Authorization" => upload_auth.authorization_token
    }, headers)
    |> Map.drop([
      "Cache-Control",
      "Content-Disposition",
      "Content-Encoding",
      "Content-Language",
      "Content-Location",
      "Content-Language",
      "Content-Range",
      "Expires"
    ])
    |> Enum.into([])

    %HTTPRequest{
      method: :post,
      url: upload_auth.upload_url,
      headers: headers,
      request_body: file_contents
    }
  end

  defp build_request(method, auth, url_type, api_name, query_args \\ %{}) do
    %HTTPRequest{
      method: method,
      url: url_for(url_type, auth, api_name, query_args),
      headers: headers(method, auth)
    }
  end

  defp put_request_body(request, body) when is_map(body),
    do: put_request_body(request, Poison.encode_to_iodata!(body))
  defp put_request_body(request, body),
    do: %{request | request_body: body}

  @spec headers(atom, Authorization.t) :: http_headers
  defp headers(:post, auth) do
    headers(:get, auth) ++ [
      {"Content-Type", "application/json"}
    ]
  end

  defp headers(_, auth) do
    [
      {"Authorization", auth.authorization_token},
      {"User-Agent", "Elixir/B2Client"},
    ]
  end

  defp url_for(url_type, auth, api_name, query_args) when is_map(query_args) do
    qstr = if map_size(query_args) > 0 do
      "?" <> URI.encode_query(query_args)
    else
      ""
    end

    url_for(url_type, auth, api_name, qstr)
  end

  defp url_for(:download, %{download_url: base}, "b2_download_file_by_name", _) do
    base <> "/file/"
  end

  defp url_for(:download, %{download_url: base}, api, qstr) do
    base <> "/b2api/v1/" <> api <> qstr
  end

  defp url_for(:api, %{api_url: base}, api, qstr) do
    base <> "/b2api/v1/" <> api <> qstr
  end
end

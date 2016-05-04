defmodule B2Client.Backend.HTTPRequestTest do
  use ExUnit.Case, async: true

  alias B2Client.{Authorization, Backend.HTTPRequest, Bucket,
    UploadAuthorization}

  def auth, do: %Authorization{
    api_url: "http://api-url.example",
    authorization_token: "token",
    download_url: "http://download-url.example",
    account_id: "valid_account_id"
  }

  def bucket, do: %Bucket{
    bucket_name: "bucket_name",
    bucket_id: "bucket_id",
    bucket_type: "allPrivate",
    account_id: "valid_account_id"
  }

  def upload_auth, do: %UploadAuthorization{
    bucket_id: "bucket_id",
    upload_url: "https://pod-000-0000-00.backblaze.com/b2api/v1/b2_upload_file/4a48fe8875c6214145260818/c001_v0001007_t0042",
    authorization_token: "upload_token"
  }

  test "b2_authorize_account" do
    assert %HTTPRequest{
      method: :get,
      url: "https://api.backblaze.com/b2api/v1/b2_authorize_account",
      headers: headers
    } = HTTPRequest.b2_authorize_account("valid_account_id", "valid_application_key")

    assert {"Authorization", "Basic dmFsaWRfYWNjb3VudF9pZDp2YWxpZF9hcHBsaWNhdGlvbl9rZXk="} in headers
  end

  test "b2_delete_file_version" do
    assert %HTTPRequest{
      method: :post,
      url: "http://api-url.example/b2api/v1/b2_delete_file_version",
      headers: headers,
      request_body: json_body
    } = HTTPRequest.b2_delete_file_version(auth, "hello.txt", "hello-file-id")

    assert {"Authorization", auth.authorization_token} in headers
    assert {"Content-Type", "application/json"} in headers

    body = Poison.decode!(json_body)
    assert body["fileName"] == "hello.txt"
    assert body["fileId"] == "hello-file-id"
  end

  test "b2_download_file_by_id" do
    assert %HTTPRequest{
      method: :get,
      url: "http://download-url.example/b2api/v1/b2_download_file_by_id?fileId=hello-file-id",
      headers: headers
    } = HTTPRequest.b2_download_file_by_id(auth, "hello-file-id")

    assert {"Authorization", auth.authorization_token} in headers
  end

  test "b2_download_file_by_name" do
    assert %HTTPRequest{
      method: :get,
      url: "http://download-url.example/file/bucket_name/file/path.txt",
      headers: headers
    } = HTTPRequest.b2_download_file_by_name(auth, bucket, "file/path.txt")

    assert {"Authorization", auth.authorization_token} in headers
  end

  test "b2_get_file_info" do
    assert %HTTPRequest{
      method: :post,
      url: "http://api-url.example/b2api/v1/b2_get_file_info",
      headers: headers,
      request_body: json_body
    } = HTTPRequest.b2_get_file_info(auth, "hello-file-id")

    assert {"Authorization", auth.authorization_token} in headers
    assert {"Content-Type", "application/json"} in headers

    body = Poison.decode!(json_body)
    assert body["fileId"] == "hello-file-id"
  end

  test "b2_get_upload_url" do
    assert %HTTPRequest{
      method: :post,
      url: "http://api-url.example/b2api/v1/b2_get_upload_url",
      headers: headers,
      request_body: json_body
    } = HTTPRequest.b2_get_upload_url(auth, bucket)

    assert {"Authorization", auth.authorization_token} in headers
    assert {"Content-Type", "application/json"} in headers

    body = Poison.decode!(json_body)
    assert body["bucketId"] == bucket.bucket_id
  end

  test "b2_list_buckets" do
    assert %HTTPRequest{
      method: :post,
      url: "http://api-url.example/b2api/v1/b2_list_buckets",
      headers: headers,
      request_body: json_body
    } = HTTPRequest.b2_list_buckets(auth)

    assert {"Authorization", auth.authorization_token} in headers
    assert {"Content-Type", "application/json"} in headers

    body = Poison.decode!(json_body)
    assert body["accountId"] == auth.account_id
  end

  test "b2_list_file_names" do
    assert %HTTPRequest{
      method: :post,
      url: "http://api-url.example/b2api/v1/b2_list_file_names",
      headers: headers,
      request_body: json_body
    } = HTTPRequest.b2_list_file_names(auth, bucket, %{"startFileName" => "hello"})

    assert {"Authorization", auth.authorization_token} in headers
    assert {"Content-Type", "application/json"} in headers

    body = Poison.decode!(json_body)
    assert body["bucketId"] == bucket.bucket_id
    assert body["startFileName"] == "hello"
  end

  test "b2_list_file_versions" do
    assert %HTTPRequest{
      method: :post,
      url: "http://api-url.example/b2api/v1/b2_list_file_versions",
      headers: headers,
      request_body: json_body
    } = HTTPRequest.b2_list_file_versions(auth, bucket, %{"startFileId" => "hello"})

    assert {"Authorization", auth.authorization_token} in headers
    assert {"Content-Type", "application/json"} in headers

    body = Poison.decode!(json_body)
    assert body["bucketId"] == bucket.bucket_id
    assert body["startFileId"] == "hello"
  end

  test "b2_upload_file" do
    assert %HTTPRequest{
      method: :post,
      url: url,
      headers: headers,
      request_body: body
    } = HTTPRequest.b2_upload_file(upload_auth, [
      {"X-Bz-File-Name", "hello.txt"},
      {"Content-Length", "5"},
      {"X-Bz-Content-Sha1", "XXX"}
    ], "hello")

    assert url == upload_auth.upload_url
    assert {"Authorization", upload_auth.authorization_token} in headers
    assert {"Content-Type", "b2/x-auto"} in headers
    assert {"X-Bz-File-Name", "hello.txt"} in headers
    assert {"Content-Length", "5"} in headers
    assert {"X-Bz-Content-Sha1", "XXX"} in headers

    assert body == "hello"
  end
end

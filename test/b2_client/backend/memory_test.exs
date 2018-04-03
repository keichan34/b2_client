defmodule B2Client.Backend.MemoryTest do
  use ExUnit.Case, async: false

  def backend, do: B2Client.Backend.Memory

  alias B2Client.{Authorization, Bucket, File}

  @account_id "valid_account_id"
  @application_key "valid_application_key"

  setup do
    backend().reset!
    :ok
  end

  test "authenticate/2" do
    assert {:ok, %Authorization{}} = backend().authenticate(@account_id, @application_key)
  end

  test "get_bucket/2" do
    {:ok, auth} = backend().authenticate(@account_id, @application_key)
    assert {:ok, %Bucket{} = bucket} = backend().get_bucket(auth, "ex-b2-client-test-bucket")
    assert bucket.bucket_name == "ex-b2-client-test-bucket"
    assert bucket.bucket_id == "8c654d7edfe71ef507ed5c27d6b787a5"
    assert bucket.bucket_type == "allPrivate"
    assert bucket.account_id == "valid_account_id"
  end

  test "download/3 when the file exists" do
    {:ok, auth} = backend().authenticate(@account_id, @application_key)
    assert {:ok, %Bucket{} = bucket} = backend().get_bucket(auth, "ex-b2-client-test-bucket")

    {:ok, %File{}} = backend().upload(auth, bucket, "hello there", "hello_there.txt")
    assert {:ok, "hello there"} = backend().download(auth, bucket, "hello_there.txt")
  end

  test "download/3 when the file doesn't exist" do
    {:ok, auth} = backend().authenticate(@account_id, @application_key)
    assert {:ok, %Bucket{} = bucket} = backend().get_bucket(auth, "ex-b2-client-test-bucket")

    assert {:error, {:http_404, _}} = backend().download(auth, bucket, "nope.txt")
  end

  test "upload/4 to a Bucket.t" do
    {:ok, auth} = backend().authenticate(@account_id, @application_key)
    assert {:ok, %Bucket{} = bucket} = backend().get_bucket(auth, "ex-b2-client-test-bucket")

    assert {:ok, %File{} = file} =
             backend().upload(auth, bucket, "hello there", "hello_there.txt")

    assert file.file_name == "hello_there.txt"
    assert file.content_length == 11
  end
end

defmodule B2Client.Backend.HTTPoisonTest do
  use ExUnit.Case, async: false
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  def backend, do: B2Client.Backend.HTTPoison

  alias B2Client.{Authorization, Bucket, File}

  @account_id Application.get_env(:b2_client, :account_id)
  @application_key Application.get_env(:b2_client, :application_key)

  setup_all do
    on_exit(fn ->
      {{year, _, _}, _} = :calendar.local_time()

      dir = Path.expand("../../fixtures/vcr_cassettes", __DIR__)
      {:ok, files} = Elixir.File.ls(dir)

      Enum.each(files, fn file ->
        file = Path.expand(file, dir)
        contents = Elixir.File.read!(file)

        contents =
          Regex.replace(
            ~r/3_#{year}\d{10}_[0-9a-f]{24}_[0-9a-f]{40}_000_(acct|upld)/,
            contents,
            "3_#{year}XXXXXXXXXX_XXXXXXXXXXXXXXXXXXXXXXXX_XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX_000_\\1"
          )

        Elixir.File.write!(file, contents)
      end)
    end)

    :ok
  end

  test "authenticate/2" do
    use_cassette "httpoison_authenticate_2" do
      assert {:ok, %Authorization{}} = backend().authenticate(@account_id, @application_key)
    end
  end

  test "get_bucket/2" do
    use_cassette "httpoison_get_bucket_2" do
      {:ok, auth} = backend().authenticate(@account_id, @application_key)
      assert {:ok, %Bucket{} = bucket} = backend().get_bucket(auth, "ex-b2-client-test-bucket")
      assert bucket.bucket_name == "ex-b2-client-test-bucket"
      assert bucket.bucket_id == "6dd33353ffdd65f85e410312"
      assert bucket.bucket_type == "allPrivate"
      assert bucket.account_id == "valid_account_id"
    end
  end

  test "download/2 when the file exists" do
    use_cassette "httpoison_download_2_file_exists" do
      {:ok, auth} = backend().authenticate(@account_id, @application_key)
      file_id = "4_z6dd33353ffdd65f85e410312_f1172ee1b90ad92b9_d20160502_m061500_c000_v0001007_t0027"

      assert {:ok, "hello there"} = backend().download(auth, file_id)
    end
  end

  test "download/2 when the file doesn't exist" do
    use_cassette "httpoison_download_2_file_doesnt_exist" do
      {:ok, auth} = backend().authenticate(@account_id, @application_key)
      file_id = "4_z6dd33353ffdd65f85e410312_f1172ee1b90ad92b9_d20160502_m061500_c000_v0001007_t0026"

      assert {:error, {:http_401, _}} = backend().download(auth, file_id)
    end
  end

  test "download/3 when the file exists" do
    use_cassette "httpoison_download_3_file_exists" do
      {:ok, auth} = backend().authenticate(@account_id, @application_key)
      assert {:ok, %Bucket{} = bucket} = backend().get_bucket(auth, "ex-b2-client-test-bucket")

      assert {:ok, "hello there"} = backend().download(auth, bucket, "hello_there.txt")
    end
  end

  test "download/3 when the file doesn't exist" do
    use_cassette "httpoison_download_3_file_doesnt_exist" do
      {:ok, auth} = backend().authenticate(@account_id, @application_key)
      assert {:ok, %Bucket{} = bucket} = backend().get_bucket(auth, "ex-b2-client-test-bucket")

      assert {:error, {:http_404, _}} = backend().download(auth, bucket, "nope.txt")
    end
  end

  test "download_head/2 when the file exists" do
    use_cassette "httpoison_download_head_2_file_exists" do
      {:ok, auth} = backend().authenticate(@account_id, @application_key)
      file_id = "4_z6dd33353ffdd65f85e410312_f1172ee1b90ad92b9_d20160502_m061500_c000_v0001007_t0027"

      assert {:ok, %{filename: "hello_there.txt", size: 11}} = backend().download_head(auth, file_id)
    end
  end

  test "download_head/2 when the file doesn't exist" do
    use_cassette "httpoison_download_head_2_file_doesnt_exist" do
      {:ok, auth} = backend().authenticate(@account_id, @application_key)
      file_id = "4_z6dd33353ffdd65f85e410312_f1172ee1b90ad92b9_d20160502_m061500_c000_v0001007_t0026"

      assert {:error, _} = backend().download_head(auth, file_id)
    end
  end


  test "download_head/3 when the file exists" do
    use_cassette "httpoison_download_head_3_file_exists" do
      {:ok, auth} = backend().authenticate(@account_id, @application_key)
      {:ok, bucket} = backend().get_bucket(auth, "ex-b2-client-test-bucket")
      filename = "hello_there.txt"

      assert {:ok, 11} = backend().download_head(auth, bucket, filename)
    end
  end

  test "download_head/3 when the file doesn't exist" do
    use_cassette "httpoison_download_head_3_file_doesnt_exist" do
      {:ok, auth} = backend().authenticate(@account_id, @application_key)
      {:ok, bucket} = backend().get_bucket(auth, "ex-b2-client-test-bucket")
      filename = "nope.txt"

      assert {:error, _} = backend().download_head(auth, bucket, filename)
    end
  end

  test "upload/4 to a Bucket.t" do
    use_cassette "httpoison_upload_4_bucket" do
      {:ok, auth} = backend().authenticate(@account_id, @application_key)
      assert {:ok, %Bucket{} = bucket} = backend().get_bucket(auth, "ex-b2-client-test-bucket")

      assert {:ok, %File{} = file} =
               backend().upload(auth, bucket, "hello there", "hello_there.txt")

      assert file.file_name == "hello_there.txt"
      assert file.content_length == 11
    end
  end
end

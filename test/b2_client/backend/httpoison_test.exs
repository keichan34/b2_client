defmodule B2Client.Backend.HTTPoisonTest do
  use ExUnit.Case, async: false
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  def backend, do: B2Client.Backend.HTTPoison

  alias B2Client.{Authorization, Bucket, File}

  @application_key_id Application.get_env(:b2_client, :application_key_id)
  @application_key Application.get_env(:b2_client, :application_key)
  @test_bucket Application.get_env(:b2_client, :test_bucket)
  @test_bucket_id Application.get_env(:b2_client, :test_bucket_id)
  @test_file_id Application.get_env(:b2_client, :test_file_id)

  setup_all do
    on_exit(fn ->
      dir = Path.expand("../../fixtures/vcr_cassettes", __DIR__)
      {:ok, files} = Elixir.File.ls(dir)

      Enum.each(files, fn file ->
        file = Path.expand(file, dir)
        contents = Elixir.File.read!(file)

        contents =
          Regex.replace(
            ~r/\\\"accountId\\\":\s*\\\"[a-z0-9]+\\\"/,
            contents,
            "\\\"accountId\\\":\\\"CENSORED\\\"")

        contents =
          Regex.replace(~r/[^\"]*(acct|upld)[^\\\"]*/, contents, "CENSORED")

        Elixir.File.write!(file, contents)
      end)
    end)

    :ok
  end

  test "authenticate/2" do
    use_cassette "httpoison_authenticate_2" do
      assert {:ok, %Authorization{}} = backend().authenticate(@application_key_id, @application_key)
    end
  end

  test "get_bucket/2" do
    use_cassette "httpoison_get_bucket_2" do
      {:ok, auth} = backend().authenticate(@application_key_id, @application_key)
      assert {:ok, %Bucket{} = bucket} = backend().get_bucket(auth, @test_bucket)
      assert bucket.bucket_name == @test_bucket
      assert bucket.bucket_id == @test_bucket_id
      assert bucket.bucket_type == "allPrivate"
    end
  end

  test "upload/4 to a Bucket.t" do
    use_cassette "httpoison_upload_4_bucket" do
      {:ok, auth} = backend().authenticate(@application_key_id, @application_key)
      assert {:ok, %Bucket{} = bucket} = backend().get_bucket(auth, @test_bucket)

      assert {:ok, %File{} = file} =
               backend().upload(auth, bucket, "hello there", "hello_there.txt")

      assert file.file_name == "hello_there.txt"
      assert file.content_length == 11
    end
  end

  test "download/2 when the file exists" do
    use_cassette "httpoison_download_2_file_exists" do
      {:ok, auth} = backend().authenticate(@application_key_id, @application_key)
      file_id = @test_file_id

      assert {:ok, "hello there"} = backend().download(auth, file_id)
    end
  end

  test "download/2 when the file doesn't exist" do
    use_cassette "httpoison_download_2_file_doesnt_exist" do
      {:ok, auth} = backend().authenticate(@application_key_id, @application_key)
      file_id = "4_z84033973b2fd87077f35021f_f110c0206f69f5407_d20200724_m134209_c003_v0312003_t0015"

      assert {:error, {:http_404, _}} = backend().download(auth, file_id)
    end
  end

  test "download/3 when the file exists" do
    use_cassette "httpoison_download_3_file_exists" do
      {:ok, auth} = backend().authenticate(@application_key_id, @application_key)
      assert {:ok, %Bucket{} = bucket} = backend().get_bucket(auth, @test_bucket)

      assert {:ok, "hello there"} = backend().download(auth, bucket, "hello_there.txt")
    end
  end

  test "download/3 when the file doesn't exist" do
    use_cassette "httpoison_download_3_file_doesnt_exist" do
      {:ok, auth} = backend().authenticate(@application_key_id, @application_key)
      assert {:ok, %Bucket{} = bucket} = backend().get_bucket(auth, @test_bucket)

      assert {:error, {:http_404, _}} = backend().download(auth, bucket, "nope.txt")
    end
  end

  test "download_head/2 when the file exists" do
    use_cassette "httpoison_download_head_2_file_exists" do
      {:ok, auth} = backend().authenticate(@application_key_id, @application_key)
      file_id = @test_file_id

      assert {:ok, %{filename: "hello_there.txt", size: 11}} = backend().download_head(auth, file_id)
    end
  end

  test "download_head/2 when the file doesn't exist" do
    use_cassette "httpoison_download_head_2_file_doesnt_exist" do
      {:ok, auth} = backend().authenticate(@application_key_id, @application_key)
      file_id = "4_z84033973b2fd87077f35021f_f110c0206f69f5407_d20200724_m134209_c003_v0312003_t0015"

      assert {:error, _} = backend().download_head(auth, file_id)
    end
  end


  test "download_head/3 when the file exists" do
    use_cassette "httpoison_download_head_3_file_exists" do
      {:ok, auth} = backend().authenticate(@application_key_id, @application_key)
      {:ok, bucket} = backend().get_bucket(auth, @test_bucket)
      filename = "hello_there.txt"

      assert {:ok, 11} = backend().download_head(auth, bucket, filename)
    end
  end

  test "download_head/3 when the file doesn't exist" do
    use_cassette "httpoison_download_head_3_file_doesnt_exist" do
      {:ok, auth} = backend().authenticate(@application_key_id, @application_key)
      {:ok, bucket} = backend().get_bucket(auth, @test_bucket)
      filename = "nope.txt"

      assert {:error, _} = backend().download_head(auth, bucket, filename)
    end
  end
end

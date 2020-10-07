defmodule B2Client.Backend.Memory do
  @moduledoc """
  A mock to store test data.
  """

  use GenServer

  alias B2Client.{Authorization, Bucket, File, UploadAuthorization}

  @behaviour B2Client.Backend

  def start_link do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @doc """
  Resets the backend back to the initial state.
  """
  def reset! do
    GenServer.call(__MODULE__, :reset)
  end

  ## B2Client.Backend callbacks ##

  def authenticate(application_key_id, application_key) do
    GenServer.call(__MODULE__, {:authenticate, application_key_id, application_key})
  end

  def get_bucket(b2, bucket_name) do
    GenServer.call(__MODULE__, {:get_bucket, b2, bucket_name})
  end

  def get_upload_url(b2, bucket) do
    GenServer.call(__MODULE__, {:get_upload_url, b2, bucket})
  end

  def upload(b2, %Bucket{} = bucket, iodata, filename) do
    {:ok, auth} = get_upload_url(b2, bucket)
    upload(b2, auth, iodata, filename)
  end

  def upload(b2, %UploadAuthorization{} = auth, iodata, filename) do
    GenServer.call(__MODULE__, {:upload, b2, auth, iodata, filename})
  end

  def download(b2, bucket, path) do
    GenServer.call(__MODULE__, {:download, b2, bucket, path})
  end

  def download_head(b2, bucket, path) do
    GenServer.call(__MODULE__, {:download_head, b2, bucket, path})
  end

  def delete(b2, bucket, path) do
    GenServer.call(__MODULE__, {:delete, b2, bucket, path})
  end

  # def delete(b2, file) do
  #   GenServer.call(__MODULE__, {:delete, b2, file})
  # end

  # def list_file_versions(b2, bucket, path) do
  #   GenServer.call(__MODULE__, {:list_file_versions, b2, bucket, path})
  # end

  ## GenServer Callbacks ##

  def init(:ok) do
    {:ok, initial_state()}
  end

  defp initial_state do
    %{
      accounts: %{
        "valid_application_key_id" => %{
          api_url: "https://api900.backblaze.example",
          download_url: "https://f900.backblaze.example",
          account_id: "valid_account_id",
          application_key: "valid_application_key"
        }
      },
      authorizations: %{
        "fake_auth_token" => "valid_application_key_id"
      },
      buckets: %{
        "valid_account_id" => [
          %Bucket{
            bucket_name: "ex-b2-client-test-bucket",
            bucket_id: "8c654d7edfe71ef507ed5c27d6b787a5",
            bucket_type: "allPrivate",
            account_id: "valid_account_id"
          }
        ]
      },
      files: %{}
    }
  end

  def handle_call({:authenticate, application_key_id, application_key}, _from, state) do
    r =
      case Map.fetch(state.accounts, application_key_id) do
        {:ok, %{application_key: ^application_key} = acct} ->
          client = Map.drop(acct, [:application_key])

          client =
            Map.merge(%Authorization{}, client)
            |> Map.put(:authorization_token, "fake_auth_token")

          {:ok, client}

        _ ->
          {:error, :authentication_failed}
      end

    {:reply, r, state}
  end

  def handle_call(:reset, _from, _state) do
    {:reply, :ok, initial_state()}
  end

  def handle_call(rpc, _from, state) do
    b2 = elem(rpc, 1)
    auth = validate_authentication!(b2, state)
    {r, state} = execute_rpc(auth, rpc, state)
    {:reply, r, state}
  end

  defp validate_authentication!(b2, state) do
    case Map.fetch(state.authorizations, b2.authorization_token) do
      {:ok, account_id} ->
        client = Map.drop(state.accounts[account_id], [:application_key])

        Map.merge(%Authorization{}, client)
        |> Map.put(:authorization_token, "fake_auth_token")

      :error ->
        false
    end
  end

  defp execute_rpc(false, _, state), do: {{:error, :token_wrong}, state}

  defp execute_rpc(b2, {:get_bucket, _, bucket_name}, state) do
    b =
      Enum.find(state.buckets[b2.account_id], fn
        %{bucket_name: ^bucket_name} -> true
        _ -> false
      end)

    if b do
      {{:ok, b}, state}
    else
      {{:error, :bucket_not_found}, state}
    end
  end

  defp execute_rpc(_b2, {:get_upload_url, _, bucket}, state) do
    {{:ok,
      %UploadAuthorization{
        bucket_id: bucket.bucket_id,
        upload_url:
          "https://pod-000-1000-00.backblaze.example/b2api/v1/b2_upload_file?cvt=c000-1000-00&bucket=#{
            bucket.bucket_id
          }",
        authorization_token: "fake_upload_auth_token"
      }}, state}
  end

  defp execute_rpc(b2, {:upload, _, auth, iodata, filename}, state) do
    bucket_id = auth.bucket_id

    bucket =
      Enum.find(state.buckets[b2.account_id], fn
        %{bucket_id: ^bucket_id} -> true
        _ -> false
      end)

    uri = get_download_url(b2, bucket, filename)
    bytes = IO.iodata_to_binary(iodata)

    file =
      %File{
        bucket_id: auth.bucket_id,
        file_id: "some-random-file-id",
        file_name: filename,
        content_length: byte_size(bytes),
        content_sha1: sha1hash(bytes),
        content_type: "text/plain",
        file_info: %{}
      }
      |> Map.put(:file_contents, bytes)

    state = update_in(state.files, &Map.put(&1, uri, file))

    {
      {:ok, file},
      state
    }
  end

  defp execute_rpc(b2, {:download, _, bucket, path}, state) do
    uri = get_download_url(b2, bucket, path)

    case Map.fetch(state.files, uri) do
      {:ok, file} ->
        {{:ok, file.file_contents}, state}

      _ ->
        {{:error, {:http_404, ""}}, state}
    end
  end

  defp execute_rpc(b2, {:download_head, _, bucket, path}, state) do
    case execute_rpc(b2, {:download, nil, bucket, path}, state) do
      {{:ok, contents}, state} ->
        file_size = byte_size(contents)
        {{:ok, file_size}, state}

      other ->
        other
    end
  end

  defp execute_rpc(b2, {:delete, _, bucket, path}, state) do
    uri = get_download_url(b2, bucket, path)
    state = update_in(state.files, &Map.delete(&1, uri))
    {:ok, state}
  end

  # defp execute_rpc(b2, {:list_file_versions, _, bucket, path}, state) do
  #   uri = get_download_url(b2, bucket, path)
  #   file_versions = Enum.filter(state.files, fn
  #     {^uri, _} -> true
  #     _ -> false
  #   end)
  #   {{:ok, file_versions}, state}
  # end

  defp execute_rpc(_, bad_rpc, state) do
    IO.inspect(bad_rpc)
    {{:error, :badrpc}, state}
  end

  defp sha1hash(bytes) do
    :crypto.hash(:sha, bytes) |> Base.encode16(case: :lower)
  end

  defp get_download_url(%{download_url: download_url}, %{bucket_name: bucket_name}, filename) do
    download_url <> "/file/" <> bucket_name <> "/" <> filename
  end
end

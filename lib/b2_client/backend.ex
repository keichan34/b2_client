defmodule B2Client.Backend do
  alias B2Client.{Authorization, Bucket, File, UploadAuthorization}

  @type account_id :: String.t
  @type application_key :: String.t

  @type file_contents :: iodata
  @type file_name :: String.t

  @callback authenticate(account_id, application_key) :: {:ok, Authorization.t} | {:error, atom}
  @callback get_bucket(Authorization.t, String.t) :: {:ok, Bucket.t} | {:error, atom}

  @callback download(Authorization.t, Bucket.t, Path.t) :: {:ok, file_contents} | {:error, atom}
  @callback download_head(Authorization.t, Bucket.t, Path.t) :: {:ok, non_neg_integer} | {:error, atom}

  @callback get_upload_url(Authorization.t, Bucket.t) :: {:ok, UploadAuthorization.t} | {:error, atom}
  @callback upload(Authorization.t, Bucket.t, file_contents, file_name) :: {:ok, File.t} | {:error, atom}
  @callback upload(Authorization.t, UploadAuthorization.t, file_contents, file_name) :: {:ok, File.t} | {:error, atom}

  @callback delete(Authorization.t, Bucket.t, Path.t) :: :ok | {:error, atom}
  @callback delete(Authorization.t, File.t) :: :ok | {:error, atom}

  @callback list_file_versions(Authorization.t, Bucket.t, file_name) :: {:ok, [File.t, ...]} | {:error, atom}
end

defmodule B2Client.Backend do
  @moduledoc """
  Defines the protocol to which a backend that interfaces with B2 adheres to.
  """

  alias B2Client.{Authorization, Bucket, File, UploadAuthorization}

  @type account_id :: String.t
  @type application_key :: String.t

  @type file_contents :: iodata
  @type file_name :: String.t

  @type metadata :: map

  @type error_response :: {:error, :server_error |
    %{String.t => any}}
  @type misc_options :: %{binary => binary}

  @doc """
  Fetch short-lived authorization credentials from Backblaze B2

  Returns an `Authorization` struct with the appropriate credentials. Backends
  use this struct to authenticate their requests to the API or download
  endpoints.
  """
  @callback authenticate(account_id, application_key) :: {:ok, Authorization.t} | error_response

  @doc """
  Retrieves information about a named bucket.

  Returns a `Bucket` struct.
  """
  @callback get_bucket(Authorization.t, String.t) :: {:ok, Bucket.t} | error_response

  @doc """
  Downloads a file (by name) from B2.

  Returns a `File` struct with metadata and contents.

  This function will return `{:error, :bad_hash}` if the SHA1 hash does not
  match. This usually means there has been a network disruption -- retrying
  the request should fix it.
  """
  @callback download(Authorization.t, Bucket.t, Path.t) :: {:ok, File.t} | error_response | {:error, :bad_hash}

  @doc """
  Performs a HEAD request to the download endpoint.

  Returns the `{:ok, size}` where `size` is the number of bytes the file is, or
  an error response.
  """
  @callback download_head(Authorization.t, Bucket.t, Path.t) :: {:ok, non_neg_integer} | error_response

  @doc """
  Authorizes an upload to a specific bucket.
  """
  @callback get_upload_authorization(Authorization.t, Bucket.t) :: {:ok, UploadAuthorization.t} | error_response

  @doc """
  Upload a file to a bucket.

  This function will automatically retrieve the `UploadAuthorization` using the
  provided `Authorization` struct.
  """
  @callback upload(Authorization.t, Bucket.t, file_contents, file_name) :: {:ok, File.t} | error_response

  @doc """
  Upload a file using an `UploadAuthorization`.
  """
  @callback upload(UploadAuthorization.t, file_contents, file_name) :: {:ok, File.t} | error_response

  @doc """
  Delete a file in a bucket.
  """
  @callback delete(Authorization.t, Bucket.t, Path.t) :: :ok | error_response

  @doc """
  Delete a file represented as a `File` struct.
  """
  @callback delete(Authorization.t, File.t) :: :ok | error_response

  @doc """
  Emits a stream of file versions for a specific bucket.

  See `list_file_versions/3` for more information.
  """
  @callback list_file_versions(Authorization.t, Bucket.t) :: Enum.t | no_return

  @doc """
  Emits a stream of file versions for a specific bucket.

  Because querying the B2 API is expensive, the stream is lazily queried. Any
  errors that occur will be thrown as exceptions, so be careful.

  Options are a map with string keys and values. They will be encoded in to the
  request to B2. For valid options, see the [B2 Docs](https://www.backblaze.com/b2/docs/b2_list_file_versions.html).

  Available options (at the time of this writing) are:

  * `startFileName`
  * `startFileId` (note that this will be overridden on the second request onward for pagination)
  * `maxFileCount`
  """
  @callback list_file_versions(Authorization.t, Bucket.t, misc_options) :: Enum.t | no_return
end

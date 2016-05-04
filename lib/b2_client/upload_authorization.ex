defmodule B2Client.UploadAuthorization do
  @moduledoc """
  A struct representing file upload authentication credentials.
  """

  defstruct bucket_id: nil, upload_url: nil, authorization_token: nil

  @type t :: %B2Client.UploadAuthorization{
    bucket_id: String.t,
    upload_url: String.t,
    authorization_token: String.t,
  }

  def from_json(map) do
    %B2Client.UploadAuthorization{
      bucket_id: map["bucketId"],
      upload_url: map["uploadUrl"],
      authorization_token: map["authorizationToken"]
    }
  end
end

defmodule B2Client.UploadAuthorization do
  defstruct bucket_id: nil, upload_url: nil, authorization_token: nil

  @type t :: %B2Client.UploadAuthorization{
    bucket_id: String.t,
    upload_url: String.t,
    authorization_token: String.t,
  }
end

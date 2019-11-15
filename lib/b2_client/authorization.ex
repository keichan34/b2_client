defmodule B2Client.Authorization do
  defstruct api_url: nil, authorization_token: nil, download_url: nil,
            account_id: nil, bucket_id: nil

  @type t :: %B2Client.Authorization{
    account_id: String.t,
    api_url: String.t,
    authorization_token: String.t,
    bucket_id: String.t,
    download_url: String.t
  }
end

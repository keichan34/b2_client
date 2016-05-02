defmodule B2Client.Authorization do
  defstruct api_url: nil, authorization_token: nil, download_url: nil,
            account_id: nil

  @type t :: %B2Client.Authorization{
    api_url: String.t,
    authorization_token: String.t,
    download_url: String.t,
    account_id: String.t
  }
end

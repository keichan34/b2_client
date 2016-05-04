defmodule B2Client.Authorization do
  @moduledoc """
  A struct representing short-lived authentication credentials for B2.

  The credentials may be expired. If the request using these credentials fail
  for a reason of unauthenticated or invalid authentication, try retrieving them
  again.

  When you authorize your account, the token is ["valid for at most 24 hours"](https://www.backblaze.com/b2/docs/b2_authorize_account.html).
  """

  defstruct api_url: nil, authorization_token: nil, download_url: nil,
            account_id: nil

  @type t :: %B2Client.Authorization{
    api_url: String.t,
    authorization_token: String.t,
    download_url: String.t,
    account_id: String.t
  }
end

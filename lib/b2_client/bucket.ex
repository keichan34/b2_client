defmodule B2Client.Bucket do
  defstruct bucket_name: nil, bucket_id: nil, bucket_type: nil, account_id: nil

  @type t :: %B2Client.Bucket{
    bucket_name: String.t,
    bucket_id: String.t,
    bucket_type: String.t,
    account_id: String.t,
  }
end

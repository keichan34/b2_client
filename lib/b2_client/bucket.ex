defmodule B2Client.Bucket do
  @moduledoc """
  A struct representing a bucket in B2.
  """

  defstruct bucket_name: nil, bucket_id: nil, bucket_type: nil, account_id: nil

  @type t :: %B2Client.Bucket{
    bucket_name: String.t,
    bucket_id: String.t,
    bucket_type: String.t,
    account_id: String.t,
  }

  def from_json(map) do
    %B2Client.Bucket{
      bucket_name: map["bucketName"],
      bucket_id: map["bucketId"],
      bucket_type: map["bucketType"],
      account_id: map["accountId"],
    }
  end
end

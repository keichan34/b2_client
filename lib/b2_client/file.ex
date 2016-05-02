defmodule B2Client.File do
  defstruct bucket_id: nil, file_id: nil, file_name: nil, content_length: nil,
            content_sha1: nil, content_type: nil, file_info: nil

  @type t :: %B2Client.File{
    bucket_id: String.t,
    file_id: String.t,
    file_name: String.t,
    content_length: integer,
    content_sha1: String.t,
    content_type: String.t,
    file_info: String.t,
  }
end

defmodule B2Client.File do
  @moduledoc """
  A struct representing a file in B2.
  """

  defstruct bucket_id: nil, file_id: nil, file_name: nil, content_length: nil,
            content_sha1: nil, content_type: nil, file_info: nil, contents: nil

  @type t :: %B2Client.File{
    bucket_id: String.t,
    file_id: String.t,
    file_name: String.t,
    content_length: integer,
    content_sha1: String.t,
    content_type: String.t,
    file_info: String.t,
    contents: iodata
  }

  def from_response_metadata(map) do
    %B2Client.File{
      file_id:        map["x-bz-file-id"],
      file_name:      map["x-bz-file-name"],
      content_length: map["content-length"],
      content_sha1:   map["x-bz-content-sha1"],
      content_type:   map["content-type"],
    }
  end

  def from_json(map) do
    %B2Client.File{
      bucket_id: map["bucketId"],
      file_id: map["fileId"],
      file_name: map["fileName"],
      content_length: map["contentLength"],
      content_sha1: map["contentSha1"],
      content_type: map["contentType"],
      file_info: map["fileInfo"],
    }
  end
end

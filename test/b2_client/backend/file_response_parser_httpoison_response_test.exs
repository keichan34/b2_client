defmodule B2Client.Backend.FileResponseParser.HTTPoisonResponseTest do
  use ExUnit.Case, async: true

  alias B2Client.Backend.FileResponseParser
  alias HTTPoison.Response

  test "a request with status code 200" do
    assert {:ok, file} = FileResponseParser.parse(%Response{
      status_code: 200,
      body: ~s(file contents),
      headers: [
        {"x-bz-file-id", "4_z6dd33"},
        {"Content-Type", "text/plain"},
        {"x-bz-content-sha1", "034fa2ed8e211e4d20f20e792d777f4a30af1a93"}
      ]
    })

    assert file.contents == "file contents"
    assert file.file_id == "4_z6dd33"
    assert file.content_type == "text/plain"
  end

  test "a request with status code 404 with valid JSON" do
    assert {:error, %{"key" => "value"}} = FileResponseParser.parse(%Response{
      status_code: 404,
      body: ~s({"key":"value"})
    })
  end

  test "a request with status code 404 with invalid JSON" do
    assert {:error, :server_error} = FileResponseParser.parse(%Response{
      status_code: 404,
      body: ~s({"key":"value})
    })
  end

  test "a request with status code 500" do
    assert {:error, :server_error} = FileResponseParser.parse(%Response{
      status_code: 500,
      body: ""
    })
  end
end

defmodule B2Client.Backend.JSONResponseParser.HTTPoisonResponseTest do
  use ExUnit.Case, async: true

  alias B2Client.Backend.JSONResponseParser
  alias HTTPoison.Response

  test "a request with status code 200 with valid JSON" do
    assert {:ok, %{"key" => "value"}} = JSONResponseParser.parse(%Response{
      status_code: 200,
      body: ~s({"key":"value"})
    })
  end

  test "a request with status code 200 with invalid JSON" do
    assert {:error, :server_error} = JSONResponseParser.parse(%Response{
      status_code: 200,
      body: ~s({"key":"value})
    })
  end

  test "a request with status code 404 with valid JSON" do
    assert {:error, %{"key" => "value"}} = JSONResponseParser.parse(%Response{
      status_code: 404,
      body: ~s({"key":"value"})
    })
  end

  test "a request with status code 404 with invalid JSON" do
    assert {:error, :server_error} = JSONResponseParser.parse(%Response{
      status_code: 404,
      body: ~s({"key":"value})
    })
  end

  test "a request with status code 500" do
    assert {:error, :server_error} = JSONResponseParser.parse(%Response{
      status_code: 500,
      body: ""
    })
  end
end

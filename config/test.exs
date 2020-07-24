use Mix.Config

config :b2_client,
  start_memory_server: true,
  application_key_id: "valid_account_id",
  application_key: "valid_application_key",
  test_bucket: "valid_bucket_name",
  test_bucket_id: "valid_bucket_id",
  test_file_id: "valid_file_id"

config :exvcr,
  vcr_cassette_library_dir: "test/fixtures/vcr_cassettes",
  filter_request_headers: ["Authorization"]

if File.exists?(Path.expand("test.secret.exs", __DIR__)) do
  import_config "test.secret.exs"
end

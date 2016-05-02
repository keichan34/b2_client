use Mix.Config

config :b2_client,
  start_memory_server: true,
  account_id: "valid_account_id",
  application_key: "valid_application_key"

config :exvcr,
  vcr_cassette_library_dir: "test/fixtures/vcr_cassettes"

if File.exists?(Path.expand("test.secret.exs", __DIR__)) do
  import_config "test.secret.exs"
end

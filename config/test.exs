use Mix.Config

config :b2_client,
  start_memory_server: true,
  application_key_id: "valid_account_id",
  application_key: "valid_application_key",
  test_bucket: "b2client-test",
  test_bucket_id: "84033973b2fd87077f35021f",
  test_file_id: "4_z84033973b2fd87077f35021f_f110c0206f69f5407_d20200724_m134209_c003_v0312003_t0014"

config :exvcr,
  vcr_cassette_library_dir: "test/fixtures/vcr_cassettes",
  filter_request_headers: ["Authorization"]

if File.exists?(Path.expand("test.secret.exs", __DIR__)) do
  import_config "test.secret.exs"
end

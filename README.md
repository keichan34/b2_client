# B2Client

[![Build Status](https://travis-ci.org/keichan34/b2_client.svg?branch=master)](https://travis-ci.org/keichan34/b2_client) [![Deps Status](https://beta.hexfaktor.org/badge/all/github/keichan34/b2_client.svg)](https://beta.hexfaktor.org/github/keichan34/b2_client)

A client for the [Backblaze B2](https://www.backblaze.com/b2/cloud-storage.html) cloud storage service.

## Installation

1. Add `b2_client` to your list of dependencies in `mix.exs`:

	```elixir
	def deps do
	  [{:b2_client, "~> 0.0.1"}]
	end
	```

2. Ensure b2_client is started before your application:

	```elixir
	def application do
	  [applications: [:b2_client]]
	end
	```

## Usage

B2Client ships with two backends -- a HTTPoion-based backend meant for
production and a in-memory temporary backend for testing. The default backend is
the HTTPoison backend.

To change the backend you want to use in the current environment, simply add
the configuration in your `config/XXX.exs` file:

```elixir
config :b2_client, :backend, B2Client.Backend.Memory
```

To retrieve the current backend, use `B2Client.backend`.

## Example

```elixir
{:ok, auth} = B2Client.backend.authenticate("account ID", "application key")
{:ok, bucket} = B2Client.backend.get_bucket(auth, "my-bucket-name")
{:ok, file_contents} = B2Client.backend.download(auth, bucket, "file.txt")
```

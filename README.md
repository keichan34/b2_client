# B2Client

[![Build Status](https://travis-ci.org/keichan34/b2_client.svg?branch=master)](https://travis-ci.org/keichan34/b2_client)

A client for the [Backblaze B2](https://www.backblaze.com/b2/cloud-storage.html) cloud storage service.

## Installation

1. Add `b2_client` to your list of dependencies in `mix.exs`:

	def deps do
	  [{:b2_client, "~> 0.0.1"}]
	end

2. Ensure b2_client is started before your application:

	def application do
	  [applications: [:b2_client]]
	end

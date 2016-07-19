defmodule B2Client.Mixfile do
  use Mix.Project

  def project do
    [
      app: :b2_client,
      version: "0.0.1",
      elixir: "~> 1.2",
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      deps: deps,
      source_url: "https://github.com/keichan34/b2_client",
      docs: [
        extras: ["README.md"]
      ],
      package: package,
      description: description,
      dialyzer: [
        plt_file: ".local.plt",
        plt_add_apps: [
          :exfile,
          :httpoison,
          :poison
        ]
      ],
   ]
  end

  def application do
    [
      mod: {B2Client, []},
      applications: [
        :logger,
        :httpoison,
        :poison,
        :crypto
      ]
    ]
  end

  defp package do
    [
      files: ["lib", "mix.exs", "README*", "LICENSE*"],
      maintainers: ["Keitaroh Kobayashi"],
      licenses: ["MIT"],
      links: %{
        "GitHub" => "https://github.com/keichan34/b2_client",
        "Docs" => "http://hexdocs.pm/b2_client/readme.html"
      }
    ]
  end

  defp description do
    """
    A Backblaze B2 library for Elixir
    """
  end

  defp deps do
    [
      {:httpoison, "~> 0.9.0"},
      {:poison, "~> 1.5 or ~> 2.0"},
      {:exvcr, "~> 0.7", only: :test},
      {:earmark, "~> 1.0", only: :dev},
      {:ex_doc, "~> 0.11", only: :dev}
    ]
  end
end

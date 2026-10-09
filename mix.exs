defmodule Codepagex.MixProject do
  use Mix.Project

  def project do
    [
      app: :codepagex,
      version: "0.2.0",
      elixir: "~> 1.16",
      name: "Codepagex",
      description: description(),
      package: package(),
      source_url: "https://github.com/tallakt/codepagex",
      deps: deps(),
      aliases: [],
      docs: [main: Codepagex],
      dialyzer: [
        plt_add_apps: [:mix],
        plt_local_path: "priv/plts",
        plt_core_path: "priv/plts"
      ],
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      elixirc_paths: elixirc_paths(Mix.env())
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp description() do
    """
    Codepagex is an  elixir library to convert between string encodings to and
    from utf-8. Like iconv, but written in pure Elixir.
    """
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ex_doc, "~> 0.38", only: :dev},
      {:benchee, "~> 1.4", only: :dev},
      {:inch_ex, "~> 2.0", only: :dev},
      {:credo, "~> 1.7", only: :dev},
      {:dialyxir, "~> 1.4", only: :dev, runtime: false},
      {:iconv, "~> 1.0", only: :dev}
    ]
  end

  defp package() do
    [
      files: ["lib", "mix.exs", "README*", "LICENSE*", "CHANGELOG*", "unicode"],
      contributors: ["Tallak Tveide"],
      maintainers: ["Tallak Tveide"],
      licenses: ["Apache-2.0"],
      links: %{
        "GitHub" => "https://github.com/tallakt/codepagex",
        "Changelog" => "https://github.com/tallakt/codepagex/blob/main/CHANGELOG.md"
      }
    ]
  end

  def elixirc_paths(env) do
    case env do
      :dev -> ["lib", "dev"]
      _ -> ["lib"]
    end
  end
end

defmodule Codepagex.Mixfile do
  use Mix.Project

  def project do
    [
      app: :codepagex,
      version: "0.1.7",
      elixir: "~> 1.5",
      name: "Codepagex",
      description: description(),
      package: package(),
      source_url: "https://github.com/tallakt/codepagex",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: [],
      docs: [main: Codepagex]
    ]
  end

  # Configuration for the OTP application
  #
  # Type `mix help compile.app` for more information
  def application() do
    [applications: [:logger]]
  end

  defp description() do
    """
    Codepagex is an  elixir library to convert between string encodings to and
    from utf-8. Like iconv, but written in pure Elixir.
    """
  end

  defp package() do
    [
      files: ["lib", "mix.exs", "README*", "LICENSE*", "unicode"],
      contributors: ["Tallak Tveide"],
      maintainers: ["Tallak Tveide"],
      licenses: ["Apache 2.0"],
      links: %{
        "GitHub" => "https://github.com/tallakt/codepagex"
      }
    ]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type `mix help deps` for more examples and options
  defp deps() do
    [
      {:benchee, "~> 1.3", only: :dev},
      {:earmark, "~> 1.4", only: :dev},
      {:ex_doc, "~> 0.31", only: :dev},
      {:inch_ex, "~> 2.0", only: :docs},
      {:credo, "~> 1.7", only: :dev}
    ]
  end
end

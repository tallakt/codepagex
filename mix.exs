defmodule Codepagex.Mixfile do
  use Mix.Project

  def project do
    [app: :codepagex,
     version: "0.1.2",
     elixir: "~> 1.0",
     name: "Codepagex",
     description: description,
     package: package,
     source_url: "https://github.com/tallakt/codepagex",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps,
     aliases: aliases]
  end

  # Configuration for the OTP application
  #
  # Type `mix help compile.app` for more information
  def application do
    [applications: [:logger]]
  end

  defp description do
    """
    Codepagex is an  elixir library to convert between string encodings to and
    from utf-8. Like iconv, but written in pure Elixir.
    """
  end

  defp package do
    [
      files: ["lib", "mix.exs", "README*", "LICENSE*", "unicode"],
      maintainers: ["Tallak Tveide"],
      licenses: ["Apache 2.0"],
      links: %{
        "GitHub" => "https://github.com/tallakt/codepagex",
        "Docs" => "http://hexdocs.pm/codepagex/"
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
  defp deps do
    [
       {:benchwarmer, "~> 0.0.2", only: :dev },
       {:earmark, only: :dev},
       {:ex_doc, only: :dev}, 
       {:inch_ex, only: :docs}
    ]
  end

  defp aliases do
    [
      {:"codepagex.download", &download_from_unicode_org/1}
    ]
  end
  # This mix task wil download the source mapping files from http://unicode.org
  # 
  # The files should already be present in the git repository, but if necessary,
  # this mix task may be run to refresh them.
  # 
  # `wget` is assumed to be installed.
  # 
  # Some files are left out of the download process altogether, while others are
  # filtered by `.gitignore`, depending on what seemed most practical.
  # 
  # ## Synopsis
  # 
  # $ mix codepagex.download
  # 

  @ftp "ftp://ftp.unicode.org/Public/MAPPINGS/"
  @ignore ~w(
      /Public/MAPPINGS/OBSOLETE
      /Public/MAPPINGS/ISO8859/DatedVersions/
      /Public/MAPPINGS/VENDORS/ADOBE/
      /Public/MAPPINGS/VENDORS/MICSFT/WindowsBestFit/
    ) |> Enum.join(",")
  # note: other files are downloaded, but are in unicode/.gitignore

  def download_from_unicode_org(_) do
    Mix.shell.cmd "wget -nH --cut-dirs=2 -r -P unicode -nv -X #{@ignore} #{@ftp}"
  end
end

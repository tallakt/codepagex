defmodule Mix.Tasks.Codepagex.Unicode do
  use Mix.Task

  @moduledoc """
    This mix task wil download the source mapping files from http://unicode.org

    The files should already be present in the git repository, but if necessary,
    this mix task may be run to refresh them.

    `wget` is assumed to be installed.

    Some files are left out of the download process altogether, while others are
    filtered by `.gitignore`, depending on what seemed most practical.

    Only use this when developing for Codepagex itself.

    ## Synopsis

    $ mix codepagex.unicode

  """


  @ftp "ftp://ftp.unicode.org/Public/MAPPINGS/"

  @ignore ~w(
      /Public/MAPPINGS/OBSOLETE
      /Public/MAPPINGS/ISO8859/DatedVersions/
      /Public/MAPPINGS/VENDORS/ADOBE/
      /Public/MAPPINGS/VENDORS/MICSFT/WindowsBestFit/
    ) |> Enum.join(",")

  # note: other files are downloaded, but are in unicode/.gitignore


  @shortdoc "Download source code files from unicode.org"
  def run(_) do
    Mix.shell.cmd(
      "wget -nH --cut-dirs=2 -r -P unicode -nv -X #{@ignore} #{@ftp}"
    )
  end
end


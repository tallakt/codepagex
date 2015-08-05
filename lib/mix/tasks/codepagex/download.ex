defmodule Mix.Tasks.Codepagex.Download do
  use Mix.Task

  @ftp "ftp://ftp.unicode.org/Public/MAPPINGS/"
  @ignore ~w(
      /Public/MAPPINGS/OBSOLETE
      /Public/MAPPINGS/ISO8859/DatedVersions/
      /Public/MAPPINGS/VENDORS/ADOBE/
      /Public/MAPPINGS/VENDORS/MICSFT/WindowsBestFit/
    ) |> Enum.join(",")
  # note: other files are downloaded, but are in unicode/.gitignore

  @shortdoc "download source data files from unicode.org"
  def run(_) do
    Mix.shell.cmd "wget -nH --cut-dirs=2 -r -P unicode -nv -X #{@ignore} #{@ftp}"
  end
end

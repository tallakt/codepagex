defmodule Codepagex.Helpers do
  def name_for_file(filename) do
    m = Regex.run ~r|unicode/(.*)[.]txt|i, filename
    m[1]
  end
end

defmodule Codepagex do
  require Codepagex.Helpers
  import Codepagex.Helpers

  @mapping_folder __DIR__ |> Path.join(~w(.. unicode))
  @mapping_files (
    @mapping_folder
    |> Path.join(~w(** *.TXT))
    |> Path.wildcard
    |> Enum.reject(&(String.match(&1, ~r(README)i)))
    |> Enum.filter(&(String.match(&1, ~r(8859-1)))) # debug
    )
  @names_files for n <- @mapping_files, do: {n, name_for_file(n)}, into: %{}
  @names @names_files |> Dict.keys |> Enum.sort

  def list_codepages, do: @names
end

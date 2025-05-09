defmodule Codepagex.Mappings do
  @moduledoc false

  require Codepagex.Mappings.Helpers
  alias Codepagex.Mappings.Helpers

  # aliases
  @iso_aliases for n <- 1..16, do: {:"iso_8859_#{n}", "ISO8859/8859-#{n}"}
  @ascii_alias [{:ascii, "VENDORS/MISC/US-ASCII-QUOTES"}]
  @all_aliases (@iso_aliases ++ @ascii_alias) |> Enum.into(%{})

  def aliases(selection \\ nil)

  def aliases(:all), do: @all_aliases

  def aliases(_) do
    aliases(:all)
    |> Enum.filter(fn {_, e} ->
      Enum.member?(Codepagex.Mappings.encoding_list(:configured), e)
    end)
    |> Enum.into(%{})
  end

  # folders containing mapping files
  @mapping_folder Path.join([__DIR__] ++ ~w(.. .. unicode))
  @default_mapping_filter [:ascii, ~r[iso8859]i]

  @all_mapping_files @mapping_folder
                     |> Path.join(Path.join(~w(** *.TXT)))
                     |> Path.wildcard()
                     |> Enum.reject(&String.match?(&1, ~r[README]i))
                     # lots of weird stuff
                     |> Enum.reject(&String.match?(&1, ~r[VENDORS/APPLE]i))
                     # seems useless, other format
                     |> Enum.reject(&String.match?(&1, ~r[MISC/IBMGRAPH]i))
                     # generates warnings
                     |> Enum.reject(&String.match?(&1, ~r[VENDORS/MISC/APL-ISO-IR-68]i))
                     # generates warnings
                     |> Enum.reject(&String.match?(&1, ~r[VENDORS/MISC/CP1006]i))
                     # generates warnings
                     |> Enum.reject(&String.match?(&1, ~r[NEXT]i))
                     # generates warnings
                     |> Enum.reject(&String.match?(&1, ~r[EBCDIC/CP875]i))

  @all_names_files for n <- @all_mapping_files, do: {Helpers.name_for_file(n), n}, into: %{}

  @filtered_names_files Helpers.filter_to_selected_encodings(
                          @all_names_files,
                          Application.compile_env(
                            :codepagex,
                            :encodings,
                            @default_mapping_filter
                          ),
                          @all_aliases
                        )

  # These are documented in Codepagex.encoding_list/1
  def encoding_list(selection \\ nil)
  def encoding_list(:all), do: @all_names_files |> Map.keys() |> Enum.sort()
  def encoding_list(_), do: @filtered_names_files |> Enum.into(%{}) |> Map.keys() |> Enum.sort()

  # load mapping files
  @encodings Enum.flat_map(
               Task.async_stream(
                 @filtered_names_files,
                 fn {name, file} -> {name, Codepagex.MappingFile.load(file)} end,
                 ordered: false,
                 timeout: :infinity
               ),
               fn
                 {:ok, val} -> [val]
                 _else -> []
               end
             )

  def get_encodings, do: @encodings

  def to_string(binary, encoding, missing_fun, acc) do
    Codepagex.Functions.ToString.to_string(binary, encoding, missing_fun, acc)
  end

  def from_string(string, encoding, missing_fun, acc) do
    Codepagex.Functions.FromString.from_string(string, encoding, missing_fun, acc)
  end
end

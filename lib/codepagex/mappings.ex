defmodule Codepagex.Mappings.Helpers do
  @moduledoc false

  def name_for_file(filename) do
    ~r"unicode/(.*)\.txt$"i
    |> Regex.run(filename)
    |> Enum.at(1)
  end

  def function_name_for_mapping_name(prefix, mapping_name) do
    mapping_part =
      mapping_name
      |> String.replace(~r|[-/]|, "_")
      |> String.downcase()

    :"#{prefix}_#{mapping_part}"
  end

  defmacro def_to_string(name, encoding) do
    quote(bind_quoted: [n: name, e: encoding], generated: true, unquote: false) do
      alias Codepagex.Mappings.Helpers
      fn_name = Helpers.function_name_for_mapping_name("to_string", n)

      for encoding_point <- e do
        case encoding_point do
          {from, to} ->
            defp unquote(fn_name)(
                  unquote(from) <> rest,
                  acc,
                  missing_fun,
                  outer_acc
                ) do
              unquote(fn_name)(
                rest,
                acc <> <<unquote(to)::utf8>>,
                missing_fun,
                outer_acc
              )
            end
        end
      end

      defp unquote(fn_name)("", result, _, outer_acc) do
        {:ok, result, outer_acc}
      end

      defp unquote(fn_name)(rest, acc, missing_fun, outer_acc) do
        case missing_fun.(rest, outer_acc) do
          res = {:error, _, _} ->
            res

          {:ok, codepoints, new_rest, new_outer_acc} ->
            unquote(fn_name)(
              new_rest,
               acc <> codepoints,
              missing_fun,
              new_outer_acc
            )
        end
      end
    end
  end

  defmacro def_from_string(name, encoding) do
    quote(bind_quoted: [n: name, e: encoding], generated: true, unquote: false) do
      alias Codepagex.Mappings.Helpers
      fn_name = Helpers.function_name_for_mapping_name("from_string", n)

      for encoding_point <- e do
        case encoding_point do
          {from, to} ->
            defp unquote(fn_name)(
                  <<unquote(to)::utf8>> <> rest,
                  acc,
                  fun,
                  outer_acc
                ) do
              unquote(fn_name)(rest, acc <> unquote(from), fun, outer_acc)
            end
        end
      end

      defp unquote(fn_name)("", result, _, outer_acc) do
        {:ok, result, outer_acc}
      end

      defp unquote(fn_name)(rest, acc, missing_fun, outer_acc) do
        case missing_fun.(rest, outer_acc) do
          res = {:error, _, _} ->
            res

          {:ok, added_binary, new_rest, new_outer_acc} ->
            unquote(fn_name)(new_rest, acc <> added_binary, missing_fun, new_outer_acc)
        end
      end
    end
  end

  defp name_matches?(name, %Regex{} = filter), do: Regex.match?(filter, name)
  defp name_matches?(name, filter), do: name == to_string(filter)

  def filter_to_selected_encodings(names, filters, aliases) do
    matching =
      for n = {k, _} <- names,
          f <- Enum.map(filters, &Map.get(aliases, &1, &1)),
          name_matches?(k, f),
          do: n

    matching
    |> Enum.sort()
    |> Enum.uniq()
  end
end

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

  # define the to_string_xxx for each mapping
  for {n, m} <- @encodings, do: Helpers.def_to_string(n, m)

  # define methods to forward to_string(...) to a specific implementation
  for {name, _} <- @encodings do
    fun_name = Helpers.function_name_for_mapping_name("to_string", name)

    def to_string(binary, unquote(name |> String.to_atom()), missing_fun, acc) do
      unquote(fun_name)(binary, <<>>, missing_fun, acc)
    end
  end

  def to_string(_, encoding, _, acc) do
    {:error, "Unknown encoding #{inspect(encoding)}", acc}
  end

  # define the from_string_xxx for each encoding
  for {n, m} <- @encodings, do: Helpers.def_from_string(n, m)

  # define methods to forward from_string(...) to a specific implementation
  for {name, _} <- @encodings do
    fun_name = Helpers.function_name_for_mapping_name("from_string", name)

    def from_string(
          string,
          unquote(name |> String.to_atom()),
          missing_fun,
          acc
        ) do
      unquote(fun_name)(string, <<>>, missing_fun, acc)
    end
  end

  def from_string(_, encoding, _, acc) do
    {:error, "Unknown encoding #{inspect(encoding)}", acc}
  end
end

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

      for {from, to} <- e do
        def to_string(
              unquote(from) <> rest,
              acc,
              fun,
              outer_acc
            ) do
          to_string(rest, acc <> <<unquote(to)::utf8>>, fun, outer_acc)
        end
      end

      def to_string("", result, _, outer_acc) do
        {:ok, result, outer_acc}
      end

      def to_string(rest, acc, missing_fun, outer_acc) do
        case missing_fun.(rest, outer_acc) do
          res = {:error, _, _} ->
            res

          {:ok, added_binary, new_rest, new_outer_acc} ->
            to_string(new_rest, acc <> added_binary, missing_fun, new_outer_acc)
        end
      end
    end
  end

  defmacro def_from_string(name, encoding) do
    quote(bind_quoted: [n: name, e: encoding], generated: true, unquote: false) do
      alias Codepagex.Mappings.Helpers

      for {from, to} <- e do
        def from_string(
              <<unquote(to)::utf8>> <> rest,
              acc,
              fun,
              outer_acc
            ) do
          from_string(rest, acc <> unquote(from), fun, outer_acc)
        end
      end

      def from_string("", result, _, outer_acc) do
        {:ok, result, outer_acc}
      end

      def from_string(rest, acc, missing_fun, outer_acc) do
        case missing_fun.(rest, outer_acc) do
          res = {:error, _, _} ->
            res

          {:ok, added_binary, new_rest, new_outer_acc} ->
            from_string(new_rest, acc <> added_binary, missing_fun, new_outer_acc)
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

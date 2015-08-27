defmodule Codepagex.MappingFile do
  @moduledoc false

  @ignored ~r/^\s*(#.*|\n|#{<<26>>})$/ # 26: Ctrl+Z

  @re ~r/^0x(([[:xdigit:]]{2})+)\s*\t+(0x(([[:xdigit:]]{2})+)\s*\t+)?#/

  def load(filename) do
    File.stream!(filename)
    |> Stream.with_index
    |> Stream.map(&(parse_line(&1, filename)))
    |> Stream.filter(&(&1))
    |> remove_overlapping
    |> Enum.reverse
  end

  defp remove_overlapping(enum) do
    enum
    |> Stream.chunk(2, 1, [nil])
    |> Stream.reject(fn 
          [{a, _}, {b, _}] ->
            :binary.longest_common_prefix([a, b]) == byte_size(a)
          _ ->
            false
        end)
    |> Stream.map(fn [a, _] -> a end)
  end

  defp parse_line({line, line_number}, filename) do
    case Regex.run(@re, line) do
      [_, from, _, _, to, _] ->
        {hex_to_binary(from), String.to_integer(to, 16)}
      [_, _ | _] ->
        nil # undefined or just not in the list, treat them the same
      _ ->
        if String.match?(line, @ignored) do
          nil
        else
          raise "Illegal line in file #{filename} line #{line_number + 1}:" <>
                " #{line |> inspect}"
        end
    end
  end

  defp hex_to_binary(hex) do
    for <<a, b <- hex>>, into: "", do: <<String.to_integer(<<a, b>>, 16)::8>>
  end
end

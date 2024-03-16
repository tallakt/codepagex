defmodule Codepagex.MappingFile do
  @moduledoc false

  # 26: Ctrl+Z
  @ignored ~r/^\s*(#.*|\n|#{<<26>>})$/

  @re ~r/^0x(([[:xdigit:]]{2})+)\s*\t+(0x(([[:xdigit:]]{2})+)\s*\t+)?#/

  def load(filename) do
    filename
    |> File.stream!()
    |> Stream.with_index()
    |> Task.async_stream(
      &parse_line(&1, filename),
      ordered: true,
      timeout: :infinity
    )
    |> Stream.filter(fn
      {:ok, val} -> val
      _else -> false
    end)
    |> Stream.map(fn {:ok, val} -> val end)
    |> remove_overlapping()
    |> Enum.reverse()
  end

  defp remove_overlapping(enum) do
    enum
    |> Stream.chunk_every(2, 1, [nil])
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
        # undefined or just not in the list, treat them the same
        nil

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

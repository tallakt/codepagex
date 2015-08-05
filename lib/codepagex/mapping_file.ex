defmodule Codepagex.MappingFile do
  @comment ~r/^\s*#/
  @re ~r/^0x(([[:xdigit:]]{2})+)\t+(0x(([[:xdigit:]]{2})+)\t+)?#/

  def load(filename) do
    File.stream!(filename)
    |> Stream.map(&parse_line/1)
    |> Stream.filter(&(&1))
    |> remove_overlapping
    |> Stream.map(fn {f, t} -> {string_hex_to_bytes(f), t} end)
  end

  defp remove_overlapping(enum) do
    enum
    |> Stream.chunk(2, 1, [nil])
    |> Stream.reject(fn 
          [{a, _}, {b, _}] -> 
            String.starts_with?(b, a) 
          _ ->
            false
        end)
    |> Stream.map(fn [a, _] -> a end)
  end

  defp parse_line(line) do
    case Regex.run(@re, line) do
      [_, from, _, _, to, _] ->
        {from, String.to_integer(to, 16)}
      [_, from | _] ->
        {from, :undefined}
      _ ->
        cond do
          String.match?(line, @comment) ->
            nil
          true ->
            raise "Illegal line: #{line |> inspect}"
        end
    end
  end

  defp string_hex_to_bytes(hex) do
    for <<a::8, b::8 <- hex>>, do: String.to_integer(<<a, b>>, 16)
  end
end


defmodule Codepagex.Chunk do
  @doc """
  Splits an enumerable where the passed function returns true for two neighbor
  elements

  ## Examples

      iex> list = for x <- 1000..1011, rem(x, 5) != 0, do: x
      iex> chunk_between(list, fn a, b -> b - a != 1 end)
      [[1001, 1002, 1003, 1004], [1006, 1007, 1008, 1009], [1011]]

  """
  def chunk_between(enum, f) do
    chunks = %{result: [], current: Enum.take(enum, 1)}
    chunks = 
      enum
      |> Enum.chunk(2, 1)
      |> Enum.reduce(chunks, fn [a, b], acc ->
          if f.(a,b) do
            %{acc | result: [acc.current | acc.result], current: [b]}
          else
            %{acc | current: [b | acc.current]}
          end
        end)

    result = 
      if Enum.empty?(chunks.current) do
        chunks.result
      else
        [chunks.current | chunks.result]
      end

    result
    |> Enum.reverse
    |> Enum.map(&Enum.reverse/1)
  end
end


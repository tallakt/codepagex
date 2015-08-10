defmodule Codepagex do
  @moduledoc """
  Codepagex is a pure Elixir module to provide conversion between text in 
  different codepages to and from Elixir strings in utf-8 format.

  A list of supported mappings is emmitted by list_mappings/0, a list of 
  shorthand aliases by aliases/0.

  For conversion use the functions to_string/2, from_string/2 and translate/3.
  """

  # aliases
  @iso_aliases for n <- 1..16, do: {:"iso_8859_#{n}", "ISO8859/8859-#{n}"}
  @ascii_alias [{:ascii, "VENDORS/MISC/US-ASCII-QUOTES"}]
  @alias_table (@iso_aliases ++ @ascii_alias) |> Enum.into %{}

  @aliases_markdown (
    @alias_table
    |> Enum.map(fn {a, m} -> "  - #{inspect(a) |> String.ljust(15)} => #{m}" end)
    |> Enum.join("\n")
    )

  @doc """
  Returns a list of shorthand aliases that may be used instead of the full name
  of the mapping. For a list of full mappings, see list_mappings/0

  The available aliases are: #{"\n\n" <> @aliases_markdown}
  """
  def aliases, do: @alias_table

  @mappings_markdown (
    Codepagex.Mappings.list_mappings
    |> Enum.map(fn m -> "  - #{m}" end)
    |> Enum.join("\n")
    )

  @doc """
  Returns a list of the supported mappings. These are extracted from 
  http://unicode.org/ and the names correspond to a mapping file on that page

  For a list of shorthand names, see aliases/0

  The available mappings are: #{"\n\n" <> @mappings_markdown}
  """
  def list_mappings, do: Codepagex.Mappings.list_mappings

  @doc """
  Converts a binary in a given encoding to an Elixir string in utf-8 encoding.
  The encoding encoding

      iex> Codepagex.to_string(:iso_8859_1, <<72, 201, 166, 166, 211>>)
      {:ok, "HÉ¦¦Ó"}

      iex> Codepagex.to_string("ETSI/GSM0338", <<128>>)
      {:error, "Missing code point"}


  The mapping parameter should be in list_mappings/0 or aliases/0. If it is a
  full mapping name, it may be passed as an atom or string.

  """
  # create a to_string implementation for each alias
  for {aliaz, mapping} <- @alias_table do
    def to_string(unquote(aliaz), binary) do
      Codepagex.Mappings.to_string(unquote(mapping |> String.to_atom), binary)
    end
  end

  @mappings_atom Codepagex.Mappings.list_mappings |> Enum.map(&String.to_atom/1)

  def to_string(mapping, binary) when is_atom(mapping) do
    Codepagex.Mappings.to_string(mapping, binary)
  end

  def to_string(mapping, binary) when is_binary(mapping) do
    try do 
      to_string(String.to_existing_atom(mapping), binary)
    rescue
      e in ArgumentError ->
        {:error, "Unknown mapping #{inspect mapping}"}
    end
  end

  @doc """
  This variant of to_string/2 may raise an exception

      iex> Codepagex.to_string!(:iso_8859_1, <<72, 201, 166, 166, 211>>)
      "HÉ¦¦Ó"

      iex> Codepagex.to_string!("ETSI/GSM0338", <<128>>)
      ** (RuntimeError) Missing code point
  """
  def to_string!(mapping, binary) do
    case to_string(mapping, binary) do
      {:ok, result} ->
        result
      {:error, reason} ->
        raise reason
    end
  end

  @doc """
  Converts an Elixir string in utf-8 encoding to a binary in another encoding.

      iex> Codepagex.from_string(:iso_8859_1, "HÉ¦¦Ó")
      {:ok, <<72, 201, 166, 166, 211>>}

      iex> Codepagex.from_string(:iso_8859_1, "ʒ")
      {:error, "Missing code point"}

  The mapping parameter should be in list_mappings/0 or aliases/0. It may be 
  passed as an atom, or a string for full mapping names.
  """
  for {aliaz, mapping} <- @alias_table do
    def from_string(unquote(aliaz), binary) do
      Codepagex.Mappings.from_string(unquote(mapping |> String.to_atom), binary)
    end
  end

  def from_string(mapping, binary) when is_atom(mapping) do
    Codepagex.Mappings.from_string(mapping, binary)
  end

  def from_string(mapping, binary) when is_binary(mapping) do
    try do
      from_string(String.to_existing_atom(mapping), binary)
    rescue
      e in ArgumentError ->
        {:error, "Unknown mapping #{inspect mapping}"}
    end
  end

  @doc ~S"""
  Converts an Elixir string in utf-8 encoding to a binary in another encoding.

  This variant of from_string/2 will raise an exception on error

      iex> Codepagex.from_string!(:iso_8859_1, "HÉ¦¦Ó")
      <<72, 201, 166, 166, 211>>

      iex> Codepagex.from_string!(:iso_8859_1, "ʒ")
      ** (RuntimeError) Missing code point

  The mapping parameter should be in list_mappings/0 or aliases/0. It may be 
  passed as an atom, or a string for full mapping names.
  """
  def from_string!(mapping, binary) do
    case from_string(mapping, binary) do
      {:ok, result} ->
        result
      {:error, reason} ->
        raise reason
    end
  end

  @doc """
  Converts a binary in one encoding to a binary in another encoding. The string
  is converted to utf-8 internally in the process.

      iex> Codepagex.translate(:iso_8859_1, :iso_8859_15, <<174>>)
      {:ok, <<174>>}

      iex> Codepagex.translate(:iso_8859_1,:iso_8859_2, <<174>>)
      {:error, "Missing code point"}

  The mapping parameters should be in list_mappings/0 or aliases/0. It may be 
  passed as an atom, or a string for full mapping names.
  """
  def translate(mapping_from, mapping_to, binary) do
    case to_string(mapping_from, binary) do
      {:ok, b} ->
        from_string(mapping_to, b)
      err = _ ->
        err
    end
  end

  @doc """
  Converts a binary in one encoding to a binary in another encoding. The string
  is converted to utf-8 internally in the process.

      iex> Codepagex.translate!(:iso_8859_1, :iso_8859_15, <<174>>)
      <<174>>

      iex> Codepagex.translate!(:iso_8859_1,:iso_8859_2, <<174>>)
      ** (RuntimeError) Missing code point

  The mapping parameters should be in list_mappings/0 or aliases/0. It may be 
  passed as an atom, or a string for full mapping names.
  """
  def translate!(mapping_from, mapping_to, binary) do
    case translate(mapping_from, mapping_to, binary) do
      {:ok, result} ->
        result
      {:error, reason} ->
        raise reason
    end
  end
end

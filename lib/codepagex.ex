defmodule Codepagex do
  @moduledoc """
  Codepagex is a pure Elixir module to provide conversion between text in 
  different codepages to and from Elixir strings in utf-8 format.

  A list of supported encodings is emmitted by encoding_list/0, a list of 
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
  of the encoding. For a full list of encodings, see encoding_list/0

  The available aliases are: #{"\n\n" <> @aliases_markdown}
  """
  def aliases, do: @alias_table

  @encodings_markdown (
    Codepagex.Mappings.encoding_list
    |> Enum.map(fn m -> "  - #{m}" end)
    |> Enum.join("\n")
    )

  @encodings_atom Codepagex.Mappings.encoding_list |> Enum.map(&String.to_atom/1)

  @doc """
  Returns a list of the supported encodings. These are extracted from 
  http://unicode.org/ and the names correspond to a encoding file on that page

  For a list of shorthand names, see aliases/0

  The available encodings are: #{"\n\n" <> @encodings_markdown}
  """
  def encoding_list, do: Codepagex.Mappings.encoding_list

  defp error_on_missing(_, _) do
    {:error, "Invalid bytes for encoding", nil}
  end

  def silently_replace_invalid_bytes(<<_, rest::binary>>, _) do
    # � replacement character used to replace an unknown or unrepresentable
    # character
    {:ok,"� ", rest, nil}
  end

  defp strip_acc({code, return_value, _acc}), do: {code, return_value}


  @doc """
  Converts a binary in a given encoding to an Elixir string in utf-8 encoding.
  The encoding encoding

      iex> Codepagex.to_string(:iso_8859_1, <<72, 201, 166, 166, 211>>)
      {:ok, "HÉ¦¦Ó"}

      iex> Codepagex.to_string("ETSI/GSM0338", <<128>>)
      {:error, "Invalid bytes for encoding"}


  The encoding parameter should be in encoding_list/0 or aliases/0. If it is a
  full encoding name, it may be passed as an atom or string.
  """
  def to_string(encoding, binary) do
    to_string(encoding, binary, &error_on_missing/2)
    |> strip_acc
  end


  @doc """
  TODO
  """
  def to_string(encoding, binary, missing_fun, acc \\ nil)

  # create a forwarding to_string implementation for each alias
  for {aliaz, encoding} <- @alias_table do
    def to_string(unquote(aliaz), binary, missing_fun, acc) do
      to_string(unquote(encoding |> String.to_atom), binary, missing_fun, acc)
    end
  end

  def to_string(encoding, binary, missing_fun, acc) when is_atom(encoding) do
    Codepagex.Mappings.to_string(encoding, binary, missing_fun, acc)
  end

  def to_string(encoding, binary, missing_fun, acc) when is_binary(encoding) do
    try do 
      to_string(String.to_existing_atom(encoding), binary, missing_fun, acc)
    rescue
      ArgumentError ->
        {:error, "Unknown encoding #{inspect encoding}", acc}
    end
  end

  @doc """
  This variant of to_string/2 may raise an exception

      iex> Codepagex.to_string!(:iso_8859_1, <<72, 201, 166, 166, 211>>)
      "HÉ¦¦Ó"

      iex> Codepagex.to_string!("ETSI/GSM0338", <<128>>)
      ** (RuntimeError) Invalid bytes for encoding
  """
  def to_string!(encoding, binary) do
    to_string!(encoding, binary, &error_on_missing/2, nil)
  end

  @doc """
  TODO
  """
  def to_string!(encoding, binary, missing_fun, acc \\ nil) do
    case to_string(encoding, binary, missing_fun, acc) do
      {:ok, result, _} ->
        result
      {:error, reason, _} ->
        raise reason
    end
  end

  @doc """
  Converts an Elixir string in utf-8 encoding to a binary in another encoding.

      iex> Codepagex.from_string(:iso_8859_1, "HÉ¦¦Ó")
      {:ok, <<72, 201, 166, 166, 211>>}

      iex> Codepagex.from_string(:iso_8859_1, "ʒ")
      {:error, "Invalid bytes for encoding"}

  The encoding parameter should be in encoding_list/0 or aliases/0. It may be 
  passed as an atom, or a string for full encoding names.
  """
  def from_string(encoding, string) do
    from_string(encoding, string, &error_on_missing/2, nil)
    |> strip_acc
  end

  @doc """
  TODO
  """
    def from_string(encoding, string, missing_fun, acc \\ nil)

    # aliases are forwarded to proper name
    for {aliaz, encoding} <- @alias_table do
      def from_string(unquote(aliaz), string, missing_fun, acc) do
      Codepagex.Mappings.from_string(
        unquote(encoding |> String.to_atom), string, missing_fun, acc
      )
    end
  end

  def from_string(encoding, string, missing_fun, acc) when is_atom(encoding) do
    Codepagex.Mappings.from_string(encoding, string, missing_fun, acc)
  end

  def from_string(encoding, string, missing_fun, acc) when is_binary(encoding) do
    try do
      from_string(String.to_existing_atom(encoding), string, missing_fun, acc)
    rescue
      ArgumentError ->
        {:error, "Unknown encoding #{inspect encoding}", acc}
    end
  end

  @doc """
  Converts an Elixir string in utf-8 encoding to a binary in another encoding.

  This variant of from_string/2 will raise an exception on error

      iex> Codepagex.from_string!(:iso_8859_1, "HÉ¦¦Ó")
      <<72, 201, 166, 166, 211>>

      iex> Codepagex.from_string!(:iso_8859_1, "ʒ")
      ** (RuntimeError) Invalid bytes for encoding

  The encoding parameter should be in encoding_list/0 or aliases/0. It may be 
  passed as an atom, or a string for full encoding names.
  """
  def from_string!(encoding, binary) do
    from_string! encoding, binary, &error_on_missing/2, nil
  end

  @doc """
  todo
  """
  def from_string!(encoding, string, missing_fun, acc \\ nil) do
    case from_string(encoding, string, missing_fun, acc) do
      {:ok, result, _} ->
        result
      {:error, reason, _} ->
        raise reason
    end
  end

  @doc """
  Converts a binary in one encoding to a binary in another encoding. The string
  is converted to utf-8 internally in the process.

      iex> Codepagex.translate(:iso_8859_1, :iso_8859_15, <<174>>)
      {:ok, <<174>>}

      iex> Codepagex.translate(:iso_8859_1,:iso_8859_2, <<174>>)
      {:error, "Invalid bytes for encoding"}

  The encoding parameters should be in encoding_list/0 or aliases/0. It may be 
  passed as an atom, or a string for full encoding names.
  """
  def translate(encoding_from, encoding_to, binary) do
    case to_string(encoding_from, binary, &error_on_missing/2) do
      {:ok, b, _} ->
        from_string(encoding_to, b, &error_on_missing/2)
      err = _ ->
        err
    end
    |> strip_acc
  end

  @doc """
  Converts a binary in one encoding to a binary in another encoding. The string
  is converted to utf-8 internally in the process.

      iex> Codepagex.translate!(:iso_8859_1, :iso_8859_15, <<174>>)
      <<174>>

      iex> Codepagex.translate!(:iso_8859_1,:iso_8859_2, <<174>>)
      ** (RuntimeError) Invalid bytes for encoding

  The encoding parameters should be in encoding_list/0 or aliases/0. It may be 
  passed as an atom, or a string for full encoding names.
  """
  def translate!(encoding_from, encoding_to, binary) do
    case translate(encoding_from, encoding_to, binary) do
      {:ok, result} ->
        result
      {:error, reason} ->
        raise reason
    end
  end
end

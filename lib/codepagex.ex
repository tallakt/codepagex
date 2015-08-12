defmodule Codepagex do
  @moduledoc """
  Codepagex is a pure Elixir module to provide conversion between text in 
  different codepages to and from Elixir strings in utf-8 format.

  A list of supported encodings is emmitted by `encoding_list/0`, a list of 
  shorthand aliases by `aliases/0`.

  For conversion use the functions `to_string/2`, `from_string/2` and
  `translate/3`.
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
  of the encoding. For a full list of encodings, see `encoding_list/0`

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

  For a list of shorthand names, see `aliases/0`

  The available encodings are: #{"\n\n" <> @encodings_markdown}
  """
  def encoding_list, do: Codepagex.Mappings.encoding_list

  # This is the default missing_fun
  defp error_on_missing(_, _) do
    {:error, "Invalid bytes for encoding", nil}
  end

  @doc """
  This function may be used as a parameter to `to_string/4` such that any bytes
  in the input binary that don't have a proper encoding are replaced with a
  special unicode character and the function will not return an error, or an
  exception in the case of `to_string!/4`

  The accumulator input `acc` of `to_string/4` is ignored and may be omitted.

  ## Examples

      iex> iso = "Hello æøå!" |> from_string!(:iso_8859_1)
      iex> to_string!(iso, :ascii, &use_utf_replacement/2)
      "Hello � � � !"

  """
  def use_utf_replacement(<<_, rest::binary>>, _) do
    # � replacement character used to replace an unknown or unrepresentable
    # character
    {:ok,"� ", rest, nil}
  end
  

  @doc """
  This function may be used in conjunction with to `from_string/4` such that
  any character points in the input string is replaced with a supplied binary
  if a mapping from utf-8 to the specified encoding is undefined.  Thus
  `from_string/4` will not return an error for any input, or raise an exception
  for `from_string/4`

  The `replace_with` is a binary in the target encoding. If it
  contains invalid bytes, the resulting binary returned by `from_string/4` will
  also be invalid. If you need to be certain that `replace_with` is valid, it
  may first be converted from utf-8 by `to_string/2` or similar.

  This function will return as anonymous function to be passed as parameter.
  
  The accumulator input `acc` of `from_string/4` is ignored and may be omitted.

  ## Examples

      iex> from_string!("Hello æøå!", :ascii, replace_nonexistent("_"))
      "Hello ___!"

  To make sure that the replacement is valid

      iex> replacement = "#"
      iex> f = replace_nonexistent(replacement |> from_string!(:ascii))
      iex> from_string!("Hello æøå!", :ascii, f)
      "Hello ###!"

  """
  def replace_nonexistent(replace_with) do
    fn <<_ :: utf8, rest :: binary>>, _ -> {:ok, replace_with, rest, nil} end
  end

  defp strip_acc({code, return_value, _acc}), do: {code, return_value}


  @doc """
  Converts a binary in a given encoding to an Elixir string in utf-8 encoding.
  The encoding encoding

      iex> to_string(<<72, 201, 166, 166, 211>>, :iso_8859_1)
      {:ok, "HÉ¦¦Ó"}

      iex> to_string(<<128>>, "ETSI/GSM0338")
      {:error, "Invalid bytes for encoding"}


  The encoding parameter should be in `encoding_list/0` or `aliases/0`. If it
  is a full encoding name, it may be passed as an atom or string.
  """
  def to_string(binary, encoding) do
    to_string(binary, encoding, &error_on_missing/2)
    |> strip_acc
  end


  @doc """
  TODO
  """
  def to_string(binary, encoding, missing_fun, acc \\ nil)

  # create a forwarding to_string implementation for each alias
  for {aliaz, encoding} <- @alias_table do
    def to_string(binary, unquote(aliaz), missing_fun, acc) do
      to_string(binary, unquote(encoding |> String.to_atom), missing_fun, acc)
    end
  end

  def to_string(binary, encoding, missing_fun, acc) when is_atom(encoding) do
    Codepagex.Mappings.to_string(binary, encoding, missing_fun, acc)
  end

  def to_string(binary, encoding, missing_fun, acc) when is_binary(encoding) do
    try do 
      to_string(binary, String.to_existing_atom(encoding), missing_fun, acc)
    rescue
      ArgumentError ->
        {:error, "Unknown encoding #{inspect encoding}", acc}
    end
  end

  @doc """
  This variant of `to_string/2` may raise an exception

      iex> to_string!(<<72, 201, 166, 166, 211>>, :iso_8859_1)
      "HÉ¦¦Ó"

      iex> to_string!(<<128>>, "ETSI/GSM0338")
      ** (RuntimeError) Invalid bytes for encoding
  """
  def to_string!(binary, encoding) do
    to_string!(binary, encoding, &error_on_missing/2, nil)
  end

  @doc """
  TODO
  """
  def to_string!(binary, encoding, missing_fun, acc \\ nil) do
    case to_string(binary, encoding, missing_fun, acc) do
      {:ok, result, _} ->
        result
      {:error, reason, _} ->
        raise reason
    end
  end

  @doc """
  Converts an Elixir string in utf-8 encoding to a binary in another encoding.

      iex> from_string("HÉ¦¦Ó", :iso_8859_1)
      {:ok, <<72, 201, 166, 166, 211>>}

      iex> from_string("ʒ", :iso_8859_1)
      {:error, "Invalid bytes for encoding"}

  The encoding parameter should be in `encoding_list/0` or `aliases/0`. It may
  be passed as an atom, or a string for full encoding names.
  """
  def from_string(string, encoding) do
    from_string(string, encoding, &error_on_missing/2, nil)
    |> strip_acc
  end

  @doc """
  TODO
  """
    def from_string(string, encoding, missing_fun, acc \\ nil)

    # aliases are forwarded to proper name
    for {aliaz, encoding} <- @alias_table do
      def from_string(string, unquote(aliaz), missing_fun, acc) do
      Codepagex.Mappings.from_string(
        string, unquote(encoding |> String.to_atom), missing_fun, acc)
    end
  end

  def from_string(string, encoding, missing_fun, acc) when is_atom(encoding) do
    Codepagex.Mappings.from_string(string, encoding, missing_fun, acc)
  end

  def from_string(string, encoding, missing_fun, acc) when is_binary(encoding) do
    try do
      from_string(string, String.to_existing_atom(encoding), missing_fun, acc)
    rescue
      ArgumentError ->
        {:error, "Unknown encoding #{inspect encoding}", acc}
    end
  end

  @doc """
  Convert an Elixir string in utf-8 encoding to a binary in another encoding.

  This variant of `from_string/2` will raise an exception on error

      iex> from_string!("HÉ¦¦Ó", :iso_8859_1)
      <<72, 201, 166, 166, 211>>

      iex> from_string!("ʒ", :iso_8859_1)
      ** (RuntimeError) Invalid bytes for encoding

  The encoding parameter should be in `encoding_list/0` or `aliases/0`. It may be 
  passed as an atom, or a string for full encoding names.
  """
  def from_string!(binary, encoding) do
    from_string! binary, encoding, &error_on_missing/2, nil
  end

  @doc """
  todo
  """
  def from_string!(string, encoding, missing_fun, acc \\ nil) do
    case from_string(string, encoding, missing_fun, acc) do
      {:ok, result, _} ->
        result
      {:error, reason, _} ->
        raise reason
    end
  end

  @doc """
  Convert a binary in one encoding to a binary in another encoding. The string
  is converted to utf-8 internally in the process.

      iex> translate(<<174>>, :iso_8859_1, :iso_8859_15)
      {:ok, <<174>>}

      iex> translate(<<174>>, :iso_8859_1, :iso_8859_2)
      {:error, "Invalid bytes for encoding"}

  The encoding parameters should be in `encoding_list/0` or `aliases/0`. It may
  be passed as an atom, or a string for full encoding names.
  """
  def translate(binary, encoding_from, encoding_to) do
    case to_string(binary, encoding_from) do
      {:ok, string} ->
        from_string(string, encoding_to)
      err ->
        err
    end
  end

  @doc """
  Convert a binary in one encoding to a binary in another encoding. The string
  is converted to utf-8 internally in the process.

      iex> translate!(<<174>>, :iso_8859_1, :iso_8859_15)
      <<174>>

      iex> translate!(<<174>>, :iso_8859_1,:iso_8859_2)
      ** (RuntimeError) Invalid bytes for encoding

  The encoding parameters should be in `encoding_list/0` or `aliases/0`. It may be 
  passed as an atom, or a string for full encoding names.
  """
  def translate!(binary, encoding_from, encoding_to) do
    binary
    |> to_string!(encoding_from)
    |> from_string!(encoding_to)
  end
end

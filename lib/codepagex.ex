defmodule Codepagex do
  require Codepagex.Mappings

  alias Codepagex.Mappings

  # unfortunately exdoc doesnt support ``` fenced blocks
  @moduledoc (
    File.read!("README.md")
    |> String.split("\n") 
    |> Enum.reject(&(String.match?(&1, ~r/```/)))
    |> Enum.join("\n")
    )

  @aliases_markdown (
    Mappings.aliases(:all)
    |> Enum.map(fn {a, m} -> "  | #{inspect(a) |> String.ljust(15)} | #{m} |" end)
    |> Enum.join("\n")
    )

  @doc """
  Returns a list of shorthand aliases that may be used instead of the full name
  of the encoding. 

  The available aliases are:

  | Alias | Full name |
  |------:|:----------|
  #{@aliases_markdown}

  Some of these may not be available depending on mix configuration. If the
  `selection` parameter is `:all` then all possible aliases are listed,
  otherwise, only the available aliases are listed

  For a full list of encodings, see `encoding_list/1`
  """
  def aliases(selection \\ nil)
  defdelegate aliases(selection), to: Mappings


  @encodings_markdown (
    # format as table with 3 columns
    Mappings.encoding_list(:all)
    |> Enum.map(&(String.ljust(&1, 30)))
    |> Enum.chunk(3, 3, ["", ""])
    |> Enum.map(&(Enum.join(&1, " | ")))
    |> Enum.map(&("| #{&1} |"))
    |> Enum.join("\n")
    )

  @encodings_atom (
    Mappings.encoding_list(:all)
    |> Enum.map(&String.to_atom/1)
    )

  @doc """
  Returns a list of the supported encodings. These are extracted from 
  http://unicode.org/ and the names correspond to a encoding file on that page


  `encoding_list/1` is normally called without any parameters to list the
  encodings that are currently configured during compilation. To see all
  available options, even those unavailable, use `encoding_list(:all)`

  The available encodings are: 
  
  #{@encodings_markdown}

  For more information about configuring encodings, refer to `Codepagex`.

  For a list of shorthand names, see `aliases/1`

  """
  def encoding_list(selection \\ nil)
  defdelegate encoding_list(selection), to: Mappings

  # This is the default missing_fun
  defp error_on_missing(_, _) do
    {:error, "Invalid bytes for encoding", nil}
  end

  @doc """
  This function may be used as a parameter to `to_string/4` such that any bytes
  in the input binary that don't have a proper encoding are replaced with a
  special unicode character and the function will not return an error, or an
  exception in the case of `to_string!/4`

  The accumulator input `acc` of `to_string/4` may be nil or a start number,
  which is incremented by the number of replacements made.

  ## Examples

      iex> iso = "Hello æøå!" |> from_string!(:iso_8859_1)
      iex> to_string!(iso, :ascii, &use_utf_replacement/2)
      "Hello ���!"

  """
  def use_utf_replacement(<<_, rest::binary>>, acc) do
    # � replacement character used to replace an unknown or unrepresentable
    # character
    new_acc = if is_integer(acc), do: acc + 1, else: 1
    {:ok,<<0xFFFD :: utf8>>, rest, new_acc}
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
  
  The accumulator input `acc` of `from_string/4` may be nil or a number and the
  returned `acc` is incremented by the number og replacements made.

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
    fn <<_ :: utf8, rest :: binary>>, acc ->
      new_acc = if is_integer(acc), do: acc + 1, else: 1
      {:ok, replace_with, rest, new_acc}
    end
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
  Convert a binary in a specified encoding into an Elixir string in utf-8
  encoding

  Compared to `to_string/2`, this function has a function parameter to handle
  any bytes that are not supported by the encoding format. Depending on the
  supplied function, the function may or may not return an error.

  The function `use_utf_replacement/2` may be used a a parameter if you want
  to make sure the conversion succeeds even if the binary contains invalid
  bytes.

  The function `missing_fun` must receive two arguments, the first being a
  binary containing the rest of the `binary` parameter that is still
  unprocessed. The second is the accumultor `acc`. it must return:

  - `{:ok, replacement, new_rest, new_acc}` to continue processing
  - `{:error, reason, new_acc}` to return an error from `to_string/4`

  The `acc` parameter is passed to the `missing_fun` every time it is called,
  and updated according to the return value of `missing_fun`. In the end it is
  returned in the return value of `to_string/4`. The accumulator is useful if
  you need to keep track of a state in the string, for example left-right mode
  or the number of replacements done. In some cases it may be ignored.


  ## Examples

  Using the `use_utf_replacement` function to handle invalid bytes:

      iex> iso = "Hello æøå!" |> from_string!(:iso_8859_1)
      iex> to_string(iso, :ascii, &use_utf_replacement/2)
      {:ok, "Hello ���!", 3}

  In this example, we replace missing chars with "#" and then count the number
  of replacements done.

      iex> iso = "Hello æøå!" |> from_string!(:iso_8859_1)
      iex> f = fn <<_, rest :: binary>>, acc ->
      ...>                {:ok, "#", rest, acc + 1}
      ...> end
      iex> to_string(iso, :ascii, f, 0)
      {:ok, "Hello ###!", 3}
  
  """
  def to_string(binary, encoding, missing_fun, acc \\ nil)

  # create a forwarding to_string implementation for each alias
  for {aliaz, encoding} <- Mappings.aliases do
    def to_string(binary, unquote(aliaz), missing_fun, acc) do
      to_string(binary, unquote(encoding |> String.to_atom), missing_fun, acc)
    end
  end

  def to_string(binary, encoding, missing_fun, acc) when is_atom(encoding) do
    Mappings.to_string(binary, encoding, missing_fun, acc)
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
      ** (Codepagex.Error) Invalid bytes for encoding
  """
  def to_string!(binary, encoding) do
    to_string!(binary, encoding, &error_on_missing/2, nil)
  end

  @doc """
  Convert a binary in a specified encoding into an Elixir string in utf-8
  encoding. May raise an exception.

  Compared to `to_string!/2`, this function has a function parameter to handle
  any bytes that are not supported by the encoding format. Depending on the
  supplied function, the function may or may raise an exception.

  The function `use_utf_replacement/2` may be used a a parameter if you want
  to make sure the conversion succeeds even if the binary contains invalid
  bytes.

  The function `missing_fun` must receive two arguments, the first being a
  binary containing the rest of the `binary` parameter that is still
  unprocessed. The second is the accumultor `acc`. It must return:

  - `{:ok, replacement, new_rest, new_acc}` to continue processing
  - `{:error, reason, new_acc}` to return an error from `to_string/4`

  The `acc` parameter is passed to the `missing_fun` every time it is called,
  and updated according to the return value of `missing_fun`. The accumulator
  is useful if you need to keep track of a state in the string, for example
  left-right mode or the number of replacements done. In some cases it may be
  ignored. If you need to return the last `acc` value you must use
  `to_string/4`


  ## Examples

  Using the `use_utf_replacement` function to handle invalid bytes:

      iex> iso = "Hello æøå!" |> from_string!(:iso_8859_1)
      iex> to_string!(iso, :ascii, &use_utf_replacement/2)
      "Hello ���!"

  In this example, we replace missing chars with "#" 

      iex> iso = "Hello æøå!" |> from_string!(:iso_8859_1)
      iex> f = fn <<_, rest :: binary>>, _acc ->
      ...>                {:ok, "#", rest, nil}
      ...> end
      iex> to_string!(iso, :ascii, f)
      "Hello ###!"
  """
  def to_string!(binary, encoding, missing_fun, acc \\ nil) do
    case to_string(binary, encoding, missing_fun, acc) do
      {:ok, result, _} ->
        result
      {:error, reason, _} ->
        raise Codepagex.Error, reason
    end
  end

  @doc """
  Converts an Elixir string in utf-8 encoding to a binary in another encoding.

      iex> from_string("HÉ¦¦Ó", :iso_8859_1)
      {:ok, <<72, 201, 166, 166, 211>>}

      iex> from_string("HÉ¦¦Ó", :"ISO8859/8859-1") # without alias
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
  Convert a string to a binary with a given encoding. A function is passed to
  handle codepoints that are not possible to encode properly.

  Encoding must be a string or atom as returned by `aliases/0` or
  `encoding_list/0`. 

  If you want to replace all impossible codepoints to a certain character, use
  the function `replace_nonexistent/1`.

  The function parameter `missing_fun` must receive two arguments, the first
  being a string containing the rest of the `string` parameter that is still
  unprocessed. The second is the accumultor `acc`. `acc` is used to preserve
  state between invocations of `missing_fun`. It must return:

  - `{:ok, replacement, new_rest, new_acc}` to continue processing
  - `{:error, reason, new_acc}` to return an error from `to_string/4`

  The `replacement` value is inserted into the result binary, and must be in
  the encoding of the result. Processing will continue with `rest`. `acc` is
  passed to the nect invocation of `missing_fun`, or returned by
  `from_string/4`.

  The accumulator is useful if you need to keep track of a state in the string,
  for example left-right mode or the number of replacements done. In some cases
  it may be ignored. 

  See also `from_string!/4`

  ## Examples

  Using the `replace_nonexistent/1` function to handle invalid bytes:

      iex> f = "_" |> to_string!(:ascii) |> replace_nonexistent
      iex> from_string("Hello æøå!", :ascii, f)
      {:ok, "Hello ___!", 3}

  In this example, we replace missing chars with "#", and return the number of
  replacements made:

      iex> f = fn <<_::utf8, rest::binary>>, acc -> {:ok, "#", rest, acc + 1} end
      iex> from_string("Hello æøå!", :ascii, f, 0)
      {:ok, "Hello ###!", 3}

  """
  def from_string(string, encoding, missing_fun, acc \\ nil)

  # aliases are forwarded to proper name
  for {aliaz, encoding} <- Mappings.aliases do
    def from_string(string, unquote(aliaz), missing_fun, acc) do
    Mappings.from_string(
      string, unquote(encoding |> String.to_atom), missing_fun, acc)
    end
  end

  def from_string(string, encoding, missing_fun, acc) when is_atom(encoding) do
    Mappings.from_string(string, encoding, missing_fun, acc)
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
      ** (Codepagex.Error) Invalid bytes for encoding

  The encoding parameter should be in `encoding_list/0` or `aliases/0`. It may be 
  passed as an atom, or a string for full encoding names.
  """
  def from_string!(binary, encoding) do
    from_string! binary, encoding, &error_on_missing/2, nil
  end

  @doc """
  Convert a string to a binary with a given encoding. A function is passed to
  handle codepoints that are not possible to encode properly.

  Encoding must be a string or atom as returned by `aliases/0` or
  `encoding_list/0`. 

  If you want to replace all impossible codepoints to a certain character, use
  the function `replace_nonexistent/1`.

  The function parameter `missing_fun` must receive two arguments, the first
  being a string containing the rest of the `string` parameter that is still
  unprocessed. The second is the accumultor `acc`. `acc` is used to preserve
  state between invocations of `missing_fun`. It must return:

  - `{:ok, replacement, new_rest, new_acc}` to continue processing
  - `{:error, reason, new_acc}` to return an error from `to_string/4`

  The `replacement` value is inserted into the result binary, and must be in
  the encoding of the result. Processing will continue with `rest`. `acc` is
  passed to the next invocation of `missing_fun`, or returned by
  `from_string/4`.

  The accumulator is useful if you need to keep track of a state in the string,
  for example left-right mode or the number of replacements done. In some cases
  it may be ignored. 

  See also `from_string/4`

  ## Examples

  Using the `replace_nonexistent/1` function to handle invalid bytes:

      iex> f = "_" |> to_string!(:ascii) |> replace_nonexistent
      iex> from_string!("Hello æøå!", :ascii, f)
      "Hello ___!"

  In this example, we replace missing chars with "#", and return the number of
  replacements made:

      iex> f = fn <<_::utf8, rest::binary>>, acc -> {:ok, "#", rest, acc + 1} end
      iex> from_string!("Hello æøå!", :ascii, f, 0)
      "Hello ###!"

  """
  def from_string!(string, encoding, missing_fun, acc \\ nil) do
    case from_string(string, encoding, missing_fun, acc) do
      {:ok, result, _} ->
        result
      {:error, reason, _} ->
        raise Codepagex.Error, reason
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
      ** (Codepagex.Error) Invalid bytes for encoding

  The encoding parameters should be in `encoding_list/0` or `aliases/0`. It may be 
  passed as an atom, or a string for full encoding names.
  """
  def translate!(binary, encoding_from, encoding_to) do
    binary
    |> to_string!(encoding_from)
    |> from_string!(encoding_to)
  end
end

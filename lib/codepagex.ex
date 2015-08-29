defmodule Codepagex do
  # unfortunately exdoc doesnt support ``` fenced blocks
  @moduledoc (
    File.read!("README.md")
    |> String.split("\n") 
    |> Enum.reject(&(String.match?(&1, ~r/```|Build Status|Documentation Status/)))
    |> Enum.join("\n")
    )

  require Codepagex.Mappings
  alias Codepagex.Mappings

  @type to_s_missing_inner :: ((binary, term) -> {:ok, String.t, binary, term} | {:error, term})
  @type to_s_missing_outer :: ((String.t) -> {:ok, to_s_missing_inner} | {:error, term})

  @type from_s_missing_inner :: ((String.t, term) -> {:ok, binary, String.t, term} | {:error, term})
  @type from_s_missing_outer :: ((String.t) -> {:ok, from_s_missing_inner} | {:error, term})

  @type encoding :: atom | String.t

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
  @spec aliases(atom) :: list(atom)
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
  @spec encoding_list(atom) :: list(String.t)
  def encoding_list(selection \\ nil)
  defdelegate encoding_list(selection), to: Mappings

  # This is the default missing_fun
  defp error_on_missing do
    fn _ ->
      {:ok, fn _, _ ->
        {:error, "Invalid bytes for encoding", nil}
      end}
    end
  end

  @doc """
  This function may be used as a parameter to `to_string/4` or `to_string!/4`
  such that any bytes in the input binary that don't have a proper encoding are
  replaced with a special unicode character and the function will not
  fail.

  If this function is used, `to_string/4` will never return an error.

  The accumulator input `acc` of `to_string/4` is incremented by the number of
  replacements made.

  ## Examples

      iex> iso = "Hello æøå!" |> from_string!(:iso_8859_1)
      iex> to_string!(iso, :ascii, use_utf_replacement)
      "Hello ���!"

      iex> iso = "Hello æøå!" |> from_string!(:iso_8859_1)
      iex> to_string(iso, :ascii, use_utf_replacement)
      {:ok, "Hello ���!", 3}

  """
  @spec use_utf_replacement :: to_s_missing_outer
  def use_utf_replacement do
    fn _encoding ->
      inner = 
        fn <<_, rest::binary>>, acc ->
          # � replacement character used to replace an unknown or unrepresentable
          # character
          new_acc = if is_integer(acc), do: acc + 1, else: 1
          {:ok, <<0xFFFD :: utf8>>, rest, new_acc}
        end
      {:ok, inner}
    end
  end
  

  @doc """
  This function may be used in conjunction with to `from_string/4` or
  `from_string!/4`. If there are utf-8 codepoints in the source string that are
  not possible to represent in the target encoding, they are replaced with a
  String.
  
  When using this function, `from_string/4` will never return an error if
  `replace_with` converts to the target encoding without errors.

  
  The accumulator input `acc` of `from_string/4` is incremented on each
  replacement done.

  ## Examples

      iex> from_string!("Hello æøå!", :ascii, replace_nonexistent("_"))
      "Hello ___!"

      iex> from_string("Hello æøå!", :ascii, replace_nonexistent("_"), 100)
      {:ok, "Hello ___!", 103}

  """
  @spec replace_nonexistent(String.t) :: from_s_missing_outer
  def replace_nonexistent(replace_with) do
    fn encoding ->
      case from_string(replace_with, encoding) do
        {:ok, encoded_replace_with} ->
          inner = 
            fn <<_ :: utf8, rest :: binary>>, acc ->
              new_acc = if is_integer(acc), do: acc + 1, else: 1
              {:ok, encoded_replace_with, rest, new_acc}
            end
            {:ok, inner}
        err ->
          err
      end
    end
  end

  defp strip_acc({code, return_value, _acc}), do: {code, return_value}


  @doc """
  Converts a binary in a specified encoding to an Elixir string in utf-8
  encoding.

  The encoding parameter should be in `encoding_list/0` (passed as atoms or
  strings), or in `aliases/0`. 

  ## Examples

      iex> to_string(<<72, 201, 166, 166, 211>>, :iso_8859_1)
      {:ok, "HÉ¦¦Ó"}

      iex> to_string(<<128>>, "ETSI/GSM0338")
      {:error, "Invalid bytes for encoding"}

  """
  @spec to_string(binary, encoding) :: {:ok, String.t} | {:error, term}
  def to_string(binary, encoding) do
    to_string(binary, encoding, error_on_missing)
    |> strip_acc
  end


  @doc """
  Convert a binary in a specified encoding into an Elixir string in utf-8
  encoding

  Compared to `to_string/2`, you may pass a `missing_fun` function parameter to
  handle encoding errors in the `binary`.  The function `use_utf_replacement/0`
  may be used as a default error handling machanism.

  ## Implementing missing_fun

  The `missing_fun` must be an anonymous function that returns a second
  function. The outer function will receive the encoding used by `to_string/4`,
  and must then return `{:ok, inner_function}` or `{:error, reason}`. Returning
  `:error` will cause `to_string/4` to fail.

  The returned inner function must receive two arguments. 

  - a binary containing the remainder of the `binary` parameter that is still
    unprocessed.
  - the accumulator `acc`

  The return value must be

  - `{:ok, replacement, new_rest, new_acc}` to continue processing
  - `{:error, reason, new_acc}` to cause `to_string/4` to fail

  The `acc` parameter from `to_string/4` is passed between every invocation of
  the inner function then returned by `to_string/4`. In many use cases, `acc`
  may be ignored.


  ## Examples

  Using the `use_utf_replacement/0` function to handle invalid bytes:

      iex> iso = "Hello æøå!" |> from_string!(:iso_8859_1)
      iex> to_string(iso, :ascii, use_utf_replacement)
      {:ok, "Hello ���!", 3}

      iex> iso = "Hello æøå!" |> from_string!(:iso_8859_1)
      iex> missing_fun =
      ...>   fn encoding ->
      ...>     case to_string("#", encoding) do
      ...>       {:ok, replacement} ->
      ...>         inner_fun = 
      ...>           fn <<_, rest :: binary>>, acc ->
      ...>             {:ok, replacement, rest, acc + 1}
      ...>           end
      ...>         {:ok, inner_fun}
      ...>       err ->
      ...>         err
      ...>     end
      ...>   end
      iex> to_string(iso, :ascii, missing_fun, 0)
      {:ok, "Hello ###!", 3}
  
  The previous code was included for completeness. If you know your replacement
  is valid in the target encoding, you might as well do:

      iex> iso = "Hello æøå!" |> from_string!(:iso_8859_1)
      iex> missing_fun = 
      ...>   fn _encoding ->
      ...>     inner_fun = 
      ...>       fn <<_, rest :: binary>>, acc ->
      ...>         {:ok, "#", rest, acc + 1}
      ...>       end
      ...>     {:ok, inner_fun}
      ...>   end
      iex> to_string(iso, :ascii, missing_fun, 10)
      {:ok, "Hello ###!", 13}
  """
  @spec to_string(binary, encoding, to_s_missing_outer, term) :: {:ok, String.t} | {:error, term}
  def to_string(binary, encoding, missing_fun, acc \\ nil)

  # create a forwarding to_string implementation for each alias
  for {aliaz, encoding} <- Mappings.aliases do
    def to_string(binary, unquote(aliaz), missing_fun, acc) do
      to_string(binary, unquote(encoding |> String.to_atom), missing_fun, acc)
    end
  end

  def to_string(binary, encoding, missing_fun, acc) when is_atom(encoding) do
    case missing_fun.(encoding) do
      {:ok, inner_fun} ->
        Mappings.to_string(binary, encoding, inner_fun, acc)
      err ->
        err
    end
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
  Like `to_string/2` but raises exceptions on errors.

  ## Examples

      iex> to_string!(<<72, 201, 166, 166, 211>>, :iso_8859_1)
      "HÉ¦¦Ó"

      iex> to_string!(<<128>>, "ETSI/GSM0338")
      ** (Codepagex.Error) Invalid bytes for encoding
  """
  @spec to_string!(binary, encoding) :: String.t | no_return
  def to_string!(binary, encoding) do
    to_string!(binary, encoding, error_on_missing, nil)
  end

  @doc """
  Like `to_string/4` but raises exceptions on errors.

  ## Examples

      iex> iso = "Hello æøå!" |> from_string!(:iso_8859_1)
      iex> to_string!(iso, :ascii, use_utf_replacement)
      "Hello ���!"

  """
  @spec to_string!(binary, encoding, to_s_missing_outer, term) :: String.t | no_return
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

  The `encoding` parameter should be in `encoding_list/0` as an atom or String,
  or in `aliases/0`.

  ## Examples

      iex> from_string("HÉ¦¦Ó", :iso_8859_1)
      {:ok, <<72, 201, 166, 166, 211>>}

      iex> from_string("HÉ¦¦Ó", :"ISO8859/8859-1") # without alias
      {:ok, <<72, 201, 166, 166, 211>>}

      iex> from_string("ʒ", :iso_8859_1)
      {:error, "Invalid bytes for encoding"}

  """
  @spec from_string(String.t, encoding) :: {:ok, binary} | {:error, term}
  def from_string(string, encoding) do
    from_string(string, encoding, error_on_missing, nil)
    |> strip_acc
  end

  @doc """
  Convert an Elixir String in utf-8 to a binary in a specified encoding. A
  function parameter specifies how to deal with codepoints that are not
  representable in the target encoding.

  Compared to `from_string/2`, you may pass a `missing_fun` function parameter
  to handle encoding errors in `string`. The function `replace_nonexistent/1`
  may be used as a default error handling machanism.

  The `encoding` parameter should be in `encoding_list/0` as an atom or String,
  or in `aliases/0`.

  ## Implementing missing_fun

  The `missing_fun` must be an anonymous function that returns a second
  function. The outer function will receive the encoding used by
  `from_string/4`, and must then return `{:ok, inner_function}` or `{:error,
  reason}`. Returning `:error` will cause `from_string/4` to fail.

  The returned inner function must receive two arguments. 

  - a String containing the remainder of the `string` parameter that is still
    unprocessed.
  - the accumulator `acc`

  The return value must be

  - `{:ok, replacement, new_rest, new_acc}` to continue processing
  - `{:error, reason, new_acc}` to cause `from_string/4` to fail

  The `acc` parameter from `from_string/4` is passed between every invocation
  of the inner function then returned by `to_string/4`. In many use cases,
  `acc` may be ignored.


  ## Examples

  Using the `replace_nonexistent/1` function to handle invalid bytes:

      iex> from_string("Hello æøå!", :ascii, replace_nonexistent("_"))
      {:ok, "Hello ___!", 3}

  Defining a custom `missing_fun`:

      iex> missing_fun =
      ...>   fn encoding ->
      ...>     case from_string("#", encoding) do
      ...>       {:ok, replacement} ->
      ...>         inner_fun = 
      ...>           fn <<_ :: utf8, rest :: binary>>, acc ->
      ...>             {:ok, replacement, rest, acc + 1}
      ...>           end
      ...>         {:ok, inner_fun}
      ...>       err ->
      ...>         err
      ...>     end
      ...>   end
      iex> from_string("Hello æøå!", :ascii, missing_fun, 0)
      {:ok, "Hello ###!", 3}
  
  The previous code was included for completeness. If you know your replacement
  is valid in the target encoding, you might as well do:

      iex> missing_fun = fn _encoding ->
      ...>   inner_fun = 
      ...>     fn <<_ :: utf8, rest :: binary>>, acc ->
      ...>       {:ok, "#", rest, acc + 1}
      ...>     end
      ...>   {:ok, inner_fun}
      ...> end
      iex> from_string("Hello æøå!", :ascii, missing_fun, 10)
      {:ok, "Hello ###!", 13}
  """
  @spec from_string(binary, encoding, from_s_missing_outer, term) :: {:ok, String.t} | {:error, term}
  def from_string(string, encoding, missing_fun, acc \\ nil)

  # aliases are forwarded to proper name
  for {aliaz, encoding} <- Mappings.aliases do
    def from_string(string, unquote(aliaz), missing_fun, acc) do
      from_string(
        string, unquote(encoding |> String.to_atom), missing_fun, acc)
    end
  end

  def from_string(string, encoding, missing_fun, acc) when is_atom(encoding) do
    case missing_fun.(encoding) do
      {:ok, inner_fun} ->
        Mappings.from_string(string, encoding, inner_fun, acc)
      err ->
        err
    end
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
  Like `from_string/2` but raising exceptions on errors.

  ## Examples

      iex> from_string!("HÉ¦¦Ó", :iso_8859_1)
      <<72, 201, 166, 166, 211>>

      iex> from_string!("ʒ", :iso_8859_1)
      ** (Codepagex.Error) Invalid bytes for encoding

  """
  @spec from_string!(String.t, encoding) :: binary | no_return
  def from_string!(binary, encoding) do
    from_string! binary, encoding, error_on_missing, nil
  end

  @doc """
  Like `from_string/4` but raising exceptions on errors.

  ## Examples

      iex> missing_fun = replace_nonexistent("_")
      iex> from_string!("Hello æøå!", :ascii, missing_fun)
      "Hello ___!"

  """
  @spec from_string!(String.t, encoding, from_s_missing_outer, term) :: binary | no_return
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

  The encoding parameters should be in `encoding_list/0` or `aliases/0`. It may
  be passed as an atom, or a string for full encoding names.

  ## Examples 

      iex> translate(<<174>>, :iso_8859_1, :iso_8859_15)
      {:ok, <<174>>}

      iex> translate(<<174>>, :iso_8859_1, :iso_8859_2)
      {:error, "Invalid bytes for encoding"}

  """
  @spec translate(binary, encoding, encoding) :: {:ok, binary} | {:error, term}
  def translate(binary, encoding_from, encoding_to) do
    case to_string(binary, encoding_from) do
      {:ok, string} ->
        from_string(string, encoding_to)
      err ->
        err
    end
  end

  @doc """
  Like `translate/3` but raises exceptions on errors

  ## Examples

      iex> translate!(<<174>>, :iso_8859_1, :iso_8859_15)
      <<174>>

      iex> translate!(<<174>>, :iso_8859_1,:iso_8859_2)
      ** (Codepagex.Error) Invalid bytes for encoding

  """
  @spec translate(binary, encoding, encoding) :: binary
  def translate!(binary, encoding_from, encoding_to) do
    binary
    |> to_string!(encoding_from)
    |> from_string!(encoding_to)
  end
end

defmodule Codepagex.Backend do
  @moduledoc """
  A module of your own with the encodings it is given, compiled into it.

  The encodings `Codepagex` itself has are set by `config :codepagex, :encodings`
  in the configuration of the application at the top. A library can't add to
  them, and an application that sets them must recompile Codepagex. A backend
  is compiled with the module it is defined in instead, with the encodings that
  module asks for, and without any configuration:

      defmodule MyLib.Encodings do
        use Codepagex.Backend,
          encodings: [:ascii, :iso_8859_1, :windows_1251, :windows_1252]
      end

      MyLib.Encodings.to_string(<<0xC0, 0xE1>>, :windows_1251)
      #=> {:ok, "Аб"}

  The encodings are given as for `config :codepagex, :encodings`: by alias,
  by full name as a string or an atom, or by a regular expression matching full
  names. One that matches no encoding is a compile error.

  The module has the functions of `Codepagex`, for its own encodings:
  `to_string/2`, `to_string/4`, `to_string!/2`, `to_string!/4`,
  `from_string/2`, `from_string/4`, `from_string!/2`, `from_string!/4`,
  `translate/3`, `translate!/3`, `encoding_list/0`, `aliases/0`,
  `use_utf_replacement/0` and `replace_nonexistent/1`. Each backend has its own
  copy of the code for an encoding; those with long compile times, such as
  CP932, are as slow to compile in a backend.
  """

  alias Codepagex.{MappingFile, Mappings}
  alias Codepagex.Mappings.Helpers

  # The options are evaluated with the module, so they may use its attributes, and the encodings
  # compiled in before it is done.
  defmacro __using__(opts) do
    quote do
      @codepagex_backend_encodings Keyword.fetch!(unquote(opts), :encodings)
      @before_compile Codepagex.Backend
    end
  end

  defmacro __before_compile__(env) do
    filters = Module.get_attribute(env.module, :codepagex_backend_encodings)
    selected = select!(filters, env)

    aliases =
      for {aliaz, name} <- Mappings.aliases(:all),
          Enum.any?(selected, fn {n, _} -> n == name end),
          into: %{},
          do: {aliaz, name}

    encodings =
      for {name, path} <- selected do
        module =
          Module.concat([env.module, Generated, String.replace(name, ["/", " "], "_")])

        entries = MappingFile.load(path)
        from_entries = Helpers.from_string_entries(name, entries)

        definition =
          quote do
            @external_resource unquote(path)

            defmodule unquote(module) do
              @moduledoc false
              require Codepagex.Mappings.Helpers

              def to_string(binary, missing_fun, acc),
                do: to_string(binary, <<>>, missing_fun, acc)

              def from_string(string, missing_fun, acc),
                do: from_string(string, <<>>, missing_fun, acc)

              Codepagex.Mappings.Helpers.def_to_string(
                unquote(name),
                unquote(Macro.escape(entries))
              )

              Codepagex.Mappings.Helpers.def_from_string(
                unquote(name),
                unquote(Macro.escape(from_entries))
              )
            end
          end

        {String.to_atom(name), module, definition}
      end

    quote do
      unquote(for {_atom, _module, definition} <- encodings, do: definition)

      @doc "The encodings of this backend, by full name."
      @spec encoding_list() :: [String.t()]
      def encoding_list, do: unquote(selected |> Enum.map(&elem(&1, 0)) |> Enum.sort())

      @doc "The aliases of this backend's encodings."
      @spec aliases() :: %{atom => String.t()}
      def aliases, do: unquote(Macro.escape(aliases))

      @doc false
      unquote(
        for {atom, module, _definition} <- encodings do
          quote do
            def __codepagex__(:to_string, unquote(atom), binary, fun, acc),
              do: unquote(module).to_string(binary, fun, acc)

            def __codepagex__(:from_string, unquote(atom), string, fun, acc),
              do: unquote(module).from_string(string, fun, acc)
          end
        end
      )

      def __codepagex__(_direction, encoding, _data, _fun, acc),
        do: {:error, "Unknown encoding #{inspect(encoding)}", acc}

      @doc "As `Codepagex.to_string/2`, with this backend's encodings."
      @spec to_string(binary, Codepagex.encoding()) :: {:ok, String.t()} | {:error, term}
      def to_string(binary, encoding),
        do: Codepagex.Backend.to_string(__MODULE__, binary, encoding)

      @doc "As `Codepagex.to_string/4`, with this backend's encodings."
      @spec to_string(binary, Codepagex.encoding(), Codepagex.to_s_missing_outer(), term) ::
              {:ok, String.t(), term} | {:error, term, term}
      def to_string(binary, encoding, missing_fun, acc \\ nil),
        do: Codepagex.Backend.to_string(__MODULE__, binary, encoding, missing_fun, acc)

      @doc "As `Codepagex.to_string!/2`, with this backend's encodings."
      @spec to_string!(binary, Codepagex.encoding()) :: String.t()
      def to_string!(binary, encoding),
        do: Codepagex.Backend.to_string!(__MODULE__, binary, encoding)

      @doc "As `Codepagex.to_string!/4`, with this backend's encodings."
      @spec to_string!(binary, Codepagex.encoding(), Codepagex.to_s_missing_outer(), term) ::
              String.t()
      def to_string!(binary, encoding, missing_fun, acc \\ nil),
        do: Codepagex.Backend.to_string!(__MODULE__, binary, encoding, missing_fun, acc)

      @doc "As `Codepagex.from_string/2`, with this backend's encodings."
      @spec from_string(String.t(), Codepagex.encoding()) :: {:ok, binary} | {:error, term}
      def from_string(string, encoding),
        do: Codepagex.Backend.from_string(__MODULE__, string, encoding)

      @doc "As `Codepagex.from_string/4`, with this backend's encodings."
      @spec from_string(String.t(), Codepagex.encoding(), Codepagex.from_s_missing_outer(), term) ::
              {:ok, binary, term} | {:error, term, term}
      def from_string(string, encoding, missing_fun, acc \\ nil),
        do: Codepagex.Backend.from_string(__MODULE__, string, encoding, missing_fun, acc)

      @doc "As `Codepagex.from_string!/2`, with this backend's encodings."
      @spec from_string!(String.t(), Codepagex.encoding()) :: binary
      def from_string!(string, encoding),
        do: Codepagex.Backend.from_string!(__MODULE__, string, encoding)

      @doc "As `Codepagex.from_string!/4`, with this backend's encodings."
      @spec from_string!(String.t(), Codepagex.encoding(), Codepagex.from_s_missing_outer(), term) ::
              binary
      def from_string!(string, encoding, missing_fun, acc \\ nil),
        do: Codepagex.Backend.from_string!(__MODULE__, string, encoding, missing_fun, acc)

      @doc "As `Codepagex.translate/3`, with this backend's encodings."
      @spec translate(binary, Codepagex.encoding(), Codepagex.encoding()) ::
              {:ok, binary} | {:error, term}
      def translate(binary, from, to),
        do: Codepagex.Backend.translate(__MODULE__, binary, from, to)

      @doc "As `Codepagex.translate!/3`, with this backend's encodings."
      @spec translate!(binary, Codepagex.encoding(), Codepagex.encoding()) :: binary
      def translate!(binary, from, to),
        do: Codepagex.Backend.translate!(__MODULE__, binary, from, to)

      @doc "As `Codepagex.use_utf_replacement/0`."
      @spec use_utf_replacement() :: Codepagex.to_s_missing_outer()
      defdelegate use_utf_replacement(), to: Codepagex

      @doc "As `Codepagex.replace_nonexistent/1`, with this backend's encodings."
      @spec replace_nonexistent(String.t()) :: Codepagex.from_s_missing_outer()
      def replace_nonexistent(replace_with),
        do: Codepagex.Backend.replace_nonexistent(__MODULE__, replace_with)
    end
  end

  # The encodings the filters match, as {name, path}, each filter matching one
  # at least.
  defp select!(filters, caller) do
    files = Mappings.mapping_files()
    aliases = Mappings.aliases(:all)

    if not is_list(filters) do
      raise CompileError,
        file: caller.file,
        line: caller.line,
        description: "Codepagex.Backend: encodings: must be a list, got: #{inspect(filters)}"
    end

    selected =
      for filter <- filters do
        target = Map.get(aliases, filter, filter)

        case Enum.filter(files, fn {name, _path} -> matches?(name, target) end) do
          [] ->
            raise CompileError,
              file: caller.file,
              line: caller.line,
              description:
                "Codepagex.Backend: #{inspect(filter)} in encodings: matches no encoding"

          matched ->
            matched
        end
      end

    selected |> List.flatten() |> Enum.uniq() |> Enum.sort()
  end

  defp matches?(name, %Regex{} = filter), do: Regex.match?(filter, name)

  defp matches?(name, filter) when is_atom(filter) or is_binary(filter),
    do: name == to_string(filter)

  defp matches?(_name, _filter), do: false

  # The functions a backend's own call, with the backend to dispatch to.

  @doc false
  def to_string(backend, binary, encoding) do
    backend |> to_string(binary, encoding, error_on_missing(), nil) |> strip_acc()
  end

  @doc false
  def to_string(backend, binary, encoding, missing_fun, acc) do
    convert(backend, :to_string, binary, encoding, missing_fun, acc)
  end

  @doc false
  def to_string!(backend, binary, encoding, missing_fun \\ error_on_missing(), acc \\ nil) do
    case to_string(backend, binary, encoding, missing_fun, acc) do
      {:ok, result, _acc} -> result
      {:error, reason, _acc} -> raise Codepagex.Error, reason
    end
  end

  @doc false
  def from_string(backend, string, encoding) do
    backend |> from_string(string, encoding, error_on_missing(), nil) |> strip_acc()
  end

  @doc false
  def from_string(backend, string, encoding, missing_fun, acc) do
    convert(backend, :from_string, string, encoding, missing_fun, acc)
  end

  @doc false
  def from_string!(backend, string, encoding, missing_fun \\ error_on_missing(), acc \\ nil) do
    case from_string(backend, string, encoding, missing_fun, acc) do
      {:ok, result, _acc} -> result
      {:error, reason, _acc} -> raise Codepagex.Error, reason
    end
  end

  @doc false
  def translate(backend, binary, from, to) do
    with {:ok, string} <- to_string(backend, binary, from),
         do: from_string(backend, string, to)
  end

  @doc false
  def translate!(backend, binary, from, to) do
    backend
    |> to_string!(binary, from)
    |> then(&from_string!(backend, &1, to))
  end

  @doc false
  def replace_nonexistent(backend, replace_with) do
    fn encoding ->
      case from_string(backend, replace_with, encoding) do
        {:ok, encoded} ->
          {:ok,
           fn
             <<_::utf8, rest::binary>>, acc -> {:ok, encoded, rest, count(acc)}
             <<_, rest::binary>>, acc -> {:ok, encoded, rest, count(acc)}
           end}

        error ->
          error
      end
    end
  end

  defp count(acc), do: if(is_integer(acc), do: acc + 1, else: 1)

  defp convert(backend, direction, data, encoding, missing_fun, acc) do
    case resolve(backend, encoding) do
      {:ok, name} ->
        case missing_fun.(name) do
          {:ok, inner_fun} -> backend.__codepagex__(direction, name, data, inner_fun, acc)
          {:error, reason} -> {:error, reason, acc}
          other -> other
        end

      :error ->
        {:error, "Unknown encoding #{inspect(encoding)}", acc}
    end
  end

  # An alias or a name, as the atom of the full name.
  defp resolve(backend, encoding) when is_atom(encoding) do
    case Map.fetch(backend.aliases(), encoding) do
      {:ok, name} -> {:ok, String.to_atom(name)}
      :error -> {:ok, encoding}
    end
  end

  defp resolve(_backend, encoding) when is_binary(encoding) do
    {:ok, String.to_existing_atom(encoding)}
  rescue
    ArgumentError -> :error
  end

  defp resolve(_backend, _encoding), do: :error

  defp error_on_missing do
    fn _encoding -> {:ok, fn _rest, acc -> {:error, "Invalid bytes for encoding", acc} end} end
  end

  defp strip_acc({code, value, _acc}), do: {code, value}
end

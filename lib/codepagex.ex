defmodule Codepagex do

  # aliases
  @iso_aliases for n <- 1..16, do: {:"iso_8859_#{n}", "ISO8859/8859-#{n}"}
  @ascii_alias [{:ascii, "VENDORS/MISC/US-ASCII-QUOTES"}]
  @alias_table (@iso_aliases ++ @ascii_alias) |> Enum.into %{}

  def aliases, do: @alias_table

  def list_mappings, do: Codepagex.Mappings.list_mappings

  # create a to_string implementation for each alias
  for {aliaz, mapping} <- @alias_table do
    def to_string(unquote(aliaz), binary) do
      Codepagex.Mappings.to_string(unquote(mapping |> String.to_atom), binary)
    end
  end

  for {aliaz, mapping} <- @alias_table do
    def from_string(unquote(aliaz), binary) do
      Codepagex.Mappings.from_string(unquote(mapping |> String.to_atom), binary)
    end
  end

  @mappings_atom Codepagex.Mappings.list_mappings |> Enum.map(&String.to_atom/1)

  def to_string(mapping, binary) when is_atom(mapping) do
    Codepagex.Mappings.to_string(mapping, binary)
  end

  def to_string(mapping, binary) when is_binary(mapping) do
    to_string(String.to_existing_atom(mapping), binary)
  end

  def to_string!(mapping, binary) do
    case to_string(mapping, binary) do
      {:ok, result} ->
        result
      {:error, reason} ->
        raise reason
    end
  end

  def from_string(mapping, binary) when is_atom(mapping) do
    Codepagex.Mappings.from_string(mapping, binary)
  end

  def from_string(mapping, binary) when is_binary(mapping) do
    from_string(String.to_existing_atom(mapping), binary)
  end

  def from_string!(mapping, binary) do
    case from_string(mapping, binary) do
      {:ok, result} ->
        result
      {:error, reason} ->
        raise reason
    end
  end

  def translate(mapping_from, mapping_to, binary) do
    case to_string(mapping_from, binary) do
      {:ok, b} ->
        from_string(mapping_to, b)
      err = _ ->
        err
    end
  end

  def translate!(mapping_from, mapping_to, binary) do
    case translate(mapping_from, mapping_to, binary) do
      {:ok, result} ->
        result
      {:error, reason} ->
        raise reason
    end
  end
end

defmodule Codepagex.Functions.FromString do
  @moduledoc false
  require Codepagex.Mappings.Helpers

  encodings = Codepagex.Mappings.get_encodings()

  # define methods to forward from_string(...) to a specific implementation
  for {name, _} <- encodings do
    parsed_name = String.replace(name, ["/", " "], "_")
    module_name = Module.concat(Codepagex.Functions.FromString.Generated, parsed_name)

    module_content = """
    defmodule #{inspect(module_name)} do
      require Codepagex.Mappings.Helpers
      alias Codepagex.Mappings.Helpers

      encodings = Codepagex.Mappings.get_encodings()
      {name, mappings} = Enum.find(encodings, fn {n, _} -> n == #{inspect(name)} end)

      Helpers.def_from_string_raw(name, mappings)
    end
    """

    {{:module, _module_name, module_binary, _exports}, _bindings} =
      Code.eval_string(module_content)

    :code.load_binary(module_name, ~c"#{module_name}.beam", module_binary)

    def from_string(binary, unquote(name |> String.to_atom()), missing_fun, acc) do
      apply(unquote(module_name), :from_string, [binary, <<>>, missing_fun, acc])
    end
  end

  def from_string(_, encoding, _, acc) do
    {:error, "Unknown encoding #{inspect(encoding)}", acc}
  end
end

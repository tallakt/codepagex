defmodule Codepagex.DynamicConverter do
  @moduledoc """
  This module generate a dynamic module for each encoding that is configured by the user.
  It then creates a clause that calls this new module through apply/3.
  It also has catch-all clauses for encodings that are not configured.
  """
  require Codepagex.Mappings.Helpers

  encodings = Codepagex.Mappings.get_encoding_names()

  for name <- encodings do
    parsed_name = String.replace(name, ["/", " "], "_")
    module_name = Module.concat(Codepagex.Functions.ToString.Generated, parsed_name)

    module_content = """
    defmodule #{inspect(module_name)} do
      require Codepagex.Mappings.Helpers
      alias Codepagex.Mappings.Helpers

      encodings = Codepagex.Mappings.get_encodings(#{inspect(name)})

      Helpers.def_to_string(#{inspect(name)}, encodings)
      Helpers.def_from_string(#{inspect(name)}, encodings)
    end
    """

    {{:module, _module_name, module_binary, _exports}, _bindings} =
      Code.eval_string(module_content)

    :code.load_binary(module_name, ~c"#{module_name}.beam", module_binary)

    def to_string(binary, unquote(String.to_atom(name)), missing_fun, acc) do
      apply(unquote(module_name), :to_string, [binary, <<>>, missing_fun, acc])
    end

    def from_string(binary, unquote(String.to_atom(name)), missing_fun, acc) do
      apply(unquote(module_name), :from_string, [binary, <<>>, missing_fun, acc])
    end
  end

  def to_string(_, encoding, _, acc) do
    {:error, "Unknown encoding #{inspect(encoding)}", acc}
  end

  def from_string(_, encoding, _, acc) do
    {:error, "Unknown encoding #{inspect(encoding)}", acc}
  end
end

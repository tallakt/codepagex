defmodule Codepagex.Error do
  @moduledoc """
  An error returned by Codepagex
  """
  defexception [:message]

  @doc false
  def exception(msg) do
    %__MODULE__{message: msg}
  end
end



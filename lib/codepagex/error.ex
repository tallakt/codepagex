defmodule Codepagex.Error do
  @moduledoc """
  An error returned by Codepagex
  """
  defexception [:message]

  # The reason is whatever a missing_fun returned, so it may not be a string
  @doc false
  def exception(msg) when is_binary(msg) do
    %__MODULE__{message: msg}
  end

  def exception(reason) do
    %__MODULE__{message: inspect(reason)}
  end
end

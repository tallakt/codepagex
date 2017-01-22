defmodule Mix.Tasks.Codepagex.Benchee do
  @moduledoc false

  use Mix.Task

  import Codepagex
  require Codepagex

  @iso from_string("æøåæøåæøåæøåæøåÆØÅÆØÅÆØÅÆØÅÆØÅabcdefghijlm", :iso_8859_1)
  @ascii from_string("abcdefghijklmnopqrstuvwxyzABCDEFGHIJK", :ascii)
  @utf8 "abcdefghijklmnoÆØÅæøåABCDEFGæøåæøåæøåæøåæøåæøåæøåæøå"

  @shortdoc "Run codepagex benchmarks"
  def run(_) do
    Benchee.run %{time: 3},
      ascii_to_string: &ascii_to_string/0,
      iso_to_string: &iso_to_string/0,
      ascii_from_string: &ascii_from_string/0,
      iso_from_string: &iso_from_string/0
  end

  defp ascii_to_string do
    for _ <- 1..1000, do: to_string(@ascii, :ascii)
  end

  defp iso_to_string do
    for _ <- 1..1000, do: to_string(@iso, :iso_8859_1)
  end

  defp ascii_from_string do
    for _ <- 1..1000, do: from_string(@utf8, :ascii, replace_nonexistent("_"))
  end

  defp iso_from_string do
    for _ <- 1..1000, do: from_string(@utf8, :iso_8859_1)
  end
end

defmodule Mix.Tasks.Codepagex.Benchee do
  use Mix.Task

  import Codepagex
  require Codepagex

  @iso from_string("æøåæøåæøåæøåæøåÆØÅÆØÅÆØÅÆØÅÆØÅabcdefghijlm", :iso_8859_1)
  @ascii from_string("abcdefghijklmnopqrstuvwxyzABCDEFGHIJK", :ascii)
  @utf8 "abcdefghijklmnoÆØÅæøåABCDEFGæøåæøåæøåæøåæøåæøåæøåæøå"

  @shortdoc "Run codepagex benchmarks"
  def run(_) do
    Benchee.run %{time: 3},
      ascii_to_string: (fn -> for _ <- 1..1000, do: to_string(@ascii, :ascii) end),
      iso_to_string: (fn -> for _ <- 1..1000, do: to_string(@iso, :iso_8859_1) end),
      ascii_from_string: (fn -> for _ <- 1..1000, do: from_string(@utf8, :ascii, replace_nonexistent("_")) end),
      iso_from_string: (fn -> for _ <- 1..1000, do: from_string(@utf8, :iso_8859_1) end)
  end
end

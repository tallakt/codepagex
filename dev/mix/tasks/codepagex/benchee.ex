defmodule Mix.Tasks.Codepagex.Benchee do
  @moduledoc false

  use Mix.Task

  import Codepagex
  require Codepagex

  @iso from_string!("æøåæøåæøåæøåæøåÆØÅÆØÅÆØÅÆØÅÆØÅabcdefghijlm", :iso_8859_1)
  @iso_gigantic from_string!(
                  Stream.cycle(["Æ"]) |> Stream.take(1 * 1000 * 1000) |> Enum.into(""),
                  :iso_8859_1
                )
  @ascii from_string!("abcdefghijklmnopqrstuvwxyzABCDEFGHIJK", :ascii)
  @utf8 "abcdefghijklmnoÆØÅæøåABCDEFGæøåæøåæøåæøåæøåæøåæøåæøå"
  @utf8_gigantic Stream.cycle(["A"]) |> Stream.take(1 * 1000 * 1000) |> Enum.into("")

  @shortdoc "Run codepagex benchmarks"
  def run(_) do
    tests = %{
      ascii_to_string: &ascii_to_string/0,
      iso_to_string: &iso_to_string/0,
      gigantic_iso_to_string: &gigantic_iso_to_string/0,
      ascii_from_string: &ascii_from_string/0,
      ascii_from_gigantic_string: &ascii_from_gigantic_string/0,
      iso_from_string: &iso_from_string/0,
      iso_from_gigantic_string: &iso_from_gigantic_string/0,
      erlang_unicode_from_gigantic_string: &erlang_unicode_from_gigantic_string/0
    }

    Benchee.run(tests, time: 3, memory_time: 2)
  end

  defp ascii_to_string do
    for _ <- 1..1000, do: to_string!(@ascii, :ascii)
  end

  defp gigantic_iso_to_string do
    for _ <- 1..1000, do: to_string!(@iso_gigantic, :iso_8859_1)
  end

  defp iso_to_string do
    for _ <- 1..1000, do: to_string!(@iso, :iso_8859_1)
  end

  defp ascii_from_string do
    for _ <- 1..1000, do: from_string!(@utf8, :ascii, replace_nonexistent("_"))
  end

  defp ascii_from_gigantic_string do
    for _ <- 1..1000, do: from_string!(@utf8_gigantic, :ascii, replace_nonexistent("_"))
  end

  defp iso_from_string do
    for _ <- 1..1000, do: from_string!(@utf8, :iso_8859_1)
  end

  defp iso_from_gigantic_string do
    for _ <- 1..1000, do: from_string!(@utf8_gigantic, :iso_8859_1)
  end

  defp erlang_unicode_from_gigantic_string do
    for _ <- 1..1000, do: :unicode.characters_to_binary(@utf8_gigantic, :utf8, :latin1)
  end
end

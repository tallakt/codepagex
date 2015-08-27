defmodule Mix.Tasks.Codepagex.Benchmark do
  use Mix.Task
  import Codepagex

  # run with mix codepagex.benchmark
  # It is not documented so that any project depending on this one will have
  # this task available in `mix help`
  def run(_) do
    iso = from_string "æøåæøåæøåæøåæøåÆØÅÆØÅÆØÅÆØÅÆØÅabcdefghijlm", :iso_8859_1
    ascii = from_string "abcdefghijklmnopqrstuvwxyzABCDEFGHIJK", :ascii
    utf8 = "abcdefghijklmnoÆØÅæøåABCDEFGæøåæøåæøåæøåæøåæøåæøåæøå"

    IO.puts "testing `to_string` from :ascii"
    Benchwarmer.benchmark(
      fn -> to_string ascii, :ascii end
    )

    IO.puts "testing `to_string` from :iso-8859-1"
    Benchwarmer.benchmark(
      fn -> to_string iso, :iso_8859_1 end
    )

    IO.puts "testing `from_string` to :ascii"
    Benchwarmer.benchmark(
      fn -> from_string utf8, :ascii, replace_nonexistent("_") end
    )

    IO.puts "testing `from_string` to :iso-8859-1"
    Benchwarmer.benchmark(
      fn -> from_string utf8, :iso_8859_1 end
    )
  end
end

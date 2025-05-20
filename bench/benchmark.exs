import Codepagex

k1 = 1 * 1000
k10 = 10 * 1000
k100 = 100 * 1000
m1 = 1 * 1000 * 1000

ascii = from_string("abcdefghijklmnopqrstuvwxyzABCDEFGHIJK", :ascii) |> elem(1)

ascii_1K =
  Stream.cycle([ascii])
  |> Stream.take(k1)
  |> Enum.into(<<>>)
  |> binary_slice(0, k1)

ascii_10K =
  Stream.cycle([ascii])
  |> Stream.take(k10)
  |> Enum.into(<<>>)
  |> binary_slice(0, k10)

ascii_100K =
  Stream.cycle([ascii])
  |> Stream.take(k100)
  |> Enum.into(<<>>)
  |> binary_slice(0, k100)

ascii_1M =
  Stream.cycle([ascii])
  |> Stream.take(m1)
  |> Enum.into(<<>>)
  |> binary_slice(0, m1)

IO.puts("ASCII to UTF-8")

Benchee.run(
  %{
    "Codepagex.from_string" => &Codepagex.to_string(&1, :ascii),
    ":iconv.convert" => &:iconv.convert("ascii", "utf-8", &1)
  },
  inputs: %{
    "Small ASCII String" => ascii,
    "K1 ASCII String" => ascii_1K,
    "K10 ASCII String" => ascii_10K,
    "K100 ASCII String" => ascii_100K,
    "M1 ASCII String" => ascii_1M
  },
  time: 5,
  memory_time: 5
)

iso = from_string("æøåæøåæøåæøåæøåÆØÅÆØÅÆØÅÆØÅÆØÅabcdefghijlm", :iso_8859_1) |> elem(1)

iso_1K =
  Stream.cycle([iso])
  |> Stream.take(k1)
  |> Enum.into(<<>>)
  |> binary_slice(0, k1)

iso_10K =
  Stream.cycle([iso])
  |> Stream.take(k10)
  |> Enum.into(<<>>)
  |> binary_slice(0, k10)

iso_100K =
  Stream.cycle([iso])
  |> Stream.take(k100)
  |> Enum.into(<<>>)
  |> binary_slice(0, k100)

iso_1M =
  Stream.cycle([iso])
  |> Stream.take(m1)
  |> Enum.into(<<>>)

IO.puts "ISO8859-1 to UTF-8"

Benchee.run(
  %{
    "Codepagex.from_string" => &Codepagex.to_string(&1, :iso_8859_1),
    ":iconv.convert" => &:iconv.convert("iso8859-1", "utf-8", &1),
    ":unicode.characters_to_binary" => &:unicode.characters_to_binary(&1, :latin1, :utf8)
  },
  inputs: %{
    "Small ISO8859-1 String" => iso,
    "K1 ISO8859-1 String" => iso_1K,
    "K10 ISO8859-1 String" => iso_10K,
    "K100 ISO8859-1 String" => iso_100K,
    "M1 ISO8859-1 String" => iso_1M
  },
  time: 5,
  memory_time: 5
)

utf8 = "abcdefghijklmnoÆØÅæøåABCDEFGæøåæøåæøåæøåæøåæøåæøåæøå"
utf8_stream = utf8 |> String.graphemes() |> Stream.cycle()
utf8_1K = utf8_stream |> Stream.take(k1) |> Enum.into("")
utf8_10K = utf8_stream |> Stream.take(k10) |> Enum.into("")
utf8_100K = utf8_stream |> Stream.take(k100) |> Enum.into("")
utf8_1M = utf8_stream |> Stream.take(m1) |> Enum.into("")

IO.puts "UTF-8 to ISO8895-1"

Benchee.run(
  %{
    "Codepagex.from_string" => &Codepagex.from_string(&1, :iso_8859_1),
    ":iconv.convert" => &:iconv.convert("utf-8", "iso8859-1", &1),
    ":unicode.characters_to_binary" => &:unicode.characters_to_binary(&1, :utf8, :latin1)
  },
  inputs: %{
    "Small UTF-8 String" => utf8,
    "K1 UTF-8 String" => utf8_1K,
    "K10 UTF-8 String" => utf8_10K,
    "K100 UTF-8 String" => utf8_100K,
    "M1 UTF-8 String" => utf8_1M
  },
  time: 5,
  memory_time: 5
)

IO.puts "UTF-8 to ASCII"

Benchee.run(
  %{
    "Codepagex.from_string" => &Codepagex.from_string(&1, :ascii, replace_nonexistent("_")),
    ":iconv.convert" => &:iconv.convert("utf-8", "ascii", &1)
  },
  inputs: %{
    "Small UTF-8 String" => utf8,
    "K1 UTF-8 String" => utf8_1K,
    "K10 UTF-8 String" => utf8_10K,
    "K100 UTF-8 String" => utf8_100K,
    "M1 UTF-8 String" => utf8_1M
  },
  time: 5,
  memory_time: 5
)

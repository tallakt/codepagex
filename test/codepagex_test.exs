defmodule CodepagexTest do
  use ExUnit.Case, async: true
  doctest Codepagex, import: true

  @iso_hello "hello " <> <<230, 248, 229>>
  @missing "Invalid bytes for encoding"

  test "encoding_list should return some existing values" do
    assert "ETSI/GSM0338" in Codepagex.encoding_list()
    assert "ISO8859/8859-14" in Codepagex.encoding_list()
  end

  test "only include encodings from mix env" do
    refute "VENDORS/MICSFT/PC/CP852" in Codepagex.encoding_list()
  end

  test "aliases should contain come aliases" do
    assert Codepagex.aliases().iso_8859_1 == "ISO8859/8859-1"
    assert Codepagex.aliases().iso_8859_5 == "ISO8859/8859-5"
  end

  test "to_string should work for ISO8859/8859-1" do
    assert Codepagex.to_string(@iso_hello, "ISO8859/8859-1") == {:ok, "hello æøå"}
  end

  test "to_string should work for alias :iso_8859_1" do
    assert Codepagex.to_string(@iso_hello, :iso_8859_1) == {:ok, "hello æøå"}
  end

  test "to_string should work for ETSI/GSM0338" do
    assert Codepagex.to_string(<<96>>, "ETSI/GSM0338") == {:ok, "¿"}
  end

  test "to_string should fail for ETSI/GSM0338 undefined character" do
    assert Codepagex.to_string(<<128>>, "ETSI/GSM0338") == {:error, @missing}
  end

  test "to_string should fail for ETSI/GSM0338 single escape character" do
    assert Codepagex.to_string(<<27>>, "ETSI/GSM0338") == {:error, @missing}
  end

  test "to_string should succeed for ETSI/GSM0338 multibyte character" do
    assert Codepagex.to_string(<<27, 101>>, "ETSI/GSM0338") == {:ok, "€"}
  end

  test "to_string! should work for ETSI/GSM0338" do
    assert Codepagex.to_string!(<<96>>, "ETSI/GSM0338") == "¿"
  end

  test "to_string! should fail for ETSI/GSM0338 undefined character" do
    assert_raise Codepagex.Error, fn ->
      Codepagex.to_string!(<<128>>, "ETSI/GSM0338")
    end
  end

  test ":ascii is plain US-ASCII, mapping every byte 0..127 to itself" do
    all = for b <- 0..127, into: <<>>, do: <<b>>

    assert Codepagex.aliases().ascii == "VENDORS/MISC/US-ASCII"
    assert Codepagex.to_string(all, :ascii) == {:ok, all}
    assert Codepagex.from_string(all, :ascii) == {:ok, all}
  end

  test ":ascii keeps apostrophe and backtick as is" do
    assert Codepagex.to_string("don't `x`", :ascii) == {:ok, "don't `x`"}
    assert Codepagex.from_string("don't `x`", :ascii) == {:ok, "don't `x`"}
  end

  test ":ascii rejects bytes above 127 and non-ascii characters" do
    assert {:error, @missing} = Codepagex.to_string(<<128>>, :ascii)
    assert {:error, @missing} = Codepagex.from_string("æ", :ascii)
    assert {:error, @missing} = Codepagex.from_string("’", :ascii)
  end

  test "replace_nonexistent replaces bytes that are not valid utf-8" do
    assert Codepagex.from_string(
             "a" <> <<255>> <> "b",
             :ascii,
             Codepagex.replace_nonexistent("_")
           ) ==
             {:ok, "a_b", 1}

    assert Codepagex.from_string(
             <<255, 254>> <> "æ",
             :ascii,
             Codepagex.replace_nonexistent("_"),
             0
           ) ==
             {:ok, "___", 3}
  end

  test "to_string returns error on unknown encoding" do
    assert Codepagex.to_string("test", :unknown) ==
             {:error, "Unknown encoding :unknown"}

    assert Codepagex.to_string("test", "bogus") ==
             {:error, "Unknown encoding \"bogus\""}
  end

  test "from_string should work for ISO8859/8859-1" do
    assert Codepagex.from_string("hello æøå", "ISO8859/8859-1") == {:ok, @iso_hello}
  end

  test "from_string should work for alias :iso_8859_1" do
    assert Codepagex.from_string("hello æøå", :iso_8859_1) == {:ok, @iso_hello}
  end

  test "from_string should work for ETSI/GSM0338" do
    assert Codepagex.from_string("¿", "ETSI/GSM0338") == {:ok, <<96>>}
  end

  test "from_string should fail for ETSI/GSM0338 undefined character" do
    assert Codepagex.from_string("൨", "ETSI/GSM0338") == {:error, @missing}
  end

  test "from_string should succeed for ETSI/GSM0338 multibyte character" do
    assert Codepagex.from_string("€", "ETSI/GSM0338") == {:ok, <<27, 101>>}
  end

  test "from_string! should work for ETSI/GSM0338" do
    assert Codepagex.from_string!("¿", "ETSI/GSM0338") == <<96>>
  end

  test "from_string! should raise exception for undefined character" do
    assert_raise Codepagex.Error, fn ->
      Codepagex.from_string!("൨", "ETSI/GSM0338")
    end
  end

  test "from_string returns error on unknown encoding" do
    assert Codepagex.from_string("test", :unknown) ==
             {:error, "Unknown encoding :unknown"}

    assert Codepagex.from_string("test", "bogus") ==
             {:error, "Unknown encoding \"bogus\""}
  end

  test "translate works between ISO8859/8859-1 and ETSI/GSM0338" do
    assert Codepagex.translate(@iso_hello, :iso_8859_1, "ETSI/GSM0338") ==
             {:ok, "hello " <> <<29, 12, 15>>}
  end

  test "translate! works between ISO8859/8859-1 and ETSI/GSM0338" do
    assert Codepagex.translate!(@iso_hello, :iso_8859_1, "ETSI/GSM0338") ==
             "hello " <> <<29, 12, 15>>
  end

  test "translate! raises exception on failure" do
    assert_raise Codepagex.Error, fn ->
      Codepagex.translate!("൨", :iso_8859_1, "ETSI/GSM0338")
    end
  end

  # This test must be run by itself. It may be initiated by running:
  #
  # `mix test --only run_solo`
  #
  # Also please run the test a few times, as it's a bit flaky
  @tag :run_solo
  test "atoms loaded from Codepagex.Mappings" do
    assert {:ok, "Codepagex"} = Codepagex.to_string("Codepagex", "ETSI/GSM0338")
  end
end

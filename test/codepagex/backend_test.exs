defmodule Codepagex.BackendTest do
  use ExUnit.Case, async: true

  # The Windows code pages aren't in the encodings this project's config gives
  # Codepagex itself, so they're the backend's own.
  defmodule Encodings do
    use Codepagex.Backend, encodings: [:ascii, :windows_1251, ~r{WINDOWS/CP125[02]$}]
  end

  test "it has the encodings it was given, and their aliases" do
    assert Encodings.encoding_list() == [
             "VENDORS/MICSFT/WINDOWS/CP1250",
             "VENDORS/MICSFT/WINDOWS/CP1251",
             "VENDORS/MICSFT/WINDOWS/CP1252",
             "VENDORS/MISC/US-ASCII"
           ]

    assert Encodings.aliases() == %{
             ascii: "VENDORS/MISC/US-ASCII",
             windows_1250: "VENDORS/MICSFT/WINDOWS/CP1250",
             windows_1251: "VENDORS/MICSFT/WINDOWS/CP1251",
             windows_1252: "VENDORS/MICSFT/WINDOWS/CP1252"
           }

    refute "VENDORS/MICSFT/WINDOWS/CP1251" in Codepagex.encoding_list()
  end

  test "to_string and from_string, by alias, full name as a string and as an atom" do
    assert Encodings.to_string(<<0xC0, 0xE1>>, :windows_1251) == {:ok, "Аб"}
    assert Encodings.to_string(<<0x80>>, "VENDORS/MICSFT/WINDOWS/CP1252") == {:ok, "€"}

    assert Encodings.from_string("Grüße €", :windows_1252) ==
             {:ok, <<"Gr", 0xFC, 0xDF, "e ", 0x80>>}

    assert Encodings.from_string!("Ł", :"VENDORS/MICSFT/WINDOWS/CP1250") == <<0xA3>>
    assert Encodings.to_string!(<<0xA3>>, :windows_1250) == "Ł"
  end

  test "errors, and what to do with what doesn't convert" do
    assert Encodings.to_string(<<0x98>>, :windows_1251) == {:error, "Invalid bytes for encoding"}

    assert Encodings.to_string(<<0x98, 0x41>>, :windows_1251, Encodings.use_utf_replacement()) ==
             {:ok, "�A", 1}

    assert Encodings.from_string("Ω", :windows_1252) == {:error, "Invalid bytes for encoding"}

    assert Encodings.from_string("aΩb", :windows_1252, Encodings.replace_nonexistent("?"), 0) ==
             {:ok, "a?b", 1}

    assert_raise Codepagex.Error, fn -> Encodings.from_string!("Ω", :windows_1252) end
    assert Encodings.to_string("x", :iso_8859_1) == {:error, "Unknown encoding :iso_8859_1"}

    assert Encodings.to_string("x", "NOT/AN/ENCODING") ==
             {:error, "Unknown encoding \"NOT/AN/ENCODING\""}
  end

  test "translate between its encodings" do
    assert Encodings.translate(<<0xE0>>, :windows_1251, :windows_1252) ==
             {:error, "Invalid bytes for encoding"}

    assert Encodings.translate!("Hello", :ascii, :windows_1251) == "Hello"
  end

  test "it agrees with Codepagex for an encoding both have" do
    defmodule Iso do
      use Codepagex.Backend, encodings: [:iso_8859_5]
    end

    bytes = Enum.into(0x20..0xFF, <<>>, &<<&1>>)
    assert Iso.to_string(bytes, :iso_8859_5) == Codepagex.to_string(bytes, :iso_8859_5)
  end

  test "the encodings may come from the module's attributes, as from config" do
    defmodule FromAttributes do
      @common [:ascii]
      @extra Application.compile_env(:codepagex, :backend_test_extra, [:windows_1253])
      use Codepagex.Backend, encodings: @common ++ @extra
    end

    assert FromAttributes.encoding_list() == [
             "VENDORS/MICSFT/WINDOWS/CP1253",
             "VENDORS/MISC/US-ASCII"
           ]

    assert FromAttributes.to_string(<<0xC1>>, :windows_1253) == {:ok, "Α"}
  end

  test "an encoding that matches nothing doesn't compile" do
    assert_raise CompileError, ~r/:windows_9999 in encodings: matches no encoding/, fn ->
      Code.compile_string("""
      defmodule Codepagex.BackendTest.Broken do
        use Codepagex.Backend, encodings: [:windows_9999]
      end
      """)
    end
  end
end

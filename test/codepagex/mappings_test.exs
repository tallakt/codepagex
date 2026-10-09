defmodule Codepagex.MappingsTest do
  use ExUnit.Case, async: false
  import ExUnit.CaptureIO

  alias Codepagex.Mappings.Helpers

  @names %{"ISO8859/8859-1" => "a", "VENDORS/MISC/CP424" => "b"}
  @aliases %{iso_8859_1: "ISO8859/8859-1", iso_8859_12: "ISO8859/8859-12"}

  defp filter(filters) do
    with_io(:stderr, fn ->
      Helpers.filter_to_selected_encodings(@names, filters, @aliases)
    end)
  end

  test "matching filters select encodings without warnings" do
    {result, warnings} =
      filter([:iso_8859_1, "VENDORS/MISC/CP424", ~r[cp4]i])

    assert result == [{"ISO8859/8859-1", "a"}, {"VENDORS/MISC/CP424", "b"}]
    assert warnings == ""
  end

  test "a string that matches nothing produces a warning" do
    {result, warnings} = filter([:iso_8859_1, "MISC/CP424"])

    assert result == [{"ISO8859/8859-1", "a"}]
    assert warnings =~ ~s("MISC/CP424" in config :codepagex, :encodings)
  end

  test "an alias with no encoding behind it produces a warning" do
    {_, warnings} = filter([:iso_8859_12])
    assert warnings =~ ":iso_8859_12 in config :codepagex, :encodings"
  end

  test "a regex that matches nothing produces a warning" do
    {_, warnings} = filter([~r[nothing]])
    assert warnings =~ "~r/nothing/"
  end

  test "each unmatched filter gets its own warning" do
    {_, warnings} = filter(["x", "y", :iso_8859_1])
    assert warnings =~ ~s("x")
    assert warnings =~ ~s("y")
    refute warnings =~ "iso_8859_1 in"
  end

  test "name_for_file strips the extension from a relative path" do
    assert Helpers.name_for_file("ISO8859/8859-1.TXT") == "ISO8859/8859-1"
    assert Helpers.name_for_file("VENDORS/MISC/CP424.txt") == "VENDORS/MISC/CP424"
  end

  describe "from_string_entries" do
    @cp932 "VENDORS/MICSFT/WINDOWS/CP932"
    @cp932_file Path.join([__DIR__] ++ ~w(.. .. unicode VENDORS MICSFT WINDOWS CP932.TXT))

    test "leaves other encodings unchanged" do
      entries = [{<<2>>, 0x41}, {<<1>>, 0x41}]
      assert Helpers.from_string_entries("ISO8859/8859-1", entries) == entries
    end

    test "CP932 uses one byte sequence per codepoint" do
      entries = Codepagex.MappingFile.load(@cp932_file)
      used = Helpers.from_string_entries(@cp932, entries)

      codepoints = Enum.map(used, fn {_, cp} -> cp end)
      assert codepoints == Enum.uniq(codepoints)
      assert MapSet.new(codepoints) == MapSet.new(entries, fn {_, cp} -> cp end)
    end

    test "CP932 prefers the standard byte sequences" do
      used =
        @cp932
        |> Helpers.from_string_entries(Codepagex.MappingFile.load(@cp932_file))
        |> Map.new(fn {bytes, cp} -> {cp, Base.encode16(bytes)} end)

      # JIS X 0208 rather than the NEC row 13 duplicate
      assert used[0x2252] == "81E0"
      assert used[0x222A] == "81BE"
      # JIS X 0208 rather than the IBM extension
      assert used[0xFFE2] == "81CA"
      # NEC row 13 rather than the IBM extension
      assert used[0x2160] == "8754"
      # IBM extension rather than the NEC selected IBM extension
      assert used[0x7E8A] == "FA5C"
    end
  end
end

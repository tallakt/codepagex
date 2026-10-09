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
end

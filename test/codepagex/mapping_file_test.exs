#
# http://www.unicode.org/Public/MAPPINGS/
# 0x1B  0x00A0  # ESCAPE TO EXTENSION TABLE (or displayed as NBSP, see note above)
# 0x1B0A  0x000C  # FORM FEED
# unicode/ETSI/GSM0338.TXT



defmodule Codepagex.DataFileTest do
  use ExUnit.Case
  @gsm0338 Path.join([__DIR__] ++ ~w(.. .. unicode ETSI GSM0338.TXT))

  test "it should be able to read the mapping file for ETSI/GSM0338" do
    data = Codepagex.MappingFile.load(@gsm0338) |> Enum.into(%{})
    assert data[<<0x1b, 0x0a>>] == 0x000c
    assert data[<<0x00>>] == 0x0040 # first
    assert data[<<0x7f>>] == 0x00e0 # last
    refute Map.has_key? data, <<0x1b>>  # 0x1b is an escape character
  end
end

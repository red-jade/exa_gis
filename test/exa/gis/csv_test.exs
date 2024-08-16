defmodule Exa.Gis.CsvTest do
  use ExUnit.Case

  use Exa.Csv.Constants

  alias Exa.Parse
  alias Exa.Csv.CsvReader
  alias Exa.Gis.Location

  # TODO - remove when roll Exa Core version
  # default fields for parsing null and boolean values
  @nulls ["", "nil", "null", "nan", "inf"]

  @default [
    [1, true, "3 45.0 N 2 12.25 W", "3°45.0'S 2°12.25'E"],
    [9, false, "3 45 0.0, -2 12 15.0", "3°45'0.0\"S 2°12'15.0\"E"],
    [7, true, nil, nil]
  ]

  @parsed [
    [1, true, {{3, 45.0, :N}, {2, 12.25, :W}}, {{3, 45.0, :S}, {2, 12.25, :E}}],
    [9, false, {{3, 45, 0.0, :N}, {2, 12, 15.0, :W}}, {{3, 45, 0.0, :S}, {2, 12, 15.0, :E}}],
    [7, true, nil, nil]
  ]

  @in_dir Path.join(["test", "input", "csv"])

  defp in_file(name), do: Exa.File.join(@in_dir, name, @filetype_csv)

  test "lat lon" do
    file = in_file("lat_lon")

    # raw csv
    {:csv, :list, csv} = CsvReader.from_file(file)
    assert @default == csv

    # default parser
    {:csv, :list, csv} = CsvReader.from_file(file, pardef: Location.p_guess())
    assert @parsed == csv

    # specific parser
    latlonpar = Parse.compose([Parse.p_null(@nulls), &Location.parse/1])
    parsers = %{2 => latlonpar, 3 => latlonpar}
    {:csv, _keys, csv} = CsvReader.from_file(file, parsers: parsers)
    assert @parsed == csv
  end
end

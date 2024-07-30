defmodule Exa.Gis.GeoJsonTest do
  use ExUnit.Case

  use Exa.Json.Constants

  import Exa.Gis.GeoJson.GeoJson

  @filetype_geojson "geojson"

  @in_dir ["test", "input", "json"]
  @geo_dir ["deps", "geo_countries", "data"]

  defp file(name), do: Exa.File.join(@in_dir, name, @filetype_geojson)
  defp deps(name), do: Exa.File.join(@geo_dir, name, @filetype_geojson)

  test "simple file" do
    from_file(file("simple"))
    # |> IO.inspect()
  end

  test "features file" do
    from_file(file("features"))
    # |> IO.inspect()
  end

  test "countries" do
    _countries = from_file(deps("countries"))
    # IO.inspect(Map.get(countries, :type))
    # IO.inspect(hd(Map.get(countries, :features)))
  end
end

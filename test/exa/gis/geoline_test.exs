defmodule Exa.Gis.GeoLineTest do
  use ExUnit.Case

  use Exa.Gis.Constants

  alias Exa.Gis.GeoLine
  alias Exa.Gis.Location

  # coordinates from Wikipedia
  @london "51°30′26″N 0°7′39″W"
  @paris "48°51′24″N 2°21′8″E"

  doctest Exa.Gis.Projection

  test "projection london paris" do
    london = Location.parse!(@london)
    paris = Location.parse!(@paris)

    lonpar = GeoLine.new_line(london, paris)
    {:geodesic, pts} = GeoLine.interp_n(lonpar, 10)
    assert 10 = length(pts)
    assert Location.equals?(london, List.first(pts))
    assert Location.equals?(paris, List.last(pts))
  end
end

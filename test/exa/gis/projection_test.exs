defmodule Exa.Gis.ProjectionTest do
  use ExUnit.Case

  use Exa.Gis.Constants

  import Exa.Gis.Projection

  alias Exa.Gis.GeoLine
  alias Exa.Gis.Location

  # coordinates from Wikipedia
  @london "51°30′26″N 0°7′39″W"
  @paris "48°51′24″N 2°21′8″E"

  doctest Exa.Gis.GeoLine

  test "geoline london paris" do
    london = Location.parse!(@london)
    paris = Location.parse!(@paris)
    lonpar = GeoLine.new_line(london, paris)
    midloc = GeoLine.midpoint(lonpar)
    equi = new_equirect(midloc, 100_000.0, 150_000.0)
    IO.inspect(equi)

    {:ok, lonpos} = project(equi, london)
    {:ok, parpos} = project(equi, paris)
    IO.inspect(lonpos)
    IO.inspect(parpos)

    {:ok, line} = project(equi, lonpar)
    IO.inspect(line)

    desic = GeoLine.interp_n(lonpar, 10)
    {:ok, desic} = project(equi, desic)
    IO.inspect(desic)
  end
end

defmodule Exa.Gis.GeoLine do
  @moduledoc """
  A geographical line represented by two endpoints.

  The shortest great circle path between the points can be generated 
  with a fixed number of steps, or a fixed length of step.
  """
  use Exa.Gis.Constants

  import Exa.Types
  alias Exa.Types, as: E

  import Exa.Gis.Types
  alias Exa.Gis.Types, as: G

  alias Exa.Math
  alias Exa.Gis.Location

  # -----------
  # constructor
  # -----------

  @doc "A simple line between two locations."
  @spec new_line(G.location(), G.location()) :: G.geoline()
  def new_line(loc1, loc2), do: {:geoline, Location.to_dd(loc1), Location.to_dd(loc2)}

  @doc "Extract the first and last points from a geodesic."
  @spec new_line(G.geodesic()) :: G.geoline()
  def new_line({:geodesic, locs}), do: {:geoline, List.first(locs), List.last(locs)}

  @doc """
  A polyline representing the shortest 
  great circle path between two locations.
  """
  @spec new_geodesic(G.locations()) :: G.geodesic()
  def new_geodesic(locs) when is_locs(locs), do: {:geodesic, Enum.map(locs, &Location.to_dd/1)}

  # ---------
  # distances
  # ---------

  @doc "Get the total length of a line or geodesic."
  @spec distance(G.distance_algo(), G.geoline() | G.geodesic()) :: G.metres()
  def distance(algo \\ :haversine, geo)

  def distance(algo, {:geoline, loc1, loc2}), do: Location.distance(algo, loc1, loc2)

  def distance(algo, {:geodesic, locs}) do
    # note there is a messy optimization possible at ~50% level
    # to carry forward the trig functions of lat and lon to next segment
    {_, d} =
      Enum.reduce(tl(locs), {hd(locs), 0.0}, fn loc2, {loc1, d} ->
        {loc2, d + Location.distance(algo, loc1, loc2)}
      end)

    d
  end

  # -----------
  # interpolate
  # -----------

  @doc """
  Get the midpoint on a great circle between the endpoints.

  The result is always in decimal degress.
  """
  @spec midpoint(G.geoline()) :: G.location_dd()
  def midpoint(geoline) do
    {:geodesic, [_, midloc, _loc2]} = interp_n(geoline, 3)
    midloc
  end

  @doc """
  Generate a geodesic for the great circle path between the endpoints.

  The `step` argument is the maximum length of each segment (m).
  All segment lengths will be equal, 
  each one less than the maximum step size.
  """
  @spec interp_step(G.geoline(), G.metres()) :: G.geodesic()
  def interp_step({:geoline, loc1, loc2}, step) when is_float_pos(step) do
    dist = Location.distance(loc1, loc2)

    case trunc(ceil(dist / step)) do
      n when n <= 2 -> {:geodesic, [loc1, loc2]}
      n -> do_interp(loc1, loc2, dist, n)
    end
  end

  @doc """
  Generate a polyline for the great circle between the endpoints.

  The `n` argument is the number of points to generate (n >= 2).
  """
  @spec interp_n(G.geoline(), E.count1()) :: G.geodesic()

  def interp_n({:geoline, loc1, loc2}, n) when is_integer(n) and n <= 2 do
    {:geodesic, [loc1, loc2]}
  end

  def interp_n({:geoline, loc1, loc2}, n) when is_count1(n) do
    do_interp(loc1, loc2, Location.distance(loc1, loc2), n)
  end

  # factor out the interpolation
  # so the haversine is only calculated once
  defp do_interp({lat1, lon1} = loc1, {lat2, lon2} = loc2, dist, n) do
    distR = dist / @mean_radius
    sindistR = :math.sin(distR)

    coslat1 = Math.cosd(lat1)
    coslat2 = Math.cosd(lat2)
    sinlat1 = Math.sind(lat1)
    sinlat2 = Math.sind(lat2)

    cc1 = coslat1 * Math.cosd(lon1)
    cc2 = coslat2 * Math.cosd(lon2)
    cs1 = coslat1 * Math.sind(lon1)
    cs2 = coslat2 * Math.sind(lon2)

    del = 1.0 / (n - 1)

    {_1, pts} =
      Enum.reduce(1..(n - 2), {del, [loc1]}, fn _, {t, pts} ->
        tdistR = t * distR
        a = :math.sin(distR - tdistR) / sindistR
        b = :math.sin(tdistR) / sindistR
        x = a * cc1 + b * cc2
        y = a * cs1 + b * cs2
        z = a * sinlat1 + b * sinlat2
        lat = Math.atand(z, :math.sqrt(x * x + y * y))
        lon = Math.atand(y, x)
        {t + del, [{lat, lon} | pts]}
      end)

    {:geodesic, Enum.reverse([loc2 | pts])}
  end
end

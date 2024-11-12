defmodule Exa.Gis.Projection do
  @moduledoc """
  Projections for geo-locations and geodesics.

  A projection maps geo-coordinates to a 
  bounded 2D Cartesian coordinate system.
  The 2D system has x to the right, and y upwards,
  so x aligns with increasing longitude,
  and y aligns with increasing latitude.

  The 2D system may be parameterized in various ways.
  A projection object is the set of parameters 
  needed to define the projection.
  """
  use Exa.Gis.Constants

  import Exa.Types
  alias Exa.Math

  alias Exa.Space.Types, as: S

  alias Exa.Space.BBox2f

  import Exa.Gis.Types
  alias Exa.Gis.Types, as: G

  alias Exa.Gis.Location

  # -----
  # types
  # -----

  # TODO - revert to Scene2d when it is published 

  @type line2d() :: {:line2d, S.pos2f(), S.pos2f()}

  @type polyline2d() :: {:polyline2d, [S.pos2f()]}

  # -----------
  # projections
  # -----------

  @doc """
  Get a new Equirectangular projection.

  The projection uses Pythagoras's Theorem for distances
  within a 2D plane tangent to a central location.
  The half-width and half-height of the 2D Cartesian system are given in metres. 
  These extents are symmetrical about the mid-point,
  so the bounding box of the final projection is `{(-w2,-h2),(w2,h2)}`.

  The extent should not cross the poles or the date-line meridian.
  """
  @spec new_equirect(loc :: G.location(), w2 :: G.metres(), h2 :: G.metres()) :: any()
  def new_equirect(loc, w2, h2) when is_float_pos(w2) and is_float_pos(h2) do
    {plat, _} = dd = Location.to_dd(loc)
    mlat = @lat1_eqtr + @delta_pole * abs(plat) / 90.0
    mlon = @lon1_eqtr * Math.cosd(plat)
    {:ok, bbox} = BBox2f.new(-w2, -h2, w2, h2)
    {:equirect, dd, mlat, mlon, bbox}
  end

  @doc "Project a location, geoline or geodesic.."
  @spec project(G.projection_algo(), G.location() | G.geoline() | G.geodesic()) ::
          :degenerate | {:ok | :clip, S.pos2f() | line2d() | polyline2d()}

  def project(proj, {:geoline, loc1, loc2}) do
    {tag1, p1} = project(proj, loc1)
    {tag2, p2} = project(proj, loc2)

    # TODO - revert to Scene2d when it is published 
    # line2d = Line2D.new(p1, p2) 
    line2d = {:ok, {:line2d, p1, p2}}

    case line2d do
      # :degenerate -> :degenerate
      {:ok, line2d} -> {is_clip(tag1, tag2), line2d}
    end
  end

  def project(proj, {:geodesic, locs}) when is_list(locs) do
    {clip, pts} =
      Enum.reduce(locs, {:ok, []}, fn loc, {clip, pts} ->
        {tag, pt} = project(proj, loc)
        {is_clip(clip, tag), [pt | pts]}
      end)

    # TODO - revert to Scene2d when it is published 
    # polyline2d = pts |> Enum.reverse() |> Polyline2D.new()
    polyline2d = {:ok, {:polyline2d, Enum.reverse(pts)}}

    case polyline2d do
      # :degenerate -> :degenerate
      {:ok, prim} -> {clip, prim}
    end
  end

  def project({:equirect, {plat, plon}, mlat, mlon, bbox}, loc) when is_loc(loc) do
    {lat, lon} = Location.to_dd(loc)
    pos = {mlon * (lon - plon), mlat * (lat - plat)}

    case BBox2f.classify(bbox, pos) do
      :outside -> {:clip, pos}
      _ -> {:ok, pos}
    end
  end

  defp is_clip(:clip, _), do: :clip
  defp is_clip(_, :clip), do: :clip
  defp is_clip(:ok, :ok), do: :ok
end

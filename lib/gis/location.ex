defmodule Exa.Gis.Location do
  @moduledoc """
  Utilities for geographical coordinates and locations.

  There are 4 representations of geo-locations:
  - DD: signed decimal degrees, without any directional information 
    `{lat_dd, lon_dd}`
  - D: non-neg decimal degrees, with directions 
    `{{lat_d, :N | :S}, {lon_d, :E | :W}}`
  - DM: non-neg int degrees, non-neg decimal minutes, with directions:
    `{{lat_i, min_d, :N | :S}, {lon_i, min_d, :E | :W}}`
  - DMS: non-neg int degrees, non-neg int minutes, non-neg decimal seconds, with directions:
    `{{lat_i, min_i, sec_d, :N | :S}, {lon_i, min_i, sec_d, :E | :W}}`

  The parser/formatter can recognize/generate 
  several variations on the 4 basic representations.

  Equality is based on strict floating-point comparison.

  For a more robust physical comparison, 
  it is best to calculate the small-distance approximation
  for the separation of two geo-locations,
  then threshold that radius.

  There are two distance measures provided:
  - simple Pythagoras's Theorem in the tangent plane 
    allowing for some ellipsoidal variation
  - general Haversine using spherical approximation

  The Haversine is generally more accurate than the 
  simple Pythagorean approximation, 
  especially over larger distances.
  However, it is slower, so if performance matters
  and the locations are within a few 100 km
  then the simple distance is often adequate.

  For example, London to Paris is about 343.5 km.
  The difference between simple distance and Haversine 
  is 162.5 m, or about 0.05 %.

  Reference:
  - https://www.movable-type.co.uk/scripts/latlong.html
  """
  require Logger

  use Exa.Gis.Constants
  use Exa.Constants

  import Exa.Types
  alias Exa.Types, as: E

  import Exa.Gis.Types
  alias Exa.Gis.Types, as: G

  alias Exa.Parse, as: P
  alias Exa.Parse

  alias Exa.Math
  alias Exa.Gis.Bearing

  # ===============================
  # DO NOT MIX-FORMAT THIS FILE !!!
  # DO NOT LET YOUR EDITOR REFORMAT
  # note excluded in .formatter.exs
  # ===============================

  # TODO - remove when roll Exa Core version

      # default fields for parsing null and boolean values
      @nulls ["", "nil", "null", "nan", "inf"]
      @falses ["false", "f"]
      @trues ["true", "t"]

  # ----------
  # comparison
  # ----------

  @doc """
  Compare locations for equality.

  Floating-point comparisons use the default epsilon value of 10E-6,
  which means the tolerance for degrees is about 10cm. 

  The poles at latitude +-90.0 are correctly matched for any valid longitude.
  """
  @spec equals?(G.location(), G.location()) :: bool()

  def equals?({{ 90, 0, 0.0, _}, {od1, om1, os1, ew1}}, {{ 90, 0, 0.0, _}, {od2, om2, os2, ew2}}) when 
      is_lon_dms(od1, om1, os1, ew1) and is_lon_dms(od2, om2, os2, ew2), do: true
  def equals?({{-90, 0, 0.0, _}, {od1, om1, os1, ew1}}, {{-90, 0, 0.0, _}, {od2, om2, os2, ew2}}) when 
      is_lon_dms(od1, om1, os1, ew1) and is_lon_dms(od2, om2, os2, ew2), do: true

  def equals?(
    {{ad1, am1, as1, ns1}, {od1, om1, os1, ew1}},
    {{ad2, am2, as2, ns2}, {od2, om2, os2, ew2}}) when 
      is_loc_dms(ad1, am1, as1, ns1, od1, om1, os1, ew1) and 
      is_loc_dms(ad2, am2, as2, ns2, od2, om2, os2, ew2) do
    ns1 == ns2 and ad1 == ad2 and am1 == am2 and Math.equals?(as1, as2) and
    ew1 == ew2 and od1 == od2 and om1 == om2 and Math.equals?(os1, os2) 
  end

  def equals?({{ 90, 0.0, _}, {od1, om1, ew1}}, {{ 90, 0.0, _}, {od2, om2, ew2}}) when 
      is_lon_dm(od1, om1, ew1) and is_lon_dm(od2, om2, ew2), do: true
  def equals?({{-90, 0.0, _}, {od1, om1, ew1}}, {{-90, 0.0, _}, {od2, om2, ew2}}) when 
      is_lon_dm(od1, om1, ew1) and is_lon_dm(od2, om2, ew2), do: true

  def equals?(
    {{ad1, am1, ns1}, {od1, om1, ew1}}, 
    {{ad2, am2, ns2}, {od2, om2, ew2}}) when 
      is_loc_dm(ad1, am1, ns1, od1, om1, ew1) and 
      is_loc_dm(ad2, am2, ns2, od2, om2, ew2) do
    ns1 == ns2 and ad1 == ad2 and Math.equals?(am1, am2) and
    ew1 == ew2 and od1 == od2 and Math.equals?(om1, om2) 
  end

  def equals?({{ 90.0, _}, {od1, ew1}}, {{ 90.0, _}, {od2, ew2}}) when 
      is_lon_d(od1, ew1) and is_lon_d(od2, ew2), do: true
  def equals?({{-90.0, _}, {od1, ew1}}, {{-90.0, _}, {od2, ew2}}) when 
      is_lon_d(od1, ew1) and is_lon_d(od2, ew2), do: true

  def equals?(
    {{ad1, ns1}, {od1, ew1}}, 
    {{ad2, ns2}, {od2, ew2}}) when 
      is_loc_d(ad1, ns1, od1, ew1) and 
      is_loc_d(ad2, ns2, od2, ew2) do
    ns1 == ns2 and Math.equals?(ad1, ad2) and 
    ew1 == ew2 and Math.equals?(od1, od2) 
  end

  def equals?({ 90.0, od1}, { 90.0, od2}) when is_lon_dd(od1) and is_lon_dd(od2), do: true
  def equals?({-90.0, od1}, {-90.0, od2}) when is_lon_dd(od1) and is_lon_dd(od2), do: true

  def equals?(
    {ad1, od1}, 
    {ad2, od2}) when 
      is_loc_dd(ad1, od1) and 
      is_loc_dd(ad2, od2) do
    Math.equals?(ad1, ad2) and 
    Math.equals?(od1, od2) 
  end

  def equals?(loc1, loc2), do: equals?( to_d(loc1), to_d(loc2) )
  
  # ------------
  # add/subtract
  # ------------

  @doc """
  Get the destination location after
  travelling along a great circle 
  on on initial bearing from a starting point.

  Note this is _not_ a line of constant bearing.

  The result is always decimal degrees.
  """
  @spec travel(G.location(), G.direction(), m :: E.pos_float()) :: G.location_dd()
  def travel(loc, cp, m) when is_compass(cp) do
    travel(loc, Bearing.bearing(cp), m)
  end
  def travel(loc, deg, m) when is_pos_float(m) do
    {lat1, lon1} = to_dd(loc)
    sinlat1 = Math.sind(lat1)
    coslat1 = Math.cosd(lon1)

    sinbear = Math.sind(deg)
    cosbear = Math.cosd(deg)

    distR = m / @mean_radius
    sindistR = :math.sin(distR)
    cosdistR = :math.cos(distR)

    lat2 = Math.asind( sinlat1*cosdistR + coslat1*sindistR*cosbear )
    dlon2 = Math.atand(
              sinbear*sindistR*coslat1,
              cosdistR - sinlat1*Math.sind(lat2)
            )

    add({lat2, lon1}, 0.0, dlon2)
  end

  @doc """
  Get the initial bearing from a starting location
  in the direction of a great circle path 
  to a destination point.
  """
  @spec heading(G.location(), G.location()) :: G.bearing()
  def heading(loc1, loc2) do
    {lat1, lon1} = to_dd(loc1)
    {lat2, lon2} = to_dd(loc2)
    sinlat1 = Math.sind(lat1)
    coslat1 = Math.cosd(lat1)
    sinlat2 = Math.sind(lat2)
    coslat2 = Math.cosd(lat2)
    dlon = lon2 - lon1

    y = coslat2 * Math.sind(dlon) 
    x = coslat1*sinlat2 - sinlat1*coslat2*Math.cosd(dlon)
    theta = Math.atand(y, x)
    Bearing.bearing(theta)
  end

  @doc """
  Add decimal degrees to a location.

  The result is always in decimal degrees.

  Longitude wraps to give values in the allowed range `-180.0 < lon <= 180.0`.

  Latitude folds to give values in the allowed range `-90.0 < lat < 90.0`.
  Latitudes that add to be in quadrants 1 or 2,
  then flip longitude by adding 180.0.
  """
  @spec add(G.location(), float(), float()) :: G.location_dd()

  def add(loc, 0.0, delta_lon) when is_float(delta_lon) do
    {lat, init_lon} = to_dd(loc)
    lon = 180.0 * Math.frac_sign((init_lon + delta_lon) / 180.0)
    to_dd({lat, lon})
  end

  def add(loc, delta_lat, delta_lon) when is_float(delta_lat) and is_float(delta_lon) do
    {init_lat, init_lon} = to_dd(loc)

    fac_lat = (init_lat + delta_lat) / 90.0
    lat = 90.0 * Math.frac_sign_mirror(fac_lat)

    quadrant = fac_lat |> trunc() |> rem(4) 
    flip = if quadrant in [1, 2, -1, -2], do: 180.0, else: 0.0

    fac_lon = (init_lon + delta_lon + flip) / 180.0
    lon = 180.0 * Math.frac_sign(fac_lon)

    to_dd({lat, lon})
  end

  # ---------
  # distances
  # ---------

  @doc """
  Find the approximate distance (m) 
  between two geo-locations.

  There are two algorithms available:

  ### Equirectangular

  The approximation uses Pythagoras's Theorem
  in the 2D plane tangent to the mid-point,
  the so-called _Equirectangular Projection._

  The points should be _close_ to each other.
  Errors will increase as the distance increases,
  especially separation in latitude.

  The distance will be the length of the line 
  lying _within_ the lat/lon coordinate bounds.
  This line will only be the shortest distance
  if the actual geodesic (great circle) path 
  does not cross the poles or the date-line meridian.

  Unit distance for longitude
  is the value at the equator 
  scaled by the cosine of latitude.

  Unit distance for latitude 
  uses a simple linear interpolation 
  between values at the equator and poles.
  For a true sphere it would be constant,
  but the Earth is actually an ellipsoid.
  The variation between equator and pole is about 1%.

  ### Haversine

  Perform exact spherical geometry.
  Errors arise because the Earth is not a perfect sphere, but an ellipsoid.
  """
  @spec distance(G.distance_algo(), G.location(), G.location()) :: G.metres()
  def distance(algo \\ :haversine, loc1, loc2)

  def distance(:equirect, loc1, loc2) do
    {lat1, lon1} = to_dd(loc1)
    {lat2, lon2} = to_dd(loc2)
    avlat = 0.5 * (lat1 + lat2)
    mlat = @lat1_eqtr + (@delta_pole * abs(avlat) / 90.0)
    mlon = @lon1_eqtr * Math.cosd(avlat)
    dlat = mlat * abs(lat2 - lat1)
    dlon = mlon * abs(lon2 - lon1)
    :math.sqrt(dlat*dlat + dlon*dlon)
  end

  def distance(:haversine, loc1, loc2) do
    {lat1, lon1} = to_dd(loc1)
    {lat2, lon2} = to_dd(loc2)
    coslat1 = Math.cosd(lat1)
    coslat2 = Math.cosd(lat2)
    sindlat = Math.sind(0.5 * (lat2 - lat1))
    sindlon = Math.sind(0.5 * (lon2 - lon1))
    a = sindlat*sindlat + coslat1*coslat2*sindlon*sindlon
    2.0 * @mean_radius * :math.atan2( :math.sqrt(a), :math.sqrt(1.0-a) )
  end

  # -----------
  # conversions
  # -----------

  @doc "Convert any location to decimal degree (DD) signed format."
  @spec to_dd(G.location()) :: G.location_dd() | {:error, any()}

  def to_dd({{ad, am, as, ns} = lat, {od, om, os, ew} = lon}) 
      when is_loc_dms(ad, am, as, ns, od, om, os, ew),
    do: {lat |> dec() |> dd(), lon |> dec() |> dd()}

  def to_dd({{ad, am, ns} = lat, {od, om, ew} = lon}) 
      when is_loc_dm(ad, am, ns, od, om, ew),
    do: {lat |> dec() |> dd(), lon |> dec() |> dd()}

  def to_dd({{ad, ns}=lat, {od, ew}=lon}) 
      when is_loc_d(ad, ns, od, ew), 
    do: {lat |> dd(), lon |> dd()}

  def to_dd({ad, od}=loc) 
      when is_loc_dd(ad, od), 
    do: loc

  def to_dd(loc), do: {:error, "Unrecognized location format '#{loc}'"}

  @doc "Convert any location to decimal degree (D) directional format."
  @spec to_d(G.location()) :: G.location_d() | {:error, any()}

  def to_d({{ad, am, as, ns} = lat, {od, om, os, ew} = lon}) 
      when is_loc_dms(ad, am, as, ns, od, om, os, ew),
    do: {dec(lat), dec(lon)}

  def to_d({{ad, am, ns} = lat, {od, om, ew} = lon}) 
      when is_loc_dm(ad, am, ns, od, om, ew),
    do: {dec(lat), dec(lon)}

  def to_d({{ad, ns}, {od, ew}} = loc) 
      when is_loc_d(ad, ns, od, ew), 
    do: loc

  def to_d({ad, od}) 
      when is_loc_dd(ad, od), 
    do: {ad |> latns(), od |> lonew()}

  def to_d(loc), do: {:error, "Unrecognized location format '#{loc}'"}

  @doc "Convert any location to degree and decimal minute (DM) directional format."
  @spec to_dm(G.location()) :: G.location_dm() | {:error, any()}

  def to_dm({{ad, am, as, ns}=lat, {od, om, os, ew}=lon}) 
      when is_loc_dms(ad, am, as, ns, od, om, os, ew),
    do: {dec(lat), dec(lon)}

  def to_dm({{ad, am, ns}, {od, om, ew}} = loc) 
      when is_loc_dm(ad, am, ns, od, om, ew), 
    do: loc

  def to_dm({{ad, ns}=lat, {od, ew}=lon}) 
      when is_loc_d(ad, ns, od, ew), 
    do: {dm(lat), dm(lon)}

  def to_dm({ad, od}) 
      when is_loc_dd(ad, od), 
    do: {ad |> latns() |> dm(), od |> lonew() |> dm()}

  def to_dm(loc), do: {:error, "Unrecognized location format '#{loc}'"}

  @doc "Convert any location to degree, minute and decimal second (DMS) directional format."
  @spec to_dms(G.location()) :: G.location_dms() | {:error, any()}

  def to_dms({{ad, am, as, ns}, {od, om, os, ew}}=loc) 
      when is_loc_dms(ad, am, as, ns, od, om, os, ew), 
    do: loc

  def to_dms({{ad, am, ns}=lat, {od, om, ew}=lon}) 
      when is_loc_dm(ad, am, ns, od, om, ew),
    do: {dms(lat), dms(lon)}

  def to_dms({{ad, ns}=lat, {od, ew}=lon}) 
      when is_loc_d(ad, ns, od, ew), 
    do: {dms(lat), dms(lon)}

  def to_dms({ad, od}) 
      when is_loc_dd(ad, od), 
    do: {ad |> latns() |> dms(), od |> lonew() |> dms()}

  def to_dms(loc), do: {:error, "Unrecognized location format '#{loc}'"}

  # private conversion utilities 
  # neutral between lat/lon, always copy through the nsew
  # use latns/lonew below, to create initial directional forms

  defp dms({id, m, nsew}), do: {id, trunc(m), 60.0 * Math.frac(m), nsew}
  defp dms({_,_}=d), do: d |> dm() |> dms()

  defp dm({d, nsew}), do: {trunc(d), 60.0 * Math.frac(d), nsew}

  defp dd({d,ne}) when ne in [:N,:E], do:  d
  defp dd({d,sw}) when sw in [:S,:W], do: -d

  defp dec({id, m, nsew}), do: {id + m / 60.0, nsew}
  defp dec({id, im, s, nsew}), do: dec({id, im + s / 60.0, nsew})

  # ----------
  # formatting
  # ----------

  @doc """
  Format any location as a string.
  The format will correspond to the type of the input.

  The arguments are:
  - set of precisions for DMS float values, default `{5, 3, 1}`
    giving accuracy of 1-3m
  - flag for coordinate separator: `:comma` or `:nsew`
    so either `lat, lon` or `lat N/S lon E/W`
  - set of delimiters for DMS components,
    default is ASCII `{"°", "'", "\""}}`,
    but Unicode values are also available 
  """
  @spec format(G.location(), G.prec_dms(), G.sep_nsew(), G.sep_dms()) :: String.t() | {:error, any()}
  def format(loc, prec \\ @prec_dms, sep_nsew \\ :nsew, sep_dms \\ @sym_ascii)

  # format dms

  def format({{ad, am, as, ns}, {od, om, os, ew}}, {_, _, sp}, :comma, nil)
      when is_loc_dms(ad, am, as, ns, od, om, os, ew) do
    isgn(ad,ns) <> " " <> pos(am) <> " " <> pos(as, sp) <> ", " <>
    isgn(od,ew) <> " " <> pos(om) <> " " <> pos(os, sp)
  end

  def format({{ad, am, as, ns}, {od, om, os, ew}}, {_, _, sp}, :nsew, nil)
      when is_loc_dms(ad, am, as, ns, od, om, os, ew) do
    pos(ad) <> " " <> pos(am) <> " " <> pos(as, sp) <> " " <> nsew(ns) <> " " <> 
    pos(od) <> " " <> pos(om) <> " " <> pos(os, sp) <> " " <> nsew(ew)
  end

  def format({{ad, am, as, ns}, {od, om, os, ew}}, {_, _, sp}, :comma, {deg, min, sec})
      when is_loc_dms(ad, am, as, ns, od, om, os, ew) do
    isgn(ad,ns) <> deg <> pos(am) <> min <> pos(as, sp) <> sec <> ", " <> 
    isgn(od,ew) <> deg <> pos(om) <> min <> pos(os, sp) <> sec
  end

  def format({{ad, am, as, ns}, {od, om, os, ew}}, {_, _, sp}, :nsew, {deg, min, sec})
      when is_loc_dms(ad, am, as, ns, od, om, os, ew) do
    pos(ad) <> deg <> pos(am) <> min <> pos(as, sp) <> sec <> " " <> nsew(ns) <> " " <>
    pos(od) <> deg <> pos(om) <> min <> pos(os, sp) <> sec <> " " <> nsew(ew)
  end

  # format dm

  def format({{ad, am, ns}, {od, om, ew}}, {_, mp, _}, :comma, nil) 
      when is_loc_dm(ad, am, ns, od, om, ew) do
    isgn(ad,ns) <> " " <> pos(am, mp) <> ", " <> 
    isgn(od,ew) <> " " <> pos(om, mp)
  end

  def format({{ad, am, ns}, {od, om, ew}}, {_, mp, _}, :nsew, nil) 
      when is_loc_dm(ad, am, ns, od, om, ew) do
    pos(ad) <> " " <> pos(am, mp) <> " " <> nsew(ns) <> " " <>
    pos(od) <> " " <> pos(om, mp) <> " " <> nsew(ew)
  end

  def format({{ad, am, ns}, {od, om, ew}}, {_, mp, _}, :comma, {deg, min, _})
      when is_loc_dm(ad, am, ns, od, om, ew) do
    isgn(ad,ns) <> deg <> pos(am, mp) <> min <> ", " <> 
    isgn(od,ew) <> deg <> pos(om, mp) <> min
  end

  def format({{ad, am, ns}, {od, om, ew}}, {_, mp, _}, :nsew, {deg, min, _})
      when is_loc_dm(ad, am, ns, od, om, ew) do
    pos(ad) <> deg <> pos(am, mp) <> min <> " " <> nsew(ns) <> " " <> 
    pos(od) <> deg <> pos(om, mp) <> min <> " " <> nsew(ew)
  end

  # format d

  def format({{ad, ns}, {od, ew}}, {dp, _, _}, :comma, nil) 
      when is_loc_d(ad, ns, od, ew) do
    sgn(ad, ns, dp) <> ", " <> 
    sgn(od, ew, dp)
  end

  def format({{ad, ns}, {od, ew}}, {dp, _, _}, :nsew, nil)
      when is_loc_d(ad, ns, od, ew) do
    pos(ad, dp) <> " " <> nsew(ns) <> " " <> 
    pos(od, dp) <> " " <> nsew(ew)
  end

  def format({{ad, ns}, {od, ew}}, {dp, _, _}, :comma, {deg, _, _}) 
      when is_loc_d(ad, ns, od, ew) do
    sgn(ad, ns, dp) <> deg <> ", " <> 
    sgn(od, ew, dp) <> deg
  end

  def format({{ad, ns}, {od, ew}}, {dp, _, _}, :nsew, {deg, _, _}) 
      when is_loc_d(ad, ns, od, ew) do
    pos(ad, dp) <> deg <> " " <> nsew(ns) <> " " <> 
    pos(od, dp) <> deg <> " " <> nsew(ew)
  end

  # format dd - note nsew unsupported

  def format({ad, od}, {dp, _, _}, _, nil) 
      when is_loc_dd(ad, od) do
    sgn(ad, dp) <> ", " <> 
    sgn(od, dp)
  end

  def format({ad, od}, {dp, _, _}, _, {deg, _, _}) 
      when is_loc_dd(ad, od) do
    sgn(ad, dp) <> deg <> ", " <> 
    sgn(od, dp) <> deg
  end

  def format(loc, _, _, _) do
    {:error, "Unrecognized location format '#{loc}'"}
  end

  # format utils

  defp isgn(coord, :N), do:  coord |> Integer.to_string()
  defp isgn(coord, :E), do:  coord |> Integer.to_string()
  defp isgn(coord, :S), do: -coord |> Integer.to_string()
  defp isgn(coord, :W), do: -coord |> Integer.to_string()

  defp sgn(coord, dp), do: (1.0 * coord) |> Float.round(dp) |> Float.to_string()

  defp sgn(coord, :N, dp), do: ( 1.0 * coord) |> Float.round(dp) |> Float.to_string()
  defp sgn(coord, :E, dp), do: ( 1.0 * coord) |> Float.round(dp) |> Float.to_string()
  defp sgn(coord, :S, dp), do: (-1.0 * coord) |> Float.round(dp) |> Float.to_string()
  defp sgn(coord, :W, dp), do: (-1.0 * coord) |> Float.round(dp) |> Float.to_string()

  defp pos(coord), do: coord |> Integer.to_string()

  defp pos(coord, dp), do: (1.0 * coord) |> Float.round(dp) |> Float.to_string()

  defp nsew(:N), do: "N"
  defp nsew(:S), do: "S"
  defp nsew(:E), do: "E"
  defp nsew(:W), do: "W"

  # -----------
  # URL formats
  # -----------

  @type google_zoom() :: 1..20
  defguard is_google_zoom(z) when is_in_range(1,z,20)

  @base_google_uri "//www.google.com/maps/place/"

  @doc """
  Convert a location to a Google Maps URL with zoom level.

  Enabling `https?` may require that you explicitly install `erlang-ssl`
  on your platform, as it is not always included in distributions.

  ## Examples
      iex> to_google({{54,28,0.0,:N}, {56,16,0.0,:E}}, 15)
      "http://www.google.com/maps/place/" <> 
      "54%C2%B028'0.0%22%20N%2056%C2%B016'0.0%22%20E/" <>
      "@54.4666667%C2%B0,%2056.2666667%C2%B0,15z"
  """

  def to_google(loc, zoom \\ 10, https? \\ false) when is_google_zoom(zoom) do
    dd = loc |> to_dd() |> format({7,3,1})
    dms = loc |> to_dms() |> format()
    scheme(https?) <> @base_google_uri <> URI.encode("#{dms}/@#{dd},#{zoom}z")
  end

  defp scheme(false), do: "http:"
  defp scheme(true),  do: "https:"

  # ---------------
  # guessing parser
  # ---------------

  @doc """
  Return a composed parser that tries several 
  parsers to find the scalar data type.

  Tries null, bool, int, float, date, time, datetime, naive_datetime
  and lat/lon location.

  Note hex integers are not included, 
  because there is ambiguity with base-10 integers.
  """
  @spec p_guess([String.t()], [String.t()], [String.t()], Calendar.calendar()) :: P.parfun(any())
  def p_guess(nulls \\ @nulls, trues \\ @trues, falses \\ @falses, cal \\ Calendar.ISO) do
    Parse.compose([Parse.p_guess(nulls, trues, falses, cal), &parse/1])
  end

  # -----
  # parse
  # -----

  @typep token() :: integer() | float() | G.nsew() | :deg | :min | :sec | :com
  @typep tokens() :: [token()]

  @doc """
  Parse a geo-location.
  Do not raise on error.

  Function signature is compatible with `Exa.Parse.parfun()`.

  If the input cannot be parsed, the original string is returned.

  A `nil` argument is passed through as a `nil` result.
  """
  @spec parse(nil | String.t()) :: nil | String | G.location()
  def parse(nil), do: nil
  def parse(str) when is_string(str) do
    case do_parse(str) do
      {:error, _msg} -> str
      latlon         -> latlon
    end
  end

  @doc "Parse a geo-location. Raise on error."
  @spec parse!(String.t()) :: G.location()
  def parse!(str) when is_string(str) do
    case do_parse(str) do
      {:error, msg} -> Logger.error(msg)
                       raise ArgumentError, message: msg
      latlon        -> latlon
    end
  end

  @spec do_parse(String.t()) :: G.location() | {:error, any()}
  defp do_parse(str) when is_string(str) do
    with toks             when not is_err(toks) <- lex(str,[]),
         {toks, lat}=part when not is_err(part) <- lat(toks),
         lon              when not is_err(lon)  <- lon(toks) do
      {lat, lon}
    end
  end

  @spec lat(tokens()) :: {tokens(), G.latitude()} | {:error, any()}
  
  defp lat([ f,                        :com|ts]) when is_lat_dec_deg(f),    do: {ts, f} 
  defp lat([ f,:deg,                   :com|ts]) when is_lat_dec_deg(f),    do: {ts, f}
  defp lat([ f,     ns,                :com|ts]) when is_lat_d(f,ns),       do: {ts, {f,ns}}
  defp lat([ f,:deg,ns,                :com|ts]) when is_lat_d(f,ns),       do: {ts, {f,ns}}
  defp lat([di,     mf,                :com|ts]) when is_lat_dm(di,mf),     do: {ts, latns(di,mf)} 
  defp lat([di,:deg,mf,:min,           :com|ts]) when is_lat_dm(di,mf),     do: {ts, latns(di,mf)} 
  defp lat([di,     mf,     ns,        :com|ts]) when is_lat_dm(di,mf,ns),  do: {ts, {di,mf,ns}}
  defp lat([di,:deg,mf,:min,ns,        :com|ts]) when is_lat_dm(di,mf,ns),  do: {ts, {di,mf,ns}}
  defp lat([di,     mi,     sf,        :com|ts]) when is_lat_dms(di,mi,sf), do: {ts, latns(di,mi,sf)}
  defp lat([di,:deg,mi,:min,sf,:sec,   :com|ts]) when is_lat_dms(di,mi,sf), do: {ts, latns(di,mi,sf)}
  defp lat([di,     mi,     sf,     ns,:com|ts]) when is_lat_dms(di,mi,sf,ns), do: {ts, {di,mi,sf,ns}}
  defp lat([di,:deg,mi,:min,sf,:sec,ns,:com|ts]) when is_lat_dms(di,mi,sf,ns), do: {ts, {di,mi,sf,ns}}
  
  defp lat(toks) do
    msg = "Illegal latitude tokens '#{inspect(toks)}'"
    Logger.warning(msg)
    {:error, msg}
  end

  @spec lon(tokens()) :: G.longitude() | {:error, any()}
  
  defp lon([ f        ]                ) when is_lon_dec_deg(f),       do: f 
  defp lon([ f,:deg   ]                ) when is_lon_dec_deg(f),       do: f 
  defp lon([ f,     ew]                ) when is_lon_d(f,ew),          do: {f,ew}
  defp lon([ f,:deg,ew]                ) when is_lon_d(f,ew),          do: {f,ew}
  defp lon([di,     mf        ]        ) when is_lon_dm(di,mf),        do: lonew(di,mf)
  defp lon([di,:deg,mf,:min   ]        ) when is_lon_dm(di,mf),        do: lonew(di,mf)
  defp lon([di,     mf,     ew]        ) when is_lon_dm(di,mf,ew),     do: {di,mf,ew}
  defp lon([di,:deg,mf,:min,ew]        ) when is_lon_dm(di,mf,ew),     do: {di,mf,ew}
  defp lon([di,     mi,     sf]        ) when is_lon_dms(di,mi,sf),    do: lonew(di,mi,sf) 
  defp lon([di,:deg,mi,:min,sf,:sec   ]) when is_lon_dms(di,mi,sf),    do: lonew(di,mi,sf)
  defp lon([di,     mi,     sf,     ew]) when is_lon_dms(di,mi,sf,ew), do: {di,mi,sf,ew}
  defp lon([di,:deg,mi,:min,sf,:sec,ew]) when is_lon_dms(di,mi,sf,ew), do: {di,mi,sf,ew}

  defp lon(toks) do
    msg = "Illegal longitude tokens '#{inspect(toks)}'"
    Logger.warning(msg)
    {:error, msg}
  end

  @spec latns(G.lat_dec_deg()) :: G.lat_d()
  defp latns(f) when f >= 0.0, do: {f,:N}
  defp latns(f), do: {-f,:S}

  @spec latns({G.lat_int_deg(),G.pos_min()}) :: G.lat_dm()
  defp latns(di,mf) when di >= 0, do: {di,mf,:N}
  defp latns(di,mf), do: {-di,mf,:S}

  @spec latns({G.lat_int_deg(),G.nat_min(),G.pos_sec()}) :: G.lat_dms()
  defp latns(di,mi,sf) when di >= 0, do: {di,mi,sf,:N}
  defp latns(di,mi,sf), do: {-di,mi,sf,:S}

  @spec lonew(G.lat_dec_deg()) :: G.lon_d()
  defp lonew(f) when f >= 0.0, do: {f,:E}
  defp lonew(f), do: {-f,:W}

  @spec lonew(G.lon_nat_deg(),G.pos_min()) :: G.lon_dm()
  defp lonew(di,mf) when di >= 0, do: {di,mf,:E}
  defp lonew(di,mf), do: {-di,mf,:W}

  @spec lonew({G.lon_nat_deg(),G.nat_min(),G.pos_sec()}) :: G.lon_dms()
  defp lonew(di,mi,sf) when di >= 0, do: {di,mi,sf,:E}
  defp lonew(di,mi,sf), do: {-di,mi,sf,:W}

  # lexer
  # always force :com as a delimiter between lat-lon 
  # allow extra comma delimiter after N/S
  # accept male ordinal symbol as mistake for degree sign
  # MS Word often auto-converts quotes to the fancy 66-99 form so:
  # accept fancy single quote for minutes
  # accept fancy '99' double quote for seconds 

  @spec lex(String.t(), tokens()) :: tokens() | {:error, any()}
  
  defp lex(<<c,   b::binary>>, ts) when is_ws(c),           do: lex(b, ts)
  defp lex(<<c, _::binary>>=b, ts) when is_numstart(c),     do: num(b, <<>>, false, ts)
  defp lex(<<c::utf8, b::binary>>, ts) when c in @deg_syms, do: lex(b, [:deg|ts])
  defp lex(<<c::utf8, b::binary>>, ts) when c in @min_syms, do: lex(b, [:min|ts])
  defp lex(<<c::utf8, b::binary>>, ts) when c in @sec_syms, do: lex(b, [:sec|ts])
  defp lex(<<?N, ?,,  b::binary>>, ts),                     do: lex(b, [:com,:N|ts])
  defp lex(<<?S, ?,,  b::binary>>, ts),                     do: lex(b, [:com,:S|ts])
  defp lex(<<?N,      b::binary>>, ts),                     do: lex(b, [:com,:N|ts])
  defp lex(<<?S,      b::binary>>, ts),                     do: lex(b, [:com,:S|ts])
  defp lex(<<?E,      b::binary>>, ts),                     do: lex(b, [:E|ts])
  defp lex(<<?W,      b::binary>>, ts),                     do: lex(b, [:W|ts])
  defp lex(<<?,,      b::binary>>, ts),                     do: lex(b, [:com|ts])
  defp lex(<<>>,                   ts),                     do: Enum.reverse(ts)
  
  defp lex(<<c::utf8,    _::binary>>, _ ) do
    msg = "Illegal char \\u#{Exa.String.int_hex(c)} '#{<<c::utf8>>}'"
    Logger.warning(msg)
    {:error, msg}
  end

  @spec num(String.t(), String.t(), bool(), tokens()) :: tokens()
  defp num(<<?., b::binary>>, n, false, ts),             do: num(b,<<n::binary,?.>>,true,ts)
  defp num(<<c,b::binary>>,n,isf,ts) when is_numchar(c), do: num(b,<<n::binary, c>>, isf,ts)
  defp num(b, n, false, ts), do: lex(b, [String.to_integer(n)|ts])
  defp num(b, n,  true, ts), do: lex(b, [String.to_float(n)  |ts])
end

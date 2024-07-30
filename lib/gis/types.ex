defmodule Exa.Gis.Types do
  @moduledoc """
  Types for GIS data.

  Latitude -90 (S) +90 (N) degrees

  Longitude -180 (W) +180 (E) degrees

  Note that we not allow longitude -180 (int) or -180.0 (float).
  The bounds are enforced as (-180,+180] for int, and (-180.0,180.0] for float.

  Technically the longitude is undefined at latitudes +- 90.
  Any valid longitude may be provided, but 0 is preferred.
  """
  import Exa.Types
  alias Exa.Types, as: E

  # ---------------------------
  # compass points and bearings
  # ---------------------------

  @points4 [:N, :E, :S, :W]
  @points8 @points4 ++ [:NE, :SE, :SW, :NW]
  @points16 @points8 ++ [:NNE, :ENE, :ESE, :SSE, :SSW, :WSW, :WNW, :NNW]

  @type compass_point() ::
          :N
          | :NNE
          | :NE
          | :ENE
          | :E
          | :ESE
          | :SE
          | :SSE
          | :S
          | :SSW
          | :SW
          | :WSW
          | :W
          | :WNW
          | :NW
          | :NNW

  defguard is_compass(cp) when cp in @points16

  @type bearing() :: E.degrees()
  defguard is_bearing(d) when is_float(d) and 0.0 <= d and d < 360.0

  @type direction() :: compass_point() | bearing()
  defguard is_direction(b) when is_compass(b) or is_bearing(b)

  # -----------------------------
  # distance and projection algos
  # -----------------------------

  # *** temporary - until we have UOM working ***
  @type metres() :: float()

  @type distance_algo() :: :equirect | :haversine
  defguard is_dist_algo(a) when is_atom(a) and a in [:equirect, :haversine]

  @type projection_algo() :: :equirect
  defguard is_proj_algo(p) when is_atom(p) and p in [:equirect]

  # -----------------
  # string formatting
  # -----------------

  @typedoc """
  The separator used for latitude and longitude:
  a single comma, or N/S after latitude and E/W after longitude.
  """
  @type sep_nsew() :: :comma | :nsew

  @typedoc "The separator characters used for degrees, minutes and seconds."
  @type sep_dms() :: nil | {String.t(), String.t(), String.t()}

  @typedoc """
  Decimal precision to be used for degrees, minutes and seconds,
  when they are the final floating-point component of a location.
  """
  @type prec_dms() :: {pos_integer(), pos_integer(), pos_integer()}

  # --------------
  # lat/long types
  # --------------

  @type ns() :: :N | :S
  @type ew() :: :W | :E
  @type nsew() :: ns() | ew()

  defguard is_ns(ns) when ns in [:N, :S]
  defguard is_ew(ew) when ew in [:W, :E]
  defguard is_nsew(nsew) when nsew in @points4

  @type lat_int_deg() :: -90..90
  @type lon_int_deg() :: -179..180

  @type lat_nat_deg() :: 0..90
  @type lon_nat_deg() :: 0..180

  defguard is_lat_int_deg(ad) when is_in_range(-90, ad, 90)
  defguard is_lon_int_deg(od) when is_in_range(-179, od, 180)

  defguard is_lat_nat_deg(ad) when is_in_range(0, ad, 90)
  defguard is_lon_nat_deg(od) when is_in_range(0, od, 180)

  @type nat_min() :: 0..59
  @type nat_sec() :: 0..59

  defguard is_nat_min(m) when is_in_range(0, m, 59)
  defguard is_nat_sec(s) when is_in_range(0, s, 59)

  @type lat_dec_deg() :: float()
  @type lon_dec_deg() :: float()

  @type lat_pos_deg() :: float()
  @type lon_pos_deg() :: float()

  @type pos_min() :: float()
  @type pos_sec() :: float()

  defguard is_lat_dec_deg(ad) when is_float(ad) and -90.0 <= ad and ad <= 90.0
  defguard is_lon_dec_deg(od) when is_float(od) and -180.0 < od and od <= 180.0

  defguard is_lat_pos_deg(ad) when is_float(ad) and 0.0 <= ad and ad <= 90.0
  defguard is_lon_pos_deg(od) when is_float(od) and 0.0 <= od and od <= 180.0

  defguard is_pos_min(m) when is_number(m) and 0.0 <= m and m < 60.0
  defguard is_pos_sec(m) when is_number(m) and 0.0 <= m and m < 60.0

  # signed decimal degrees, no direction

  @type lat_dd() :: lat_dec_deg()
  @type lon_dd() :: lon_dec_deg()

  defguard is_lat_dd(ad) when is_lat_dec_deg(ad)
  defguard is_lon_dd(od) when is_lon_dec_deg(od)

  @type location_dd() :: {lat_dd(), lon_dd()}

  defguard is_loc_dd(ad, od) when is_lat_dd(ad) and is_lon_dd(od)

  # nonneg integer degrees and direction

  @type lat_d() :: {lat_pos_deg(), ns()}
  @type lon_d() :: {lon_pos_deg(), ew()}

  defguard is_lat_d(ad, ns) when is_lat_pos_deg(ad) and is_ns(ns)
  defguard is_lon_d(od, ew) when is_lon_pos_deg(od) and is_ew(ew)

  @type location_d() :: {lat_d(), lon_d()}

  defguard is_loc_d(ad, ns, od, ew) when is_lat_d(ad, ns) and is_lon_d(od, ew)

  # nonneg integer degrees, nonneg decimal minutes and direction

  @type lat_dm() :: {lat_nat_deg(), pos_min(), ns()}
  @type lon_dm() :: {lon_nat_deg(), pos_min(), ew()}

  @type location_dm() :: {lat_dm(), lon_dm()}

  defguard is_lat_dm(d, m) when is_lat_int_deg(d) and is_pos_min(m)
  defguard is_lon_dm(d, m) when is_lon_int_deg(d) and is_pos_min(m)

  defguard is_lat_dm(d, m, ns) when is_lat_nat_deg(d) and is_pos_min(m) and is_ns(ns)
  defguard is_lon_dm(d, m, ew) when is_lon_nat_deg(d) and is_pos_min(m) and is_ew(ew)

  defguard is_loc_dm(lad, lam, ns, lod, lom, ew)
           when is_lat_dm(lad, lam, ns) and
                  is_lon_dm(lod, lom, ew)

  # nonneg integer degrees, nonneg integer minutes, nonneg decimal seconds and direction

  @type lat_dms() :: {lat_nat_deg(), nat_min(), pos_sec(), ns()}
  @type lon_dms() :: {lon_nat_deg(), nat_min(), pos_sec(), ew()}

  @type location_dms() :: {lat_dms(), lon_dms()}

  defguard is_lat_dms(d, m, s)
           when is_lat_int_deg(d) and is_nat_min(m) and is_pos_sec(s)

  defguard is_lon_dms(d, m, s)
           when is_lon_int_deg(d) and is_nat_min(m) and is_pos_sec(s)

  defguard is_lat_dms(d, m, s, ns)
           when is_lat_nat_deg(d) and is_nat_min(m) and is_pos_sec(s) and is_ns(ns)

  defguard is_lon_dms(d, m, s, ew)
           when is_lon_nat_deg(d) and is_nat_min(m) and is_pos_sec(s) and is_ew(ew)

  defguard is_loc_dms(ad, am, as, ns, od, om, os, ew)
           when is_lat_dms(ad, am, as, ns) and
                  is_lon_dms(od, om, os, ew)

  # generic geo-location 

  @type latitude() :: lat_dd() | lat_d() | lat_dm() | lat_dms()
  @type longitude() :: lat_dd() | lon_d() | lon_dm() | lon_dms()

  @type location() :: location_dd() | location_d() | location_dm() | location_dms()
  defguard is_loc(loc) when is_tuple(loc) and tuple_size(loc) == 2

  @type locations() :: [location(), ...]
  defguard is_locs(locs) when is_list(locs) and length(locs) > 1 and is_loc(hd(locs))

  # geo line between two locations
  # endpoints are represented in decimal degrees
  # a geodesic is the polyline representing the 
  # shortest great cicle path between two points

  @type geoline() :: {:geoline, location_dd(), location_dd()}
  defguard is_geoline(g) when is_tag_tuple(g, 3, :geoline)

  @type geodesic() :: {:geodesic, [location_dd()]}
  defguard is_geodesic(g) when is_tag_tuple(g, 2, :geodesic)
end

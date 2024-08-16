defmodule Exa.Gis.GeoJson.Types do
  @moduledoc """
  Types for GeoJSON format.

  All coordinates are in decimal degrees.
  Locations are lon/lat order, to match Cartesian (x,y).

  Note that GIS types use tagged tuples,
  but GeoJSON uses structs. 

  There is some overlap with the base GIS types,
  but GeoJSON has a consistent 
  standalone set of types with clear semantics.
  """

  alias Exa.Space.Types, as: S

  # -------------------
  # GEO JSON primitives
  # -------------------

  # coordinates

  # NOTE *** these are [longitude, latitude] to match projected (x,y) ***
  @type coord() :: [float()]
  @type coords() :: [coord()]
  @type coordss() :: [coords()]
  @type coordsss() :: [coordss()]

  # point

  defmodule GeoPoint do
    alias Exa.Gis.GeoJson.Types, as: GJ

    @enforce_keys [:coordinates]
    defstruct [:coordinates, :bbox, type: "Point"]

    @type t() :: %__MODULE__{
            type: String.t(),
            bbox: S.bbox2f(),
            coordinates: GJ.coord()
          }
  end

  defguard is_geopoint(p)
           when is_struct(p, GeoPoint) and
                  p.type == "Point" and length(p.coordinates) == 2

  # line string 

  defmodule GeoLineString do
    alias Exa.Gis.GeoJson.Types, as: GJ

    @enforce_keys [:coordinates]
    defstruct [:coordinates, :bbox, type: "LineString"]

    @type t() :: %__MODULE__{
            type: String.t(),
            bbox: S.bbox2f(),
            coordinates: GJ.coords()
          }
  end

  defguard is_geolinestring(ls)
           when is_struct(ls, GeoLineString) and
                  ls.type == "LineString" and length(ls.coordinates) >= 2

  # polygon

  defmodule GeoPolygon do
    alias Exa.Gis.GeoJson.Types, as: GJ

    @enforce_keys [:coordinates]
    defstruct [:coordinates, :bbox, type: "Polygon"]

    @type t() :: %__MODULE__{
            type: String.t(),
            bbox: S.bbox2f(),
            coordinates: GJ.coordss()
          }
  end

  defguard is_geopolygon(mp)
           when is_struct(mp, GeoMultiPoint) and
                  mp.type == "MultiPoint" and length(mp.coordinates) >= 1 and
                  length(hd(mp.coordinates)) >= 1

  # multi point 

  defmodule GeoMultiPoint do
    alias Exa.Gis.GeoJson.Types, as: GJ

    @enforce_keys [:coordinates]
    defstruct [:coordinates, :bbox, type: "MultiPoint"]

    @type t() :: %__MODULE__{
            type: String.t(),
            bbox: S.bbox2f(),
            coordinates: GJ.coords()
          }
  end

  defguard is_geomultipoint(mp)
           when is_struct(mp, GeoMultiPoint) and
                  mp.type == "MultiPoint" and length(mp.coordinates) >= 1 and
                  length(hd(mp.coordinates)) >= 1

  # multi line string

  defmodule GeoMultiLineString do
    alias Exa.Gis.GeoJson.Types, as: GJ

    @enforce_keys [:coordinates]
    defstruct [:coordinates, :bbox, type: "MultiLineString"]

    @type t() :: %__MODULE__{
            type: String.t(),
            bbox: S.bbox2f(),
            coordinates: GJ.coordss()
          }
  end

  defguard is_geomultilinestring(mls)
           when is_struct(mls, GeoMultiLineString) and
                  mls.type == "MultiLineString" and length(mls.coordinates) >= 1 and
                  length(hd(mls.coordinates)) >= 2

  # multi polygon

  defmodule GeoMultiPolygon do
    alias Exa.Gis.GeoJson.Types, as: GJ

    @enforce_keys [:coordinates]
    defstruct [:coordinates, :bbox, type: "MultiPolygon"]

    @type t() :: %__MODULE__{
            type: String.t(),
            bbox: S.bbox2f(),
            coordinates: GJ.coordsss()
          }
  end

  defguard is_geomultipolygon(mp)
           when is_struct(mp, GeoMultiPolygon) and
                  mp.type == "MultiPolygon" and length(mp.coordinates) >= 1 and
                  length(hd(mp.coordinates)) >= 1

  # geometry 

  @type geometry() ::
          %GeoPoint{}
          | %GeoLineString{}
          | %GeoPolygon{}
          | %GeoMultiPoint{}
          | %GeoMultiLineString{}
          | %GeoMultiPolygon{}

  # geometry collection 

  defmodule GeoGeometryCollection do
    alias Exa.Gis.GeoJson.Types, as: GJ

    @enforce_keys [:geometries]
    defstruct [:geometries, :bbox, type: "GeometryCollection"]

    @type t() :: %__MODULE__{
            type: String.t(),
            bbox: S.bbox2f(),
            geometries: [GJ.geometry()]
          }
  end

  defguard is_geometrycollection(mp)
           when is_struct(mp, GeoGeometryCollection) and
                  mp.type == "GeometryCollection" and length(mp.geometries) >= 1

  @type geogeometrycollection() :: %GeoGeometryCollection{}

  # feature 

  defmodule GeoFeature do
    alias Exa.Gis.GeoJson.Types, as: GJ

    @enforce_keys [:geometry]
    defstruct [:geometry, :bbox, properties: [], type: "Feature"]

    @type t() :: %__MODULE__{
            type: String.t(),
            bbox: S.bbox2f(),
            properties: map(),
            geometry: GJ.geometry()
          }
  end

  @type geofeature() :: %GeoFeature{}

  defguard is_geofeature(f) when is_struct(f, GeoFeature) and f.type == "Feature" >= 1

  # feature collection

  defmodule GeoFeatureCollection do
        alias Exa.Gis.GeoJson.Types, as: GJ

    @enforce_keys [:features]
    defstruct [:features, :bbox, properties: [], type: "FeatureCollection"]

    @type t() :: %__MODULE__{
            type: String.t(),
            bbox: S.bbox2f(),
            properties: map(),
            features: [GJ.geofeature()]
          }
  end

  @type geofeaturecollection() :: %GeoFeatureCollection{}

  defguard is_featurecollection(fc)
           when is_struct(fc, GeoFeatureCollection) and
                  fc.type == "FeatureCollection" and length(fc.features) >= 1

  # geojson

  @type geojson() :: geometry() | geogeometrycollection() | geofeature() | geofeaturecollection()
end

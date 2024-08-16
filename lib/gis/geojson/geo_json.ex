defmodule Exa.Gis.GeoJson.GeoJson do
  @moduledoc """
  An interface for GeoJSON utilities.
  """
  require Logger
  
  import Exa.Types
  alias Exa.Types, as: E

  alias Exa.Json.Types, as: J
  alias Exa.Json.JsonReader

  alias Exa.Gis.GeoJson.Types, as: GJ

  alias Exa.Space.BBox2f

  @doc "Read a GeoJSON file."
  @spec from_file(String.t(), E.options()) :: J.value()
  def from_file(filename, options \\ []) when is_string(filename) do
    # could/should be a way to retain and cascade parsers here....
    options = Keyword.put(options, :object, &geo_factory/1)
    JsonReader.from_json(filename, options)
  end

  @doc """
  The factory function for GeoJSON in the JSON parser.

  Take a Keyword list of {key,value} pairs,
  match the `type` field and return the GeoJSON object.

  If there is no type field, 
  or the type field has an unrecognized value (e.g. TopoJSON),
  then return a map as a default.

  """
  @spec geo_factory(Keyword.t()) :: {:struct, GJ.geojson()} | {:map, map()}
  def geo_factory(kw) when is_keyword(kw) do
    case Keyword.get(kw, :type, :error) do
      :error ->
        {:map, Map.new(kw)}

      "Point" ->
        %GJ.GeoPoint{
          bbox: to_bbox(Keyword.get(kw, :bbox)),
          coordinates: Keyword.fetch!(kw, :coordinates)
        }

      "LineString" ->
        %GJ.GeoLineString{
          bbox: to_bbox(Keyword.get(kw, :bbox)),
          coordinates: Keyword.fetch!(kw, :coordinates)
        }

      "Polygon" ->
        %GJ.GeoPolygon{
          bbox: to_bbox(Keyword.get(kw, :bbox)),
          coordinates: Keyword.fetch!(kw, :coordinates)
        }

      "MultiPoint" ->
        %GJ.GeoMultiPoint{
          bbox: to_bbox(Keyword.get(kw, :bbox)),
          coordinates: Keyword.fetch!(kw, :coordinates)
        }

      "MultiLineString" ->
        %GJ.GeoMultiLineString{
          bbox: to_bbox(Keyword.get(kw, :bbox)),
          coordinates: Keyword.fetch!(kw, :coordinates)
        }

      "MultiPolygon" ->
        %GJ.GeoMultiPolygon{
          bbox: to_bbox(Keyword.get(kw, :bbox)),
          coordinates: Keyword.fetch!(kw, :coordinates)
        }

      "GeometryCollection" ->
        %GJ.GeoGeometryCollection{
          bbox: to_bbox(Keyword.get(kw, :bbox)),
          geometries: Keyword.fetch!(kw, :geometries)
        }

      "Feature" ->
        %GJ.GeoFeature{
          bbox: to_bbox(Keyword.get(kw, :bbox, nil)),
          properties: Keyword.get(kw, :properties, []),
          geometry: Keyword.fetch!(kw, :geometry)
        }

      "FeatureCollection" ->
        %GJ.GeoFeatureCollection{
          bbox: to_bbox(Keyword.get(kw, :bbox, nil)),
          properties: Keyword.get(kw, :properties, []),
          features: Keyword.fetch!(kw, :features)
        }

      type ->
        msg = "Unrecognized GeoJSON type '#{inspect(type)}'"
        Logger.warning(msg)
        {:map, Map.new(kw)} 
    end
  end

  defp to_bbox(nil), do: nil
  defp to_bbox([x1, y1, x2, y2]), do: BBox2f.new(x1, y1, x2, y2)
end

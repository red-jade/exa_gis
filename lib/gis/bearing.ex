defmodule Exa.Gis.Bearing do
  @moduledoc """
  Utilities for geographical directions, 
  compass points and bearings from North.

  A valid bearing is in the range `[0.0, 360.0)`.
  """
  use Exa.Constants
  use Exa.Gis.Constants

  alias Exa.Types, as: E

  import Exa.Gis.Types
  alias Exa.Gis.Types, as: G

  alias Exa.Math

  @doc """
  Compare bearings for equality.
  """
  @spec equals?(G.direction(), G.direction(), E.epsilon()) :: bool()
  def equals?(b1, b2, eps \\ @epsilon)
  def equals?(b1, b2, _eps) when is_compass(b1) and is_compass(b2), do: b1 == b2
  def equals?(b1, b2, eps), do: Math.equals?(bearing(b1), bearing(b2), eps)

  @doc """
  Convert compass point to bearing from North in degrees.

  If the direction argument is already a float value,
  then transform it to be in the valid range `[0.0,360.0)`.
  """
  @spec bearing(G.direction()) :: E.degrees()
  def bearing(:N), do: 0.0
  def bearing(:NNE), do: 22.5
  def bearing(:NE), do: 45.0
  def bearing(:ENE), do: 67.5
  def bearing(:E), do: 90.0
  def bearing(:ESE), do: 112.5
  def bearing(:SE), do: 135.0
  def bearing(:SSE), do: 157.5
  def bearing(:S), do: 180.0
  def bearing(:SSW), do: 202.5
  def bearing(:SW), do: 225.0
  def bearing(:WSW), do: 247.5
  def bearing(:W), do: 270.0
  def bearing(:WNW), do: 292.5
  def bearing(:NW), do: 315.0
  def bearing(:NNW), do: 337.5
  def bearing(b) when is_float(b), do: 360.0 * Math.frac(b / 360.0)

  @doc "Add directions to give bearing in the range [0.0,360.0)."
  @spec add(G.direction(), G.direction()) :: G.bearing()
  def add(b1, b2), do: bearing(bearing(b1) + bearing(b2))
end

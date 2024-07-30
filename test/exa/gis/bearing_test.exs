defmodule Exa.Gis.BearingTest do
  use ExUnit.Case

  import Exa.Gis.Bearing

  alias Exa.Math

  doctest Exa.Gis.Bearing

  test "add bearing" do
    assert Math.equals?(280.0, add(100.0, 180.0))
    assert Math.equals?(120.0, add(300.0, 180.0))
    assert Math.equals?(80.0, add(-100.0, 180.0))
    assert Math.equals?(280.0, add(100.0, -180.0))
    assert Math.equals?(180.0, add(-100.0, -80.0))

    assert Math.equals?(110.0, add(:E, 20.0))
    assert Math.equals?(0.0, add(:NNW, 22.5))
  end
end

defmodule Exa.Gis.LocationTest do
  use ExUnit.Case

  use Exa.Gis.Constants

  import Exa.Gis.Location

  alias Exa.Math
  alias Exa.Http

  @dd {3 + 45.0 / 60.0, -(2.0 + 12.0 / 60.0 + 15.0 / 3600.0)}
  @d {{3 + 45.0 / 60.0, :N}, {2.0 + 12.0 / 60.0 + 15.0 / 3600.0, :W}}
  @dm {{3, 45.0, :N}, {2, 12.25, :W}}
  @dms {{3, 45, 0.0, :N}, {2, 12, 15.0, :W}}

  @london "51°30′26″N 0°7′39″W"
  @paris "48°51′24″N 2°21′8″E"

  doctest Exa.Gis.Location

  test "simple conversion and equality" do
    assert equals?(@dd, to_dd(@dd))
    assert equals?(@dd, to_dd(@d))
    assert equals?(@dd, to_dd(@dm))
    assert equals?(@dd, to_dd(@dms))

    assert equals?(@d, to_d(@dd))
    assert equals?(@d, to_d(@d))
    assert equals?(@d, to_d(@dm))
    assert equals?(@d, to_d(@dms))

    assert equals?(@dm, to_dm(@dd))
    assert equals?(@dm, to_dm(@d))
    assert equals?(@dm, to_dm(@dm))
    assert equals?(@dm, to_dm(@dms))

    assert equals?(@dms, to_dms(@dd))
    assert equals?(@dms, to_dms(@d))
    assert equals?(@dms, to_dms(@dm))
    assert equals?(@dms, to_dms(@dms))

    assert equals?({90.0, 43.2}, {90.0, -27.9})
    assert equals?({{90.0, :N}, {43.2, :E}}, {{90.0, :N}, {27.9, :W}})
    assert equals?({{90, 0, 0.0, :N}, {43, 15, 6.2, :E}}, {{90, 0, 0.0, :N}, {27, 47, 3.9, :W}})
    assert equals?({{90, 0, 0.0, :N}, {43, 15, 6.2, :E}}, {{90, 0, 0.0, :N}, {27, 47, 3.9, :W}})
  end

  test "format" do
    # dd

    fmt = format(@dd, @prec_dms, :comma, nil)
    assert "3.75, -2.20417" == fmt

    fmt = format(@d, @prec_dms, :comma, @sym_ascii)
    assert "3.75°, -2.20417°" == fmt

    # d

    fmt = format(@d, @prec_dms, :comma, nil)
    assert "3.75, -2.20417" == fmt

    fmt = format(@d, @prec_dms, :comma, @sym_ascii)
    assert "3.75°, -2.20417°" == fmt

    fmt = format(@d, @prec_dms, :nsew, nil)
    assert "3.75 N 2.20417 W" == fmt

    fmt = format(@d, @prec_dms, :nsew, @sym_ascii)
    assert "3.75° N 2.20417° W" == fmt

    # dm

    fmt = format(@dm, @prec_dms, :comma, nil)
    assert "3 45.0, -2 12.25" == fmt

    fmt = format(@dm, @prec_dms, :comma, @sym_ascii)
    assert "3°45.0', -2°12.25'" == fmt

    fmt = format(@dm, @prec_dms, :nsew, nil)
    assert "3 45.0 N 2 12.25 W" == fmt

    fmt = format(@dm, @prec_dms, :nsew, @sym_ascii)
    assert "3°45.0' N 2°12.25' W" == fmt

    # dms

    fmt = format(@dms, @prec_dms, :comma, nil)
    assert "3 45 0.0, -2 12 15.0" == fmt

    fmt = format(@dms, @prec_dms, :comma, @sym_ascii)
    assert "3°45'0.0\", -2°12'15.0\"" == fmt

    fmt = format(@dms, @prec_dms, :nsew, nil)
    assert "3 45 0.0 N 2 12 15.0 W" == fmt

    fmt = format(@dms, @prec_dms, :nsew, @sym_ascii)
    assert "3°45'0.0\" N 2°12'15.0\" W" == fmt
  end

  test "parse" do
    # dd

    toks = parse("3.75, -2.20417")
    assert {3.75, -2.20417} == toks

    toks = parse("3.75\u00BA, -2.20417\u00B0")
    assert {3.75, -2.20417} == toks

    # d

    toks = parse("3.75 N 2.20417 W")
    assert {{3.75, :N}, {2.20417, :W}} == toks

    toks = parse("3.75°S 2.20417°E")
    assert {{3.75, :S}, {2.20417, :E}} == toks

    toks = parse("3.75 N, 2.20417 W")
    assert {{3.75, :N}, {2.20417, :W}} == toks

    toks = parse("3.75°S, 2.20417°E")
    assert {{3.75, :S}, {2.20417, :E}} == toks

    # dm

    toks = parse("3 45.0, -2 12.25")
    assert {{3, 45.0, :N}, {2, 12.25, :W}} == toks

    toks = parse("3°45.0\u2032, -2°12.25\u2032")
    assert {{3, 45.0, :N}, {2, 12.25, :W}} == toks

    toks = parse("3 45.0 N 2 12.25 W")
    assert {{3, 45.0, :N}, {2, 12.25, :W}} == toks

    toks = parse("3°45.0'S 2°12.25'E")
    assert {{3, 45.0, :S}, {2, 12.25, :E}} == toks

    # dms

    toks = parse("3 45 0.0, -2 12 15.0")
    assert {{3, 45, 0.0, :N}, {2, 12, 15.0, :W}} == toks

    toks = parse("3°45\u20320.0\u2033, -2°12\u203215.0\u2033")
    assert {{3, 45, 0.0, :N}, {2, 12, 15.0, :W}} == toks

    toks = parse("3 45 0.0 N 2 12 15.0 W")
    assert {{3, 45, 0.0, :N}, {2, 12, 15.0, :W}} == toks

    toks = parse("3°45'0.0\"S 2°12'15.0\"E")
    assert {{3, 45, 0.0, :S}, {2, 12, 15.0, :E}} == toks
  end

  test "parse errors" do
    assert "foo" == parse("foo")

    assert_raise ArgumentError, fn -> parse!("foo") end
    assert_raise ArgumentError, fn -> parse!("123foo") end

    assert_raise ArgumentError, fn -> parse!("3°45.0°S 2°12.25'E") end
    assert_raise ArgumentError, fn -> parse!("3°45.0'S 2°12.25\"E") end
  end

  test "distances" do
    eqlat1 =
      distance(
        :equirect,
        {{0, 30, 0.0, :S}, {0, 0, 0.0, :E}},
        {{0, 30, 0.0, :N}, {0, 0, 0.0, :E}}
      )

    assert @lat1_eqtr == eqlat1

    eqlon1 =
      distance(
        :equirect,
        {{0, 0, 0.0, :N}, {0, 30, 0.0, :W}},
        {{0, 0, 0.0, :N}, {0, 30, 0.0, :E}}
      )

    assert @lon1_eqtr == eqlon1

    npole =
      distance(
        :equirect,
        {{90, 0, 0.0, :N}, {46, 30, 51.0, :W}},
        {{90, 0, 0.0, :N}, {23, 30, 22.3, :E}}
      )

    assert Math.zero?(npole)
  end

  test "london paris" do
    # coordinates from Wikipedia
    london = parse!(@london)
    paris = parse!(@paris)
    dist = distance(:equirect, london, paris)
    have = distance(:haversine, london, paris)
    diff = abs(have - dist)
    assert diff < 200.0
    percent = 100 * diff / have
    assert percent < 0.05
  end

  test "add" do
    origin = {0.0, 0.0}
    assert {10.0, 20.0} = add(origin, 10.0, 20.0)
    assert {-10.0, -20.0} = add(origin, -10.0, -20.0)

    # wrap longitude
    assert {10.0, -160.0} = add(origin, 10.0, 200.0)
    assert {10.0, 0.0} = add(origin, 10.0, 360.0)

    # flip longitude
    assert {80.0, -160.0} = add(origin, 100.0, 20.0)
    assert equals?({-20.0, -160.0}, add(origin, 200.0, 20.0))
    assert {-80.0, 20.0} = add(origin, 280.0, 20.0)
  end

  test "initial bearing" do
    baghdad = parse!("35.0 N,45.0 E")
    osaka = parse!("35.0 N,135.0 E")
    heading = heading(baghdad, osaka)
    assert 60.0 < heading and heading < 61.0
  end

  test "google maps" do
    if Http.internet?() do
      :ok
    else
      raise RuntimeError, message: "Not connected to the internet"
    end

    goog(false)
    goog(true)
  end

  defp goog(https?) do
    url = to_google({{54, 28, 0.0, :N}, {56, 16, 0.0, :E}}, 10, https?)
    response = Http.get(url)
    {200, "OK", content, body} = response
    true = is_binary(body)
    %{content_length: _, mime_type: "text/html", charset: "UTF-8"} = content
    IO.inspect(content)
  end
end

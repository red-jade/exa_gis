defmodule Exa.Gis.Constants do
  @moduledoc """
  Constants for GIS data.
  """

  defmacro __using__(_) do
    quote do
      # degree minutes seconds for formatting output
      @sym_ascii {"°", "'", "\""}
      @sym_uni1 {"°", "\u2032", "\u2033"}
      @sym_uni2 {"°", "\u02B9", "\u02BA"}

      # degree delimiters accepted for parsing input
      # include the male ordinal as it is often confused with degree
      # include ring above, just in case
      @deg_syms [?°, 0x00BA, 0x02DA]

      # minute delimiters accepted for parsing input
      # include the '9' right single quotation mark
      # as it is often auto-converted by MS Word (aaagh)
      @min_syms [?', 0x2032, 0x02B9, 0x2019]

      # second delimiters accepted for parsing input
      # include the '99' right double quotation mark
      # as it is often auto-converted by MS Word (aaagh)
      @sec_syms [?", 0x2033, 0x02BA, 0x201D]

      # default precision for degree, minute second
      # accuracy is approx:
      #  degree 5 dp -> 1.11 m
      #  minute 3 dp -> 1.85 m
      #  second 1 dp -> 3.08 m
      @prec_dms {5, 3, 1}

      # distance for 1 degree latitude (m)
      # simple formula uses linear expression: 
      # @lat1_eqtr + @delta_pole * |lat| / 90.0
      @lat1_eqtr 110_574
      @delta_pole 1_124

      # distance for 1 degree longitude (m)
      # actual distance = @lon1_eqtr * cos(lat)
      @lon1_eqtr 111_320

      # mean radius of the Earth (m)
      # for spherical approximation
      @mean_radius 6_371_000
    end
  end
end

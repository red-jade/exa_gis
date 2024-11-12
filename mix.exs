defmodule Exa.Gis.MixProject do
  use Mix.Project

  @lib  :exa_gis
  @name "Exa Gis"
  @ver  "0.3.1"

  # umbrella project
  @exa {:exa,
        git: "https://github.com/red-jade/exa.git",
        branch: "main",
        only: [:dev, :test],
        runtime: false}

  # dependency config code
  @mix_util Path.join(["deps", "exa", "mix_util.ex"])

  def project do
    exa_deps = cond do
       System.fetch_env("EXA_BUILD") in [:error, {:ok, "rel"}] -> 
        # read auto-generated deps file
        "deps.ex" |> Code.eval_file() |> elem(0) 

      File.regular?(@mix_util) ->
        # generate deps using exa umbrella project
        if not Code.loaded?(Exa.MixUtil) do
          [{Exa.MixUtil, _}] = Code.compile_file(@mix_util)
        end

        Exa.MixUtil.exa_deps(@lib, exa_libs())
      true ->
        # bootstrap from exa umbrella project
        [@exa]
      end

    [
      app: @lib,
      name: @name,
      version: @ver,
      elixir: "~> 1.17",
      erlc_options: [:verbose, :report_errors, :report_warnings, :export_all],
      start_permanent: Mix.env() == :prod,
      deps: exa_deps ++ local_deps(),
      docs: docs(),
      test_pattern: "*_test.exs",
      dialyzer: [flags: [:no_improper_lists]]
    ]
  end

  def application do
    [
      extra_applications: extra(Mix.env())
    ]
  end

  defp extra(:prod), do: [:logger]
  defp extra(_), do: [:logger, :inets, :ssl]

  def docs do
    [
      main: "readme",
      output: "doc/api",
      assets: %{"assets" => "assets"},
      extras: ["README.md"]
    ]
  end

  defp exa_libs() do
    [  
      :exa_core, 
      :exa_space,
      :exa_json,
      :dialyxir, 
      :ex_doc,
      :benchee,

      # test parser for CSVs, not runtime dependency
      # but no way to specify that in current exa framework
      # ... only: [:dev, :test], runtime: false
      :exa_csv
    ] 
  end

  defp local_deps() do 
    [
      # GeoJSON files for testing (no code)
      {:geo_countries,
       git: "https://github.com/datasets/geo-countries.git",
       branch: "main",
       only: [:dev, :test],
       runtime: false,
       compile: "ls",
       app: false}
    ]
  end
end

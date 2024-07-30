defmodule Exa.Gis.MixProject do
  use Mix.Project

  def project do
    [
      app: :exa_gis,
      name: "Exa Gis",
      version: "0.1.0",
      elixir: "~> 1.15",
      erlc_options: [:verbose, :report_errors, :report_warnings, :export_all],
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      docs: docs(),
      test_pattern: "*_test.exs",
      dialyzer: [flags: [:no_improper_lists]]
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  def docs do
    [
      main: "readme",
      output: "doc/api",
      assets: %{"assets" => "assets"},
      extras: ["README.md"]
    ]
  end

  defp deps do
    [
      # runtime code dependencies ----------

      {:exa, git: "https://github.com/red-jade/exa_core.git", tag: "v0.1.5"},
      {:exa_space, git: "https://github.com/red-jade/exa_space.git", tag: "v0.1.5"},
      {:exa_json, git: "https://github.com/red-jade/exa_json.git", tag: "v0.1.5"},

      # building, documenting, testing ----------

      # typechecking
      {:dialyxir, "~> 1.0", only: [:dev, :test], runtime: false},

      # documentation
      {:ex_doc, "~> 0.30", only: [:dev, :test], runtime: false},

      # benchmarking
      {:benchee, "~> 1.0", only: [:dev, :test]},

      # GeoJSON files for testing (no code)
      {:geo_countries,
       git: "https://github.com/datasets/geo-countries.git",
       only: :test,
       runtime: false,
       app: false},

      # test parser for CSVs
      {:exa_csv, 
        git: "https://github.com/red-jade/exa_csv.git",
        tag: "v0.1.5",
        only: [:dev, :test],
        runtime: false}
    ]
  end
end

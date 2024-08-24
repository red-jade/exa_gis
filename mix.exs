defmodule Exa.Gis.MixProject do
  use Mix.Project

  def project do
    [
      app: :exa_gis,
      name: "Exa Gis",
      version: "0.2.0",
      elixir: "~> 1.15",
      erlc_options: [:verbose, :report_errors, :report_warnings, :export_all],
      start_permanent: Mix.env() == :prod,
      deps: exa_deps(:exa_space, exa_libs()) ++ local_deps(),
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
      # # GeoJSON files for testing (no code)
      {:geo_countries,
       git: "https://github.com/datasets/geo-countries.git",
       only: [:dev, :test],
       runtime: false,
       app: false}
    ]
  end

  # ---------------------------
  # ***** EXA boilerplate *****
  # shared by all EXA libraries
  # ---------------------------
  
  # main entry point for dependencies
  defp exa_deps(name, libs), do: System.argv() |> hd() |> do_deps(name,libs)

  defp do_deps("exa", _name, _libs), do: [exa_project()]

  defp do_deps("deps.clean", _name, _libs) do
    Enum.each([:local, :main, :tag], fn scope ->
      scope |> deps_file() |> File.rm()
    end)

    [exa_project()]
  end

  defp do_deps(cmd, name, libs) do
    scope = arg_build()
    deps_path = deps_file(scope)

    if not File.exists?(deps_path) do
      # invoke the exa project mix task to generate dependencies
      exa_args = Enum.map([:exa, scope | libs], &to_string/1)

      case System.cmd("mix", exa_args) do
        {_out, 0} -> :ok
        {out, n} -> args = Enum.join(exa_args, " ")
        raise RuntimeError, message: "Failed 'mix #{args}' status #{n} '#{out}'"
      end

      if not File.exists?(deps_path) do
        raise RuntimeError, message: "Cannot create dependency file: #{deps_path}"
      end
    end

    deps = deps_path |> Code.eval_file() |> elem(0)

    if String.starts_with?(cmd, ["deps", "compile"]) do
      IO.inspect(deps, label: "#{name} #{scope}")
    end
    [exa_project()|deps]
  end

  # the deps literal file to be written for each scope
  defp deps_file(scope), do: Path.join([".", "deps", "deps_#{scope}.ex"])

  # parse the build scope from:
  # - mix command line --build option
  # - MIX_BUILD system environment variable
  # - default to "tag"
  defp arg_build() do
    default = case System.fetch_env("MIX_BUILD") do
      :error -> "tag"
      {:ok, mix_build} -> mix_build
    end

    System.argv() 
    |> tl() 
    |> OptionParser.parse(strict: [build: :string])
    |> elem(0)
    |> Keyword.get(:build, default)
    |> String.to_atom()
  end

  # the main exa umbrella library project
  # provides the 'mix exa' task to generate dependencies
  defp exa_project() do
    {
      :exa,
      # git: "https://github.com/red-jade/exa.git", 
      # branch: "main",
      path: "../exa", only: [:dev, :test], runtime: false
    }
  end
end

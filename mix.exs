defmodule Rollbax.Mixfile do
  use Mix.Project

  def project() do
    [app: :rollbax,
     version: "0.6.0",
     elixir: "~> 1.0",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     description: description(),
     package: package(),
     deps: deps(Mix.env)]
  end

  def application() do
    [applications: [:logger, :hackney, :poison],
     mod: {Rollbax, []}]
  end

  defp deps(env) do
    [{:hackney, "~> 1.4.7"},
     {:poison,  "~> 1.4"},
     {:plug,    "~> 1.0.3", optional: (env !== :test)},
     {:cowboy,  "~> 1.0.4", optional: (env !== :test)}]
  end

  defp description() do
    "Exception tracking and logging from Elixir to Rollbar"
  end

  defp package() do
    [maintainers: ["Aleksei Magusev"],
     licenses: ["ISC"],
     links: %{"GitHub" => "https://github.com/elixir-addicts/rollbax"}]
  end
end

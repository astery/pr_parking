defmodule Cached.MixProject do
  use Mix.Project

  def project do
    [
      app: :cached,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.12",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {Cached.Application, []}
    ]
  end

  defp deps do
    [
      {:hammox, "~> 0.5", only: :test}
    ]
  end
end

defmodule Dogfight.MixProject do
  use Mix.Project

  def project do
    [
      app: :dogfight,
      version: "0.1.0",
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {Dogfight.Application, []},
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:libcluster, "~> 3.3"},
      {:horde, "~> 0.9"},
      {:uuid, "~> 1.1"}
    ]
  end

  defp aliases do
    [
      # (2)
      test: "test --no-start"
    ]
  end
end

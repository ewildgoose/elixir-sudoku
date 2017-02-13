defmodule Sudoku.Mixfile do
  use Mix.Project

  def project do
    [app: :sudoku,
     version: "1.0.0",
     elixir: "~> 1.2",
     description: "Sudoku solver in Elixir, which prefers to use heuristics over guessing",
     package: package(),
     source_url: "https://github.com/ewildgoose/elixir-sudoku",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps()]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [applications: [:logger]]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
  [{:earmark, "~> 1.1", only: :dev},
   {:ex_doc, "~> 0.14", only: :dev}]
  end

  defp package do
    [
     files: ["lib", "priv", "mix.exs", "README*", "LICENSE*"],
     maintainers: ["Ed Wildgoose"],
     licenses: ["Apache 2.0"],
     links: %{"GitHub" => "https://github.com/ewildgoose/elixir-sudoku"}
   ]
  end

end

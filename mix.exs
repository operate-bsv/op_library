defmodule Operate.Library do
  use Mix.Project

  def project do
    [
      app: :op_library,
      version: "0.1.0-dev.1",
      elixir: "~> 1.9",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:operate, git: "https://github.com/operate-bsv/agent.git"},
      {:luerl, git: "https://github.com/libitx/luerl.git", branch: "develop", override: true},
      {:tesla, "~> 1.2.1"}
    ]
  end
end

defmodule FB.Library do
  use Mix.Project

  def project do
    [
      app: :fb_library,
      version: "0.1.0-dev.1",
      elixir: "~> 1.9",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:fb, git: "https://github.com/functional-bitcoin/agent.git"}
    ]
  end
end

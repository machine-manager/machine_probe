defmodule MachineProbe.Mixfile do
	use Mix.Project

	def project do
		[
			app: :machine_probe,
			version: "0.1.0",
			elixir: "~> 1.5-dev",
			build_embedded: Mix.env == :prod,
			start_permanent: Mix.env == :prod,
			escript: [main_module: MachineProbe],
			deps: deps()
		]
	end

	defp deps do
		[
			{:converge, ">= 0.1.1"},
			{:poison,   ">= 3.1.0"},
		]
	end
end

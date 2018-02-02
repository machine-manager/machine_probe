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
			{:gears,    ">= 0.1.0"},
			{:converge, ">= 0.1.1"},
			{:jason,    ">= 1.0.0"},
		]
	end
end

defmodule MachineProbe do
	@doc """
	Probes a machine and outputs the data as a binary term to stdout.
	"""
	def main(_argv) do
		meminfo   = Converge.Util.get_meminfo()
		probe_out = %{
			:ram_mb => meminfo["MemTotal"] / (1024 * 1024) |> Float.floor |> round
		}
		:ok = IO.write(:erlang.term_to_binary(probe_out))
	end
end

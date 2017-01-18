defmodule MachineProbe do
	@doc """
	Probes a machine and outputs the data as a binary term to stdout.
	"""
	def main(_argv) do
		meminfo   = Converge.Util.get_meminfo()
		cpuinfo   = Converge.Util.get_cpuinfo()
		probe_out = %{
			ram_mb:           meminfo["MemTotal"] / (1024 * 1024) |> Float.floor |> round,
			cpu_model_name:   cpuinfo.model_name,
			core_count:       cpuinfo.cores,
			thread_count:     cpuinfo.threads,
			country:          Converge.Util.get_country(),
			kernel:           get_kernel(),
			boot_time_ms:     get_boot_time_ms(),
			pending_upgrades: get_pending_upgrades(),
		}
		:ok = IO.write(Poison.encode!(probe_out))
	end

	defp get_kernel() do
		{out, 0} = System.cmd("uname", ["--kernel-name", "--kernel-release"])
		out |> String.trim_trailing
	end

	# This assumes apt-get update was already run recently.
	defp get_pending_upgrades() do
		{out, 0} = System.cmd("apt-get", ["--simulate", "dist-upgrade"])
		Regex.scan(~r/^Inst (\S+)/m, out, capture: :all_but_first)
		|> Enum.map(&hd/1)
	end

	defp get_boot_time_ms() do
		now_ms    = :erlang.system_time(:millisecond)
		{out, 0}  = System.cmd("cat", ["/proc/uptime"])
		uptime_ms = out |> String.split(" ") |> hd |> String.to_float |> Kernel.*(1000) |> round
		now_ms - uptime_ms
	end
end

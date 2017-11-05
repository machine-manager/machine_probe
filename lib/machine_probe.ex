alias Gears.StringUtil

defmodule MachineProbe do
	@doc """
	Probes a machine and outputs the data as a binary term to stdout.
	"""
	def main(_argv) do
		meminfo   = Converge.Util.get_meminfo()
		cpuinfo   = Converge.Util.get_cpuinfo()
		probe_out = %{
			ram_mb:           meminfo["MemTotal"] / (1024 * 1024) |> Float.floor |> round,
			cpu_architecture: cpuinfo.architecture,
			cpu_model_name:   cpuinfo.model_name,
			core_count:       cpuinfo.cores,
			thread_count:     cpuinfo.threads,
			kernel:           get_kernel(),
			boot_time_ms:     get_boot_time_ms(),
			pending_upgrades: get_pending_upgrades(),
			time_offset:      get_time_offset(),
		}
		:ok = IO.write(Poison.encode!(probe_out))
	end

	defp get_kernel() do
		{out, 0} = System.cmd("uname", ["--kernel-name", "--kernel-release", "--kernel-version"])
		String.trim_trailing(out)
	end

	# This assumes apt-get update was already run recently.
	defp get_pending_upgrades() do
		case get_uid() do
			0 ->
				# Last upgrade may have been interrupted
				{_, 0} = System.cmd("dpkg", ["--configure", "-a"])
			_ -> nil
		end
		{out, 0} = System.cmd("apt-get", ["dist-upgrade", "--simulate", "--no-install-recommends"])
		inst_lines           = Regex.scan(~r/^Inst /m, out)
		# These lack an [oldversion]
		pending_new_packages = Regex.scan(~r/^Inst (\S+) \((\S+) (.*?) \[(\S+)\]\)/m, out, capture: :all_but_first)
		|> Enum.map(fn [name, new_version, origins, architecture] ->
		     %{
		       name:         name,
		       new_version:  new_version,
		       origins:      String.split(origins, ", "),
		       architecture: architecture,
		     }
		   end)
		pending_upgrades     = Regex.scan(~r/^Inst (\S+) \[([^\]]+)\] \((\S+) (.*?) \[(\S+)\]\)/m, out, capture: :all_but_first)
		|> Enum.map(fn [name, old_version, new_version, origins, architecture] ->
		     %{
		       name:         name,
		       old_version:  old_version,
		       new_version:  new_version,
		       origins:      String.split(origins, ", "),
		       architecture: architecture,
		     }
		   end)
		if length(pending_upgrades) + length(pending_new_packages) != length(inst_lines) do
			raise(RuntimeError,
				"""
				Failed to parse all Inst output from `apt-get --simulate dist-upgrade`:

				#{out}
				""")
		end
		pending_upgrades
	end

	defp get_uid() do
		{uid_s, 0} = System.cmd("id", ["-u"])
		uid_s
		|> String.trim_trailing
		|> String.to_integer
	end

	defp get_boot_time_ms() do
		now_ms    = :erlang.system_time(:millisecond)
		{out, 0}  = System.cmd("cat", ["/proc/uptime"])
		uptime_ms = out |> String.split(" ") |> hd |> String.to_float |> Kernel.*(1000) |> round
		now_ms - uptime_ms
	end

	defp get_time_offset() do
		case System.cmd("chronyc", ["tracking"]) do
			{out, 0} ->
				# e.g. "System time     : 0.001385530 seconds slow of NTP time"
				line        = out    |> StringUtil.grep(~r/^System time +: /) |> hd
				[_, string] = line   |> String.split(" : ", parts: 2)
				offset_s    = string |> String.split(" ") |> hd
				offset_s    = cond do
					String.ends_with?(string, " seconds slow of NTP time") -> "-" <> offset_s
					String.ends_with?(string, " seconds fast of NTP time") -> offset_s
					true ->
						raise(RuntimeError, "Unexpected line from `chronyc tracking`: #{inspect line}")
				end
				offset_s
			{_, _} -> nil
		end
	end
end

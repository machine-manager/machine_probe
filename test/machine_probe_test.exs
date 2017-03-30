defmodule MachineProbeTest do
	use ExUnit.Case
	import ExUnit.CaptureIO

	test "main" do
		out = capture_io(fn ->
			MachineProbe.main([])
		end)
		Poison.decode!(out)
	end
end

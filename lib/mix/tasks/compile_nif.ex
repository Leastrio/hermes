defmodule Mix.Tasks.Compile.TunTapNif do
  def run(_) do
    {result, _err} = System.cmd("make", [])
    IO.binwrite(result)
  end
end
